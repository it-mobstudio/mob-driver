import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';

/// The frame every bottom sheet in the driver app shares: rounded top, a grab
/// handle, a title, and content that scrolls above the keyboard.
class DriverSheet extends StatelessWidget {
  const DriverSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        // A Material (not a painted Container): ink ripples inside need one
        // above them, and an opaque box in between hides them.
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: DriverColors.line,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(title,
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: const TextStyle(
                              color: DriverColors.muted,
                              fontSize: 12.5,
                              height: 1.4)),
                    ],
                    const SizedBox(height: 16),
                    child,
                  ]),
            ),
          ),
        ),
      );
}

Future<bool> _showSheet(BuildContext context, Widget sheet) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    ) ??
    false;

/// Aadhaar: the 12-digit number (only its last four digits are kept) and both
/// sides of the card. Resolves true once the backend has accepted it.
Future<bool> showAadharSheet(
  BuildContext context, {
  PhotoCapture capture = const DevicePhotoCapture(),
  KycItem? current,
}) =>
    _showSheet(context, _AadharSheet(capture: capture, current: current));

/// Driving licence: number, expiry and the card's front (and, optionally, back).
Future<bool> showLicenceSheet(
  BuildContext context, {
  PhotoCapture capture = const DevicePhotoCapture(),
  KycItem? current,
}) =>
    _showSheet(context, _LicenceSheet(capture: capture, current: current));

/// Police verification certificate: one picture of it.
Future<bool> showPoliceSheet(
  BuildContext context, {
  PhotoCapture capture = const DevicePhotoCapture(),
  KycItem? current,
}) =>
    _showSheet(context, _PoliceSheet(capture: capture, current: current));

class _RejectionNote extends StatelessWidget {
  const _RejectionNote(this.item);
  final KycItem? item;

  @override
  Widget build(BuildContext context) {
    final note = item?.rejectionNote;
    if (item?.status != KycStatus.rejected) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InfoBanner(
        key: const Key('rejection_note'),
        text: 'Sent back for a fix${note == null ? '.' : ': $note'}',
        icon: Icons.error_outline_rounded,
        color: DriverColors.red,
      ),
    );
  }
}

/// State every document sheet shares: which pictures are chosen, whether a
/// submit is in flight, and the error to show if the backend said no.
mixin _SheetState<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  PhotoCapture get capture;

  Future<CapturedPhoto?> pick() => chooseDocumentPhoto(context, capture);

  /// Runs [submit]; closes the sheet on success, shows the reason otherwise.
  Future<void> run(
      Future<AppFailure?> Function(DriverSessionCubit cubit) submit) async {
    setState(() {
      busy = true;
      error = null;
    });
    final failure = await submit(context.read<DriverSessionCubit>());
    if (!mounted) return;
    if (failure != null) {
      AppHaptics.error();
      setState(() {
        busy = false;
        error = failure.message;
      });
      return;
    }
    AppHaptics.success();
    Navigator.pop(context, true);
  }

  Widget errorBanner() => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: error == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InfoBanner(
                  key: const Key('sheet_error'),
                  text: error!,
                  icon: Icons.error_outline_rounded,
                  color: DriverColors.red,
                ),
              ),
      );
}

// -- Aadhaar -----------------------------------------------------------------

class _AadharSheet extends StatefulWidget {
  const _AadharSheet({required this.capture, this.current});
  final PhotoCapture capture;
  final KycItem? current;

  @override
  State<_AadharSheet> createState() => _AadharSheetState();
}

class _AadharSheetState extends State<_AadharSheet> with _SheetState {
  final _number = TextEditingController();
  CapturedPhoto? _front;
  CapturedPhoto? _back;

  @override
  PhotoCapture get capture => widget.capture;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  String get _digits => _number.text.replaceAll(' ', '');
  bool get _ready => _digits.length == 12 && _front != null && _back != null;

  @override
  Widget build(BuildContext context) => DriverSheet(
        title: 'Aadhaar card',
        subtitle:
            'Photograph both sides clearly. We only keep the last 4 digits of the number.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RejectionNote(widget.current),
          DriverTextField(
            key: const Key('field_aadhar_number'),
            controller: _number,
            label: 'Aadhaar number',
            hint: '1234 5678 9012',
            keyboardType: TextInputType.number,
            inputFormatters: const [GroupedDigitsFormatter()],
            textInputAction: TextInputAction.done,
            enabled: !busy,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: PhotoTile(
                key: const Key('aadhar_front'),
                label: 'Front',
                photo: _front,
                enabled: !busy,
                onTap: () async {
                  final p = await pick();
                  if (p != null) setState(() => _front = p);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PhotoTile(
                key: const Key('aadhar_back'),
                label: 'Back',
                photo: _back,
                enabled: !busy,
                onTap: () async {
                  final p = await pick();
                  if (p != null) setState(() => _back = p);
                },
              ),
            ),
          ]),
          errorBanner(),
          const SizedBox(height: 18),
          PrimaryButton(
            key: const Key('aadhar_submit'),
            label: 'Submit Aadhaar',
            loading: busy,
            onPressed: _ready
                ? () => run((cubit) => cubit.submitAadhar(
                      number: _digits,
                      front: _front!,
                      back: _back!,
                    ))
                : null,
          ),
        ]),
      );
}

// -- Driving licence ---------------------------------------------------------------

class _LicenceSheet extends StatefulWidget {
  const _LicenceSheet({required this.capture, this.current});
  final PhotoCapture capture;
  final KycItem? current;

  @override
  State<_LicenceSheet> createState() => _LicenceSheetState();
}

class _LicenceSheetState extends State<_LicenceSheet> with _SheetState {
  final _number = TextEditingController();
  DateTime? _expiry;
  CapturedPhoto? _front;
  CapturedPhoto? _back;

  @override
  PhotoCapture get capture => widget.capture;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  bool get _ready =>
      _number.text.trim().length >= 8 && _expiry != null && _front != null;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return DriverSheet(
      title: 'Driving licence',
      subtitle:
          'Enter it exactly as printed on the card, then photograph the front.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _RejectionNote(widget.current),
        DriverTextField(
          key: const Key('field_dl_number'),
          controller: _number,
          label: 'Licence number',
          hint: 'KA01 20110012345',
          textCapitalization: TextCapitalization.characters,
          maxLength: 25,
          enabled: !busy,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        DriverDateField(
          key: const Key('field_dl_expiry'),
          label: 'Valid until',
          value: _expiry,
          enabled: !busy,
          firstDate: DateTime(today.year, today.month, today.day),
          lastDate: DateTime(today.year + 30, today.month, today.day),
          initialDate: DateTime(today.year + 1, today.month, today.day),
          helper: 'An expired licence can’t be used.',
          onChanged: (d) => setState(() => _expiry = d),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: PhotoTile(
              key: const Key('dl_front'),
              label: 'Front',
              photo: _front,
              enabled: !busy,
              onTap: () async {
                final p = await pick();
                if (p != null) setState(() => _front = p);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PhotoTile(
              key: const Key('dl_back'),
              label: 'Back',
              optional: true,
              photo: _back,
              enabled: !busy,
              onTap: () async {
                final p = await pick();
                if (p != null) setState(() => _back = p);
              },
            ),
          ),
        ]),
        errorBanner(),
        const SizedBox(height: 18),
        PrimaryButton(
          key: const Key('dl_submit'),
          label: 'Submit licence',
          loading: busy,
          onPressed: _ready
              ? () => run((cubit) => cubit.submitLicence(
                    number: _number.text.trim(),
                    expiry: _expiry!,
                    front: _front!,
                    back: _back,
                  ))
              : null,
        ),
      ]),
    );
  }
}

// -- Police verification ----------------------------------------------------------------

class _PoliceSheet extends StatefulWidget {
  const _PoliceSheet({required this.capture, this.current});
  final PhotoCapture capture;
  final KycItem? current;

  @override
  State<_PoliceSheet> createState() => _PoliceSheetState();
}

class _PoliceSheetState extends State<_PoliceSheet> with _SheetState {
  CapturedPhoto? _document;

  @override
  PhotoCapture get capture => widget.capture;

  @override
  Widget build(BuildContext context) => DriverSheet(
        title: 'Police verification',
        subtitle:
            'A police clearance / verification certificate. You can add this later — it’s needed before you can take trips.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _RejectionNote(widget.current),
          PhotoTile(
            key: const Key('police_document'),
            label: 'Certificate',
            height: 150,
            photo: _document,
            enabled: !busy,
            onTap: () async {
              final p = await pick();
              if (p != null) setState(() => _document = p);
            },
          ),
          errorBanner(),
          const SizedBox(height: 18),
          PrimaryButton(
            key: const Key('police_submit'),
            label: 'Submit certificate',
            loading: busy,
            onPressed: _document == null
                ? null
                : () => run((cubit) => cubit.submitPolice(_document!)),
          ),
        ]),
      );
}
