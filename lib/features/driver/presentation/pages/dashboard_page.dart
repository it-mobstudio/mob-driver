import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:m_o_b_demand_side/core/location/location_permission_helper.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/data/realtime/driver_realtime.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_home_map.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_flow.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_top_bar.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/finder_video.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/map_sheet.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/vehicle_art.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/widgets/skeleton_shimmer.dart';

/// "Today": the duty toggle and the day's working time over a map centred on
/// the driver, with a sheet that shows the active trip (or the wait for one)
/// — and the profile button, which opens the profile page: the way to
/// everything else (trips, wallet, vehicles, documents).
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage(
      {super.key, this.checkLocationPermission, this.mapBuilder});

  static const routeName = 'DriverDashboard';
  static const routePath = DriverRoutes.dashboard;

  /// Test seam for the OS location prompt.
  final LocationPermissionCheck? checkLocationPermission;

  /// Replaces the Google map — used by tests, which can't host a platform
  /// view (the same seam [TripPage] uses for its own map).
  final DriverMapBuilder? mapBuilder;

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  late final VoidCallback _refreshHook = _refresh;

  /// How much of the map's bottom edge the resting sheet covers, so the
  /// map's floating buttons and the camera's centre stay above it.
  double _panelHeight = 220;

  @override
  void initState() {
    super.initState();
    // Re-selecting Today (from the profile menu's back button) refreshes it.
    refreshDriverDashboard = _refreshHook;
  }

  @override
  void dispose() {
    if (refreshDriverDashboard == _refreshHook) refreshDriverDashboard = null;
    super.dispose();
  }

  Future<void> _refresh() => _cubit.load(silent: true);

  /// Days left on the licence when it's about to lapse (a month's notice),
  /// otherwise null. An expired one locks the account, so there's no banner.
  int? _licenceWarning(DriverProfile profile) {
    final days = profile.licenceDaysLeft;
    return days != null && days >= 0 && days <= 30 ? days : null;
  }

  DriverMapData _mapData(GeoPoint? point, Trip? trip) {
    final driver = point == null ? null : LatLng(point.latitude, point.longitude);
    if (trip == null || !trip.status.isActive) {
      return DriverMapData(driver: driver);
    }
    return DriverMapData(
      driver: driver,
      pickup: trip.pickup.hasCoordinates
          ? LatLng(trip.pickup.latitude!, trip.pickup.longitude!)
          : null,
      drop: trip.drop.hasCoordinates
          ? LatLng(trip.drop.latitude!, trip.drop.longitude!)
          : null,
      route: decodePolyline(trip.routePolyline, precision: trip.polylinePrecision)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(),
    );
  }

  void _openStats(DriverStats stats) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _StatsSheet(stats: stats),
      );

  /// A quick way to reach the driver's emergency contact (or, if none is
  /// saved, to go add one) without hunting through the profile menu first.
  void _openSos(DriverProfile? profile) {
    final phone = profile?.emergencyContactPhone ?? '';
    final name = profile?.emergencyContactName ?? '';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: Text(
          phone.isEmpty
              ? 'No emergency contact is saved yet. Add one from your profile so it’s ready if you ever need it.'
              : 'Call your emergency contact${name.isEmpty ? '' : ' ($name)'}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
          if (phone.isNotEmpty)
            TextButton(
              key: const Key('sos_call'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(callPhone(phone));
              },
              child: const Text('Call now',
                  style: TextStyle(
                      color: DriverColors.red, fontWeight: FontWeight.w800)),
            )
          else
            TextButton(
              key: const Key('sos_add_contact'),
              onPressed: () {
                Navigator.pop(ctx);
                context.push(DriverRoutes.editProfile);
              },
              child: const Text('Add contact'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverSessionCubit, DriverSessionState>(
      builder: (context, state) {
        final profile = state.profile;
        return Scaffold(
          backgroundColor: DriverColors.surface,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: profile == null
                ? SafeArea(
                    key: const ValueKey('loading'),
                    bottom: false,
                    child: _initial(state))
                : KeyedSubtree(
                    key: const ValueKey('content'),
                    child: _content(context, state, profile)),
          ),
        );
      },
    );
  }

  Widget _content(
      BuildContext context, DriverSessionState state, DriverProfile profile) {
    final mapBuilder = widget.mapBuilder ?? defaultDriverMapBuilder;
    final trip = state.activeTrip;

    return Column(children: [
      // The pill, any warning banners, and the working-time bar sit on a
      // solid white header — the map only starts below it, never bleeding
      // through behind them (a transparent overlay here was the bug).
      DutyHeaderSurface(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DutyStatusRow(
              avatar: DriverAvatar(profile.fullName, size: 44, photoUrl: profile.photoUrl),
              online: state.isOnline,
              busy: state.dutyBusy,
              onToggle: (goOnline) => goOnline
                  ? startDutyFlow(context,
                      checkPermission: widget.checkLocationPermission)
                  : endDutyFlow(context),
              onProfileTap: () => context.go(DriverRoutes.profile),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(children: [
                if (!profile.isEligible) ...[
                  const SizedBox(height: 10),
                  _VerificationCard(profile: profile),
                ] else if (_licenceWarning(profile) case final days?) ...[
                  const SizedBox(height: 10),
                  InfoBanner(
                    key: const Key('licence_banner'),
                    solid: true,
                    text: days == 0
                        ? 'Your driving licence expires today. Renew it to keep taking trips.'
                        : 'Your driving licence expires in $days day${days == 1 ? '' : 's'}. Renew it to keep taking trips.',
                    icon: Icons.event_busy_rounded,
                    action: TextButton(
                      onPressed: () => context.push(DriverRoutes.verification),
                      child: const Text('View'),
                    ),
                  ),
                ],
                if (state.isOnline && state.locationUnavailable) ...[
                  const SizedBox(height: 10),
                  InfoBanner(
                    key: const Key('location_banner'),
                    solid: true,
                    text:
                        'We can’t see your location, so you won’t be assigned trips. Turn on GPS and allow location access.',
                    icon: Icons.location_off_rounded,
                    action: TextButton(
                      onPressed: () =>
                          (widget.checkLocationPermission ??
                                  ensureLocationPermission)(context),
                      child: const Text('Fix'),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 10),
            WorkingTimeBanner(
              online: state.isOnline,
              dutyStartedAt: _cubit.dutyStartedAt,
              todayEarnings: state.stats.today.earnings,
              onTap: () => _openStats(state.stats),
            ),
          ]),
        ),
      ),
      Expanded(
        child: Stack(children: [
          Positioned.fill(
            child: ValueListenableBuilder<GeoPoint?>(
              valueListenable: _cubit.position,
              builder: (context, point, _) => mapBuilder(
                context,
                _mapData(point, trip),
                _panelHeight,
                () => _openSos(profile),
              ),
            ),
          ),
          Positioned.fill(child: _sheet(state)),
        ]),
      ),
    ]);
  }

  /// The sheet over the map: what's happening now (off duty / looking / the
  /// active trip) at rest, and the trip's route on the way up.
  Widget _sheet(DriverSessionState state) {
    final trip = state.activeTrip;
    final Widget peek;
    Widget? details;
    final String key;
    if (trip != null) {
      key = trip.id;
      peek = _ActiveTripPanel(trip: trip);
      details = _ActiveTripDetails(trip: trip);
    } else if (!state.tripKnown) {
      key = 'loading';
      peek = const SkeletonShimmer(child: SkeletonBlock(height: 92, radius: 18));
    } else if (!state.isOnline) {
      key = 'offline';
      peek = _OfflinePanel(
          busy: state.dutyBusy,
          vehicle: state.profile?.currentVehicle,
          checkLocationPermission: widget.checkLocationPermission);
    } else {
      key = 'looking';
      peek = const _LookingForOrdersPanel();
    }

    return MapSheet(
      onRestingHeight: (height) {
        if ((height - _panelHeight).abs() > 1) {
          setState(() => _panelHeight = height);
        }
      },
      peek: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey(key), child: peek),
        ),
      ),
      more: details,
    );
  }

  Widget _initial(DriverSessionState state) {
    if (state.load == SessionLoad.failed) {
      return KeyedSubtree(
        key: const ValueKey('error'),
        child: CenteredMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load your dashboard',
          message: state.loadError,
          actionLabel: 'Retry',
          onAction: () => _cubit.load(),
        ),
      );
    }
    return const _DashboardSkeleton(key: ValueKey('skeleton'));
  }
}

/// The dashboard's shape in grey, shown only on a true cold load (no cached
/// profile to paint yet) so the screen has structure from the first frame.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonShimmer(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(children: [
              SkeletonBlock(height: 48, radius: 24),
              SizedBox(height: 14),
              SkeletonBlock(height: 64, radius: 16),
              SizedBox(height: 14),
              SkeletonBlock(height: 56, radius: 14),
              SizedBox(height: 320),
              SkeletonBlock(height: 132, radius: 18),
            ]),
          ),
        ),
      );
}

// -- top overlay --------------------------------------------------------

/// Why the driver can't take trips yet and the one thing to do about it:
/// wait (documents in review), fix (something was sent back), or — for the odd
/// case that's neither — the plain list of what's blocking them.
class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final rejected = profile.rejectedDocuments;
    final status = profile.onboardingStatus;

    final (color, icon, title, lines, action) = switch (status) {
      OnboardingStatus.underReview => (
          DriverColors.orange,
          Icons.hourglass_top_rounded,
          'Your documents are being reviewed',
          <String>[
            'We’ll unlock trips as soon as you’re approved — usually within a day.'
          ],
          'View documents',
        ),
      OnboardingStatus.actionRequired => (
          DriverColors.red,
          Icons.error_outline_rounded,
          'Some documents need fixing',
          [
            for (final (name, item) in rejected)
              '$name: ${item.rejectionNote ?? 'sent back for a fix'}',
          ],
          'Fix documents',
        ),
      _ => (
          DriverColors.red,
          Icons.gpp_maybe_outlined,
          'You can’t take trips yet',
          profile.blockers.isEmpty
              ? <String>['Your account isn’t eligible for trips right now.']
              : profile.blockers,
          'View documents',
        ),
    };

    return DriverCard(
      key: const Key('verification_card'),
      onTap: () => context.push(DriverRoutes.verification),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: DriverColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 10),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line,
                style: const TextStyle(
                    color: DriverColors.muted, fontSize: 12.5, height: 1.4)),
          ),
        const SizedBox(height: 6),
        Text(action,
            key: const Key('verification_action'),
            style: TextStyle(
                color: color, fontSize: 13.5, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// -- the sheet ------------------------------------------------------------

class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel({required this.busy, this.vehicle, this.checkLocationPermission});
  final bool busy;
  final DriverVehicle? vehicle;
  final LocationPermissionCheck? checkLocationPermission;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          // The driver's own kind of vehicle, parked — it rolls in once.
          Container(
            width: 92,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF3F7FD), DriverColors.blueSoft],
              ),
            ),
            alignment: Alignment.center,
            child: _RollIn(
              child: VehicleArt(
                  name: vehicle?.vehicleTypeName, category: vehicle?.category, width: 66),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('You’re off duty',
                  key: Key('no_trip_title'),
                  style: TextStyle(
                      color: DriverColors.ink, fontSize: 19, letterSpacing: -.3, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Go on duty to start receiving orders near you.',
                  style: TextStyle(color: DriverColors.muted, fontSize: 13, height: 1.35)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Start duty',
          icon: Icons.play_arrow_rounded,
          loading: busy,
          onPressed: () =>
              startDutyFlow(context, checkPermission: checkLocationPermission),
        ),
      ]);
}

/// Drives its child in from the right with a small overshoot — once.
class _RollIn extends StatelessWidget {
  const _RollIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (_, t, c) => Transform.translate(offset: Offset(60 * t, 0), child: c),
      child: child,
    );
  }
}

/// Online with nothing assigned: the radar, and a status line that keeps
/// changing so a driver waiting a while can see the app is still at work.
class _LookingForOrdersPanel extends StatelessWidget {
  const _LookingForOrdersPanel();

  static const _messages = [
    'Finding orders near you',
    'Looking for your next order',
    'Still searching nearby',
    'Hang tight, we’re on it',
  ];

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        const FinderAnimation(size: 120),
        const SizedBox(height: 4),
        const SizedBox(
          height: 26,
          child: RotatingStatusText(
              key: Key('no_trip_title'), messages: _messages),
        ),
        const SizedBox(height: 6),
        // Orders arrive by push; while that link is down they still come,
        // just later (the app asks every so often) — say so rather than
        // let the driver wonder why it's quiet.
        ValueListenableBuilder<RealtimeStatus>(
          valueListenable: context.read<DriverSessionCubit>().realtimeStatus,
          builder: (_, status, __) => status == RealtimeStatus.connecting
              ? const Row(
                  key: Key('reconnecting_hint'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.6, color: DriverColors.orange),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Reconnecting — new orders may take a moment',
                          style: TextStyle(
                              color: DriverColors.orange,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                )
              : const Text(
                  'Keep the app open — we’ll ring and vibrate when an order arrives.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: DriverColors.muted, fontSize: 12.5, height: 1.4)),
        ),
      ]);
}

/// The active trip at rest: what stage it's at, and the way into it.
class _ActiveTripPanel extends StatelessWidget {
  const _ActiveTripPanel({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: DriverColors.blueSoft, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: _RollIn(child: VehicleArt(name: trip.vehicleTypeName, width: 42)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: DriverColors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: DriverColors.blue.withValues(alpha: .5), blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
                const SizedBox(width: 7),
                const Text('ACTIVE TRIP',
                    style: TextStyle(
                        color: DriverColors.blue, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8)),
              ]),
              const SizedBox(height: 3),
              Text(trip.status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DriverColors.ink, fontSize: 18, letterSpacing: -.3, fontWeight: FontWeight.w800)),
            ]),
          ),
          StatusPill(trip.isCod ? 'COD' : 'PREPAID',
              color: trip.isCod ? DriverColors.orange : DriverColors.green),
        ]),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Open trip',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.push(DriverRoutes.trip(trip.id)),
        ),
      ]);
}

/// The rest of the active trip, a pull of the sheet away: where it goes and
/// what it pays.
class _ActiveTripDetails extends StatelessWidget {
  const _ActiveTripDetails({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DriverColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: _Route(pickup: trip.pickup.address, drop: trip.drop.address),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text(formatMoney(trip.totalFare, currency: trip.currency),
              style: const TextStyle(
                  color: DriverColors.ink, fontSize: 22, letterSpacing: -.5, fontWeight: FontWeight.w800)),
          const Spacer(),
          const Icon(Icons.route_rounded, size: 16, color: DriverColors.muted),
          const SizedBox(width: 4),
          Text(
              '${formatDistance(trip.distanceMeters)} · ${formatDuration(trip.durationSeconds)}',
              style: const TextStyle(color: DriverColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
      ]);
}

class _Route extends StatelessWidget {
  const _Route({required this.pickup, required this.drop});
  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) => Column(children: [
        _point(DriverColors.green, Icons.north_rounded, 'PICKUP', pickup),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(children: [
              for (var i = 0; i < 3; i++)
                Container(
                    width: 2,
                    height: 3,
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    color: const Color(0xFFC5CED8)),
            ]),
          ),
        ),
        _point(DriverColors.red, Icons.south_rounded, 'DROP', drop),
      ]);

  Widget _point(Color color, IconData icon, String label, String address) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .8)),
              const SizedBox(height: 1),
              Text(address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DriverColors.ink, fontSize: 14, height: 1.3, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      );
}

// -- sheets ---------------------------------------------------------------

class _StatsSheet extends StatelessWidget {
  const _StatsSheet({required this.stats});
  final DriverStats stats;

  @override
  Widget build(BuildContext context) {
    final today = stats.today;
    final total = stats.allTime;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: DriverColors.line,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Today'),
              const SizedBox(height: 10),
              DriverCard(
                child: Column(children: [
                  Row(children: [
                    _Stat(
                        value: formatMoney(today.earnings),
                        label: 'You earned',
                        keyName: 'stat_earnings',
                        color: DriverColors.green),
                    _Stat(
                        value: '${today.tripsCompleted}',
                        label: 'Trips done',
                        keyName: 'stat_trips'),
                    _Stat(
                        value: formatDistance(today.distanceMeters),
                        label: 'Distance',
                        keyName: 'stat_distance'),
                  ]),
                  const Divider(height: 26),
                  InfoRow('Trip value today', formatMoney(today.totalFare),
                      key: const Key('stat_fare')),
                  InfoRow('COD collected today', formatMoney(today.codCollected)),
                  InfoRow('Cancelled today', '${today.tripsCancelled}'),
                  InfoRow('All-time trips', '${total.tripsCompleted}'),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.keyName,
    this.color = DriverColors.ink,
  });
  final String value;
  final String label;
  final String keyName;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              key: Key(keyName),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style:
                  const TextStyle(color: DriverColors.muted, fontSize: 11.5)),
        ]),
      );
}
