import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/bootstrap.dart';
import 'package:mob_driver/core/config/app_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Decoded pictures Flutter may keep in memory. Its default (100 MB) is
/// enough, with the map and the camera, to get the app killed on a 2–3 GB
/// Android phone; this app shows a few small thumbnails at a time.
const _imageCacheBytes = 40 << 20;
const _imageCacheEntries = 120;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    PaintingBinding.instance.imageCache
      ..maximumSizeBytes = _imageCacheBytes
      ..maximumSize = _imageCacheEntries;
    _drawEdgeToEdge();

    if (kIsWeb) {
      usePathUrlStrategy();
      GoRouter.optionURLReflectsImperativeAPIs = true;
      runApp(const AppBootstrap());
      return;
    }
    // Sentry traces API performance only; crashes go to Crashlytics, whose
    // handlers (set in AppBootstrap, after this) replace Sentry's.
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.environment = kDebugMode ? 'development' : 'production';
      },
      appRunner: () => runApp(const AppBootstrap()),
    );
  }, (error, stack) {
    if (!kIsWeb) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true)
          .ignore();
    }
  });
}

void _drawEdgeToEdge() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  ));
}
