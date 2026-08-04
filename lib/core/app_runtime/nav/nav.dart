import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/o_t_p_verification_widget.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/signup_widget.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/splash_screen.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/pages.dart';
import 'package:m_o_b_demand_side/shared/scaffold_with_nav_bar.dart';

export 'package:go_router/go_router.dart';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();
  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();
  bool showSplashImage = false;
  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

class _CombinedStateNotifier extends ChangeNotifier {
  _CombinedStateNotifier(this.app, this.auth) {
    app.addListener(notifyListeners);
    auth.addListener(notifyListeners);
  }
  final AppStateNotifier app;
  final AuthSession auth;
  @override
  void dispose() {
    app.removeListener(notifyListeners);
    auth.removeListener(notifyListeners);
    super.dispose();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) {
  final notifier =
      _CombinedStateNotifier(appStateNotifier, AuthSession.instance);
  final authPaths = {
    '/',
    LoginpageWidget.routePath,
    OTPVerificationWidget.routePath,
    SignupWidget.routePath
  };
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    navigatorKey: appNavigatorKey,
    observers: <NavigatorObserver>[AnalyticsService.instance.observer],
    redirect: (context, state) {
      if (appStateNotifier.showSplashImage) return null;
      final isAuth = authPaths.contains(state.matchedLocation);
      if (!AuthSession.instance.isAuthenticated)
        return isAuth ? null : LoginpageWidget.routePath;
      if (AuthSession.instance.needsRegistration)
        return state.matchedLocation == SignupWidget.routePath
            ? null
            : SignupWidget.routePath;
      if (state.matchedLocation == SignupWidget.routePath) return null;
      return isAuth ? DriverDashboardPage.routePath : null;
    },
    errorBuilder: (_, __) => AuthSession.instance.isAuthenticated
        ? const DriverDashboardPage()
        : const LoginpageWidget(),
    routes: [
      GoRoute(
          name: '_initialize',
          path: '/',
          builder: (_, __) => appStateNotifier.showSplashImage
              ? const SplashScreen()
              : const LoginpageWidget()),
      GoRoute(
          name: LoginpageWidget.routeName,
          path: LoginpageWidget.routePath,
          builder: (_, __) => const LoginpageWidget()),
      GoRoute(
          name: OTPVerificationWidget.routeName,
          path: OTPVerificationWidget.routePath,
          builder: (_, state) {
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{};
            return OTPVerificationWidget(
                phoneNumber: extra['phoneNumber']?.toString() ?? '');
          }),
      GoRoute(
          name: SignupWidget.routeName,
          path: SignupWidget.routePath,
          builder: (_, state) {
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{};
            return SignupWidget(
                phoneNumber: extra['phoneNumber']?.toString() ?? '');
          }),
      // Redirect stale bookmarks and navigation calls left in legacy modules.
      GoRoute(
          path: '/homepage',
          redirect: (_, __) => DriverDashboardPage.routePath),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNavBar(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                name: DriverDashboardPage.routeName,
                path: DriverDashboardPage.routePath,
                builder: (_, __) => const DriverDashboardPage())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                name: 'DriverTrips',
                path: DriverTripsPage.routePath,
                builder: (_, __) => const DriverTripsPage())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                name: 'DriverVehicle',
                path: DriverVehiclePage.routePath,
                builder: (_, __) => const DriverVehiclePage())
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                name: 'DriverProfile',
                path: DriverProfilePage.routePath,
                builder: (_, __) => const DriverProfilePage())
          ]),
        ],
      ),
    ],
  );
}
