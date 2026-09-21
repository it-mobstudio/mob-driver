import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'backend/analytics/analytics_service.dart';
import 'backend/firebase/firebase_config.dart';
import 'core/app_runtime/fcm_token_sync.dart';
import 'core/app_runtime/app_update_prompt.dart';
import 'core/app_runtime/push_notification_service.dart';
import 'core/app_runtime/splash_cross_fade.dart';
import 'core/auth/auth_session.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/driver/presentation/bloc/driver_session_cubit.dart';
import 'features/driver/presentation/widgets/map_pins.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'core/app_runtime/nav/nav.dart';
import 'core/styles/app_theme.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      try {
        usePathUrlStrategy();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('URL strategy warning: $e');
        }
      }
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    if (kIsWeb) {
      runApp(const AppBootstrap());
      return;
    }
    // Sentry is scoped to API/performance monitoring only here — crash
    // reporting stays owned by Firebase Crashlytics (set up below in
    // AppBootstrap._bootstrap). That split only holds because Crashlytics's
    // FlutterError.onError/PlatformDispatcher.onError assignments happen
    // *after* this and are plain reassignments, not chained handlers, so
    // they silently replace whatever Sentry registered here. Do not move
    // Crashlytics's init to run before this one, or Sentry will start
    // double-reporting crashes too.
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.environment = kDebugMode ? 'development' : 'production';
      },
      appRunner: () => runApp(const AppBootstrap()),
    );
  }, (error, stack) async {
    if (!kIsWeb) {
      try {
        await FirebaseCrashlytics.instance
            .recordError(error, stack, fatal: true);
      } catch (e) {
        if (kDebugMode) debugPrint('Crashlytics recordError failed: $e');
      }
    }
  });
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _bootstrapFuture = _bootstrap();

  Future<void> _bootstrap() async {
    // A short, fixed floor so the splash doesn't flash by — not a delay to sit
    // through. In debug builds there's no floor at all.
    final splashFloor = Future<void>.delayed(
      kDebugMode ? Duration.zero : const Duration(milliseconds: 450),
    );

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Orientation init warning: $e');
      }
    }
    GoRouter.optionURLReflectsImperativeAPIs = true;

    // Only what the first screen genuinely needs, all at once instead of one
    // after another: Firebase (the router's analytics observer needs it), the
    // stored session (decides login vs. dashboard), DI, and the saved theme.
    await Future.wait<void>([
      initFirebase(),
      AuthSession.instance.initialize().catchError((_) {}),
      setupDependencies().catchError((_) {}),
      AppTheme.initialize().catchError((_) {}),
    ]);

    // Everything else waits until the app is on screen.
    unawaited(_startBackgroundServices());

    await splashFloor;
  }

  /// Non-essential startup work, run after the first frame is already up so it
  /// can't hold the splash: analytics/crash reporting, push, the Android map
  /// renderer, and pre-drawn map pins.
  Future<void> _startBackgroundServices() async {
    AnalyticsService.instance.enableCollection().catchError((_) {});
    if (!kIsWeb) {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.setCrashlyticsCollectionEnabled(true).catchError((_) {});
      FlutterError.onError = (details) {
        if (kDebugMode) FlutterError.dumpErrorToConsole(details);
        crashlytics.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Loading the "latest" Google Maps renderer up front makes the first map
    // (the trip screen) appear noticeably sooner on Android.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final maps = GoogleMapsFlutterPlatform.instance;
      if (maps is GoogleMapsFlutterAndroid) {
        try {
          await maps.initializeWithRenderer(AndroidMapRenderer.latest);
        } catch (_) {
          // Already initialised, or unsupported — the map still works.
        }
      }
    }
    unawaited(MapPins.warmUp());

    await PushNotificationService.instance.initialize().catchError((_) {});
    unawaited(FcmTokenSync.instance.start());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final ready = snapshot.connectionState == ConnectionState.done;
        // Cross-fade from the splash into the app rather than a hard cut.
        return SplashCrossFade(
          ready: ready,
          splash: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
            builder: _buildMobileViewport,
          ),
          app: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  bool _isAuthenticated = false;

  String getRoute([RouteMatchBase? routeMatch]) {
    final RouteMatchBase lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _isAuthenticated = AuthSession.instance.isAuthenticated;
    _router = createRouter(_appStateNotifier);
    AuthSession.instance.addListener(_handleAuthSessionChanged);
    if (AppConfig.appUpdateCheckEnabled) {
      WidgetsBinding.instance.addPostFrameCallback(_runAppUpdateCheck);
    }
  }

  // The router's Navigator isn't guaranteed to be attached to
  // appNavigatorKey on the very first frame after MyApp mounts, so a single
  // post-frame check can silently find a null context and skip the update
  // check (including the API call) forever. Retry each frame until the
  // navigator context is actually available.
  void _runAppUpdateCheck(Duration _) {
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback(_runAppUpdateCheck);
      return;
    }
    unawaited(checkAndShowAppUpdatePrompt(context));
  }

  void _handleAuthSessionChanged() {
    final nextIsAuthenticated = AuthSession.instance.isAuthenticated;
    if (nextIsAuthenticated == _isAuthenticated || !mounted) return;
    _isAuthenticated = nextIsAuthenticated;
    // A fresh login only makes the signed-in identifier known at this
    // point — re-sync so the backend gets the (user, token) pairing
    // promptly instead of waiting for the next cold start.
    if (nextIsAuthenticated) {
      unawaited(FcmTokenSync.instance.syncCurrentToken());
    }
    setState(() {
      _router.dispose();
      appNavigatorKey = GlobalKey<NavigatorState>();
      _router = createRouter(_appStateNotifier);
    });
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_handleAuthSessionChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        // Singleton (see injection.dart): value-provided so this widget never
        // closes it — its GPS/polling session outlives any one screen.
        BlocProvider<DriverSessionCubit>.value(
          value: sl<DriverSessionCubit>(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MOB Driver',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Inter',
          useMaterial3: false,
          scaffoldBackgroundColor: theme.primaryBackground,
          textTheme: TextTheme(
            bodyMedium: theme.typography.bodyMedium,
          ),
          primaryColor: theme.primary,
          bottomSheetTheme: const BottomSheetThemeData(
            modalBarrierColor: Color(0x99000000),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              // Stock CupertinoPageTransitionsBuilder — not the custom
              // builder below — because it's the one that wires up
              // Cupertino's left-edge swipe-to-pop gesture detector
              // (_CupertinoBackGestureDetector). The custom builder only
              // painted a slide animation and silently dropped that gesture
              // handling, which is why swipe-back stopped working on iOS
              // while the AppBar/system back button (Navigator.pop, unrelated
              // to page transitions) kept working fine.
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.android: _MobPageTransitionsBuilder(),
            },
          ),
        ),
        // themeMode is pinned to ThemeMode.light below, so darkTheme isn't
        // actually reachable right now — left as-is (not touched by the
        // gesture fix) since dark theme is being implemented separately.
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Inter',
          useMaterial3: false,
          scaffoldBackgroundColor: theme.primaryBackground,
          textTheme: TextTheme(
            bodyMedium: theme.typography.bodyMedium,
          ),
          primaryColor: theme.primary,
          bottomSheetTheme: const BottomSheetThemeData(
            modalBarrierColor: Color(0x99000000),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.iOS: _MobPageTransitionsBuilder(),
              TargetPlatform.android: _MobPageTransitionsBuilder(),
            },
          ),
        ),
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: _buildMobileViewport,
      ),
    );
  }
}

Widget _buildMobileViewport(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();
  // Honour the user's font-size setting, but not without limit: at the largest
  // accessibility sizes these dense driver screens would overflow, and a driver
  // glancing at a phone in a cradle needs a layout that holds together.
  child = MediaQuery.withClampedTextScaling(
    minScaleFactor: 0.9,
    maxScaleFactor: 1.2,
    child: child,
  );

  final width = MediaQuery.sizeOf(context).width;
  final shouldConstrain = kIsWeb || width > 480;
  if (!shouldConstrain) return child;

  return Container(
    color: kIsWeb ? const Color(0xFF1A1A2E) : const Color(0xFFEAF0F8),
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: ClipRect(child: child),
    ),
  );
}

class _MobPageTransitionsBuilder extends PageTransitionsBuilder {
  const _MobPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, .8, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.08, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
