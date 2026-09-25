import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:m_o_b_demand_side/core/location/location_permission_helper.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_home_map.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_flow.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_top_bar.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/finder_video.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/widgets/skeleton_shimmer.dart';

/// "Today": a full-screen map centred on the driver, the duty toggle, the
/// active trip (or the wait for one), and a way to everything else (trips,
/// wallet, vehicle, profile) behind the profile button.
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

  final _panelKey = GlobalKey();
  double _panelHeight = 170;
  bool _measureScheduled = false;

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

  /// Tells the map how much of its bottom edge the panel covers, so its
  /// floating buttons and the camera's centre stay above it.
  void _measurePanel() {
    if (!mounted) return;
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null &&
        box.hasSize &&
        (box.size.height - _panelHeight).abs() > 1) {
      setState(() => _panelHeight = box.size.height);
    }
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

  void _openProfileMenu(DriverProfile profile) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProfileMenuSheet(profile: profile),
      );

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
    if (!_measureScheduled) {
      _measureScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measurePanel());
    }
    final mapBuilder = widget.mapBuilder ?? defaultDriverMapBuilder;
    final trip = state.activeTrip;

    return Column(children: [
      // The pill, any warning banners, and the working-time bar sit on a
      // solid white panel — the map only starts below it, never bleeding
      // through behind them (a transparent overlay here was the bug).
      Material(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DutyStatusRow(
                online: state.isOnline,
                busy: state.dutyBusy,
                onToggle: (goOnline) => goOnline
                    ? startDutyFlow(context,
                        checkPermission: widget.checkLocationPermission)
                    : endDutyFlow(context),
                onProfileTap: () => _openProfileMenu(profile),
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
              const SizedBox(height: 12),
              WorkingTimeBanner(
                online: state.isOnline,
                dutyStartedAt: _cubit.dutyStartedAt,
                todayEarnings: state.stats.today.earnings,
                onTap: () => _openStats(state.stats),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
      const Divider(height: 1, thickness: 1, color: DriverColors.line),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _measurePanel());
                return false;
              },
              child: SizeChangedLayoutNotifier(
                child: _BottomPanel(
                  key: _panelKey,
                  state: state,
                  checkLocationPermission: widget.checkLocationPermission,
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
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

// -- bottom panel ---------------------------------------------------------

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({super.key, required this.state, this.checkLocationPermission});
  final DriverSessionState state;
  final LocationPermissionCheck? checkLocationPermission;

  @override
  Widget build(BuildContext context) {
    final trip = state.activeTrip;
    final Widget content;
    final String key;
    if (trip != null) {
      key = trip.id;
      content = _ActiveTripPanel(trip: trip);
    } else if (!state.tripKnown) {
      key = 'loading';
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: SkeletonShimmer(child: SkeletonBlock(height: 92, radius: 18)),
      );
    } else if (!state.isOnline) {
      key = 'offline';
      content = _OfflinePanel(
          busy: state.dutyBusy, checkLocationPermission: checkLocationPermission);
    } else {
      key = 'looking';
      content = const _LookingForOrdersPanel();
    }

    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .55),
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 18 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Color(0x28000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: SingleChildScrollView(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(key: ValueKey(key), child: content),
          ),
        ),
      ),
    );
  }
}

class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel({required this.busy, this.checkLocationPermission});
  final bool busy;
  final LocationPermissionCheck? checkLocationPermission;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
              color: DriverColors.surface, shape: BoxShape.circle),
          child: const Icon(Icons.power_settings_new_rounded,
              color: DriverColors.muted, size: 26),
        ),
        const SizedBox(height: 12),
        const Text('You’re off duty',
            key: Key('no_trip_title'),
            style: TextStyle(
                color: DriverColors.ink,
                fontSize: 18,
                letterSpacing: -.2,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Go on duty to start receiving orders near you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.muted, fontSize: 13)),
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

/// Online with nothing assigned: the radar, and a status line that keeps
/// changing so a driver waiting a while can see the app is still at work.
class _LookingForOrdersPanel extends StatelessWidget {
  const _LookingForOrdersPanel();

  static const _messages = [
    'Finding orders near you',
    'Looking for the best order around you',
    'Trying hard to find you an order',
    'Hang tight — orders can land any moment',
  ];

  @override
  Widget build(BuildContext context) =>
      const Column(mainAxisSize: MainAxisSize.min, children: [
        FinderAnimation(size: 128),
        SizedBox(height: 6),
        SizedBox(
          height: 26,
          child: RotatingStatusText(
              key: Key('no_trip_title'), messages: _messages),
        ),
        SizedBox(height: 6),
        Text('Keep the app open — we’ll ring and vibrate when an order arrives.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.muted, fontSize: 12.5, height: 1.4)),
      ]);
}

class _ActiveTripPanel extends StatelessWidget {
  const _ActiveTripPanel({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.circle, size: 9, color: DriverColors.blue),
            const SizedBox(width: 8),
            const Text('ACTIVE TRIP',
                style: TextStyle(
                    color: DriverColors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7)),
            const Spacer(),
            StatusPill(trip.status.label.toUpperCase(), color: DriverColors.blue),
          ]),
        ),
        const SizedBox(height: 14),
        _Route(pickup: trip.pickup.address, drop: trip.drop.address),
        const SizedBox(height: 14),
        Row(children: [
          Text(formatMoney(trip.totalFare, currency: trip.currency),
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          StatusPill(trip.isCod ? 'COD' : 'PREPAID',
              color: trip.isCod ? DriverColors.orange : DriverColors.green),
          const Spacer(),
          Text(
              '${formatDistance(trip.distanceMeters)} · ${formatDuration(trip.durationSeconds)}',
              style: const TextStyle(color: DriverColors.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Open trip',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.push(DriverRoutes.trip(trip.id)),
        ),
      ]);
}

class _Route extends StatelessWidget {
  const _Route({required this.pickup, required this.drop});
  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) => Column(children: [
        _point(DriverColors.green, 'Pickup', pickup),
        Container(
          margin: const EdgeInsets.only(left: 5),
          height: 16,
          alignment: Alignment.centerLeft,
          child: Container(width: 2, color: DriverColors.line),
        ),
        _point(DriverColors.red, 'Drop', drop),
      ]);

  Widget _point(Color color, String label, String address) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8)),
              Text(address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      );
}

// -- sheets ---------------------------------------------------------------

/// Everything that used to live behind bottom-nav tabs: trips, wallet,
/// vehicle, profile — reached from the map screen's profile button.
class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet({required this.profile});
  final DriverProfile profile;

  void _go(BuildContext context, String path) {
    Navigator.pop(context);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = profile.currentVehicle;
    return Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: DriverColors.line,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 18),
              Row(children: [
                DriverAvatar(profile.fullName,
                    size: 48, photoUrl: profile.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(profile.fullName,
                          key: const Key('driver_name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: DriverColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Row(children: [
                        if (profile.isEligible)
                          const StatusPill('VERIFIED DRIVER',
                              color: DriverColors.green,
                              icon: Icons.verified_rounded)
                        else if (profile.onboardingStatus ==
                            OnboardingStatus.underReview)
                          const StatusPill('UNDER REVIEW',
                              color: DriverColors.orange,
                              icon: Icons.hourglass_top_rounded)
                        else if (profile.onboardingStatus ==
                            OnboardingStatus.actionRequired)
                          const StatusPill('ACTION NEEDED',
                              color: DriverColors.red,
                              icon: Icons.error_outline_rounded)
                        else
                          const StatusPill('KYC INCOMPLETE',
                              color: DriverColors.red,
                              icon: Icons.gpp_maybe_outlined),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF1F4F8),
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.two_wheeler_rounded,
                                      color: DriverColors.muted, size: 14),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                        vehicle?.registrationNumber ??
                                            'No vehicle',
                                        key: const Key('header_vehicle'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: DriverColors.ink,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: .4)),
                                  ),
                                ]),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              _MenuTile(
                  keyName: 'menu_trips',
                  icon: Icons.receipt_long_outlined,
                  label: 'Trips',
                  onTap: () => _go(context, DriverRoutes.trips)),
              _MenuTile(
                  keyName: 'menu_wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet',
                  onTap: () => _go(context, DriverRoutes.wallet)),
              _MenuTile(
                  keyName: 'menu_vehicle',
                  icon: Icons.two_wheeler_rounded,
                  label: 'My vehicle',
                  onTap: () => _go(context, DriverRoutes.vehicle)),
              _MenuTile(
                  keyName: 'menu_profile',
                  icon: Icons.person_outline_rounded,
                  label: 'Profile & settings',
                  onTap: () => _go(context, DriverRoutes.profile)),
            ]),
          ),
        ),
      );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: DriverColors.blue, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right_rounded, color: DriverColors.muted),
          ]),
        ),
      );
}

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
