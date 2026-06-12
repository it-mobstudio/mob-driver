import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'backend/analytics/analytics_service.dart';
import 'backend/firebase/firebase_config.dart';
import 'core/auth/auth_session.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'core/app_runtime/nav/nav.dart';
import 'core/styles/app_theme.dart';
import 'environment_values.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() {
    runApp(const AppBootstrap());
  }, (error, stack) async {
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
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
    final splashDelay = Future<void>.delayed(const Duration(seconds: 3));

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
    if (kIsWeb) {
      try {
        usePathUrlStrategy();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('URL strategy warning: $e');
        }
      }
    }

    final environmentValues = FFDevEnvironmentValues();
    await environmentValues.initialize();

    await initFirebase();

    // Fire-and-forget — these don't need to block app startup
    AnalyticsService.instance.enableCollection().catchError((_) {});
    if (!kIsWeb) {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.setCrashlyticsCollectionEnabled(true).catchError((_) {});
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    }

    await Future.wait([
      AuthSession.instance.initialize().catchError((_) {}),
      setupDependencies().catchError((_) {}),
      AppTheme.initialize().catchError((_) {}),
    ]);

    await splashDelay;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            builder: kIsWeb
                ? (context, child) => Container(
                      color: const Color(0xFF1A1A2E),
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: ClipRect(child: child!),
                      ),
                    )
                : null,
          );
        }
        return const MyApp();
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
  ThemeMode _themeMode = AppTheme.themeMode;

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
  }

  void setThemeMode(ThemeMode mode) {
    if (mounted) {
      setState(() {
        _themeMode = mode;
        AppTheme.saveThemeMode(mode);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartBloc>(
          create: (_) => sl<CartBloc>()..add(CartLoadRequested()),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => sl<HomeBloc>()..add(HomeLoadRequested()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
      ],
      child: MaterialApp.router(
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
        fontFamily: 'Inter',
        useMaterial3: false,
        scaffoldBackgroundColor: theme.primaryBackground,
        textTheme: TextTheme(
          bodyMedium: theme.typography.bodyMedium,
        ),
        primaryColor: theme.primary,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        useMaterial3: false,
        scaffoldBackgroundColor: theme.primaryBackground,
        textTheme: TextTheme(
          bodyMedium: theme.typography.bodyMedium,
        ),
        primaryColor: theme.primary,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: kIsWeb
          ? (context, child) => Container(
                color: const Color(0xFF1A1A2E),
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: ClipRect(child: child!),
                ),
              )
          : null,
      ),
    );
  }
}
