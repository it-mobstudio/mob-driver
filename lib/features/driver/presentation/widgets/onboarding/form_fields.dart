import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/app_text_field.dart';

InputDecoration driverInputDecoration({
  required String label,
  String? hint,
  String? helper,
  String? errorText,
  String? prefixText,
  Widget? suffixIcon,
  bool enabled = true,
}) =>
    appTextFieldDecoration(
      label: label,
      hintText: hint,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      enabled: enabled,
    ).copyWith(
      helperText: helper,
      helperMaxLines: 2,
      helperStyle: AppTextFieldStyles.label,
      errorText: errorText,
      errorMaxLines: 3,
      counterText: '',
    );

/// The app's text field: one look for every form (onboarding, edit profile,
/// payout details, the document sheets).
class FormTextField extends StatelessWidget {
  const FormTextField({
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
        style: AppTextFieldStyles.inputText,
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
class FormDateField extends StatelessWidget {
  const FormDateField({
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
            suffixIcon: Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.muted),
          ),
          child: Text(
            value == null ? '' : formatDate(value),
            style: AppTextFieldStyles.inputText,
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
