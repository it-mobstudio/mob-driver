import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

/// The colours of one appearance (light or dark). MOB's brand is navy
/// #001533 and blue #0454A3, with the logo's green as the accent; green
/// otherwise means done / pickup, red drop / problem, orange attention.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.ink,
    required this.muted,
    required this.surface,
    required this.surfaceMuted,
    required this.card,
    required this.line,
    required this.navy,
    required this.blue,
    required this.blueBright,
    required this.blueSoft,
    required this.button,
    required this.mint,
    required this.green,
    required this.orange,
    required this.red,
    required this.greenSoft,
    required this.orangeSoft,
    required this.redSoft,
  });

  final Brightness brightness;

  /// Main text.
  final Color ink;

  /// Secondary text and icons.
  final Color muted;

  /// Behind everything (the scaffold).
  final Color surface;

  /// A quieter panel inside a card: fields, chips, empty photo slots.
  final Color surfaceMuted;

  /// Cards, sheets, headers and bars.
  final Color card;

  /// Dividers and outlines.
  final Color line;

  final Color navy;
  final Color blue;
  final Color blueBright;
  final Color blueSoft;

  /// Every main action button: one flat colour, no gradient.
  final Color button;
  final Color mint;
  final Color green;
  final Color orange;
  final Color red;

  /// Pale fills behind success / attention / problem content.
  final Color greenSoft;
  final Color orangeSoft;
  final Color redSoft;

  static const light = AppPalette(
    brightness: Brightness.light,
    ink: Color(0xFF0B1B33),
    muted: Color(0xFF6A778A),
    surface: Color(0xFFF4F6FB),
    surfaceMuted: Color(0xFFF1F4F8),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE6EAF0),
    navy: Color(0xFF001533),
    blue: Color(0xFF0454A3),
    blueBright: Color(0xFF2F7FD6),
    blueSoft: Color(0xFFE8F1FB),
    button: Color(0xFF0360E5),
    mint: Color(0xFF00DE9D),
    green: Color(0xFF12A15E),
    orange: Color(0xFFD9820F),
    red: Color(0xFFE0444F),
    greenSoft: Color(0xFFE5F6EC),
    orangeSoft: Color(0xFFFFF5E3),
    redSoft: Color(0xFFFFF1F1),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    ink: Color(0xFFE8EDF5),
    muted: Color(0xFF9AA6B8),
    surface: Color(0xFF0D131B),
    surfaceMuted: Color(0xFF1F2936),
    card: Color(0xFF17202B),
    line: Color(0xFF283445),
    navy: Color(0xFF0A1B33),
    blue: Color(0xFF6FA8EC),
    blueBright: Color(0xFF8DBBF2),
    blueSoft: Color(0xFF16273D),
    button: Color(0xFF2F7CF0),
    mint: Color(0xFF2EE6B0),
    // Fills carry white text, so these stay as saturated as in light mode;
    // they also read well as text on the dark cards (about 5:1).
    green: Color(0xFF1FA463),
    orange: Color(0xFFDD8A18),
    red: Color(0xFFF2666F),
    greenSoft: Color(0xFF16302A),
    orangeSoft: Color(0xFF33280F),
    redSoft: Color(0xFF35191C),
  );
}

/// The app's colours, for the appearance in use (see AppAppearance). Screens
/// read them from here rather than spelling hex values, so light and dark
/// stay consistent.
abstract final class AppColors {
  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;

  /// Switches every colour below. The app repaints right after.
  static void use(AppPalette palette) => _palette = palette;

  static bool get isDark => _palette.brightness == Brightness.dark;

  static Color get ink => _palette.ink;
  static Color get muted => _palette.muted;
  static Color get surface => _palette.surface;
  static Color get surfaceMuted => _palette.surfaceMuted;
  static Color get card => _palette.card;
  static Color get line => _palette.line;
  static Color get navy => _palette.navy;
  static Color get blue => _palette.blue;
  static Color get blueBright => _palette.blueBright;
  static Color get blueSoft => _palette.blueSoft;
  static Color get button => _palette.button;
  static Color get mint => _palette.mint;
  static Color get green => _palette.green;
  static Color get orange => _palette.orange;
  static Color get red => _palette.red;
  static Color get greenSoft => _palette.greenSoft;
  static Color get orangeSoft => _palette.orangeSoft;
  static Color get redSoft => _palette.redSoft;

  /// The navy → blue sweep behind hero cards. Brand colours, the same in
  /// light and dark: it always carries white text.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF001533), Color(0xFF02336E), Color(0xFF0454A3)],
    stops: [0, .55, 1],
  );
}
