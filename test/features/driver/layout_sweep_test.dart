import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

const tripId = '604807b6-7053-4f5f-bf99-163eb9620dc3';

/// A trip with everything that makes the screens long: items, both bonuses,
/// long addresses and names.
Trip richTrip({String status = 'assigned'}) => Trip.fromJson({
      ...tripJson(
        status: status,
        bonusFare: '100.00',
        items: [
          itemJson(),
          itemJson(id: 'i-2', name: 'Supreme PVC SWR Pipe, Type B, 6 m length'),
        ],
      ),
      'extra_bonus_fare': '100.00',
      'pickup_address':
          'Shop No. 28, Nawabganj Ring Road, Nawabganj, Barabanki 225001',
      'pickup_contact_name': 'Gupta Building Materials & Hardware Traders',
    });

Future<void> open(
    WidgetTester tester, TestRig rig, Trip trip, String path) async {
  rig.repo.profileValue = fakeProfile(online: true);
  rig.repo.activeTripValue = trip;
  rig.repo.tripsById[trip.id] = trip;
  await rig.cubit.load();
  await tester.pumpWidget(rig.app(path));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  // 1.0 = the phone's own size; 1.4 is the most the app ever draws (the
  // largest setting the viewport allows, 1.3, times the driver boost).
  for (final scale in [1.0, 1.4]) {
    group('no overflow at text scale $scale', () {
      void scaled(WidgetTester tester) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }

      rigTest('the trip screen, before pickup', (tester, rig) async {
        scaled(tester);
        await open(tester, rig, richTrip(), '/driver/trip/$tripId');
        expect(tester.takeException(), isNull);
      });

      rigTest('the trip screen, on the way to the drop', (tester, rig) async {
        scaled(tester);
        await open(tester, rig, richTrip(status: 'in_progress'),
            '/driver/trip/$tripId');
        expect(tester.takeException(), isNull);
      });

      rigTest('the hamburger panel', (tester, rig) async {
        scaled(tester);
        await open(tester, rig, richTrip(), '/driver/trip/$tripId');
        await tester.tap(find.byKey(const Key('trip_menu')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      rigTest('the new-order offer', (tester, rig) async {
        scaled(tester);
        await open(tester, rig, richTrip(), AppRoutes.incomingOrder(tripId));
        expect(tester.takeException(), isNull);
      });

      rigTest('the order details', (tester, rig) async {
        scaled(tester);
        await open(tester, rig, richTrip(),
            AppRoutes.orderDetails(tripId, fromTrip: true));
        expect(tester.takeException(), isNull);
      });
    });
  }

  // Hindi and Kannada run longer than English — the same screens must still fit.
  for (final language in [AppLanguage.hindi, AppLanguage.kannada]) {
    group('no overflow in ${language.englishName}', () {
      void speak(WidgetTester tester) {
        AppLanguageController.instance.value = language;
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(() {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          AppLanguageController.instance.value = AppLanguage.english;
        });
      }

      rigTest('the trip screen and its hamburger panel', (tester, rig) async {
        speak(tester);
        await open(tester, rig, richTrip(), '/driver/trip/$tripId');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('trip_menu')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      rigTest('the new-order offer', (tester, rig) async {
        speak(tester);
        await open(tester, rig, richTrip(), AppRoutes.incomingOrder(tripId));
        expect(tester.takeException(), isNull);
      });
    });
  }
}
