import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

OutlineInputBorder _border(Color color, [double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color, width: width),
    );

InputDecoration driverInputDecoration({
  required String label,
  String? hint,
  String? helper,
  String? errorText,
  String? prefixText,
  Widget? suffixIcon,
  bool enabled = true,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      errorText: errorText,
      errorMaxLines: 3,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      counterText: '',
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF1F4F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      labelStyle: const TextStyle(color: DriverColors.muted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
          color: DriverColors.blue, fontWeight: FontWeight.w600),
      helperStyle: const TextStyle(color: DriverColors.muted, fontSize: 11.5),
      border: _border(DriverColors.line),
      enabledBorder: _border(DriverColors.line),
      disabledBorder: _border(DriverColors.line),
      focusedBorder: _border(DriverColors.blue, 1.6),
      errorBorder: _border(DriverColors.red),
      focusedErrorBorder: _border(DriverColors.red, 1.6),
    );

/// The app's text field: one look for every form (onboarding, edit profile,
/// payout details, the document sheets).
class DriverTextField extends StatelessWidget {
  const DriverTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        autofillHints: autofillHints,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(
            color: DriverColors.ink, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: driverInputDecoration(
          label: label,
          hint: hint,
          helper: helper,
          errorText: errorText,
          prefixText: prefixText,
          enabled: enabled,
        ),
      );
}

/// A field that shows a date and opens the calendar when tapped.
class DriverDateField extends StatelessWidget {
  const DriverDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.helper,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Where the calendar opens when nothing is chosen yet.
  final DateTime? initialDate;
  final String? helper;
  final String? errorText;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? initialDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: enabled ? () => _pick(context) : null,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: driverInputDecoration(
            label: label,
            helper: helper,
            errorText: errorText,
            enabled: enabled,
            suffixIcon: const Icon(Icons.calendar_today_rounded,
                size: 18, color: DriverColors.muted),
          ),
          child: Text(
            value == null ? '' : formatDate(value),
            style: const TextStyle(
                color: DriverColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ),
      );
}

/// Digits only, capped at [max] — for phone numbers, pincodes, account numbers.
List<TextInputFormatter> digitsOnly(int max) => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(max),
    ];

/// Groups digits as `1234 5678 9012` while typing (Aadhaar's own layout).
class GroupedDigitsFormatter extends TextInputFormatter {
  const GroupedDigitsFormatter({this.max = 12, this.group = 4});
  final int max;
  final int group;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > max) digits = digits.substring(0, max);
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % group == 0) out.write(' ');
      out.write(digits[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
