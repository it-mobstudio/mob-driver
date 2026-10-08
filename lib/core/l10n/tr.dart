import 'package:flutter/widgets.dart';
import 'package:mob_driver/core/l10n/strings_hi.dart';
import 'package:mob_driver/core/l10n/strings_kn.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages a driver can pick in Profile → Language.
enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'हिन्दी', 'Hindi'),
  kannada('kn', 'ಕನ್ನಡ', 'Kannada');

  const AppLanguage(this.code, this.nativeName, this.englishName);

  /// ISO 639-1, as Flutter's [Locale] wants it.
  final String code;

  /// The language's name in itself — how a driver who reads only that
  /// language recognises it in the picker.
  final String nativeName;
  final String englishName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => values.firstWhere(
        (l) => l.code == code,
        orElse: () => AppLanguage.english,
      );
}

/// The driver's chosen language, remembered on the device.
class AppLanguageController extends ValueNotifier<AppLanguage> {
  AppLanguageController._() : super(AppLanguage.english);

  static final instance = AppLanguageController._();

  static const _prefsKey = 'app_language';

  /// Reads the saved choice. English until (and unless) one is found.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = AppLanguage.fromCode(prefs.getString(_prefsKey));
    } catch (_) {
      // No storage (tests, a broken keystore): stay in English.
    }
  }

  Future<void> choose(AppLanguage language) async {
    value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (_) {}
  }
}

/// [english] in the driver's language. The English text *is* the key: a
/// string with no translation yet simply shows in English rather than
/// breaking, and the English app reads exactly as written.
///
/// `{name}` placeholders are filled from [args]:
/// `tr('{count} items', {'count': 3})`.
///
/// Context-free on purpose, so trip statuses, error messages and
/// notifications translate too. Screens repaint when the language changes
/// because the app rebuilds everything at that moment (see main.dart).
String tr(String english, [Map<String, Object?> args = const {}]) {
  final table = switch (AppLanguageController.instance.value) {
    AppLanguage.english => null,
    AppLanguage.hindi => kHindiStrings,
    AppLanguage.kannada => kKannadaStrings,
  };
  var text = table?[english] ?? english;
  for (final MapEntry(:key, :value) in args.entries) {
    text = text.replaceAll('{$key}', '$value');
  }
  return text;
}
