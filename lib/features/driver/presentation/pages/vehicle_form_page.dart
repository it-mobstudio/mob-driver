import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/my_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/vehicle_art.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// How many pictures one vehicle can hold (the backend enforces it too).
const kMaxVehiclePhotos = 6;

final _plate = RegExp(r'^[A-Z0-9-]{3,20}$');

/// Adds a vehicle, or edits one of the driver's own: its type, plate, capacity
/// and pictures (camera or gallery, up to six — the first is the main one).
///
/// Adding sends everything at once. Editing changes pictures straight away (each
/// add / remove is its own request, so they're never lost) and the other fields
/// on "Save changes".
class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({
    super.key,
    this.vehicleId,
    this.initial,
    this.capture = const DevicePhotoCapture(),
  });

  static const routeName = 'DriverVehicleForm';

  /// Set when editing.
  final String? vehicleId;

  /// The vehicle as the list had it, so the form opens filled in.
  final MyVehicle? initial;
  final PhotoCapture capture;

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();

  List<VehicleTypeOption>? _types;
  String? _typesError;
  String? _typeId;

  /// Adding: pictures picked but not sent yet.
  final List<CapturedPhoto> _picked = [];

  /// Editing: the vehicle as the server has it (pictures included).
  MyVehicle? _vehicle;

  bool _saving = false;
  bool _photoBusy = false;
  bool _changed = false;
  String? _error;

  bool get _editing => widget.vehicleId != null;

  @override
  void initState() {
    super.initState();
    _loadTypes();
    final initial = widget.initial;
    if (_editing && initial != null) _adopt(initial);
    if (_editing && initial == null) _loadVehicle();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _adopt(MyVehicle vehicle) {
    _vehicle = vehicle;
    _plateController.text = vehicle.registrationNumber;
    _typeId = vehicle.vehicleTypeId;
    _capacityController.text = vehicle.capacityKg == null
        ? ''
        : (vehicle.capacityKg! == vehicle.capacityKg!.roundToDouble()
            ? vehicle.capacityKg!.toStringAsFixed(0)
            : vehicle.capacityKg.toString());
  }

  Future<void> _loadVehicle() async {
    final (vehicles, failure) = await _cubit.loadMyVehicles();
    if (!mounted) return;
    final found = vehicles?.where((v) => v.id == widget.vehicleId).firstOrNull;
    setState(() {
      if (found != null) {
        _adopt(found);
      } else {
        _error = failure?.message ?? 'Could not load this vehicle.';
      }
    });
  }

  Future<void> _loadTypes() async {
    setState(() => _typesError = null);
    final (types, failure) = await _cubit.loadVehicleTypes();
    if (!mounted) return;
    setState(() {
      _types = types;
      _typesError = types == null
          ? failure?.message ?? 'Could not load the vehicle types.'
          : null;
    });
  }

  VehicleTypeOption? get _type =>
      _types?.where((t) => t.id == _typeId).firstOrNull;

  int get _photoCount =>
      _editing ? (_vehicle?.photos.length ?? 0) : _picked.length;

  Future<void> _addPhoto() async {
    final photo = await chooseDocumentPhoto(context, widget.capture);
    if (photo == null || !mounted) return;
    if (!_editing) {
      setState(() => _picked.add(photo));
      return;
    }
    setState(() => _photoBusy = true);
    final (vehicle, failure) =
        await _cubit.addVehiclePhoto(widget.vehicleId!, photo);
    if (!mounted) return;
    setState(() {
      _photoBusy = false;
      if (vehicle != null) {
        _vehicle = vehicle;
        _changed = true;
      }
    });
    if (vehicle == null) {
      _fail(failure?.message ?? 'Couldn’t add that picture.');
    }
  }

  Future<void> _removePhoto(int index) async {
    if (!_editing) {
      setState(() => _picked.removeAt(index));
      return;
    }
    setState(() => _photoBusy = true);
    final (vehicle, failure) = await _cubit.removeVehiclePhoto(
        widget.vehicleId!, _vehicle!.photos[index].id);
    if (!mounted) return;
    setState(() {
      _photoBusy = false;
      if (vehicle != null) {
        _vehicle = vehicle;
        _changed = true;
      }
    });
    if (vehicle == null) {
      _fail(failure?.message ?? 'Couldn’t remove that picture.');
    }
  }

  void _fail(String message) {
    setState(() => _error = message);
    TopSnackBar.show(context, message: message, type: TopSnackBarType.error);
  }

  /// Set once the driver taps save with something missing: every problem is
  /// then shown on its own field (red outline + words) until it's fixed.
  bool _submitted = false;
  String? _shown(String? message) => _submitted ? message : null;

  /// While signing up, the company reviews the vehicle from its pictures —
  /// the backend won't move a driver on to review without one.
  bool get _photoRequired {
    final status = _cubit.state.profile?.onboardingStatus;
    return !_editing && status != null && status != OnboardingStatus.approved;
  }

  String? get _typeError => _typeId == null ? 'Choose the type of vehicle.' : null;

  String? get _plateError {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) return 'Enter the registration number.';
    if (!_plate.hasMatch(plate)) {
      return 'The registration number can only have letters, numbers and hyphens.';
    }
    if (plate.replaceAll('-', '').length < 6) return 'That registration number looks too short — check the number plate.';
    return null;
  }

  String? get _capacityError {
    final capacity = _capacityController.text.trim();
    if (capacity.isEmpty) return null;
    final value = double.tryParse(capacity);
    return value == null || value <= 0 ? 'Enter the capacity as a number above 0, or leave it empty.' : null;
  }

  String? get _photoError =>
      _photoRequired && _photoCount == 0 ? 'Add at least one picture of your vehicle — we need it to approve you.' : null;

  /// What's wrong with the form, in words, or null.
  String? _problem() => _typeError ?? _plateError ?? _capacityError ?? _photoError;

  Future<void> _save() async {
    final problem = _problem();
    if (problem != null) {
      setState(() => _submitted = true);
      _fail(problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final plate = _plateController.text.trim().toUpperCase();
    final capacity = double.tryParse(_capacityController.text.trim());
    final (vehicle, failure) = _editing
        ? await _cubit.updateVehicle(widget.vehicleId!,
            vehicleTypeId: _typeId,
            registrationNumber: plate,
            capacityKg: capacity)
        : await _cubit.addVehicle(
            vehicleTypeId: _typeId!,
            registrationNumber: plate,
            capacityKg: capacity,
            photos: _picked);
    if (!mounted) return;
    setState(() => _saving = false);
    if (vehicle == null) {
      _fail(failure?.message ?? 'Couldn’t save the vehicle. Try again.');
      return;
    }
    TopSnackBar.show(context,
        message: _editing ? 'Saved' : '$plate added',
        type: TopSnackBarType.success);
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.pop(_changed);
        },
        child: Scaffold(
          backgroundColor: DriverColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: DriverColors.ink,
            title: Text(_editing ? 'Edit vehicle' : 'Add a vehicle',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          ),
          body: Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  const _Label('TYPE OF VEHICLE'),
                  _typeChooser(),
                  _FieldError(_shown(_typeError)),
                  const SizedBox(height: 22),
                  DriverTextField(
                    key: const Key('vehicle_plate'),
                    controller: _plateController,
                    label: 'Registration number',
                    hint: 'KA05MN7788',
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9-]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    errorText: _shown(_plateError),
                    onChanged: (_) => _submitted ? setState(() {}) : null,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 14),
                  DriverTextField(
                    key: const Key('vehicle_capacity'),
                    controller: _capacityController,
                    label: 'Load capacity in kg (optional)',
                    helper: _type?.defaultCapacityKg == null
                        ? 'Leave empty to use the vehicle type’s usual capacity.'
                        : 'Leave empty for ${_type!.defaultCapacityKg!.toStringAsFixed(0)} kg, the usual for ${_type!.name}.',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textInputAction: TextInputAction.done,
                    errorText: _shown(_capacityError),
                    onChanged: (_) => _submitted ? setState(() {}) : null,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 22),
                  _Label('PICTURES  ·  $_photoCount OF $kMaxVehiclePhotos'),
                  const Text(
                      'Clear pictures of the whole vehicle — front, side, back. The first one is shown as the main picture.',
                      style: TextStyle(
                          color: DriverColors.muted,
                          fontSize: 12.5,
                          height: 1.4)),
                  const SizedBox(height: 12),
                  _photoGrid(),
                  _FieldError(_shown(_photoError)),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    InfoBanner(
                        key: const Key('vehicle_error'),
                        text: _error!,
                        color: DriverColors.red,
                        icon: Icons.error_outline_rounded),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  18, 12, 18, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, -3)),
              ]),
              child: PrimaryButton(
                key: const Key('vehicle_save'),
                label: _editing ? 'Save changes' : 'Add vehicle',
                icon: Icons.check_rounded,
                color: DriverColors.green,
                loading: _saving,
                onPressed: _saving || _photoBusy ? null : _save,
              ),
            ),
          ]),
        ),
      );

  Widget _typeChooser() {
    if (_typesError != null) {
      return Row(children: [
        Expanded(
            child: Text(_typesError!,
                style: const TextStyle(color: DriverColors.red, fontSize: 13))),
        TextButton(onPressed: _loadTypes, child: const Text('Retry')),
      ]);
    }
    final types = _types;
    if (types == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (types.isEmpty) {
      return const Text(
          'Your company hasn’t set up any vehicle types yet. Ask them to add one.',
          style: TextStyle(color: DriverColors.muted, fontSize: 13));
    }
    // A picture per type — "what does your vehicle look like?" is quicker to
    // answer from a drawing than from a name.
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        for (final type in types)
          _TypeCard(
            key: Key('vehicle_type_${type.id}'),
            type: type,
            selected: _typeId == type.id,
            error: _shown(_typeError) != null,
            onTap: _saving ? null : () => setState(() => _typeId = type.id),
          ),
      ],
    );
  }

  Widget _photoGrid() {
    final tiles = <Widget>[
      if (_editing)
        for (var i = 0; i < (_vehicle?.photos.length ?? 0); i++)
          _PhotoSquare(
            key: Key('vehicle_photo_$i'),
            index: i,
            network: _vehicle!.photos[i].url,
            main: i == 0,
            onRemove: _photoBusy || _saving ? null : () => _removePhoto(i),
          )
      else
        for (var i = 0; i < _picked.length; i++)
          _PhotoSquare(
            key: Key('vehicle_photo_$i'),
            index: i,
            bytes: _picked[i],
            main: i == 0,
            onRemove: _saving ? null : () => _removePhoto(i),
          ),
      if (_photoCount < kMaxVehiclePhotos)
        _AddPhotoSquare(
          key: const Key('vehicle_photo_add'),
          error: _shown(_photoError) != null,
          busy: _photoBusy,
          onTap: _saving || _photoBusy ? null : _addPhoto,
        ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: DriverColors.muted,
                fontSize: 11.5,
                letterSpacing: .9,
                fontWeight: FontWeight.w800)),
      );
}

const _tile = 100.0;

class _PhotoSquare extends StatelessWidget {
  const _PhotoSquare({
    super.key,
    this.network,
    this.bytes,
    required this.index,
    required this.main,
    required this.onRemove,
  });

  final int index;
  final String? network;
  final CapturedPhoto? bytes;
  final bool main;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _tile,
        height: _tile,
        child: Stack(children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: bytes != null
                  ? Image.memory(bytes!.bytes, fit: BoxFit.cover)
                  : NetworkThumb(network, size: _tile, radius: 14),
            ),
          ),
          if (main)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('MAIN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              key: Key('vehicle_photo_remove_$index'),
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: onRemove == null ? .3 : .68),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ]),
      );
}

/// A red line of words under a field group (the type grid, the pictures).
class _FieldError extends StatelessWidget {
  const _FieldError(this.message);
  final String? message;

  @override
  Widget build(BuildContext context) => AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topLeft,
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.error_outline_rounded, color: DriverColors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(message!,
                        style: const TextStyle(color: DriverColors.red, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
      );
}

class _AddPhotoSquare extends StatelessWidget {
  const _AddPhotoSquare({super.key, required this.busy, required this.onTap, this.error = false});
  final bool busy;
  final VoidCallback? onTap;
  final bool error;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: _tile,
        height: _tile,
        child: Material(
          color: error ? const Color(0xFFFFF5F5) : const Color(0xFFF7F9FC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: error ? DriverColors.red : DriverColors.line, width: error ? 1.6 : 1.2),
          ),
          child: InkWell(
            customBorder:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onTap: onTap,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: error ? DriverColors.red : DriverColors.blue, size: 26),
                      const SizedBox(height: 6),
                      const Text('Add photo',
                          style: TextStyle(
                              color: DriverColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ),
      );
}


class _TypeCard extends StatelessWidget {
  const _TypeCard({super.key, required this.type, required this.selected, this.onTap, this.error = false});

  final VehicleTypeOption type;
  final bool selected;
  final VoidCallback? onTap;

  /// Nothing chosen yet and the driver tried to save: outline every card red.
  final bool error;

  @override
  Widget build(BuildContext context) => PressScale(
        enabled: onTap != null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2F7FD) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? DriverColors.blue : error ? DriverColors.red : DriverColors.line,
                width: selected ? 2 : error ? 1.5 : 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Center(
                            child: (type.iconUrl ?? '').isNotEmpty
                                ? Image.network(type.iconUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => VehicleArt(
                                        category: type.category, name: type.name, width: 96))
                                : VehicleArt(category: type.category, name: type.name, width: 96),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: selected ? DriverColors.blue : DriverColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(
                            [
                              if (type.categoryLabel.isNotEmpty) type.categoryLabel,
                              if (type.defaultCapacityKg != null)
                                '${type.defaultCapacityKg!.round()} kg',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: DriverColors.muted, fontSize: 12)),
                      ]),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle_rounded, color: DriverColors.blue, size: 20),
                  ),
              ]),
            ),
          ),
        ),
      );
}
