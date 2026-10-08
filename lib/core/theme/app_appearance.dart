import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark, or whatever the phone is set to — Profile → Appearance.
/// Light until the driver picks otherwise; the login screens are always
/// light, and signing out goes back to light (see DriverApp).
class AppAppearance extends ValueNotifier<ThemeMode> {
  AppAppearance._() : super(ThemeMode.light);

  static final instance = AppAppearance._();

  static const _prefsKey = 'app_theme_mode';

  /// Reads the saved choice.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      value = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.light,
      );
    } catch (_) {
      // No storage (tests, a broken keystore): stay light.
    }
  }

  Future<void> choose(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {}
  }

  /// Back to the default — the choice belongs to the driver who made it.
  Future<void> reset() => choose(ThemeMode.light);

  /// What's actually showing, given the phone's own setting.
  Brightness effectiveBrightness(Brightness platform) => switch (value) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => platform,
      };
}
