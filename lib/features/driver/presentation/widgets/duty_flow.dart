import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/push_notification_service.dart';
import 'package:m_o_b_demand_side/core/location/location_permission_helper.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/vehicle_picker_sheet.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Injectable seam for the OS permission prompt, so widget tests don't need
/// the geolocator platform channel.
typedef LocationPermissionCheck = Future<bool> Function(BuildContext context);

/// The whole "go on duty" journey, shared by the dashboard toggle and the
/// vehicle tab: explain what tracking is → ask for location permission →
/// pick a vehicle → tell the backend (with a first GPS fix).
Future<void> startDutyFlow(
  BuildContext context, {
  LocationPermissionCheck? checkPermission,
  bool skipExplanation = false,
}) async {
  final cubit = context.read<DriverSessionCubit>();
  final profile = cubit.state.profile;
  if (profile == null || cubit.state.dutyBusy) return;

  if (!profile.isEligible) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You can’t go on duty yet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final reason in profile.blockers)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('•  $reason'),
              ),
            if (profile.blockers.isEmpty)
              const Text('Your account isn’t eligible for trips right now.'),
            const SizedBox(height: 6),
            const Text('Contact your operations team to get this resolved.',
                style: TextStyle(color: DriverColors.muted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    return;
  }

  if (!skipExplanation) {
    final proceed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Start duty and live tracking?'),
        content: const Text(
          'MOB Driver shares your location while you are on duty so nearby '
          'trips can be assigned to you and your vehicle can be tracked. '
          'You can go offline any time when you have no active trip.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue')),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;
  }

  final allowed = await (checkPermission ?? ensureLocationPermission)(context);
  if (!allowed || !context.mounted) return;

  // Best effort, and never blocks going on duty: trips reach the app by
  // polling, so a denied notification prompt only costs the background alert.
  try {
    await PushNotificationService.instance.requestNotificationPermission();
  } catch (_) {}
  if (!context.mounted) return;

  final vehicle = await showVehiclePicker(
    context,
    loader: cubit.loadVehicles,
    currentVehicleId: profile.currentVehicle?.id,
    confirmLabel: 'Go online',
  );
  if (vehicle == null || !context.mounted) return;

  final failure = await cubit.goOnline(vehicle.id);
  if (failure != null && context.mounted) {
    TopSnackBar.show(context,
        message: failure.message, type: TopSnackBarType.error);
  }
}

/// Takes the driver off duty. The backend refuses while a trip is active;
/// its message is shown as-is.
Future<void> endDutyFlow(BuildContext context) async {
  final cubit = context.read<DriverSessionCubit>();
  if (cubit.state.dutyBusy) return;
  if (cubit.state.activeTrip != null) {
    TopSnackBar.show(context,
        message: 'Finish or cancel your active trip before going offline.',
        type: TopSnackBarType.error);
    return;
  }
  final failure = await cubit.goOffline();
  if (failure != null && context.mounted) {
    TopSnackBar.show(context,
        message: failure.message, type: TopSnackBarType.error);
  } else {
    await PushNotificationService.instance.hideOngoingTrip();
  }
}
