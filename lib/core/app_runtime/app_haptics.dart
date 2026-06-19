import 'dart:async';

import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static void lightTap() {
    unawaited(HapticFeedback.lightImpact());
  }

  static void addToCart() {
    unawaited(HapticFeedback.mediumImpact());
  }

  static void tabSelection() {
    unawaited(HapticFeedback.selectionClick());
  }

  static void success() {
    unawaited(HapticFeedback.vibrate());
  }

  static void error() {
    unawaited(HapticFeedback.heavyImpact());
  }
}
