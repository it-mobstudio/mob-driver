import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/app_card.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/centered_message.dart';
import 'package:mob_driver/core/widgets/info_banner.dart';
import 'package:mob_driver/core/widgets/list_skeleton.dart';
import 'package:mob_driver/core/widgets/status_pill.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/domain/entities/driver_vehicle.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/duty/duty_flow.dart';
import 'package:mob_driver/features/driver/presentation/widgets/duty/vehicle_picker_sheet.dart';
import 'package:mob_driver/features/driver/presentation/widgets/photo_widgets.dart';

/// The vehicle the driver is on duty with, and how to change it.
class VehiclePage extends StatelessWidget {
  const VehiclePage({super.key});

  Future<void> _change(BuildContext context, DriverSessionState state) async {
    final cubit = context.read<DriverSessionCubit>();
    if (state.activeTrip != null) {
      TopSnackBar.show(context,
          message: tr(
              'Finish or cancel your active trip before switching vehicles.'),
          type: TopSnackBarType.error);
      return;
    }
    final picked = await showVehiclePicker(
      context,
      loader: cubit.loadVehicles,
      currentVehicleId: state.profile?.currentVehicle?.id,
      confirmLabel: tr('Switch vehicle'),
    );
    if (picked == null || !context.mounted) return;
    if (picked.id == state.profile?.currentVehicle?.id) return;

    // Starting duty on a different vehicle is how the backend switches.
    final failure = await cubit.goOnline(picked.id);
    if (!context.mounted) return;
    TopSnackBar.show(context,
        message: failure?.message ??
            tr('Now on {registrationNumber}',
                {'registrationNumber': picked.registrationNumber}),
        type:
            failure == null ? TopSnackBarType.success : TopSnackBarType.error);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<DriverSessionCubit,
          DriverSessionState>(
      buildWhen: (a, b) =>
          a.activeTrip != b.activeTrip ||
          a.profile != b.profile ||
          a.dutyBusy != b.dutyBusy,
      builder: (context, state) {
        final profile = state.profile;
        final vehicle = profile?.currentVehicle;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.card,
            elevation: 0,
            foregroundColor: AppColors.ink,
            automaticallyImplyLeading: false,
            leading: BackButton(
                key: const Key('vehicle_back'),
                onPressed: () => context.go(AppRoutes.profile)),
            title: Text(tr('My vehicle'),
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          ),
          body: profile == null
              ? const ListSkeleton(itemCount: 3, itemHeight: 104)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  children: [
                      if (vehicle == null)
                        AppCard(
                          child: CenteredMessage(
                            icon: Icons.two_wheeler_rounded,
                            title: tr('No vehicle selected'),
                            message:
                                tr('Choose a vehicle when you start duty.'),
                          ),
                        )
                      else
                        _VehicleCard(vehicle: vehicle, onDuty: state.isOnline),
                      const SizedBox(height: 14),
                      if (profile.allowedCategories.isNotEmpty)
                        InfoBanner(
                          text: tr('Your licence covers: {p0}', {
                            'p0': profile.allowedCategories
                                .map(_categoryLabel)
                                .join(', ')
                          }),
                          color: AppColors.blue,
                          icon: Icons.badge_outlined,
                        ),
                      const SizedBox(height: 14),
                      AppCard(
                        key: const Key('my_vehicles_entry'),
                        onTap: () => context.push(AppRoutes.myVehicles),
                        child: Row(children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.blue, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('My vehicles'),
                                      style: TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  Text(tr('Add your own vehicles, with pictures'),
                                      style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12.5)),
                                ]),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.muted),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      if (state.isOnline)
                        PrimaryButton(
                          key: const Key('change_vehicle'),
                          label: tr('Change vehicle'),
                          icon: Icons.swap_horiz_rounded,
                          loading: state.dutyBusy,
                          onPressed: () => _change(context, state),
                        )
                      else
                        PrimaryButton(
                          key: const Key('vehicle_start_duty'),
                          label: tr('Start duty'),
                          icon: Icons.play_arrow_rounded,
                          loading: state.dutyBusy,
                          onPressed: () => startDutyFlow(context),
                        ),
                    ]),
        );
      });
}

String _categoryLabel(String category) =>
    DriverVehicle(id: '', registrationNumber: '', category: category)
        .categoryLabel;

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onDuty});
  final DriverVehicle vehicle;
  final bool onDuty;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          Row(children: [
            NetworkThumb(vehicle.photoUrl,
                size: 56, radius: 16, fallbackIcon: Icons.two_wheeler_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A plate is read as one unit: shrink, never wrap.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(vehicle.registrationNumber,
                          key: const Key('vehicle_reg'),
                          maxLines: 1,
                          style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (vehicle.vehicleTypeName != null)
                          vehicle.vehicleTypeName!,
                        if (vehicle.categoryLabel.isNotEmpty)
                          vehicle.categoryLabel,
                      ].join(' · '),
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ]),
            ),
            StatusPill(onDuty ? tr('ON DUTY') : tr('OFF DUTY'),
                color: onDuty ? AppColors.green : AppColors.muted),
          ]),
          if (vehicle.capacityKg != null) ...[
            const Divider(height: 26),
            InfoRow(
                tr('Capacity'), '${vehicle.capacityKg!.toStringAsFixed(0)} kg'),
          ],
        ]),
      );
}
