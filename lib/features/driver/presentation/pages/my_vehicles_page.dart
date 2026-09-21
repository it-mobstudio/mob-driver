import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/my_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// How many vehicles one driver may register (the backend enforces it too).
const kMaxOwnVehicles = 10;

/// The vehicles the driver registered themselves, each with its pictures. They
/// can take any of them on duty next to the company's fleet.
class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  static const routeName = 'DriverMyVehicles';

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
        _error = failure?.message ?? 'Could not load your vehicles.';
      }
    });
  }

  Future<void> _openForm([MyVehicle? vehicle]) async {
    final changed = await context.push<bool>(
      vehicle == null
          ? DriverRoutes.newVehicle
          : DriverRoutes.editVehicle(vehicle.id),
      extra: vehicle,
    );
    if (changed == true && mounted) _load(quietly: true);
  }

  Future<void> _remove(MyVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${vehicle.registrationNumber}?'),
        content: const Text(
            'It disappears from your vehicles and you can no longer go on duty with it. Past trips keep their record.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          TextButton(
              key: const Key('confirm_remove_vehicle'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: DriverColors.red))),
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
    if (failure == null) _load(quietly: true);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
    final full = (vehicles?.length ?? 0) >= kMaxOwnVehicles;
    return Scaffold(
      backgroundColor: DriverColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: DriverColors.ink,
        title: const Text('My vehicles',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      ),
      body: _error != null
          ? CenteredMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load your vehicles',
              message: _error,
              actionLabel: 'Retry',
              onAction: _load,
            )
          : vehicles == null
              ? const DriverListSkeleton(itemCount: 2, itemHeight: 230)
              : Column(children: [
                  Expanded(
                    child: vehicles.isEmpty
                        ? const CenteredMessage(
                            icon: Icons.two_wheeler_rounded,
                            title: 'No vehicles yet',
                            message:
                                'Add your own bike, auto or truck with pictures, then go on duty with it.',
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
                        const BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 14,
                          offset: Offset(0, -3)),
                    ]),
                    child: PrimaryButton(
                      key: const Key('add_vehicle'),
                      label: full
                          ? 'You have $kMaxOwnVehicles vehicles (the limit)'
                          : 'Add a vehicle',
                      icon: full ? null : Icons.add_rounded,
                      onPressed: full ? null : () => _openForm(),
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
    return DriverCard(
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
                      color: const Color(0xFFEAF2FF),
                      child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: DriverColors.blue, size: 30),
                            SizedBox(height: 6),
                            Text('Add pictures of this vehicle',
                                style: TextStyle(
                                    color: DriverColors.blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ]),
                    )
                  : Stack(fit: StackFit.expand, children: [
                      Image.network(
                        photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFEAF2FF),
                          child: Center(
                              child: Icon(Icons.two_wheeler_rounded,
                                  size: 38, color: DriverColors.blue)),
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
                    style: const TextStyle(
                        color: DriverColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6)),
              ),
              if (vehicle.isCurrent)
                const StatusPill('CURRENT', color: DriverColors.green),
              if (vehicle.status != 'active') ...[
                const SizedBox(width: 6),
                StatusPill(vehicle.status.toUpperCase(),
                    color: DriverColors.orange),
              ],
            ]),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(details,
                  style:
                      const TextStyle(color: DriverColors.muted, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: SecondaryButton(
                  key: Key('edit_vehicle_${vehicle.id}'),
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: DriverColors.blue,
                  onPressed: removing ? null : onEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  key: Key('remove_vehicle_${vehicle.id}'),
                  label: removing ? 'Removing…' : 'Remove',
                  icon: Icons.delete_outline_rounded,
                  color: DriverColors.red,
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
