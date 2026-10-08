import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:mob_driver/app/app.dart';
import 'package:mob_driver/app/splash_cross_fade.dart';
import 'package:mob_driver/app/splash_screen.dart';
import 'package:mob_driver/core/auth/auth_session.dart';
import 'package:mob_driver/core/di/injection.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/analytics_service.dart';
import 'package:mob_driver/core/services/firebase_initializer.dart';
import 'package:mob_driver/core/services/push_notification_service.dart';
import 'package:mob_driver/core/theme/app_appearance.dart';
import 'package:mob_driver/core/theme/app_theme.dart';
import 'package:mob_driver/features/driver/presentation/widgets/map/map_pins.dart';

/// Shows the splash while the app starts, then cross-fades into [DriverApp].
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  /// Long enough that the splash doesn't just flash by; not a wait.
  static const _minimumSplash = Duration(milliseconds: 450);

  late final Future<void> _started = _start();

  /// Only what the first screen needs, in parallel: Firebase (the router's
  /// analytics observer uses it), the saved session (login or dashboard?),
  /// the services, and the driver's language. Everything else runs after the
  /// first frame — see [_startInBackground].
  Future<void> _start() async {
    final minimumSplash =
        Future<void>.delayed(kDebugMode ? Duration.zero : _minimumSplash);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
        .catchError((_) {});
    await Future.wait<void>([
      FirebaseInitializer.initialize(),
      AuthSession.instance.initialize().catchError((_) {}),
      setupDependencies(),
      AppLanguageController.instance.load(),
      AppAppearance.instance.load(),
    ]);
    unawaited(_startInBackground());
    await minimumSplash;
  }

  Future<void> _startInBackground() async {
    unawaited(AnalyticsService.instance.enableCollection().catchError((_) {}));
    if (!kIsWeb) _reportCrashesToCrashlytics();
    await _preloadAndroidMapRenderer();
    unawaited(MapPins.warmUp());
    await PushNotificationService.instance.initialize().catchError((_) {});
  }

  /// Crashlytics owns crash reporting (Sentry, set up in main.dart, only
  /// traces API performance). These handlers replace any set before them.
  void _reportCrashesToCrashlytics() {
    final crashlytics = FirebaseCrashlytics.instance;
    unawaited(
        crashlytics.setCrashlyticsCollectionEnabled(true).catchError((_) {}));
    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.dumpErrorToConsole(details);
      crashlytics.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Loading the latest Google Maps renderer up front makes the first map
  /// appear noticeably sooner on Android.
  Future<void> _preloadAndroidMapRenderer() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final maps = GoogleMapsFlutterPlatform.instance;
    if (maps is! GoogleMapsFlutterAndroid) return;
    try {
      await maps.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {
      // Already initialised, or unsupported: the map works regardless.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _started,
        builder: (context, snapshot) => SplashCrossFade(
          ready: snapshot.connectionState == ConnectionState.done,
          splash: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
            builder: AppTheme.viewport,
          ),
          app: const DriverApp(),
        ),
      );
}
