import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

const tripId = '604807b6-7053-4f5f-bf99-163eb9620dc3';

Future<void> openDetails(WidgetTester tester, TestRig rig, Trip trip) async {
  rig.repo.profileValue = fakeProfile(online: true);
  rig.repo.activeTripValue = trip;
  rig.repo.tripsById[trip.id] = trip;
  await rig.cubit.load();
  await tester.pumpWidget(rig.app('/driver/trip/${trip.id}/details'));
  await tester.pumpAndSettle();
}

Future<void> openTracked(
    WidgetTester tester, TestRig rig, Map<String, dynamic> json) async {
  rig.repo.tripJsonById[json['id'] as String] = json;
  await openDetails(tester, rig, Trip.fromJson(json));
}

Trip withItems({String? bonusFare}) =>
    Trip.fromJson(withItemsJson(bonusFare: bonusFare));

Map<String, dynamic> withItemsJson({
  String? bonusFare,
  String pickupPhoto = 'none',
  String status = 'assigned',
}) =>
    tripJson(
      bonusFare: bonusFare,
      pickupPhoto: pickupPhoto,
      status: status,
      items: [
        {
          'id': 'i-1',
          'name': 'Cement bag 50kg',
          'quantity': 4,
          'unit': 'bags',
          'notes': 'Fragile',
          'status': 'pending',
        },
        {'id': 'i-2', 'name': 'TMT bar 12mm', 'quantity': 20, 'status': 'pending'},
      ],
    );

void main() {
  setUpAll(loadAppFonts);

  rigTest('shows the reference, both stops, the items and the total', (tester, rig) async {
    await openDetails(tester, rig, withItems());

    expect(find.textContaining('MG Road Metro, Bengaluru'), findsOneWidget);
    expect(find.textContaining('Indiranagar 100ft Rd, Bengaluru'), findsOneWidget);
    expect(find.text('2 items in shipment'), findsOneWidget);
    expect(find.text('Cement bag 50kg'), findsOneWidget);
    expect(find.text('x 4'), findsOneWidget);
    expect(find.text('TMT bar 12mm'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('order_details_total'))).data, '₹111.62');
    expect(find.byKey(const Key('heavy_unloading_banner')), findsNothing);
  });

  rigTest('a bonus shows the second fare chip and the heavy-unloading banner', (tester, rig) async {
    await openDetails(tester, rig, withItems(bonusFare: '100.00'));

    expect(tester.widget<Text>(find.byKey(const Key('order_details_total'))).data, '₹211.62');
    expect(find.byKey(const Key('fare_bonus')), findsOneWidget);
    expect(find.byKey(const Key('heavy_unloading_banner')), findsOneWidget);
    expect(find.text('Heavy unloading'), findsOneWidget);
  });

  rigTest('the item list collapses and expands', (tester, rig) async {
    await openDetails(tester, rig, withItems());
    expect(find.text('Cement bag 50kg'), findsOneWidget);

    await tester.tap(find.byKey(const Key('order_details_items_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Cement bag 50kg'), findsNothing);

    await tester.tap(find.byKey(const Key('order_details_items_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Cement bag 50kg'), findsOneWidget);
  });

  rigTest('an order that asks for no photos shows no photo box and proceeds', (tester, rig) async {
    await openDetails(tester, rig, withItems());

    expect(find.byKey(const Key('pickup_photo_box')), findsNothing);
    expect(find.text('Upload photo'), findsNothing);

    await swipe(tester, 'Pickup order');
    expect(find.text('Reached pickup'), findsOneWidget);
  });

  rigTest('one order photo: refused until taken, then geo-stamped and uploaded', (tester, rig) async {
    await openTracked(tester, rig, withItemsJson(pickupPhoto: 'order'));
    expect(find.text('Upload photo'), findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(find.text('Add a photo of the package first.'), findsOneWidget);
    expect(rig.capture.cameraCalls, 0);

    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();
    expect(rig.capture.cameraCalls, 1);
    expect(rig.capture.galleryCalls, 0); // camera only
    expect(rig.repo.pickupPhotos, ['order']);
    final stamp = rig.capture.stamps.single;
    expect((stamp.latitude, stamp.longitude), (12.9716, 77.5946));
    expect(stamp.caption, '#E2E-1 · Pickup');
    expect(find.text('Tap to change'), findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(find.text('Reached pickup'), findsOneWidget);
  });

  rigTest('one photo per item: a slot under every item, all needed to proceed', (tester, rig) async {
    await openTracked(tester, rig, withItemsJson(pickupPhoto: 'per_item'));

    expect(find.byKey(const Key('pickup_photo_box')), findsNothing);
    expect(find.text('Take a photo of each item below · 0 of 2 done'), findsOneWidget);
    expect(find.byKey(const Key('pickup_item_photo_i-1')), findsOneWidget);
    expect(find.byKey(const Key('pickup_item_photo_i-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pickup_item_photo_i-1')));
    await tester.pumpAndSettle();
    expect(rig.repo.pickupPhotos, ['i-1']);
    expect(rig.capture.stamps.single.caption, '#E2E-1 · Pickup · Cement bag 50kg');
    expect(find.text('Take a photo of each item below · 1 of 2 done'), findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(find.text('Take a photo of every item first (1 left).'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('pickup_item_photo_i-2')));
    await tester.tap(find.byKey(const Key('pickup_item_photo_i-2')));
    await tester.pumpAndSettle();
    expect(find.text('All 2 item photos taken'), findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(find.text('Reached pickup'), findsOneWidget);
  });

  rigTest('without a location fix the photo is not kept', (tester, rig) async {
    rig.location.fix = null;
    await openTracked(tester, rig, withItemsJson(pickupPhoto: 'order'));

    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Turn on location'), findsOneWidget);
    expect(rig.repo.pickupPhotos, isEmpty);
    expect(find.text('Tap to change'), findsNothing);
  });

  rigTest('a failed upload drops the photo and says why', (tester, rig) async {
    rig.repo.pickupPhotoFailure = const BusinessFailure('Upload failed.');
    await openTracked(tester, rig, withItemsJson(pickupPhoto: 'order'));

    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();

    expect(find.text('Upload failed.'), findsOneWidget);
    expect(find.text('Tap to change'), findsNothing);
  });

  rigTest('the company\'s note shows when there is one, and not otherwise', (tester, rig) async {
    final json = withItemsJson();
    json['notes'] = 'Call before arriving. Use the side gate.';
    (json['items'] as List)[1]
      ..['status'] = 'not_delivered'
      ..['driver_note'] = 'Damaged in transit';
    await openTracked(tester, rig, json);

    expect(find.text('Call before arriving. Use the side gate.'), findsOneWidget);
    expect(find.text('Not delivered · Damaged in transit'), findsOneWidget);
  });

  rigTest('the header shows our OD order number', (tester, rig) async {
    final json = withItemsJson()..['order_number'] = 'OD2026092500018';
    await openTracked(tester, rig, json);
    expect(find.text('#OD2026092500018'), findsOneWidget);
  });

  rigTest('no note, no note card', (tester, rig) async {
    await openDetails(tester, rig, withItems());
    expect(find.byKey(const Key('order_note')), findsNothing);
  });

  rigTest('a problem at pickup cancels the trip and returns to the dashboard', (tester, rig) async {
    rig.repo.actionResult = (Trip.fromJson(tripJson(status: 'cancelled')), null);
    await openDetails(tester, rig, withItems());

    await tester.tap(find.byKey(const Key('order_details_problem')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('problem_reason_Pickup not ready')));
    await tester.pump();
    await tester.tap(find.text('Report problem'));
    await tester.pumpAndSettle();

    expect(rig.repo.calls, contains('cancel[Pickup not ready]:$tripId'));
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  rigTest('Help explains where to go for support', (tester, rig) async {
    await openDetails(tester, rig, withItems());

    await tester.tap(find.byKey(const Key('order_details_help')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Contact your operations team'), findsOneWidget);
  });
}
