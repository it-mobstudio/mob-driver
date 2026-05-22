import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

abstract final class AppColors {
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF0360E5);
  static const Color primaryText = Color(0xFF0A243F);
  static const Color inputBorder = Color(0xFFDFE4EC);
  static const Color inputHint = Color(0xFFAFB4C0);
  static const Color inputLabel = Color(0xFF767C8F);
  static const Color mutedControl = Color(0xFFB5B5B5);
  static const Color rewardBackground = Color(0xFFFFEA94);
}

abstract final class AppTextStyles {
  static TextStyle get screenTitle => GoogleFonts.inter(
        color: AppColors.primaryText,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      );

  static TextStyle get body14 => GoogleFonts.inter(
        color: AppColors.primaryText,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  static TextStyle get body14Bold => body14.copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 20 / 14,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        color: AppColors.surface,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 21 / 14,
      );

  static TextStyle get legalText => GoogleFonts.inter(
        color: AppColors.primaryText,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 16 / 11,
      );

  static TextStyle get legalMedium => legalText.copyWith(
        fontWeight: FontWeight.w500,
      );

  static TextStyle get legalStrong => legalText.copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle get rewardText => GoogleFonts.inter(
        color: AppColors.primaryText,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 14 / 12,
      );

  static TextStyle get rewardStrong => rewardText.copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle get secondaryLabel => GoogleFonts.inter(
        color: AppColors.inputHint,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get otpDigit => GoogleFonts.inter(
        color: AppColors.primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      );
}

abstract final class AppComponentStyles {
  static const double fieldHeight = 48;
  static const double buttonHeight = 48;
  static const double radius = 12;

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

abstract final class AppFormFieldStyles {
  static InputDecoration outlinedDecoration(
    String label, {
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: GoogleFonts.inter(
        color: AppColors.inputLabel,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 14 / 11,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 14 / 11,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.inputHint,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 20 / 14,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minHeight: AppComponentStyles.fieldHeight,
        minWidth: 40,
      ),
      enabledBorder: _border(),
      focusedBorder: _border(
        color: AppColors.primaryText,
        width: 1.5,
      ),
      errorBorder: _border(
        color: Colors.red,
      ),
      focusedErrorBorder: _border(
        color: Colors.red,
        width: 1.5,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    );
  }

  static OutlineInputBorder _border({
    Color color = AppColors.inputBorder,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppComponentStyles.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
