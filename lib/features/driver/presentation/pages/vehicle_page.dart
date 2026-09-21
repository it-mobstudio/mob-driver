import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_flow.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/vehicle_picker_sheet.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// The vehicle the driver is on duty with, and how to change it.
class DriverVehiclePage extends StatelessWidget {
  const DriverVehiclePage({super.key});

  static const routeName = 'DriverVehicle';
  static const routePath = DriverRoutes.vehicle;

  Future<void> _change(BuildContext context, DriverSessionState state) async {
    final cubit = context.read<DriverSessionCubit>();
    if (state.activeTrip != null) {
      TopSnackBar.show(context,
          message:
              'Finish or cancel your active trip before switching vehicles.',
          type: TopSnackBarType.error);
      return;
    }
    final picked = await showVehiclePicker(
      context,
      loader: cubit.loadVehicles,
      currentVehicleId: state.profile?.currentVehicle?.id,
      confirmLabel: 'Switch vehicle',
    );
    if (picked == null || !context.mounted) return;
    if (picked.id == state.profile?.currentVehicle?.id) return;

    // Starting duty on a different vehicle is how the backend switches.
    final failure = await cubit.goOnline(picked.id);
    if (!context.mounted) return;
    TopSnackBar.show(context,
        message: failure?.message ?? 'Now on ${picked.registrationNumber}',
        type:
            failure == null ? TopSnackBarType.success : TopSnackBarType.error);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
          builder: (context, state) {
        final profile = state.profile;
        final vehicle = profile?.currentVehicle;
        return Scaffold(
          backgroundColor: DriverColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: DriverColors.ink,
            automaticallyImplyLeading: false,
            title: const Text('My vehicle',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          ),
          body: profile == null
              ? const DriverListSkeleton(itemCount: 3, itemHeight: 104)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  children: [
                      if (vehicle == null)
                        const DriverCard(
                          child: CenteredMessage(
                            icon: Icons.two_wheeler_rounded,
                            title: 'No vehicle selected',
                            message: 'Choose a vehicle when you start duty.',
                          ),
                        )
                      else
                        _VehicleCard(vehicle: vehicle, onDuty: state.isOnline),
                      const SizedBox(height: 14),
                      if (profile.allowedCategories.isNotEmpty)
                        InfoBanner(
                          text: 'Your licence covers: '
                              '${profile.allowedCategories.map(_categoryLabel).join(', ')}',
                          color: DriverColors.blue,
                          icon: Icons.badge_outlined,
                        ),
                      const SizedBox(height: 14),
                      DriverCard(
                        key: const Key('my_vehicles_entry'),
                        onTap: () => context.push(DriverRoutes.myVehicles),
                        child: const Row(children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: DriverColors.blue, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('My vehicles',
                                      style: TextStyle(
                                          color: DriverColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 2),
                                  Text('Add your own vehicles, with pictures',
                                      style: TextStyle(
                                          color: DriverColors.muted,
                                          fontSize: 12.5)),
                                ]),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: DriverColors.muted),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      if (state.isOnline)
                        PrimaryButton(
                          key: const Key('change_vehicle'),
                          label: 'Change vehicle',
                          icon: Icons.swap_horiz_rounded,
                          loading: state.dutyBusy,
                          onPressed: () => _change(context, state),
                        )
                      else
                        PrimaryButton(
                          key: const Key('vehicle_start_duty'),
                          label: 'Start duty',
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
  Widget build(BuildContext context) => DriverCard(
        child: Column(children: [
          Row(children: [
            NetworkThumb(vehicle.photoUrl,
                size: 56, radius: 16, fallbackIcon: Icons.two_wheeler_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.registrationNumber,
                        key: const Key('vehicle_reg'),
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (vehicle.vehicleTypeName != null)
                          vehicle.vehicleTypeName!,
                        if (vehicle.categoryLabel.isNotEmpty)
                          vehicle.categoryLabel,
                      ].join(' · '),
                      style: const TextStyle(
                          color: DriverColors.muted, fontSize: 13),
                    ),
                  ]),
            ),
            StatusPill(onDuty ? 'ON DUTY' : 'OFF DUTY',
                color: onDuty ? DriverColors.green : DriverColors.muted),
          ]),
          if (vehicle.capacityKg != null) ...[
            const Divider(height: 26),
            InfoRow('Capacity', '${vehicle.capacityKg!.toStringAsFixed(0)} kg'),
          ],
        ]),
      );
}
