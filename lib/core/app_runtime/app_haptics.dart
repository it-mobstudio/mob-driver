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

  /// A firm single tick. (`HapticFeedback.vibrate()` is a long buzz on both
  /// platforms — fine for an alarm, wrong for "trip step done".)
  static void success() {
    unawaited(HapticFeedback.mediumImpact());
  }

  static void error() {
    unawaited(HapticFeedback.heavyImpact());
  }
}
