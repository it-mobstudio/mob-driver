import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/router.dart';
import 'package:mob_driver/core/auth/auth_session.dart';
import 'package:mob_driver/core/di/injection.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_appearance.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/theme/app_theme.dart';
import 'package:mob_driver/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';

/// The app once it has started: theme, language, app-wide blocs and the
/// router.
class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> with WidgetsBindingObserver {
  late GoRouter _router = createAppRouter();
  late bool _signedIn = AuthSession.instance.isAuthenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthSession.instance.addListener(_onSessionChanged);
    AppLanguageController.instance.addListener(_repaintEverything);
    AppAppearance.instance.addListener(_onAppearanceChanged);
    _applyPalette();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthSession.instance.removeListener(_onSessionChanged);
    AppLanguageController.instance.removeListener(_repaintEverything);
    AppAppearance.instance.removeListener(_onAppearanceChanged);
    _router.dispose();
    super.dispose();
  }

  /// Signing in or out starts navigation from scratch, so nothing from the
  /// previous session's screens survives.
  void _onSessionChanged() {
    final signedIn = AuthSession.instance.isAuthenticated;
    if (signedIn == _signedIn || !mounted) return;
    _signedIn = signedIn;
    if (!signedIn) unawaited(AppAppearance.instance.reset());
    _applyPalette();
    setState(() {
      _router.dispose();
      _router = createAppRouter();
    });
  }

  /// The phone switched between light and dark (matters on "System").
  @override
  void didChangePlatformBrightness() => _onAppearanceChanged();

  void _onAppearanceChanged() {
    _applyPalette();
    _repaintEverything();
  }

  void _applyPalette() {
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // Signed out, the login screens are always light.
    final brightness = _signedIn
        ? AppAppearance.instance.effectiveBrightness(platform)
        : Brightness.light;
    AppColors.use(
        brightness == Brightness.dark ? AppPalette.dark : AppPalette.light);
  }

  /// Text (`tr()`) and colours (`AppColors`) aren't read through anything a
  /// widget "depends on", so a new language or appearance repaints every
  /// screen at once — including ones under the current page — without
  /// losing where the driver is.
  void _repaintEverything() {
    if (!mounted) return;
    setState(() {});
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
          // A singleton, provided by value so it's never closed here: the
          // duty session outlives any one screen.
          BlocProvider<DriverSessionCubit>.value(
              value: sl<DriverSessionCubit>()),
        ],
        child: MaterialApp.router(
          title: 'MOB Go',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.of(AppColors.palette),
          locale: AppLanguageController.instance.value.locale,
          supportedLocales: [for (final l in AppLanguage.values) l.locale],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
          builder: AppTheme.viewport,
        ),
      );
}
