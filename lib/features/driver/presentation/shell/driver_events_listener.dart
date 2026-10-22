import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/services/push_notification_service.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/data/realtime/driver_realtime.dart'
    show ExtraBonusRaised;
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/pages/trip/trip_page.dart';

/// Sits above the signed-in screens. It (a) starts the driver session when the
/// driver lands here and shuts it down when they leave (sign-out), and
/// (b) reacts to things that happen *to* the driver: a newly assigned trip
/// opens straight onto its screen with a sound and a system notification (the
/// app may be in the background, on the maps app), and a trip the company
/// cancels is announced.
class DriverEventsListener extends StatefulWidget {
  const DriverEventsListener({super.key, required this.child});

  final Widget child;

  @override
  State<DriverEventsListener> createState() => _DriverEventsListenerState();
}

class _DriverEventsListenerState extends State<DriverEventsListener>
    with WidgetsBindingObserver {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  StreamSubscription<DriverEvent>? _events;
  StreamSubscription<ExtraBonusRaised>? _bonusEvents;

  static const _newTripNotificationId = 4001;
  static const _cancelledNotificationId = 4002;
  static const _bonusNotificationId = 4003;

  @override
  void initState() {
    super.initState();
    _events = _cubit.events.listen(_onEvent);
    _bonusEvents = _cubit.extraBonusRaised.listen(_onExtraBonus);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_cubit.load());
  }

  /// Back from the background: the OS may have cut the push socket while the
  /// app slept, so reconnect and catch up on anything missed meanwhile.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_cubit.pollNow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _events?.cancel();
    _bonusEvents?.cancel();
    // Leaving the signed-in area (sign-out) ends tracking and forgets the
    // driver, so the next person to sign in on this phone starts clean.
    _cubit.reset();
    unawaited(PushNotificationService.instance.hideOngoingTrip());
    super.dispose();
  }

  void _onEvent(DriverEvent event) {
    if (!mounted) return;
    switch (event) {
      case NewTripAssigned(:final trip):
        AppHaptics.success();
        unawaited(PushNotificationService.instance.showAlert(
          id: _newTripNotificationId,
          title: tr('New trip · {p0}',
              {'p0': formatMoney(trip.totalFare, currency: trip.currency)}),
          body: '${trip.pickup.address} → ${trip.drop.address}'
              '${(trip.bonusFare ?? 0) > 0 ? tr(' · +{p0} unloading', {
                      'p0': formatMoney(trip.bonusFare, currency: trip.currency)
                    }) : ''}',
          route: AppRoutes.trip(trip.id),
        ));
        _showOngoing(trip);
        // The offer screen (accept/reject) decides where
        // the driver goes next — not straight to the trip.
        context.push(AppRoutes.incomingOrder(trip.id));
      case TripEndedExternally(:final trip):
        unawaited(PushNotificationService.instance.hideOngoingTrip());
        unawaited(PushNotificationService.instance.showAlert(
          id: _cancelledNotificationId,
          title: tr('Trip cancelled'),
          body:
              trip.cancellationReason ?? tr('The company cancelled your trip.'),
        ));
        // If the trip's own screen is open it shows the dialog itself.
        if (!TripPage.isShowing(trip.id)) {
          AppHaptics.error();
          TopSnackBar.show(context,
              message: tr('Your trip was cancelled{p0}', {
                'p0': trip.cancellationReason == null
                    ? ''
                    : ': ${trip.cancellationReason}'
              }),
              type: TopSnackBarType.error);
        }
    }
  }

  /// The company topped up the loading bonus (a heavier load than booked):
  /// a small card says so, wherever the driver is in the app.
  void _onExtraBonus(ExtraBonusRaised raised) {
    if (!mounted) return;
    AppHaptics.success();
    final currency = _cubit.state.activeTrip?.currency ?? 'INR';
    final added = formatMoney(raised.added, currency: currency);
    unawaited(PushNotificationService.instance.showAlert(
      id: _bonusNotificationId,
      title: tr('Hurray! Loading charges increased'),
      body: tr('+{p0} extra loading bonus', {'p0': added}),
      route: AppRoutes.trip(raised.tripId),
    ));
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        key: const Key('extra_bonus_card'),
        backgroundColor: AppColors.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: AppColors.orangeSoft, shape: BoxShape.circle),
              child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 16),
            Text(tr('Hurray!'),
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(tr('Loading charges increased'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Text('+$added',
                    key: const Key('extra_bonus_added'),
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(tr('Extra loading bonus'),
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const Key('extra_bonus_ok'),
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.button,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child: Text(tr('Great'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showOngoing(Trip trip) {
    unawaited(PushNotificationService.instance.showOngoingTrip(
      tripId: tr('Trip {p0}', {
        'p0': trip.id.substring(0, trip.id.length < 8 ? trip.id.length : 8)
      }),
      destination: trip.drop.address,
      eta: formatDuration(trip.durationSeconds),
      title: tr('Trip in progress'),
      route: AppRoutes.trip(trip.id),
    ));
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<DriverSessionCubit, DriverSessionState>(
        // Keep the ongoing-trip notification in step with the trip's stage.
        listenWhen: (a, b) => a.activeTrip?.status != b.activeTrip?.status,
        listener: (context, state) {
          final trip = state.activeTrip;
          if (trip == null) {
            unawaited(PushNotificationService.instance.hideOngoingTrip());
          } else {
            _showOngoing(trip);
          }
        },
        child: widget.child,
      );
}
