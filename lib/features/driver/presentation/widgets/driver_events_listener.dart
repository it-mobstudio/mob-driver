import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/app_runtime/push_notification_service.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/trip_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

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

class _DriverEventsListenerState extends State<DriverEventsListener> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  StreamSubscription<DriverEvent>? _events;

  static const _newTripNotificationId = 4001;
  static const _cancelledNotificationId = 4002;

  @override
  void initState() {
    super.initState();
    _events = _cubit.events.listen(_onEvent);
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    _events?.cancel();
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
          title:
              'New trip · ${formatMoney(trip.totalFare, currency: trip.currency)}',
          body: '${trip.pickup.address} → ${trip.drop.address}',
          route: DriverRoutes.trip(trip.id),
        ));
        _showOngoing(trip);
        // Take the driver straight to it.
        context.push(DriverRoutes.trip(trip.id));
      case TripEndedExternally(:final trip):
        unawaited(PushNotificationService.instance.hideOngoingTrip());
        unawaited(PushNotificationService.instance.showAlert(
          id: _cancelledNotificationId,
          title: 'Trip cancelled',
          body: trip.cancellationReason ?? 'The company cancelled your trip.',
        ));
        // If the trip's own screen is open it shows the dialog itself.
        if (!TripPage.isShowing(trip.id)) {
          AppHaptics.error();
          TopSnackBar.show(context,
              message:
                  'Your trip was cancelled${trip.cancellationReason == null ? '' : ': ${trip.cancellationReason}'}',
              type: TopSnackBarType.error);
        }
    }
  }

  void _showOngoing(Trip trip) {
    unawaited(PushNotificationService.instance.showOngoingTrip(
      tripId:
          'Trip ${trip.id.substring(0, trip.id.length < 8 ? trip.id.length : 8)}',
      destination: trip.drop.address,
      eta: formatDuration(trip.durationSeconds),
      title: 'Trip in progress',
      route: DriverRoutes.trip(trip.id),
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
