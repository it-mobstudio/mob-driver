import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/delivery_otp_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/edit_profile_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/item_verification_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/payment_qr_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/payout_details_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/trip_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/verification_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/wallet_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_map.dart';

import 'fakes.dart';
import 'fonts.dart';

/// Stand-in for the Google map (a platform view, which can't render under
/// `flutter test`) that exposes what the real map would have been handed.
Widget stubMap(BuildContext context, TripMapData data, double bottomPadding) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        'route=${data.route.length} leg=${data.leg.length} '
        'driver=${data.driver != null} status=${data.status.wire}',
        key: const Key('map'),
      ),
      if (data.route.isNotEmpty)
        Text('routeFirst=${data.route.first.latitude.toStringAsFixed(4)},'
            '${data.route.first.longitude.toStringAsFixed(4)}',
            key: const Key('map_first')),
      if (data.route.isNotEmpty)
        Text('routeLast=${data.route.last.latitude.toStringAsFixed(4)},'
            '${data.route.last.longitude.toStringAsFixed(4)}',
            key: const Key('map_last')),
    ]);

class TestRig {
  TestRig()
      : repo = FakeDriverRepository(),
        location = FakeLocationService() {
    cubit = DriverSessionCubit(
      repository: repo,
      location: location,
      // Effectively never: widget tests drive the cubit by hand.
      pingInterval: const Duration(hours: 1),
      pollInterval: const Duration(hours: 1),
    );
  }

  final FakeDriverRepository repo;
  final FakeLocationService location;
  late final DriverSessionCubit cubit;

  /// The camera and invoice buttons the pages are given.
  final FakePhotoCapture capture = FakePhotoCapture();
  final FakeInvoiceActions invoice = FakeInvoiceActions();

  /// Sign-out is observable here (`authRepo.signOutCalls`).
  final FakeAuthRepository authRepo = FakeAuthRepository();

  AuthBloc? _auth;
  AuthBloc get auth => _auth ??= AuthBloc(authRepo);

  Future<void> dispose() async {
    await cubit.close();
    // Only if a page asked for it — building a bloc just to close it, inside a
    // test's fake-async zone, is what stalls teardown.
    final auth = _auth;
    if (auth != null) unawaited(auth.close());
    await location.stream.close();
  }

  /// One page on its own (plus any [routes] it navigates to, and the app's
  /// blocs) — for screens that aren't part of the trip flow.
  Widget host(Widget home, {List<GoRoute> routes = const []}) => MultiBlocProvider(
        providers: [
          BlocProvider<DriverSessionCubit>.value(value: cubit),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp.router(
          theme: testTheme,
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => home),
            ...routes,
          ]),
        ),
      );

  /// The trip screens wired into a real GoRouter, plus a dashboard stub so
  /// "back to home" is observable.
  Widget app(String initialLocation) => MultiBlocProvider(
        providers: [
          BlocProvider<DriverSessionCubit>.value(value: cubit),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp.router(
          theme: testTheme,
          routerConfig: GoRouter(
            initialLocation: initialLocation,
            routes: [
              GoRoute(
                path: DriverRoutes.dashboard,
                builder: (_, __) => const Scaffold(body: Center(child: Text('DASHBOARD'))),
              ),
              GoRoute(
                path: DriverRoutes.tripPattern,
                builder: (_, s) => TripPage(
                    tripId: s.pathParameters['id']!,
                    mapBuilder: stubMap,
                    invoiceActions: invoice),
              ),
              GoRoute(
                path: DriverRoutes.itemsPattern,
                builder: (_, s) =>
                    ItemVerificationPage(tripId: s.pathParameters['id']!, capture: capture),
              ),
              GoRoute(
                path: DriverRoutes.verification,
                builder: (_, __) => DriverVerificationPage(capture: capture),
              ),
              GoRoute(path: DriverRoutes.editProfile, builder: (_, __) => const EditProfilePage()),
              GoRoute(path: DriverRoutes.payout, builder: (_, __) => const PayoutDetailsPage()),
              GoRoute(path: DriverRoutes.wallet, builder: (_, __) => const DriverWalletPage()),
              GoRoute(
                path: DriverRoutes.paymentPattern,
                builder: (_, s) => PaymentQrPage(tripId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: DriverRoutes.otpPattern,
                builder: (_, s) {
                  final extra = s.extra is Map ? Map<String, dynamic>.from(s.extra as Map) : <String, dynamic>{};
                  return DeliveryOtpPage(
                    tripId: s.pathParameters['id']!,
                    debugOtp: extra['debugOtp']?.toString(),
                    freshlySent: extra['freshlySent'] == true,
                  );
                },
              ),
            ],
          ),
        ),
      );
}

/// `testWidgets` that owns a [TestRig] and shuts it down *before* the test
/// body returns. Flutter fails a test that ends with a timer still pending,
/// and the session cubit's ping/poll timers are cancelled by `close()` — which
/// `addTearDown` would run too late (after that check).
void rigTest(
  String description,
  Future<void> Function(WidgetTester tester, TestRig rig) body,
) {
  testWidgets(description, (tester) async {
    // A typical phone (360 x 780 dp), not flutter_test's 800 x 600 default —
    // layout problems on a real handset should show up here too.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final rig = TestRig();
    try {
      await body(tester, rig);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await rig.dispose();
    }
  });
}

