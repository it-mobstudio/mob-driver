import 'package:flutter/services.dart';

final gstRegex = RegExp(r'^[0-3|9][0-9][a-zA-Z0-9]{13}$');

final gstInputFormatters = <TextInputFormatter>[
  LengthLimitingTextInputFormatter(15),
  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
];

bool isValidOptionalGst(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return true;
  return gstRegex.hasMatch(text);
}

bool isValidRequiredGst(String? value) {
  final text = value?.trim() ?? '';
  return text.isNotEmpty && gstRegex.hasMatch(text);
}

String? optionalGstValidator(String? value) {
  return isValidOptionalGst(value) ? null : 'Enter a valid GSTIN';
}

String? requiredGstValidator(String? value) {
  return isValidRequiredGst(value)
      ? null
      : 'Enter a valid 15-character GSTIN';
}
