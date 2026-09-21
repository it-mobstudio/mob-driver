import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/location/location_permission_helper.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_flow.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/widgets/skeleton_shimmer.dart';

/// "Today": duty toggle, the active trip (or the wait for one), and the
/// day's numbers.
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key, this.checkLocationPermission});

  static const routeName = 'DriverDashboard';
  static const routePath = DriverRoutes.dashboard;

  /// Test seam for the OS location prompt.
  final LocationPermissionCheck? checkLocationPermission;

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  late final VoidCallback _refreshHook = _refresh;

  @override
  void initState() {
    super.initState();
    // Re-selecting the Today tab refreshes it.
    refreshDriverDashboard = _refreshHook;
  }

  @override
  void dispose() {
    if (refreshDriverDashboard == _refreshHook) refreshDriverDashboard = null;
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<DriverSessionCubit>().load(silent: true);

  /// Days left on the licence when it's about to lapse (a month's notice),
  /// otherwise null. An expired one locks the account, so there's no banner.
  int? _licenceWarning(DriverProfile profile) {
    final days = profile.licenceDaysLeft;
    return days != null && days >= 0 && days <= 30 ? days : null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverSessionCubit, DriverSessionState>(
      builder: (context, state) {
        final profile = state.profile;
        return Scaffold(
          backgroundColor: DriverColors.surface,
          body: SafeArea(
            bottom: false,
            // Skeleton → content is a cross-fade, not a cut.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: profile == null
                  ? _initial(state)
                  : KeyedSubtree(
                      key: const ValueKey('content'),
                      child: RefreshIndicator.adaptive(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            _Header(profile: profile),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 18, 18, 110),
                              child: Column(children: [
                                FadeSlideIn(
                                  child: _DutyCard(
                                    state: state,
                                    checkPermission:
                                        widget.checkLocationPermission,
                                  ),
                                ),
                                // Banners come and go (KYC, GPS): let the
                                // space open and close instead of jumping.
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: Column(children: [
                                    if (!profile.isEligible) ...[
                                      const SizedBox(height: 12),
                                      _VerificationCard(profile: profile),
                                    ] else if (_licenceWarning(profile)
                                        case final days?) ...[
                                      const SizedBox(height: 12),
                                      InfoBanner(
                                        key: const Key('licence_banner'),
                                        text: days == 0
                                            ? 'Your driving licence expires today. Renew it to keep taking trips.'
                                            : 'Your driving licence expires in $days day${days == 1 ? '' : 's'}. Renew it to keep taking trips.',
                                        icon: Icons.event_busy_rounded,
                                        action: TextButton(
                                          onPressed: () => context
                                              .push(DriverRoutes.verification),
                                          child: const Text('View'),
                                        ),
                                      ),
                                    ],
                                    if (state.isOnline &&
                                        state.locationUnavailable) ...[
                                      const SizedBox(height: 12),
                                      InfoBanner(
                                        key: const Key('location_banner'),
                                        text:
                                            'We can’t see your location, so you won’t be assigned trips. Turn on GPS and allow location access.',
                                        icon: Icons.location_off_rounded,
                                        action: TextButton(
                                          // Asks for the permission if the OS
                                          // will still show its prompt, and
                                          // otherwise opens the right settings
                                          // page. (A resumed session — the
                                          // driver was already on duty — never
                                          // went through "Start duty", so this
                                          // is the first time it's asked.)
                                          onPressed: () =>
                                              (widget.checkLocationPermission ??
                                                      ensureLocationPermission)(
                                                  context),
                                          child: const Text('Fix'),
                                        ),
                                      ),
                                    ],
                                  ]),
                                ),
                                const SizedBox(height: 16),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 70),
                                  child: _TripSection(state: state),
                                ),
                                const SizedBox(height: 16),
                                FadeSlideIn(
                                  delay: const Duration(milliseconds: 140),
                                  child: _StatsCard(state: state),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
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
          onAction: () => context.read<DriverSessionCubit>().load(),
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
          child: Column(children: [
            SkeletonBlock(height: 132, radius: 28),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(children: [
                SkeletonBlock(height: 128, radius: 18),
                SizedBox(height: 16),
                SkeletonBlock(height: 168, radius: 18),
                SizedBox(height: 16),
                Align(
                    alignment: Alignment.centerLeft,
                    child: SkeletonBlock(width: 90, height: 18, radius: 6)),
                SizedBox(height: 10),
                SkeletonBlock(height: 132, radius: 18),
              ]),
            ),
          ]),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final vehicle = profile.currentVehicle;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          DriverAvatar(profile.fullName),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Welcome back,',
                  style: TextStyle(color: DriverColors.muted, fontSize: 13)),
              const SizedBox(height: 2),
              Text(profile.fullName,
                  key: const Key('driver_name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          if (profile.isEligible)
            const StatusPill('VERIFIED DRIVER',
                color: DriverColors.green, icon: Icons.verified_rounded)
          else if (profile.onboardingStatus == OnboardingStatus.underReview)
            const StatusPill('UNDER REVIEW',
                color: DriverColors.orange, icon: Icons.hourglass_top_rounded)
          else if (profile.onboardingStatus == OnboardingStatus.actionRequired)
            const StatusPill('ACTION NEEDED',
                color: DriverColors.red, icon: Icons.error_outline_rounded)
          else
            const StatusPill('KYC INCOMPLETE',
                color: DriverColors.red, icon: Icons.gpp_maybe_outlined),
          const SizedBox(width: 10),
          // Flexible + ellipsis: a long registration number must shrink, not
          // push the row past the edge of a narrow phone.
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.two_wheeler_rounded,
                    color: DriverColors.muted, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(vehicle?.registrationNumber ?? 'No vehicle',
                      key: const Key('header_vehicle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DriverColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4)),
                ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

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

class _DutyCard extends StatelessWidget {
  const _DutyCard({required this.state, this.checkPermission});
  final DriverSessionState state;
  final LocationPermissionCheck? checkPermission;

  @override
  Widget build(BuildContext context) {
    final online = state.isOnline;
    final color = online ? DriverColors.green : DriverColors.muted;

    void toggle(bool goOnline) => goOnline
        ? startDutyFlow(context, checkPermission: checkPermission)
        : endDutyFlow(context);

    return DriverCard(
      child: Column(children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14)),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: const Duration(milliseconds: 260),
              builder: (_, tint, __) =>
                  Icon(Icons.sensors_rounded, color: tint),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(online ? 'You are online' : 'You are offline',
                  key: const Key('duty_status'),
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                online
                    ? 'Live tracking on · ${state.profile?.currentVehicle?.registrationNumber ?? ''}'
                    : 'Go online to start receiving trips',
                style: const TextStyle(color: DriverColors.muted, fontSize: 12),
              ),
            ]),
          ),
          if (state.dutyBusy)
            const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5))
          else
            Switch.adaptive(
              key: const Key('duty_switch'),
              value: online,
              activeThumbColor: DriverColors.green,
              onChanged: toggle,
            ),
        ]),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(children: [
            if (!online) ...[
              const Divider(height: 25),
              PrimaryButton(
                label: 'Start duty',
                icon: Icons.play_arrow_rounded,
                loading: state.dutyBusy,
                onPressed: () => toggle(true),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _TripSection extends StatelessWidget {
  const _TripSection({required this.state});
  final DriverSessionState state;

  @override
  Widget build(BuildContext context) {
    final trip = state.activeTrip;
    final Widget content;
    final String key;
    if (trip != null) {
      key = trip.id;
      content = _ActiveTripCard(trip: trip);
    } else if (!state.tripKnown) {
      // The profile may be painted from the cache already, but "no trip" is
      // a claim we haven't verified yet — hold a placeholder, don't guess.
      key = 'loading';
      content =
          const SkeletonShimmer(child: SkeletonBlock(height: 92, radius: 18));
    } else {
      key = 'idle';
      content = DriverCard(
        child: Row(children: [
          Icon(
              state.isOnline
                  ? Icons.hourglass_top_rounded
                  : Icons.event_available_outlined,
              color: DriverColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.isOnline ? 'Waiting for a trip' : 'No active trip',
                  key: const Key('no_trip_title'),
                  style: const TextStyle(
                      color: DriverColors.ink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                state.isOnline
                    ? 'New trips near you will appear here automatically.'
                    : 'Start duty to get trips assigned to you.',
                style:
                    const TextStyle(color: DriverColors.muted, fontSize: 11.5),
              ),
            ]),
          ),
        ]),
      );
    }

    // A trip arriving swaps the card in with a fade while the space eases open
    // to its height — no jump.
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(key: ValueKey(key), child: content),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) => DriverCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
              StatusPill(trip.status.label.toUpperCase(),
                  color: DriverColors.blue),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
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
                    color:
                        trip.isCod ? DriverColors.orange : DriverColors.green),
                const Spacer(),
                Text(
                    '${formatDistance(trip.distanceMeters)} · ${formatDuration(trip.durationSeconds)}',
                    style: const TextStyle(
                        color: DriverColors.muted, fontSize: 12)),
              ]),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Open trip',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push(DriverRoutes.trip(trip.id)),
              ),
            ]),
          ),
        ]),
      );
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});
  final DriverSessionState state;

  @override
  Widget build(BuildContext context) {
    final today = state.stats.today;
    final total = state.stats.allTime;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
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
