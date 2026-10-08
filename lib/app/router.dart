import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/back_to_route.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/auth/auth_session.dart';
import 'package:mob_driver/core/services/analytics_service.dart';
import 'package:mob_driver/features/auth/presentation/pages/login_page.dart';
import 'package:mob_driver/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:mob_driver/features/driver/domain/entities/my_vehicle.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/pages/pages.dart';
import 'package:mob_driver/features/driver/presentation/shell/driver_events_listener.dart';
import 'package:mob_driver/features/driver/presentation/shell/driver_shell.dart';

/// The root navigator — for things outside the widget tree that need to
/// navigate (tapping a notification).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Signed-out drivers can only see the login flow; signed-in drivers never
/// see it. Re-evaluated whenever [AuthSession] changes.
GoRouter createAppRouter() => GoRouter(
      initialLocation: AppRoutes.dashboard,
      navigatorKey: appNavigatorKey,
      refreshListenable: AuthSession.instance,
      debugLogDiagnostics: kDebugMode,
      observers: [AnalyticsService.instance.observer],
      redirect: (_, state) {
        final onLoginFlow = state.matchedLocation.startsWith(AppRoutes.login);
        if (!AuthSession.instance.isAuthenticated) {
          return onLoginFlow ? null : AppRoutes.login;
        }
        return onLoginFlow ? AppRoutes.dashboard : null;
      },
      errorBuilder: (_, __) => AuthSession.instance.isAuthenticated
          ? const DashboardPage()
          : const LoginPage(),
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.otp,
          builder: (_, state) {
            final args = _mapExtra(state);
            return OtpVerificationPage(
              phoneNumber: args['phoneNumber']?.toString() ?? '',
              debugOtp: args['debugOtp']?.toString(),
            );
          },
        ),
        _shellRoute,
        ..._accountRoutes,
        ..._tripRoutes,
      ],
    );

/// The dashboard and the screens reached from the profile menu, kept alive
/// side by side. Each tab other than the dashboard goes back to the profile.
final _shellRoute = StatefulShellRoute.indexedStack(
  builder: (_, __, shell) =>
      DriverEventsListener(child: DriverShell(navigationShell: shell)),
  branches: [
    _tab(AppRoutes.dashboard, const DashboardPage()),
    _tab(AppRoutes.trips,
        const BackToRoute(route: AppRoutes.profile, child: TripsPage())),
    _tab(AppRoutes.wallet,
        const BackToRoute(route: AppRoutes.profile, child: WalletPage())),
    _tab(AppRoutes.vehicle,
        const BackToRoute(route: AppRoutes.profile, child: VehiclePage())),
    _tab(AppRoutes.profile, const ProfilePage()),
  ],
);

StatefulShellBranch _tab(String path, Widget page) => StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, __) => page)]);

final _accountRoutes = [
  GoRoute(
      path: AppRoutes.verification,
      builder: (_, __) => const VerificationPage()),
  GoRoute(
      path: AppRoutes.editProfile, builder: (_, __) => const EditProfilePage()),
  GoRoute(
      path: AppRoutes.payout, builder: (_, __) => const PayoutDetailsPage()),
  GoRoute(
      path: AppRoutes.myVehicles, builder: (_, __) => const MyVehiclesPage()),
  GoRoute(
      path: AppRoutes.newVehicle, builder: (_, __) => const VehicleFormPage()),
  GoRoute(
    path: AppRoutes.editVehiclePattern,
    builder: (_, state) => VehicleFormPage(
      vehicleId: state.pathParameters['id']!,
      initial: state.extra is MyVehicle ? state.extra as MyVehicle : null,
    ),
  ),
];

final _tripRoutes = [
  GoRoute(
    path: AppRoutes.tripPattern,
    builder: (_, state) => TripPage(tripId: _tripId(state)),
  ),
  GoRoute(
    path: AppRoutes.incomingOrderPattern,
    builder: (_, state) => IncomingOrderPage(tripId: _tripId(state)),
  ),
  GoRoute(
    path: AppRoutes.orderDetailsPattern,
    builder: (_, state) => OrderDetailsPage(
      tripId: _tripId(state),
      fromTrip: state.uri.queryParameters['from'] == 'trip',
    ),
  ),
  GoRoute(
    path: AppRoutes.photosPattern,
    builder: (_, state) => OrderPhotosPage(
      tripId: _tripId(state),
      stage: state.pathParameters['stage'] == PhotoStage.delivery.wire
          ? PhotoStage.delivery
          : PhotoStage.pickup,
    ),
  ),
  GoRoute(
    path: AppRoutes.itemsPattern,
    builder: (_, state) => ItemVerificationPage(
      tripId: _tripId(state),
      stopId: state.uri.queryParameters['stop'],
    ),
  ),
  GoRoute(
    path: AppRoutes.stopPattern,
    builder: (_, state) => StopPage(
      tripId: _tripId(state),
      stopId: state.pathParameters['stop']!,
    ),
  ),
  GoRoute(
    path: AppRoutes.paymentPattern,
    builder: (_, state) => PaymentQrPage(tripId: _tripId(state)),
  ),
  GoRoute(
    path: AppRoutes.deliveryOtpPattern,
    builder: (_, state) {
      final args = _mapExtra(state);
      return DeliveryOtpPage(
        tripId: _tripId(state),
        debugOtp: args['debugOtp']?.toString(),
        freshlySent: args['freshlySent'] == true,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.deliveredPattern,
    builder: (_, state) => DeliveryCompletePage(
      tripId: _tripId(state),
      trip: state.extra is Trip ? state.extra as Trip : null,
    ),
  ),
];

String _tripId(GoRouterState state) => state.pathParameters['id']!;

Map<String, Object?> _mapExtra(GoRouterState state) => state.extra is Map
    ? Map<String, Object?>.from(state.extra as Map)
    : const {};
