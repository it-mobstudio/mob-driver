import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/core/theme/app_appearance.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final appearance = AppAppearance.instance;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    appearance.value = ThemeMode.light;
    AppColors.use(AppPalette.light);
  });

  test('light until the driver picks otherwise', () async {
    await appearance.load();
    expect(appearance.value, ThemeMode.light);
  });

  test('the choice is remembered, and reset (on sign-out) goes back to light',
      () async {
    await appearance.choose(ThemeMode.dark);
    appearance.value = ThemeMode.light; // as on a fresh launch
    await appearance.load();
    expect(appearance.value, ThemeMode.dark);

    await appearance.reset();
    await appearance.load();
    expect(appearance.value, ThemeMode.light);
  });

  test('"same as phone" follows the phone', () {
    appearance.value = ThemeMode.system;
    expect(appearance.effectiveBrightness(Brightness.dark), Brightness.dark);
    expect(appearance.effectiveBrightness(Brightness.light), Brightness.light);
  });

  test('every colour switches with the palette', () {
    AppColors.use(AppPalette.dark);
    expect(AppColors.isDark, isTrue);
    expect(AppColors.card, AppPalette.dark.card);
    AppColors.use(AppPalette.light);
    expect(AppColors.card, AppPalette.light.card);
  });
}
