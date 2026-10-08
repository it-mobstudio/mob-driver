import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/core/l10n/strings_hi.dart';
import 'package:mob_driver/core/l10n/strings_kn.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final language = AppLanguageController.instance;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => language.value = AppLanguage.english);

  test('English is the text itself', () {
    expect(tr('Start duty'), 'Start duty');
  });

  test('Hindi and Kannada come from their catalogs', () {
    language.value = AppLanguage.hindi;
    expect(tr('Start duty'), 'ड्यूटी शुरू करें');
    language.value = AppLanguage.kannada;
    expect(tr('Start duty'), 'ಡ್ಯೂಟಿ ಪ್ರಾರಂಭಿಸಿ');
  });

  test('placeholders are filled in every language', () {
    expect(
        tr('Now on {registrationNumber}', {'registrationNumber': 'KA01AB1234'}),
        'Now on KA01AB1234');
    language.value = AppLanguage.hindi;
    expect(
        tr('Now on {registrationNumber}', {'registrationNumber': 'KA01AB1234'}),
        'अब KA01AB1234 पर');
  });

  test('a string with no translation yet falls back to English', () {
    language.value = AppLanguage.kannada;
    expect(tr('Some text nobody has translated'),
        'Some text nobody has translated');
  });

  test('the choice is remembered across restarts', () async {
    await language.choose(AppLanguage.kannada);
    language.value = AppLanguage.english; // as on a fresh launch
    await language.load();
    expect(language.value, AppLanguage.kannada);
  });

  test('every string the app translates has a Hindi and a Kannada entry', () {
    final key = RegExp(r"\btr\('((?:[^'\\]|\\.)*)'");
    final missing = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File ||
          !file.path.endsWith('.dart') ||
          file.path.contains('/l10n/')) {
        continue;
      }
      for (final m in key.allMatches(file.readAsStringSync())) {
        // The source spelling, unescaped the way Dart reads it.
        final english =
            m.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\n', '\n');
        if (!kHindiStrings.containsKey(english)) {
          missing.add('hi: $english  (${file.path})');
        }
        if (!kKannadaStrings.containsKey(english)) {
          missing.add('kn: $english  (${file.path})');
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'Add these to strings_hi.dart / strings_kn.dart');
  });
}
