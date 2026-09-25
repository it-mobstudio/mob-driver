import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/payment_qr_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/swipe_button.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

const tripId = '604807b6-7053-4f5f-bf99-163eb9620dc3';

Future<void> openTrip(WidgetTester tester, TestRig rig, Trip trip, {void Function(TestRig rig)? arrange}) async {
  rig.repo.profileValue = fakeProfile(online: true);
  rig.repo.activeTripValue = trip;
  rig.repo.tripsById[trip.id] = trip;
  arrange?.call(rig);
  await rig.cubit.load();
  await tester.pumpWidget(rig.app('/driver/trip/${trip.id}'));
  await tester.pumpAndSettle(); // the panel rises in over ~0.4 s
}

/// Text inside the open dialog (the screen behind it often repeats the same words).
Finder inDialog(String text) => find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

/// The trip panel's swipe label — what the driver does next.
String action(WidgetTester tester) =>
    tester.widget<SwipeButton>(find.byKey(const Key('trip_swipe'))).label;

void main() {
  // Real Inter metrics, loaded outside fake-async time (it does real I/O).
  setUpAll(loadAppFonts);

  group('the map gets the route', () {
    rigTest('the backend polyline is decoded at precision 6 and ends at pickup/drop', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());

      expect(find.text('routeFirst=12.9750,77.6050'), findsOneWidget);
      expect(find.text('routeLast=12.9783,77.6408'), findsOneWidget);
      expect(find.textContaining('route=3'), findsOneWidget);
    });

    rigTest('the driver → pickup leg from the navigation endpoint is drawn too', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(), arrange: (rig) {
        rig.repo.navRouteValue = NavRoute(
          target: 'pickup',
          points: decodePolyline('ox|vWogs_sCw|Aoh\\ooB_sg@'),
          distanceMeters: 3739,
          durationSeconds: 538,
        );
      });

      expect(find.textContaining('leg=3'), findsOneWidget);
    });

    rigTest('no leg (routing unavailable) still leaves a usable trip screen', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(), arrange: (rig) {
        rig.repo.navigationFailure = const ServerFailure('down', statusCode: 503);
      });

      expect(find.textContaining('leg=0'), findsOneWidget);
      expect(action(tester), 'Reached pickup');
    });

    rigTest('a trip with no polyline at all does not crash', (tester, rig) async {
      await openTrip(tester, rig, Trip.fromJson(tripJson(polyline: null)),
      );
      expect(find.textContaining('route=0'), findsOneWidget);
      expect(rig.cubit.state.activeTrip, isNotNull);
    });

    rigTest('the driver marker follows live GPS while the trip is active', (tester, rig) async {
      // No fix yet, so there's no marker to begin with.
      await openTrip(tester, rig, fakeTrip(), arrange: (rig) => rig.location.fix = null);
      expect(find.textContaining('driver=false'), findsOneWidget);

      rig.cubit.position.value = const GeoPoint(12.972, 77.596);
      await tester.pump();

      expect(find.textContaining('driver=true'), findsOneWidget);
    });
  });

  group('stage by stage', () {
    rigTest('reached pickup → pickup order → deliver, each adopting the server\'s trip', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());

      expect(action(tester), 'Reached pickup');
      expect(find.text('MG Road Metro, Bengaluru'), findsOneWidget);
      expect(find.byKey(const Key('timeline_map_0')), findsOneWidget, reason: 'the pickup is the active stop');
      expect(find.byKey(const Key('timeline_map_1')), findsNothing);

      rig.repo.actionResult = (fakeTrip(status: 'arrived_at_pickup'), null);
      await swipe(tester, 'Reached pickup');
      expect(action(tester), 'Pickup order');
      expect(rig.repo.calls, contains('arrive:$tripId'));

      rig.repo.actionResult = (fakeTrip(status: 'in_progress'), null);
      await swipe(tester, 'Pickup order');
      expect(action(tester), 'Deliver order');
      expect(rig.repo.calls, contains('start:$tripId'));
      expect(find.byKey(const Key('timeline_map_1')), findsOneWidget, reason: 'now the drop is');
    });

    rigTest('a backend rejection is shown and the stage does not change', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());
      rig.repo.actionResult = (
        null,
        const BusinessFailure('Trip must be arrived.', code: 'INVALID_TRIP_STATUS_TRANSITION')
      );

      await swipe(tester, 'Reached pickup');

      expect(find.text('Trip must be arrived.'), findsOneWidget);
      expect(action(tester), 'Reached pickup');
      await tester.pump(const Duration(seconds: 4)); // let the snackbar dismiss
    });

    rigTest('a tap alone does nothing — it takes a swipe', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());
      await tester.tap(find.byKey(const Key('trip_swipe')));
      await tester.pumpAndSettle();
      expect(rig.repo.calls, isNot(contains('arrive:$tripId')));
    });

    rigTest('View details opens the order details for reading', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'));
      await tester.tap(find.byKey(const Key('timeline_view_details_1')));
      await tester.pumpAndSettle();
      expect(find.text('Order details'), findsOneWidget);
      expect(find.byKey(const Key('order_details_pickup')), findsNothing);
      expect(find.byKey(const Key('order_details_problem')), findsNothing, reason: 'too late to cancel');
    });

    rigTest('COD in progress: Deliver order goes to payment collection', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'));
      expect(find.byKey(const Key('trip_cancel')), findsNothing, reason: 'no cancelling once underway');
      await swipe(tester, 'Deliver order');
      expect(find.byType(PaymentQrPage), findsOneWidget);
    });

    rigTest('COD paid: Deliver order goes to the delivery OTP', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress', paymentStatus: 'paid'));
      await swipe(tester, 'Deliver order');
      expect(find.text('Verify & complete delivery'), findsOneWidget);
    });

    rigTest('prepaid completes with a confirmation and no OTP', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress', paymentMode: 'prepaid', paymentStatus: 'paid'),
      );
      rig.repo.actionResult = (fakeTrip(status: 'completed', paymentMode: 'prepaid', paymentStatus: 'paid'), null);

      await swipe(tester, 'Deliver order');
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(find.text('Delivery complete'), findsOneWidget);
      expect(find.byKey(const Key('delivered_title')), findsOneWidget);
      expect(rig.repo.calls, contains('complete[null]:$tripId'));

      await tester.tap(find.byKey(const Key('delivery_complete_done')));
      await tester.pumpAndSettle();
      expect(find.text('DASHBOARD'), findsOneWidget);
    });
  });

  group('prepaid with a delivery OTP', () {
    rigTest('Deliver order texts the customer the OTP, and the code completes it', (tester, rig) async {
      final json = tripJson(status: 'in_progress', paymentMode: 'prepaid', paymentStatus: 'paid');
      json['delivery_otp'] = true;
      await openTrip(tester, rig, Trip.fromJson(json));
      rig.repo.actionResult = (fakeTrip(status: 'completed', paymentMode: 'prepaid', paymentStatus: 'paid'), null);

      await swipe(tester, 'Deliver order');
      expect(rig.repo.calls, contains('resend:$tripId'));
      expect(find.text('Verify & complete delivery'), findsOneWidget);
      expect(find.text('Complete delivery?'), findsNothing, reason: 'the code replaces the confirmation');

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();
      expect(rig.repo.calls, contains('complete[1234]:$tripId'));
      expect(find.text('Delivery complete'), findsOneWidget);
    });
  });

  group('proof photos', () {
    Future<void> openWithPhotos(WidgetTester tester, TestRig rig,
        {required String status, String pickup = 'none', String delivery = 'none'}) async {
      final json = tripJson(
        status: status,
        paymentMode: 'prepaid',
        paymentStatus: 'paid',
        pickupPhoto: pickup,
        deliveryPhoto: delivery,
        items: [
          {'id': 'i-1', 'name': 'Shower', 'quantity': 2, 'status': 'pending'},
          {'id': 'i-2', 'name': 'Tap', 'quantity': 1, 'status': 'pending'},
        ],
      );
      rig.repo.tripJsonById[tripId] = json;
      await openTrip(tester, rig, Trip.fromJson(json));
    }

    rigTest('Pickup order asks for the pickup photo first, then starts', (tester, rig) async {
      await openWithPhotos(tester, rig, status: 'arrived_at_pickup', pickup: 'order');
      rig.repo.actionResult = (fakeTrip(status: 'in_progress'), null);

      await swipe(tester, 'Pickup order');
      expect(find.text('Pickup photos'), findsOneWidget);
      expect(rig.repo.calls, isNot(contains('start:$tripId')));

      await tester.tap(find.byKey(const Key('order_photos_done')));
      await tester.pumpAndSettle();
      expect(find.text('Add a photo of the package first.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pickup_photo_box')));
      await tester.pumpAndSettle();
      expect(rig.repo.pickupPhotos, ['order']);
      expect(rig.capture.stamps.single.caption, '#E2E-1 · Pickup');

      await tester.tap(find.byKey(const Key('order_photos_done')));
      await tester.pumpAndSettle();
      expect(rig.repo.calls, contains('start:$tripId'));
      expect(action(tester), 'Deliver order');
    });

    rigTest('backing out of the photos does not start the delivery', (tester, rig) async {
      await openWithPhotos(tester, rig, status: 'arrived_at_pickup', pickup: 'order');
      await swipe(tester, 'Pickup order');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(rig.repo.calls, isNot(contains('start:$tripId')));
      expect(action(tester), 'Pickup order');
    });

    rigTest('Deliver order asks for a delivery photo of every item before finishing', (tester, rig) async {
      await openWithPhotos(tester, rig, status: 'in_progress', delivery: 'per_item');
      rig.repo.actionResult = (fakeTrip(status: 'completed', paymentMode: 'prepaid', paymentStatus: 'paid'), null);

      await swipe(tester, 'Deliver order');
      expect(find.text('Delivery photos'), findsOneWidget);

      for (final id in ['i-1', 'i-2']) {
        await tester.ensureVisible(find.byKey(Key('delivery_item_photo_$id')));
        await tester.tap(find.byKey(Key('delivery_item_photo_$id')));
        await tester.pumpAndSettle();
      }
      expect(rig.repo.deliveryPhotos, ['i-1', 'i-2']);
      expect(rig.capture.stamps.last.caption, '#E2E-1 · Delivery · Tap');

      await tester.tap(find.byKey(const Key('order_photos_done')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();
      expect(rig.repo.calls, contains('complete[null]:$tripId'));
    });

    rigTest('the camera is the only source — never the gallery', (tester, rig) async {
      await openWithPhotos(tester, rig, status: 'in_progress', delivery: 'order');
      await swipe(tester, 'Deliver order');
      await tester.tap(find.byKey(const Key('delivery_photo_box')));
      await tester.pumpAndSettle();
      expect(rig.capture.cameraCalls, 1);
      expect(rig.capture.galleryCalls, 0);
    });
  });

  group('cancelling', () {
    rigTest('needs a reason, then cancels and returns home', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());
      await tester.tap(find.byKey(const Key('trip_cancel')));
      await tester.pumpAndSettle();

      // The confirm button is disabled until a reason is chosen.
      final confirm = find.widgetWithText(ElevatedButton, 'Cancel trip');
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      await tester.tap(find.byKey(const Key('cancel_reason_Vehicle breakdown')));
      await tester.pump();
      rig.repo.actionResult = (
        Trip.fromJson(tripJson(status: 'cancelled', cancelledBy: 'driver', cancellationReason: 'Vehicle breakdown')),
        null
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(rig.repo.calls, contains('cancel[Vehicle breakdown]:$tripId'));
      expect(find.text('DASHBOARD'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('"Other" needs free text', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());
      await tester.tap(find.byKey(const Key('trip_cancel')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_reason_Other')));
      await tester.pump();
      final confirm = find.widgetWithText(ElevatedButton, 'Cancel trip');
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('cancel_other_text')), 'Flat tyre');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(confirm).onPressed, isNotNull);
    });
  });

  group('the company cancels mid-trip', () {
    rigTest('the screen announces it and shows the final state', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip());
      rig.repo.tripsById[tripId] = Trip.fromJson(
          tripJson(status: 'cancelled', cancelledBy: 'company', cancellationReason: 'Order cancelled by customer'));
      rig.repo.activeTripValue = null;

      await rig.cubit.pollNow();
      await tester.pump();
      await tester.pump();

      // pollNow only acts while working; the cubit was started by load().
      expect(inDialog('Trip cancelled'), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.textContaining('Order cancelled by customer')), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('DASHBOARD'), findsOneWidget);
    });
  });

  group('history view', () {
    rigTest('a finished trip opens read-only with its fare breakdown', (tester, rig) async {
      final done = Trip.fromJson({...tripJson(status: 'completed', paymentStatus: 'paid'), 'completed_at': '2026-09-20T16:10:00Z'});
      rig.repo.tripsById[done.id] = done;
      await tester.pumpWidget(rig.app('/driver/trip/${done.id}'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Base fare'), findsOneWidget);
      expect(find.byKey(const Key('trip_swipe')), findsNothing);
      expect(find.byKey(const Key('trip_cancel')), findsNothing);
      expect(rig.repo.calls, contains('trip:${done.id}'));
    });

    rigTest('an unknown trip shows an error with retry', (tester, rig) async {
      await tester.pumpWidget(rig.app('/driver/trip/nope'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not load trip'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('payment QR', () {
    rigTest('shows the amount and a scannable QR of the UPI payload', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'));
      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qr_amount')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('qr_amount'))).data, '₹111.62');
      final qr = tester.widget<UpiQrCode>(find.byKey(const Key('payment_qr')));
      expect(qr.payload, startsWith('upi://pay?'));
      final image = tester.widget<QrImageView>(find.descendant(of: find.byType(UpiQrCode), matching: find.byType(QrImageView)));
      expect(image.backgroundColor, Colors.white, reason: 'QR needs a white quiet zone to scan');
    });

    rigTest('"Payment received" asks first, then collects and moves to the OTP step', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'));
      rig.repo.tripsById[tripId] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');

      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment received'));
      await tester.pumpAndSettle();
      expect(find.text('Received ₹111.62?'), findsOneWidget);
      expect(rig.repo.calls.where((c) => c.startsWith('collect')), isEmpty, reason: 'must confirm first');

      await tester.tap(find.text('Yes, received'));
      await tester.pumpAndSettle();

      expect(rig.repo.calls, contains('collect:$tripId'));
      expect(find.text('Enter delivery OTP'), findsOneWidget);
      expect(find.textContaining('Customer'), findsNothing);
    });

    rigTest('an already-paid trip skips straight to the OTP', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'));
      // Backend says it's paid, but we were stale.
      rig.repo.tripsById[tripId] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');
      rig.repo.collectResult = (null, const BusinessFailure('paid', code: 'ALREADY_PAID'));

      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment received'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, received'));
      await tester.pumpAndSettle();

      expect(find.text('Enter delivery OTP'), findsOneWidget);
    });
  });

  group('payment QR — Razorpay', () {
    PaymentQr razorpayQr({DateTime? expiresAt}) => PaymentQr(
          provider: 'razorpay',
          reference: 'qr_Nx4a1',
          imageUrl: 'https://rzp.io/qr/qr_Nx4a1.png',
          amount: 111.62,
          currency: 'INR',
          expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 9, seconds: 30)),
        );

    Future<void> openPayment(WidgetTester tester, TestRig rig, PaymentQr qr) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'), arrange: (rig) => rig.repo.paymentQrValue = qr);
      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();
    }

    rigTest('shows the QR image Razorpay hosts, not one drawn locally', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());

      final image = tester.widget<Image>(find.byKey(const Key('payment_qr_image')));
      expect((image.image as NetworkImage).url, 'https://rzp.io/qr/qr_Nx4a1.png');
      expect(find.byKey(const Key('payment_qr')), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('qr_amount'))).data, '₹111.62');
    });

    rigTest('the driver is told the screen is waiting, with a countdown, and the button is "Check payment"', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());

      expect(find.byKey(const Key('qr_waiting')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('qr_countdown'))).data, matches(r'^Code valid for 0[89]:\d\d$'));
      expect(find.text('Check payment'), findsOneWidget);
      expect(find.text('Payment received'), findsNothing, reason: 'the driver\u2019s word is not what marks it paid');
    });

    rigTest('moves to the OTP step by itself once Razorpay has reported the payment', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());
      expect(find.text('Enter delivery OTP'), findsNothing);

      // The customer pays; Razorpay's webhook makes the server mark the trip paid.
      rig.repo.tripsById[tripId] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Enter delivery OTP'), findsOneWidget);
      expect(rig.repo.calls, isNot(contains('collect:$tripId')), reason: 'nothing was claimed by the driver');
    });

    rigTest('keeps waiting while the trip is still unpaid', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byKey(const Key('payment_qr_image')), findsOneWidget);
      expect(find.text('Enter delivery OTP'), findsNothing);
    });

    rigTest('"Check payment" asks the server — with no confirmation dialog — and moves on when it is paid', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());
      rig.repo.tripsById[tripId] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');

      await tester.tap(find.text('Check payment'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(rig.repo.calls, contains('collect:$tripId'));
      expect(find.text('Enter delivery OTP'), findsOneWidget);
    });

    rigTest('"Check payment" before the customer has paid says so and stays put', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());
      rig.repo.collectResult = (
        null,
        const BusinessFailure('No payment has been received for this trip yet.', code: 'PAYMENT_NOT_RECEIVED'),
      );

      await tester.tap(find.text('Check payment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No payment has been received for this trip yet.'), findsOneWidget);
      expect(find.byKey(const Key('payment_qr_image')), findsOneWidget, reason: 'the code is still there to scan');
      expect(find.text('Enter delivery OTP'), findsNothing);
      // let the snack bar go
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    rigTest('an expired code is replaced by "Get a new code", which asks for another', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr(expiresAt: DateTime.now().subtract(const Duration(seconds: 5))));

      expect(find.byKey(const Key('qr_expired')), findsOneWidget);
      expect(find.byKey(const Key('payment_qr_image')), findsNothing);
      expect(tester.widget<PrimaryButton>(find.byKey(const Key('check_payment'))).onPressed, isNull, reason: 'an expired code can\u2019t be paid');

      final before = rig.repo.paymentQrCalls;
      rig.repo.paymentQrValue = razorpayQr();
      await tester.tap(find.byKey(const Key('qr_new_code')));
      await tester.pumpAndSettle();

      expect(rig.repo.paymentQrCalls, before + 1);
      expect(find.byKey(const Key('payment_qr_image')), findsOneWidget);
      expect(find.byKey(const Key('qr_expired')), findsNothing);
    });

    rigTest('a customer who already paid (server found it while issuing the code) goes straight to the OTP', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'), arrange: (rig) {
        rig.repo.paymentQrFailure = const BusinessFailure('This trip has already been paid.', code: 'ALREADY_PAID');
      });
      rig.repo.tripsById[tripId] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');

      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();

      expect(find.text('Enter delivery OTP'), findsOneWidget);
    });

    rigTest('a payment-provider outage shows the reason with a way to retry', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'), arrange: (rig) {
        rig.repo.paymentQrFailure = const ServerFailure('Couldn\u2019t reach the payment provider.', statusCode: 503);
      });

      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();

      expect(find.text('Couldn\u2019t reach the payment provider.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      rig.repo.paymentQrFailure = null;
      rig.repo.paymentQrValue = razorpayQr();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payment_qr_image')), findsOneWidget);
    });

    rigTest('the polling stops when the screen is left (no timers leak)', (tester, rig) async {
      await openPayment(tester, rig, razorpayQr());
      await tester.pageBack();
      await tester.pumpAndSettle();
      // A leaked periodic timer fails the test at teardown; a live poll would
      // also keep hitting the repo.
      final calls = rig.repo.calls.where((c) => c.startsWith('trip:')).length;
      await tester.pump(const Duration(seconds: 9));
      expect(rig.repo.calls.where((c) => c.startsWith('trip:')).length, calls);
    });
  });

  group('delivery OTP', () {
    Future<void> openOtp(WidgetTester tester, TestRig rig) async {
      final trip = fakeTrip(status: 'in_progress', paymentStatus: 'paid');
      rig.repo.profileValue = fakeProfile(online: true);
      rig.repo.activeTripValue = trip;
      await rig.cubit.load();
      await tester.pumpWidget(rig.app('/driver/trip/$tripId'));
      await tester.pumpAndSettle(); // let the panel finish rising in
      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();
    }

    rigTest('names the recipient and their phone', (tester, rig) async {
      await openOtp(tester, rig);
      final text = tester.widget<Text>(find.byKey(const Key('otp_instructions'))).data!;
      expect(text, contains('Asha'));
      expect(text, contains('+91 98888 00002'));
      expect(text, contains('4-digit'));
    });

    rigTest('entering the 4-digit code completes the delivery', (tester, rig) async {
      await openOtp(tester, rig);
      rig.repo.actionResult = (fakeTrip(status: 'completed', paymentStatus: 'paid'), null);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      expect(rig.repo.calls, contains('complete[1234]:$tripId'));
      expect(find.text('Delivery complete'), findsOneWidget);
      expect(find.text('Added to your earnings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delivery_complete_done')));
      await tester.pumpAndSettle();
      expect(find.text('DASHBOARD'), findsOneWidget);
    });

    rigTest('a wrong code shows the backend\'s message and lets the driver retry', (tester, rig) async {
      await openOtp(tester, rig);
      rig.repo.actionResult = (
        null,
        const BusinessFailure('The delivery OTP is invalid or has expired.', code: 'INVALID_DELIVERY_OTP')
      );

      await tester.enterText(find.byType(TextField), '0000');
      await tester.pumpAndSettle();

      expect(find.text('The delivery OTP is invalid or has expired.'), findsOneWidget);
      expect(find.text('Verify & complete delivery'), findsOneWidget, reason: 'still on the OTP screen');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty, reason: 'boxes are cleared');
      await tester.pump(const Duration(seconds: 4));

      // ...and the driver can try again with the right one.
      rig.repo.actionResult = (fakeTrip(status: 'completed', paymentStatus: 'paid'), null);
      await tester.enterText(find.byType(TextField), '6543');
      await tester.pumpAndSettle();
      expect(find.text('Delivery complete'), findsOneWidget);
    });

    rigTest('the verify button stays disabled until all 4 digits are in', (tester, rig) async {
      await openOtp(tester, rig);
      final button = find.widgetWithText(ElevatedButton, 'Verify & complete delivery');
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    });

    rigTest('non-digits are ignored', (tester, rig) async {
      await openOtp(tester, rig);
      await tester.enterText(find.byType(TextField), '1a2b3');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '123');
    });

    rigTest('resend is available when reopened, and puts itself on a 30 s cool-down', (tester, rig) async {
      await openOtp(tester, rig);
      expect(find.byKey(const Key('otp_resend')), findsOneWidget);

      await tester.tap(find.byKey(const Key('otp_resend')));
      await tester.pump();
      await tester.pump();

      expect(rig.repo.calls, contains('resend:$tripId'));
      expect(find.byKey(const Key('otp_resend')), findsNothing);
      expect(find.text('Resend in 30s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 31));
      expect(find.byKey(const Key('otp_resend')), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a 429 from the backend also starts the cool-down', (tester, rig) async {
      await openOtp(tester, rig);
      rig.repo.resendResult = (null, const BusinessFailure('wait', code: 'OTP_ALREADY_REQUESTED'));

      await tester.tap(find.byKey(const Key('otp_resend')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Resend in 30s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('test-mode hint appears only when the backend echoed the OTP', (tester, rig) async {
      await openTrip(tester, rig, fakeTrip(status: 'in_progress'));
      rig.repo.tripsById[tripId] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');
      await swipe(tester, 'Deliver order');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payment received'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes, received'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test mode'), findsOneWidget);
      expect(find.textContaining('1234', findRichText: true), findsOneWidget);

      // Filling the last digit submits (that's what the field is for), so the
      // proof it was filled with the echoed OTP is the call it triggered.
      rig.repo.actionResult = (null, const BusinessFailure('nope', code: 'INVALID_DELIVERY_OTP'));
      await tester.tap(find.text('Fill'));
      await tester.pumpAndSettle();
      expect(rig.repo.calls, contains('complete[1234]:$tripId'));
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
