import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/dashboard_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/skeleton_shimmer.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

Widget dashboardApp(TestRig rig, {bool permissionGranted = true}) => BlocProvider<DriverSessionCubit>.value(
      value: rig.cubit,
      child: MaterialApp.router(
        theme: testTheme,
        routerConfig: GoRouter(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => DriverDashboardPage(checkLocationPermission: (_) async => permissionGranted),
          ),
          GoRoute(path: DriverRoutes.tripPattern, builder: (_, s) => Scaffold(body: Text('TRIP ${s.pathParameters['id']}'))),
        ]),
      ),
    );

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  // Real Inter metrics, loaded outside fake-async time (it does real I/O).
  setUpAll(loadAppFonts);

  group('loading', () {
    rigTest('a cold load shows the dashboard\'s skeleton, then cross-fades to the real thing', (tester, rig) async {
      rig.repo.profileGate = Completer<void>(); // network still out
      final loading = rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await tester.pump();

      expect(find.byType(SkeletonBlock), findsWidgets, reason: 'structure on screen from the first frame');
      expect(find.byKey(const Key('driver_name')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'no bare spinner');

      rig.repo.profileGate!.complete();
      await loading;
      await tester.pumpAndSettle();

      expect(find.byType(SkeletonBlock), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('driver_name'))).data, 'Seed Driver 1');
    });

    rigTest('a relaunch paints the cached dashboard at once; only the trip card waits for the server', (tester, rig) async {
      rig.repo.cachedProfile = fakeProfile();
      rig.repo.profileGate = Completer<void>();
      final loading = rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await tester.pump();
      await tester.pump();

      // Already showing the driver — no waiting for the network...
      expect(tester.widget<Text>(find.byKey(const Key('driver_name'))).data, 'Seed Driver 1');
      // ...but "no active trip" isn't asserted until it's actually known.
      expect(find.byKey(const Key('no_trip_title')), findsNothing);
      expect(find.byType(SkeletonBlock), findsOneWidget);

      rig.repo.profileGate!.complete();
      await loading;
      await tester.pumpAndSettle();

      expect(find.byType(SkeletonBlock), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('no_trip_title'))).data, 'No active trip');
    });

    rigTest('a trip assigned meanwhile replaces the trip placeholder with the trip', (tester, rig) async {
      rig.repo.cachedProfile = fakeProfile(online: true);
      rig.repo.profileValue = fakeProfile(online: true);
      rig.repo.activeTripValue = fakeTrip();
      rig.repo.profileGate = Completer<void>();
      final loading = rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await tester.pump();
      await tester.pump();
      expect(find.text('ACTIVE TRIP'), findsNothing);

      rig.repo.profileGate!.complete();
      await loading;
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE TRIP'), findsOneWidget);
    });

    rigTest('with reduced motion on, nothing animates in (accessibility)', (tester, rig) async {
      await rig.cubit.load();
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: dashboardApp(rig),
      ));
      await tester.pump();

      // Content is fully opaque on the very first frame: no fade to wait for.
      final fades = tester.widgetList<Opacity>(find.descendant(of: find.byType(DriverDashboardPage), matching: find.byType(Opacity)));
      expect(fades.where((o) => o.opacity < 1), isEmpty);
    });
  });

  group('offline', () {
    rigTest('greets the driver, shows the vehicle, and offers to start duty', (tester, rig) async {
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      expect(tester.widget<Text>(find.byKey(const Key('driver_name'))).data, 'Seed Driver 1');
      expect(find.text('VERIFIED DRIVER'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('duty_status'))).data, 'You are offline');
      expect(tester.widget<Text>(find.byKey(const Key('header_vehicle'))).data, 'No vehicle');
      expect(find.text('Start duty'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('no_trip_title'))).data, 'No active trip');
    });

    rigTest('shows today\'s stats, led by what the driver earned', (tester, rig) async {
      rig.repo.statsValue = const DriverStats(
        today: PeriodStats(
            tripsCompleted: 4, totalFare: 1250.5, earnings: 1000.4, codCollected: 300, distanceMeters: 21400, tripsCancelled: 1),
        allTime: PeriodStats(tripsCompleted: 37),
      );
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      expect(tester.widget<Text>(find.byKey(const Key('stat_earnings'))).data, '₹1,000.40');
      expect(tester.widget<Text>(find.byKey(const Key('stat_trips'))).data, '4');
      expect(tester.widget<Text>(find.byKey(const Key('stat_distance'))).data, '21.4 km');
      // What the customers were charged is still there — but as detail, not the headline.
      expect(find.descendant(of: find.byKey(const Key('stat_fare')), matching: find.text('₹1,250.50')), findsOneWidget);
      expect(find.text('37'), findsOneWidget);
    });

    rigTest('a load failure offers a retry that recovers', (tester, rig) async {
      rig.repo.profileFailure = const NetworkFailure();
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);
      expect(find.text('Couldn’t load your dashboard'), findsOneWidget);

      rig.repo.profileFailure = null;
      await tester.tap(find.text('Retry'));
      await settle(tester);
      expect(find.byKey(const Key('driver_name')), findsOneWidget);
    });
  });

  group('going on duty', () {
    rigTest('explain → permission → pick vehicle → online, with the first GPS fix', (tester, rig) async {
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      expect(find.text('Start duty and live tracking?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // One vehicle available: pre-selected, just confirm.
      expect(find.text('Choose your vehicle'), findsOneWidget);
      expect(find.text('KA01SEED0000'), findsOneWidget);
      await tester.tap(find.text('Go online'));
      await tester.pumpAndSettle();

      expect(rig.repo.calls, contains('startDuty:v-1:12.9716,77.5946'));
      expect(tester.widget<Text>(find.byKey(const Key('duty_status'))).data, 'You are online');
      expect(tester.widget<Text>(find.byKey(const Key('header_vehicle'))).data, 'KA01SEED0000');
      expect(tester.widget<Text>(find.byKey(const Key('no_trip_title'))).data, 'Waiting for a trip');
    });

    rigTest('declining the explanation changes nothing', (tester, rig) async {
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(rig.repo.calls.where((c) => c.startsWith('startDuty')), isEmpty);
      expect(find.text('Start duty'), findsOneWidget);
    });

    rigTest('a denied location permission stops before the vehicle picker', (tester, rig) async {
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig, permissionGranted: false));
      await settle(tester);

      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Choose your vehicle'), findsNothing);
      expect(rig.repo.calls.where((c) => c.startsWith('startDuty')), isEmpty);
    });

    rigTest('several vehicles: nothing is chosen for the driver until they pick', (tester, rig) async {
      rig.repo.vehiclesValue = const [
        DriverVehicle(id: 'v-1', registrationNumber: 'KA01AA0001', vehicleTypeName: 'Bike', category: 'two_wheeler'),
        DriverVehicle(id: 'v-2', registrationNumber: 'KA01AA0002', vehicleTypeName: 'Bike', category: 'two_wheeler'),
      ];
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);
      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final confirm = find.widgetWithText(ElevatedButton, 'Go online');
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      await tester.tap(find.text('KA01AA0002'));
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(rig.repo.calls, contains('startDuty:v-2:12.9716,77.5946'));
    });

    rigTest('no available vehicle is explained, with no way to proceed', (tester, rig) async {
      rig.repo.vehiclesValue = const [];
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);
      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('No vehicle available'), findsOneWidget);
      expect(find.text('Go online'), findsNothing);
    });

    rigTest('a backend rejection (vehicle taken meanwhile) is shown and leaves the driver offline', (tester, rig) async {
      rig.repo.startDutyFailure =
          const BusinessFailure('This vehicle is being used by another driver.', code: 'VEHICLE_IN_USE');
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);
      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go online'));
      await tester.pumpAndSettle();

      expect(find.text('This vehicle is being used by another driver.'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('duty_status'))).data, 'You are offline');
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a driver with a rejected document is told what to fix, and cannot start', (tester, rig) async {
      rig.repo.profileValue = DriverProfile.fromJson({
        ...profileJson(eligible: false, onboarding: 'action_required'),
        'police_status': 'rejected',
        'police_rejection_note': 'Certificate expired',
      });
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      expect(find.text('ACTION NEEDED'), findsOneWidget);
      expect(find.byKey(const Key('verification_card')), findsOneWidget);
      expect(find.text('Some documents need fixing'), findsOneWidget);
      expect(find.textContaining('Certificate expired'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('verification_action'))).data, 'Fix documents');

      await tester.tap(find.text('Start duty'));
      await tester.pumpAndSettle();
      expect(find.text('You can’t go on duty yet'), findsOneWidget);
      expect(find.text('Start duty and live tracking?'), findsNothing);
    });
  });

  group('online', () {
    rigTest('going offline calls the backend and stops tracking', (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);
      expect(tester.widget<Text>(find.byKey(const Key('duty_status'))).data, 'You are online');

      await tester.tap(find.byKey(const Key('duty_switch')));
      await settle(tester);

      expect(rig.repo.calls, contains('endDuty'));
      expect(tester.widget<Text>(find.byKey(const Key('duty_status'))).data, 'You are offline');
    });

    rigTest('an active trip is shown and opens its screen', (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      rig.repo.activeTripValue = fakeTrip();
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      expect(find.text('ACTIVE TRIP'), findsOneWidget);
      expect(find.text('MG Road Metro, Bengaluru'), findsOneWidget);
      expect(find.text('Indiranagar 100ft Rd, Bengaluru'), findsOneWidget);
      expect(find.text('₹111.62'), findsOneWidget);
      expect(find.text('COD'), findsOneWidget);

      await tester.tap(find.text('Open trip'));
      await tester.pumpAndSettle();
      expect(find.text('TRIP 604807b6-7053-4f5f-bf99-163eb9620dc3'), findsOneWidget);
    });

    rigTest('the switch refuses to go offline mid-trip, without asking the backend', (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      rig.repo.activeTripValue = fakeTrip();
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);

      await tester.tap(find.byKey(const Key('duty_switch')));
      await settle(tester);

      expect(find.text('Finish or cancel your active trip before going offline.'), findsOneWidget);
      expect(rig.repo.calls, isNot(contains('endDuty')));
      expect(tester.widget<Text>(find.byKey(const Key('duty_status'))).data, 'You are online');
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a GPS failure while on duty is called out', (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      await rig.cubit.load();
      await tester.pumpWidget(dashboardApp(rig));
      await settle(tester);
      expect(find.byKey(const Key('location_banner')), findsNothing);

      rig.location.stream.addError(Exception('GPS off'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('location_banner')), findsOneWidget);
    });

    rigTest('the banner\'s Fix button asks for the permission (not just opens settings)', (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      await rig.cubit.load();
      var asked = 0;
      await tester.pumpWidget(BlocProvider<DriverSessionCubit>.value(
        value: rig.cubit,
        child: MaterialApp.router(
          theme: testTheme,
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => DriverDashboardPage(checkLocationPermission: (_) async {
                asked++;
                return true;
              }),
            ),
          ]),
        ),
      ));
      await settle(tester);
      rig.location.stream.addError(Exception('permission denied'));
      await tester.pumpAndSettle(); // the banner eases open over ~0.25 s

      await tester.tap(find.text('Fix'));
      await tester.pump();

      expect(asked, 1);
    });
  });
}
