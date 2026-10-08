import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/core/errors/app_failure.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';

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

/// The details as the driver sees them at the pickup (from the trip
/// screen), where "Pickup order" checks the photos the order asks for.
Future<void> openAtPickup(
    WidgetTester tester, TestRig rig, Map<String, dynamic> json) async {
  final trip = Trip.fromJson(json);
  rig.repo.tripJsonById[trip.id] = json;
  rig.repo.profileValue = fakeProfile(online: true);
  rig.repo.activeTripValue = trip;
  rig.repo.tripsById[trip.id] = trip;
  rig.repo.actionResult =
      (Trip.fromJson({...json, 'status': 'in_progress'}), null);
  await rig.cubit.load();
  await tester.pumpWidget(rig.app('/driver/trip/${trip.id}/details?from=trip'));
  await tester.pumpAndSettle();
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
        {
          'id': 'i-2',
          'name': 'TMT bar 12mm',
          'quantity': 20,
          'status': 'pending'
        },
      ],
    );

void main() {
  setUpAll(loadAppFonts);

  rigTest('shows the reference, both stops, the items and the total',
      (tester, rig) async {
    await openDetails(tester, rig, withItems());

    expect(find.textContaining('MG Road Metro, Bengaluru'), findsOneWidget);
    expect(
        find.textContaining('Indiranagar 100ft Rd, Bengaluru'), findsOneWidget);
    expect(find.text('2 items in shipment'), findsOneWidget);
    expect(find.text('Cement bag 50kg'), findsOneWidget);
    expect(find.text('x 4'), findsOneWidget);
    expect(find.text('TMT bar 12mm'), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('order_details_total'))).data,
        '₹111.62');
    expect(find.byKey(const Key('heavy_unloading_banner')), findsNothing);
  });

  rigTest('a bonus shows the second fare chip and the heavy-unloading banner',
      (tester, rig) async {
    await openDetails(tester, rig, withItems(bonusFare: '100.00'));

    expect(
        tester.widget<Text>(find.byKey(const Key('order_details_total'))).data,
        '₹211.62');
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

  rigTest('an order that asks for no photos shows no photo box',
      (tester, rig) async {
    await openDetails(tester, rig, withItems());

    expect(find.byKey(const Key('pickup_photo_box')), findsNothing);
    expect(find.text('Upload photos'), findsNothing);
  });

  rigTest('opened from an offer, it accepts the same way the offer does',
      (tester, rig) async {
    final trip = withItems();
    rig.repo.profileValue = fakeProfile(online: true);
    rig.repo.activeTripValue = trip;
    rig.repo.tripsById[trip.id] = trip;
    await rig.cubit.load();
    await tester.pumpWidget(rig.app('/driver/trip/${trip.id}/offer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View order details'));
    await tester.pumpAndSettle();
    expect(find.text('Order details'), findsOneWidget);

    await swipe(tester, 'Accept order');
    // Back through the offer, onto the trip.
    expect(find.text('Reached pickup'), findsOneWidget);
  });

  rigTest('one order photo: refused until taken, then geo-stamped and uploaded',
      (tester, rig) async {
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'order', status: 'arrived_at_pickup'));
    expect(find.text('Upload photos'), findsOneWidget);

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
    // Compressed once, after the stamp — what goes up is the small WebP.
    expect(rig.capture.optimized, hasLength(1));
    expect(find.text('1 photo added'), findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(rig.repo.calls, contains('start:$tripId'));
  });

  rigTest('several order photos can be taken, and a wrong one removed',
      (tester, rig) async {
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'order', status: 'arrived_at_pickup'));

    // Each tap adds a photo — the first to the empty box, the rest to the "Add photo" tile.
    for (var taken = 1; taken <= 3; taken++) {
      await tester.tap(find.byKey(const Key('pickup_photo_box')));
      await tester.pumpAndSettle();
      expect(rig.capture.cameraCalls, taken);
    }
    expect(rig.repo.pickupPhotos, ['order', 'order', 'order']);
    expect(find.text('3 photos added'), findsOneWidget);
    expect(rig.cubit.state.activeTrip!.pickupPhotos.map((p) => p.id),
        ['ph-1', 'ph-2', 'ph-3']);

    // The bin on a photo asks first, then takes just that one back.
    await tester.tap(find.byKey(const Key('photo_remove_ph-2')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this photo?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(rig.repo.calls, isNot(contains('removePhoto:ph-2')));

    await tester.tap(find.byKey(const Key('photo_remove_ph-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo_remove_confirm')));
    await tester.pumpAndSettle();
    expect(rig.repo.calls, contains('removePhoto:ph-2'));
    expect(find.text('2 photos added'), findsOneWidget);
    expect(find.byKey(const Key('photo_remove_ph-2')), findsNothing);
    expect(rig.cubit.state.activeTrip!.pickupPhotos.map((p) => p.id),
        ['ph-1', 'ph-3']);
  });

  rigTest(
      'removing the last photo brings the empty box back, and the photo is owed again',
      (tester, rig) async {
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'order', status: 'arrived_at_pickup'));
    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('photo_remove_ph-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo_remove_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Tap to add photo of the package'), findsOneWidget);
    await swipe(tester, 'Pickup order');
    expect(find.text('Add a photo of the package first.'), findsOneWidget);
  });

  rigTest('a photo that could not be removed stays, and says why',
      (tester, rig) async {
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'order', status: 'arrived_at_pickup'));
    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();
    rig.repo.removePhotoFailure =
        const BusinessFailure('This photo can’t be removed any more.');

    await tester.tap(find.byKey(const Key('photo_remove_ph-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo_remove_confirm')));
    await tester.pumpAndSettle();

    expect(find.text('This photo can’t be removed any more.'), findsOneWidget);
    expect(find.text('1 photo added'), findsOneWidget);
  });

  rigTest(
      'photos can no longer be added or removed once the delivery has started',
      (tester, rig) async {
    final json = withItemsJson(pickupPhoto: 'order', status: 'in_progress')
      ..['pickup_photos'] = [
        {'id': 'ph-9', 'url': 'https://cdn.example.com/p.jpg'}
      ];
    await openTracked(tester, rig, json);

    expect(find.text('1 photo added'), findsOneWidget);
    expect(find.byKey(const Key('photo_remove_ph-9')), findsNothing);
    expect(find.byKey(const Key('pickup_photo_box')), findsNothing);
  });

  rigTest('one photo per item: a slot under every item, all needed to proceed',
      (tester, rig) async {
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'per_item', status: 'arrived_at_pickup'));

    expect(find.byKey(const Key('pickup_photo_box')), findsNothing);
    expect(find.text('Take a photo of each item below · 0 of 2 done'),
        findsOneWidget);
    expect(find.byKey(const Key('pickup_item_photo_i-1')), findsOneWidget);
    expect(find.byKey(const Key('pickup_item_photo_i-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pickup_item_photo_i-1')));
    await tester.pumpAndSettle();
    expect(rig.repo.pickupPhotos, ['i-1']);
    expect(
        rig.capture.stamps.single.caption, '#E2E-1 · Pickup · Cement bag 50kg');
    expect(find.text('Take a photo of each item below · 1 of 2 done'),
        findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(find.text('Take a photo of every item first (1 left).'),
        findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('pickup_item_photo_i-2')));
    await tester.tap(find.byKey(const Key('pickup_item_photo_i-2')));
    await tester.pumpAndSettle();
    expect(find.text('All 2 item photos taken'), findsOneWidget);

    await swipe(tester, 'Pickup order');
    expect(rig.repo.calls, contains('start:$tripId'));
  });

  rigTest('without a location fix the photo is not kept', (tester, rig) async {
    rig.location.fix = null;
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'order', status: 'arrived_at_pickup'));

    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Turn on location'), findsOneWidget);
    expect(rig.repo.pickupPhotos, isEmpty);
    expect(find.textContaining('added'), findsNothing);
  });

  rigTest('a failed upload drops the photo and says why', (tester, rig) async {
    rig.repo.pickupPhotoFailure = const BusinessFailure('Upload failed.');
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'order', status: 'arrived_at_pickup'));

    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();

    expect(find.text('Upload failed.'), findsOneWidget);
    expect(find.textContaining('added'), findsNothing);
    expect(find.text('Tap to add photo of the package'), findsOneWidget);
  });

  rigTest('the company\'s note shows when there is one, and not otherwise',
      (tester, rig) async {
    final json = withItemsJson();
    json['notes'] = 'Call before arriving. Use the side gate.';
    (json['items'] as List)[1]
      ..['status'] = 'not_delivered'
      ..['driver_note'] = 'Damaged in transit';
    await openTracked(tester, rig, json);

    expect(
        find.text('Call before arriving. Use the side gate.'), findsOneWidget);
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

  rigTest('"both": the whole-order photo and one of every item, all needed',
      (tester, rig) async {
    await openAtPickup(tester, rig,
        withItemsJson(pickupPhoto: 'both', status: 'arrived_at_pickup'));
    expect(find.text('Order & item photos'), findsOneWidget);
    expect(find.byKey(const Key('pickup_photo_box')), findsOneWidget);
    expect(find.byKey(const Key('pickup_item_photo_i-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pickup_photo_box')));
    await tester.pumpAndSettle();
    await swipe(tester, 'Pickup order');
    expect(find.text('Take a photo of every item first (2 left).'),
        findsOneWidget);
    expect(rig.repo.pickupPhotos, ['order']);
  });

  rigTest('a voice note from the dispatcher shows a play button',
      (tester, rig) async {
    final json = withItemsJson()
      ..['voice_note_url'] = 'https://cdn.example.com/note.wav'
      ..['voice_note_seconds'] = 18;
    await openTracked(tester, rig, json);
    expect(find.byKey(const Key('voice_note')), findsOneWidget);
    expect(find.text('Voice note from dispatcher'), findsOneWidget);
    expect(find.text('0:18'), findsOneWidget);
  });

  rigTest('a problem at pickup cancels the trip and returns to the dashboard',
      (tester, rig) async {
    rig.repo.actionResult =
        (Trip.fromJson(tripJson(status: 'cancelled')), null);
    await openDetails(tester, rig, withItems());

    // It's at the end of the page (under "You'll receive"), not pinned.
    await tester.ensureVisible(find.byKey(const Key('order_details_problem')));
    await tester.pumpAndSettle();
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
