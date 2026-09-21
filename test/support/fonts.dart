import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `flutter test` draws every glyph in the "Ahem" font — a full-em square —
/// so text comes out roughly twice as wide as on a device and layouts
/// "overflow" that are fine in reality (and vice versa). Loading the app's
/// real Inter font makes widget tests measure text the way the app does.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Inter');
  for (final file in const ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$file.ttf'));
  }
  await loader.load();
}

/// The theme the real app uses for text.
final ThemeData testTheme = ThemeData(fontFamily: 'Inter', useMaterial3: false);
