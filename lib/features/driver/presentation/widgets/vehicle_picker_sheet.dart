import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';

/// Bottom sheet listing the vehicles the driver can take (their licence
/// category, not already on duty with someone else). Resolves to the chosen
/// vehicle, or null if dismissed.
///
/// [loader] is `DriverSessionCubit.loadVehicles`, passed in so the sheet
/// doesn't depend on the cubit itself.
Future<DriverVehicle?> showVehiclePicker(
  BuildContext context, {
  required Future<(List<DriverVehicle>?, AppFailure?)> Function() loader,
  String? currentVehicleId,
  String confirmLabel = 'Confirm vehicle',
}) =>
    showModalBottomSheet<DriverVehicle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehiclePickerSheet(
        loader: loader,
        currentVehicleId: currentVehicleId,
        confirmLabel: confirmLabel,
      ),
    );

class _VehiclePickerSheet extends StatefulWidget {
  const _VehiclePickerSheet({
    required this.loader,
    required this.currentVehicleId,
    required this.confirmLabel,
  });

  final Future<(List<DriverVehicle>?, AppFailure?)> Function() loader;
  final String? currentVehicleId;
  final String confirmLabel;

  @override
  State<_VehiclePickerSheet> createState() => _VehiclePickerSheetState();
}

class _VehiclePickerSheetState extends State<_VehiclePickerSheet> {
  List<DriverVehicle>? _vehicles;
  String? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _vehicles = null;
      _error = null;
    });
    final (vehicles, failure) = await widget.loader();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _error = vehicles == null
          ? failure?.message ?? 'Could not load vehicles.'
          : null;
      if (vehicles != null) {
        // Pre-select the vehicle they're already on, else the only choice.
        _selectedId = vehicles.any((v) => v.id == widget.currentVehicleId)
            ? widget.currentVehicleId
            : (vehicles.length == 1 ? vehicles.first.id : null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .75),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: DriverColors.line,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose your vehicle',
                  style: TextStyle(
                      color: DriverColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            if (vehicles == null && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              CenteredMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load vehicles',
                message: _error,
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (vehicles!.isEmpty)
              const CenteredMessage(
                icon: Icons.two_wheeler_rounded,
                title: 'No vehicle available',
                message:
                    'There is no active vehicle free that your licence covers. Ask your operations team.',
              )
            else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final vehicle = vehicles[i];
                    final selected = vehicle.id == _selectedId;
                    return Material(
                      color: selected ? const Color(0xFFEAF2FF) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color:
                              selected ? DriverColors.blue : DriverColors.line,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _selectedId = vehicle.id),
                        customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected
                                  ? DriverColors.blue
                                  : DriverColors.muted,
                            ),
                            const SizedBox(width: 12),
                            NetworkThumb(vehicle.photoUrl,
                                size: 44,
                                radius: 11,
                                fallbackIcon: Icons.two_wheeler_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vehicle.registrationNumber,
                                        style: const TextStyle(
                                            color: DriverColors.ink,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: .5)),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (vehicle.vehicleTypeName != null)
                                          vehicle.vehicleTypeName!,
                                        if (vehicle.categoryLabel.isNotEmpty)
                                          vehicle.categoryLabel,
                                      ].join(' · '),
                                      style: const TextStyle(
                                          color: DriverColors.muted,
                                          fontSize: 12),
                                    ),
                                  ]),
                            ),
                            if (vehicle.isOwn) ...[
                              const StatusPill('YOURS',
                                  color: DriverColors.blue),
                              const SizedBox(width: 6),
                            ],
                            if (vehicle.isCurrent ||
                                vehicle.id == widget.currentVehicleId)
                              const StatusPill('CURRENT',
                                  color: DriverColors.green),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: widget.confirmLabel,
                icon: Icons.check_rounded,
                onPressed: _selectedId == null
                    ? null
                    : () => Navigator.pop(context,
                        vehicles.firstWhere((v) => v.id == _selectedId)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
