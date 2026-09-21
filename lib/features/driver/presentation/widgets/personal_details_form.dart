import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart'
    show driverPhoneFromDigits;
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

/// `+919555500002` → `9555500002` (the field has the +91 built in).
String _tenDigits(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

/// The driver's own details: name, date of birth, contact, address and who to
/// call in an emergency. Used for the first step of sign-up and, later, for
/// editing the profile — so what they see and what's validated is the same.
///
/// Name and date of birth are what the verified ID says, so they lock once the
/// company has verified the Aadhaar.
class PersonalDetailsForm extends StatefulWidget {
  const PersonalDetailsForm({
    super.key,
    required this.profile,
    required this.submitLabel,
    required this.onSaved,
  });

  final DriverProfile profile;
  final String submitLabel;
  final VoidCallback onSaved;

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _email = TextEditingController(text: widget.profile.email ?? '');
  late final _address =
      TextEditingController(text: widget.profile.addressLine ?? '');
  late final _city = TextEditingController(text: widget.profile.city ?? '');
  late final _pincode =
      TextEditingController(text: widget.profile.pincode ?? '');
  late final _emergencyName =
      TextEditingController(text: widget.profile.emergencyContactName ?? '');
  late final _emergencyPhone = TextEditingController(
      text: _tenDigits(widget.profile.emergencyContactPhone));
  late DateTime? _dob = widget.profile.dateOfBirth;

  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _address,
      _city,
      _pincode,
      _emergencyName,
      _emergencyPhone
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _locked => widget.profile.identityLocked;

  // Each returns the message to show, or null when the field is fine. They run
  // on every rebuild once the driver has tried to submit, so an error clears
  // the moment it's fixed.
  String? get _nameError => _name.text.trim().length < 2
      ? 'Enter your full name as on your licence.'
      : null;

  String? get _dobError => _dob == null ? 'Select your date of birth.' : null;

  String? get _emailError => _email.text.trim().isNotEmpty &&
          !_emailPattern.hasMatch(_email.text.trim())
      ? 'Enter a valid email address.'
      : null;

  String? get _pincodeError =>
      _pincode.text.isNotEmpty && _pincode.text.length != 6
          ? 'Enter a 6-digit pincode.'
          : null;

  String? get _emergencyNameError =>
      _emergencyName.text.trim().isEmpty ? 'Enter a name.' : null;

  String? get _emergencyPhoneError {
    if (_emergencyPhone.text.length != 10) return 'Enter a 10-digit number.';
    if (driverPhoneFromDigits(_emergencyPhone.text) ==
        widget.profile.phoneNumber) {
      return 'Use someone else’s number — we call them if you need help.';
    }
    return null;
  }

  bool get _valid => [
        if (!_locked) _nameError,
        if (!_locked) _dobError,
        _emailError,
        _pincodeError,
        _emergencyNameError,
        _emergencyPhoneError,
      ].every((e) => e == null);

  String? _shown(String? error) => _submitted ? error : null;

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_valid) {
      AppHaptics.error();
      return;
    }
    setState(() => _saving = true);
    final failure = await context.read<DriverSessionCubit>().updateProfile(
          ProfileUpdate(
            fullName: _locked ? null : _name.text.trim(),
            dateOfBirth: _locked ? null : _dob,
            email: _email.text.trim(),
            addressLine: _address.text.trim(),
            city: _city.text.trim(),
            pincode: _pincode.text.trim(),
            emergencyContactName: _emergencyName.text.trim(),
            emergencyContactPhone: driverPhoneFromDigits(_emergencyPhone.text),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      AppHaptics.error();
      setState(() => _serverError = failure.message);
      return;
    }
    AppHaptics.success();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_locked)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: InfoBanner(
            text:
                'Your name and date of birth match your verified ID, so they can’t be changed here.',
            icon: Icons.lock_outline_rounded,
            color: DriverColors.blue,
          ),
        ),
      DriverTextField(
        key: const Key('field_full_name'),
        controller: _name,
        label: 'Full name',
        hint: 'As on your driving licence',
        enabled: !_locked && !_saving,
        textCapitalization: TextCapitalization.words,
        errorText: _locked ? null : _shown(_nameError),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      DriverDateField(
        key: const Key('field_dob'),
        label: 'Date of birth',
        value: _dob,
        enabled: !_locked && !_saving,
        errorText: _locked ? null : _shown(_dobError),
        firstDate: DateTime(now.year - 80, now.month, now.day),
        lastDate: DateTime(now.year - 18, now.month, now.day),
        initialDate: DateTime(now.year - 28, now.month, now.day),
        helper: 'You must be at least 18.',
        onChanged: (d) => setState(() => _dob = d),
      ),
      const SizedBox(height: 14),
      DriverTextField(
        key: const Key('field_email'),
        controller: _email,
        label: 'Email (optional)',
        keyboardType: TextInputType.emailAddress,
        enabled: !_saving,
        errorText: _shown(_emailError),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      DriverTextField(
        key: const Key('field_address'),
        controller: _address,
        label: 'Address (optional)',
        textCapitalization: TextCapitalization.words,
        enabled: !_saving,
      ),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: DriverTextField(
            key: const Key('field_city'),
            controller: _city,
            label: 'City',
            textCapitalization: TextCapitalization.words,
            enabled: !_saving,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DriverTextField(
            key: const Key('field_pincode'),
            controller: _pincode,
            label: 'Pincode',
            keyboardType: TextInputType.number,
            inputFormatters: digitsOnly(6),
            enabled: !_saving,
            errorText: _shown(_pincodeError),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ]),
      const SizedBox(height: 22),
      const SectionTitle('Emergency contact'),
      const SizedBox(height: 4),
      const Text('Someone we can call if there’s a problem on the road.',
          style: TextStyle(color: DriverColors.muted, fontSize: 12.5)),
      const SizedBox(height: 12),
      DriverTextField(
        key: const Key('field_emergency_name'),
        controller: _emergencyName,
        label: 'Contact name',
        textCapitalization: TextCapitalization.words,
        enabled: !_saving,
        errorText: _shown(_emergencyNameError),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 14),
      DriverTextField(
        key: const Key('field_emergency_phone'),
        controller: _emergencyPhone,
        label: 'Contact phone',
        prefixText: '+91  ',
        keyboardType: TextInputType.phone,
        inputFormatters: digitsOnly(10),
        textInputAction: TextInputAction.done,
        enabled: !_saving,
        errorText: _shown(_emergencyPhoneError),
        onChanged: (_) => setState(() {}),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _serverError == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 14),
                child: InfoBanner(
                  key: const Key('details_error'),
                  text: _serverError!,
                  icon: Icons.error_outline_rounded,
                  color: DriverColors.red,
                ),
              ),
      ),
      const SizedBox(height: 22),
      PrimaryButton(
        key: const Key('details_submit'),
        label: widget.submitLabel,
        loading: _saving,
        onPressed: _save,
      ),
    ]);
  }
}
