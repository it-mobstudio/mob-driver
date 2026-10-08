import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/app_card.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/centered_message.dart';
import 'package:mob_driver/core/widgets/list_skeleton.dart';
import 'package:mob_driver/core/widgets/status_pill.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/domain/driver_limits.dart';
import 'package:mob_driver/features/driver/domain/entities/my_vehicle.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';

/// The vehicles the driver registered themselves, each with its pictures. They
/// can take any of them on duty next to the company's fleet.
class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  List<MyVehicle>? _vehicles;
  String? _error;
  String? _removing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quietly = false}) async {
    if (!quietly) {
      setState(() {
        _vehicles = null;
        _error = null;
      });
    }
    final (vehicles, failure) = await _cubit.loadMyVehicles();
    if (!mounted) return;
    setState(() {
      if (vehicles != null) {
        _vehicles = vehicles;
        _error = null;
      } else if (_vehicles == null) {
        _error = failure?.message ?? tr('Could not load your vehicles.');
      }
    });
  }

  Future<void> _openForm([MyVehicle? vehicle]) async {
    final changed = await context.push<bool>(
      vehicle == null
          ? AppRoutes.newVehicle
          : AppRoutes.editVehicle(vehicle.id),
      extra: vehicle,
    );
    if (changed == true && mounted) unawaited(_load(quietly: true));
  }

  Future<void> _remove(MyVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Remove {registrationNumber}?',
            {'registrationNumber': vehicle.registrationNumber})),
        content: Text(tr(
            'It disappears from your vehicles and you can no longer go on duty with it. Past trips keep their record.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Keep it'))),
          TextButton(
              key: const Key('confirm_remove_vehicle'),
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(tr('Remove'), style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removing = vehicle.id);
    final failure = await _cubit.removeVehicle(vehicle.id);
    if (!mounted) return;
    setState(() => _removing = null);
    TopSnackBar.show(context,
        message: failure?.message ?? '${vehicle.registrationNumber} removed',
        type:
            failure == null ? TopSnackBarType.success : TopSnackBarType.error);
    if (failure == null) unawaited(_load(quietly: true));
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
    final full = (vehicles?.length ?? 0) >= DriverLimits.maxOwnVehicles;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(tr('My vehicles'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      ),
      body: _error != null
          ? CenteredMessage(
              icon: Icons.cloud_off_rounded,
              title: tr('Could not load your vehicles'),
              message: _error,
              actionLabel: tr('Retry'),
              onAction: _load,
            )
          : vehicles == null
              ? const ListSkeleton(itemCount: 2, itemHeight: 230)
              : Column(children: [
                  Expanded(
                    child: vehicles.isEmpty
                        ? CenteredMessage(
                            icon: Icons.two_wheeler_rounded,
                            title: tr('No vehicles yet'),
                            message: tr(
                                'Add your own bike, auto or truck with pictures, then go on duty with it.'),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(quietly: true),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              itemCount: vehicles.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (_, i) => _VehicleCard(
                                vehicle: vehicles[i],
                                removing: _removing == vehicles[i].id,
                                onEdit: () => _openForm(vehicles[i]),
                                onRemove: () => _remove(vehicles[i]),
                              ),
                            ),
                          ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        18, 12, 18, 12 + MediaQuery.paddingOf(context).bottom),
                    decoration:
                        BoxDecoration(color: AppColors.card, boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 14,
                          offset: Offset(0, -3)),
                    ]),
                    child: PrimaryButton(
                      key: const Key('add_vehicle'),
                      label: full
                          ? tr('You have {max} vehicles (the limit)',
                              {'max': DriverLimits.maxOwnVehicles})
                          : tr('Add a vehicle'),
                      icon: full ? null : Icons.add_rounded,
                      onPressed: full ? null : _openForm,
                    ),
                  ),
                ]),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.removing,
    required this.onEdit,
    required this.onRemove,
  });

  final MyVehicle vehicle;
  final bool removing;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final photos = vehicle.photoUrls;
    final details = [
      if (vehicle.vehicleTypeName != null) vehicle.vehicleTypeName!,
      if (vehicle.categoryLabel.isNotEmpty) vehicle.categoryLabel,
      if (vehicle.capacityKg != null)
        '${vehicle.capacityKg!.toStringAsFixed(0)} kg',
    ].join(' · ');
    return AppCard(
      key: Key('my_vehicle_${vehicle.id}'),
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: onEdit,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 168,
              width: double.infinity,
              child: photos.isEmpty
                  ? Container(
                      key: Key('vehicle_no_photos_${vehicle.id}'),
                      color: AppColors.blueSoft,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.blue, size: 30),
                            const SizedBox(height: 6),
                            Text(tr('Add pictures of this vehicle'),
                                style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ]),
                    )
                  : Stack(fit: StackFit.expand, children: [
                      Image.network(
                        photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: AppColors.blueSoft,
                          child: Center(
                              child: Icon(Icons.two_wheeler_rounded,
                                  size: 38, color: AppColors.blue)),
                        ),
                      ),
                      if (photos.length > 1)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            key: Key('vehicle_photo_count_${vehicle.id}'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .62),
                                borderRadius: BorderRadius.circular(20)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.photo_library_outlined,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 5),
                              Text('${photos.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ),
                    ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(vehicle.registrationNumber,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6)),
              ),
              if (vehicle.isCurrent)
                StatusPill(tr('CURRENT'), color: AppColors.green),
              if (vehicle.status != 'active') ...[
                const SizedBox(width: 6),
                StatusPill(vehicle.status.toUpperCase(),
                    color: AppColors.orange),
              ],
            ]),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(details,
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SecondaryButton(
                  key: Key('edit_vehicle_${vehicle.id}'),
                  label: tr('Edit'),
                  icon: Icons.edit_outlined,
                  color: AppColors.blue,
                  onPressed: removing ? null : onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  key: Key('remove_vehicle_${vehicle.id}'),
                  label: removing ? tr('Removing…') : tr('Remove'),
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.red,
                  onPressed: removing ? null : onRemove,
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
