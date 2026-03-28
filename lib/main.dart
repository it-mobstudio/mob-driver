import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'backend/analytics/analytics_service.dart';
import 'backend/firebase/firebase_config.dart';
import 'core/auth/auth_session.dart';
import '/core/app_runtime/flutter_flow_theme.dart';
import 'core/app_runtime/flutter_flow_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();

    final environmentValues = FFDevEnvironmentValues();
    await environmentValues.initialize();

    await initFirebase();
    await AnalyticsService.instance.enableCollection();

    if (!kIsWeb) {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }

    await AuthSession.instance.initialize();
    await FlutterFlowTheme.initialize();
    runApp(const MyApp());
  }, (error, stack) async {
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
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
    _router = createRouter(_appStateNotifier);

    // Show splash for 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) {
        return;
      }
      safeSetState(() => _appStateNotifier.stopShowingSplashImage());
    });
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MOB Demand Side',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
        scaffoldBackgroundColor: theme.primaryBackground,
        textTheme: TextTheme(
          bodyMedium: theme.typography.bodyMedium,
          // ...add other text styles as needed
        ),
        primaryColor: theme.primary,
        // ...add other color properties as needed
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        scaffoldBackgroundColor: theme.primaryBackground,
        textTheme: TextTheme(
          bodyMedium: theme.typography.bodyMedium,
          // ...add other text styles as needed
        ),
        primaryColor: theme.primary,
        // ...add other color properties as needed
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
