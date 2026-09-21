import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/item_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

const invoiceUrl = 'https://files.example.com/invoices/INV-1001.pdf';

List<Map<String, dynamic>> twoItems() => [
      itemJson(id: 'a', name: 'Cement bag 50 kg', quantity: 4, unit: 'bags'),
      itemJson(id: 'b', name: 'TMT bar 12 mm', quantity: 20, unit: 'pcs'),
    ];

Future<Trip> openTripPage(
  WidgetTester tester,
  TestRig rig, {
  List<Map<String, dynamic>>? items,
  String? invoice,
  String? number,
  String location = 'trip',
  bool cod = false,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  rig.repo.profileValue = fakeProfile(online: true);
  final trip = rig.repo.startItemTrip(items ?? twoItems(),
      invoiceUrl: invoice, invoiceNumber: number, cod: cod);
  await rig.cubit.load();
  await tester.pumpWidget(rig.app(location == 'items'
      ? DriverRoutes.items(trip.id)
      : DriverRoutes.trip(trip.id)));
  await tester.pumpAndSettle();
  return trip;
}

String stage(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('trip_stage_title'))).data!;
String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

/// Whether a button (found by key, possibly wrapped) is tappable right now.
bool tappable(WidgetTester tester, String key) {
  final button = find.descendant(
    of: find.byKey(Key(key)),
    matching: find
        .byWidgetPredicate((w) => w is ElevatedButton || w is OutlinedButton),
  );
  final widget =
      tester.widget(button.evaluate().isEmpty ? find.byKey(Key(key)) : button);
  return switch (widget) {
    ElevatedButton b => b.onPressed != null,
    OutlinedButton b => b.onPressed != null,
    _ => true,
  };
}

void main() {
  setUpAll(loadAppFonts);

  group('the trip screen when the company sent items', () {
    rigTest('the driver is asked to verify them before anything else',
        (tester, rig) async {
      await openTripPage(tester, rig);

      expect(stage(tester), 'Check the items');
      expect(find.text('0 of 2 checked with the customer'), findsOneWidget);
      expect(find.byKey(const Key('verify_items')), findsOneWidget);
      expect(find.text('Check items (0/2)'), findsOneWidget);
      expect(find.text('Complete delivery'), findsNothing,
          reason: 'not until every item is answered');
    });

    rigTest(
        'an items card lists what is being delivered and how far along the driver is',
        (tester, rig) async {
      await openTripPage(tester, rig);

      expect(find.byKey(const Key('items_card')), findsOneWidget);
      expect(find.text('Cement bag 50 kg'), findsOneWidget);
      expect(find.text('× 4 bags'), findsOneWidget);
      expect(find.text('× 20 pcs'), findsOneWidget);
      expect(find.text('0/2 CHECKED'), findsOneWidget);
      expect(textOf(tester, 'items_card_action'), 'Check items');
    });

    rigTest('a long list is summarised, not dumped into the panel',
        (tester, rig) async {
      await openTripPage(tester, rig, items: [
        for (var i = 0; i < 6; i++) itemJson(id: 'i$i', name: 'Item $i')
      ]);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsNothing);
      expect(find.text('+ 3 more'), findsOneWidget);
    });

    rigTest('the primary button and the card both open the checklist',
        (tester, rig) async {
      await openTripPage(tester, rig);
      await tester.tap(find.byKey(const Key('verify_items')));
      await tester.pumpAndSettle();
      expect(find.text('Check items'), findsWidgets,
          reason: 'the page title (and the trip card\'s way in)');
      expect(textOf(tester, 'items_progress'), '0 of 2 checked');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('items_card')));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'items_progress'), '0 of 2 checked');
    });

    rigTest('once every item is answered the normal ending is available again',
        (tester, rig) async {
      await openTripPage(tester, rig);
      await tester.tap(find.byKey(const Key('verify_items')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_delivered_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('items_done')));
      await tester.pumpAndSettle();

      expect(stage(tester), 'Deliver to customer');
      expect(find.text('Complete delivery'), findsOneWidget);
      expect(find.byKey(const Key('verify_items')), findsNothing);
      expect(textOf(tester, 'items_card_action'), 'Review items',
          reason: 'answers given, but still open to review');
      expect(find.text('ALL CHECKED'), findsOneWidget);
    });

    rigTest(
        'an order that only lists items, without asking to verify, is just information',
        (tester, rig) async {
      tester.view.physicalSize = const Size(1080, 3000);
      rig.repo.profileValue = fakeProfile(online: true);
      final trip = Trip.fromJson(tripJson(
          status: 'in_progress',
          paymentMode: 'prepaid',
          paymentStatus: 'paid',
          items: twoItems()));
      rig.repo.activeTripValue = trip;
      rig.repo.tripsById[trip.id] = trip;
      await rig.cubit.load();
      await tester.pumpWidget(rig.app(DriverRoutes.trip(trip.id)));
      await tester.pumpAndSettle();

      expect(stage(tester), 'Deliver to customer');
      expect(find.byKey(const Key('verify_items')), findsNothing);
      expect(find.text('Complete delivery'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
    });

    rigTest('an order with no items shows no items card at all',
        (tester, rig) async {
      tester.view.physicalSize = const Size(1080, 3000);
      rig.repo.profileValue = fakeProfile(online: true);
      final trip = fakeTrip(
          status: 'in_progress', paymentMode: 'prepaid', paymentStatus: 'paid');
      rig.repo.activeTripValue = trip;
      rig.repo.tripsById[trip.id] = trip;
      await rig.cubit.load();
      await tester.pumpWidget(rig.app(DriverRoutes.trip(trip.id)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('items_card')), findsNothing);
      expect(find.byKey(const Key('invoice_card')), findsNothing);
    });
  });

  group('the checklist', () {
    rigTest('ticking an item records "delivered" and moves the progress on',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      expect(find.text('Cement bag 50 kg'), findsOneWidget);
      expect(find.text('× 4 bags'), findsWidgets);

      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();

      final answer = rig.repo.itemAnswers.single;
      expect((answer.itemId, answer.status, answer.note, answer.hasPhoto),
          ('a', ItemStatus.delivered, null, false));
      expect(textOf(tester, 'item_status_a'), startsWith('Delivered'));
      expect(textOf(tester, 'items_progress'), '1 of 2 checked');
      expect(find.text('1 item left to check'), findsOneWidget);
      expect(tappable(tester, 'items_done'), isFalse);
    });

    rigTest(
        'the photo is optional: an item is verified without one, and one can be added after',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      expect(rig.capture.cameraCalls, 0,
          reason: 'nothing forced the camera open');
      expect(find.text('Add photo'), findsWidgets);

      await tester.tap(find.byKey(const Key('item_photo_a')));
      await tester.pumpAndSettle();

      expect(rig.capture.cameraCalls, 1);
      final second = rig.repo.itemAnswers.last;
      expect((second.itemId, second.status, second.hasPhoto),
          ('a', ItemStatus.delivered, true));
      expect(find.text('Photo saved'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
    });

    rigTest(
        'proof photos come from the camera — there is no gallery route for them',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_photo_a')));
      await tester.pumpAndSettle();

      expect((rig.capture.cameraCalls, rig.capture.galleryCalls), (1, 0));
      expect(find.byKey(const Key('photo_source_gallery')), findsNothing);
    });

    rigTest('a camera that cannot open says why and records nothing more',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      rig.capture.failure = const PhotoCaptureException(
          'Camera or photo access is off. Allow it in Settings to add pictures.');

      await tester.tap(find.byKey(const Key('item_photo_a')));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Camera or photo access is off'), findsOneWidget);
      expect(rig.repo.itemAnswers, hasLength(1), reason: 'just the tick');
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('backing out of the camera leaves the answer as it was',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      rig.capture.next = null;

      await tester.tap(find.byKey(const Key('item_photo_a')));
      await tester.pumpAndSettle();

      expect(rig.repo.itemAnswers, hasLength(1));
    });

    rigTest('"Problem" needs a reason before it can be recorded',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_problem_b')));
      await tester.pumpAndSettle();

      expect(find.text('What went wrong?'), findsOneWidget);
      expect(tappable(tester, 'problem_confirm'), isFalse);

      await tester.tap(find.byKey(const Key('problem_reason_Item damaged')));
      await tester.pumpAndSettle();
      expect(tappable(tester, 'problem_confirm'), isTrue);
      await tester.tap(find.byKey(const Key('problem_confirm')));
      await tester.pumpAndSettle();

      final answer = rig.repo.itemAnswers.single;
      expect((answer.itemId, answer.status, answer.note),
          ('b', ItemStatus.notDelivered, 'Item damaged'));
      expect(textOf(tester, 'item_status_b'), 'Not delivered');
      expect(find.text('Item damaged'), findsOneWidget,
          reason: 'the reason stays on the card');
      expect(textOf(tester, 'items_progress'), '1 of 2 checked',
          reason: '"not delivered" is an answer too');
    });

    rigTest('"Other" needs the driver\'s own words', (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_problem_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem_reason_Other')));
      await tester.pumpAndSettle();
      expect(tappable(tester, 'problem_confirm'), isFalse);

      await tester.enterText(
          find.byKey(const Key('problem_other')), '  Customer wasn’t home  ');
      await tester.pump();
      expect(tappable(tester, 'problem_confirm'), isTrue);
      await tester.tap(find.byKey(const Key('problem_confirm')));
      await tester.pumpAndSettle();

      expect(rig.repo.itemAnswers.single.note, 'Customer wasn’t home');
    });

    rigTest('a photo of the problem can go with it', (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_problem_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem_reason_Wrong item')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem_confirm')));
      await tester.pumpAndSettle();

      expect(rig.repo.itemAnswers.single.hasPhoto, isTrue);
    });

    rigTest('backing out of the problem sheet records nothing',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_problem_b')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 40)); // the scrim above the sheet
      await tester.pumpAndSettle();

      expect(rig.repo.itemAnswers, isEmpty);
      expect(find.text('What went wrong?'), findsNothing);
    });

    rigTest('an answer can be taken back', (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'items_progress'), '1 of 2 checked');

      await tester.tap(find.byKey(const Key('item_undo_a')));
      await tester.pumpAndSettle();

      expect(rig.repo.calls, contains('resetItem:a'));
      expect(textOf(tester, 'items_progress'), '0 of 2 checked');
      expect(find.byKey(const Key('item_delivered_a')), findsOneWidget,
          reason: 'back to asking');
    });

    rigTest(
        'all answered: the progress turns done and Done leaves the checklist',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_problem_b')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('problem_reason_Item missing or short')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem_confirm')));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'items_progress'), 'All 2 checked');
      expect(find.text('Continue'), findsOneWidget);
      expect(tappable(tester, 'items_done'), isTrue);
    });

    rigTest('a refusal is shown and the item stays as it was',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      rig.repo.verifyItemFailure = const NetworkFailure();

      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();

      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(find.byKey(const Key('item_delivered_a')), findsOneWidget,
          reason: 'still to be answered');
      expect(textOf(tester, 'items_progress'), '0 of 2 checked');
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('while one answer is on its way, the others hold still',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items');
      rig.repo.verifyItemGate = Completer<void>();

      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pump();
      expect(tappable(tester, 'item_delivered_b'), isFalse,
          reason: 'one request at a time');
      expect(tappable(tester, 'item_problem_b'), isFalse);

      rig.repo.verifyItemGate!.complete();
      await tester.pumpAndSettle();
      expect(tappable(tester, 'item_delivered_b'), isTrue);
    });

    rigTest('a finished delivery is a read-only record of what happened',
        (tester, rig) async {
      tester.view.physicalSize = const Size(1080, 3000);
      final done = Trip.fromJson(tripJson(
        status: 'completed',
        paymentMode: 'prepaid',
        paymentStatus: 'paid',
        verifyItems: true,
        items: [
          itemJson(
              id: 'a',
              status: 'delivered',
              proofImageUrl: 'https://cdn.example.com/p.jpg'),
          itemJson(
              id: 'b',
              name: 'TMT bar',
              status: 'not_delivered',
              note: 'Damaged in transit'),
        ],
      ));
      rig.repo.profileValue = fakeProfile();
      rig.repo.tripsById[done.id] = done;
      await rig.cubit.load();
      await tester.pumpWidget(rig.app(DriverRoutes.items(done.id)));
      await tester.pumpAndSettle();

      expect(find.text('Items'), findsOneWidget,
          reason: 'not "Verify items" any more');
      expect(textOf(tester, 'item_status_a'), startsWith('Delivered'));
      expect(textOf(tester, 'item_status_b'), 'Not delivered');
      expect(find.text('Damaged in transit'), findsOneWidget);
      expect(find.text('Photo saved'), findsOneWidget);
      expect(find.byKey(const Key('item_delivered_a')), findsNothing);
      expect(find.byKey(const Key('item_undo_a')), findsNothing);
      expect(find.byKey(const Key('items_done')), findsNothing);
    });
  });

  group('the checklist is easy to read', () {
    List<Color> barColors(WidgetTester tester) => [
          for (final c in tester.widgetList<AnimatedContainer>(find.descendant(
              of: find.byType(ItemProgressBar),
              matching: find.byType(AnimatedContainer))))
            (c.decoration as BoxDecoration).color!
        ];

    rigTest(
        'what is left comes first, answered items settle below in a "done" group',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items', items: [
        itemJson(id: 'a', name: 'Cement bag 50 kg'),
        itemJson(id: 'b', name: 'TMT bar 12 mm'),
        itemJson(id: 'c', name: 'Wall putty 20 kg'),
      ]);
      expect(find.byKey(const Key('section_to_check')), findsOneWidget);
      expect(find.byKey(const Key('section_done')), findsNothing,
          reason: 'nothing answered yet');

      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_done')), findsOneWidget);
      final toCheck =
          tester.getTopLeft(find.byKey(const Key('section_to_check'))).dy;
      final done = tester.getTopLeft(find.byKey(const Key('section_done'))).dy;
      final answered = tester.getTopLeft(find.byKey(const Key('item_a'))).dy;
      final next = tester.getTopLeft(find.byKey(const Key('item_b'))).dy;
      expect(toCheck < next && next < done && done < answered, isTrue,
          reason:
              'TO CHECK, then the items still to do, then DONE, then the answered one');
      expect(
          tester
              .widget<Text>(find.descendant(
                  of: find.byKey(const Key('section_to_check')),
                  matching: find.text('2')))
              .data,
          '2');
    });

    rigTest(
        'the header says how many are done, and the bar has a segment per item in its colour',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items', items: [
        itemJson(id: 'a', name: 'Cement bag 50 kg'),
        itemJson(id: 'b', name: 'TMT bar 12 mm'),
        itemJson(id: 'c', name: 'Wall putty 20 kg'),
      ]);
      expect(textOf(tester, 'items_tally'), '3 to check');
      expect(find.textContaining('Hand each item over'), findsOneWidget,
          reason: 'the how-to only until you start');
      expect(barColors(tester), hasLength(3));

      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_problem_b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem_reason_Item damaged')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('problem_confirm')));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'items_tally'),
          '1 delivered · 1 problem · 1 to check');
      expect(find.textContaining('Hand each item over'), findsNothing);
      // Bar order follows the list: delivered, problem, still to check.
      expect(barColors(tester),
          [DriverColors.green, DriverColors.red, DriverColors.line]);
    });

    rigTest('how many, and what to watch out for, are impossible to miss',
        (tester, rig) async {
      await openTripPage(tester, rig, location: 'items', items: [
        {
          ...itemJson(id: 'a', name: 'Glass panel', quantity: 6, unit: 'pcs'),
          'notes': 'Fragile - keep upright'
        },
      ]);
      expect(find.byType(QuantityChip), findsOneWidget);
      expect(find.text('× 6 pcs'), findsOneWidget);
      expect(find.text('Fragile - keep upright'), findsOneWidget);
    });

    rigTest('the footer says what is left, then where it leads',
        (tester, rig) async {
      await openTripPage(tester, rig,
          location: 'items',
          cod: true,
          items: [itemJson(id: 'a'), itemJson(id: 'b')]);
      expect(find.text('2 items left to check'), findsOneWidget);
      await tester.tap(find.byKey(const Key('item_delivered_a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('item_delivered_b')));
      await tester.pumpAndSettle();
      expect(find.text('Continue to payment'), findsOneWidget,
          reason: 'cash on delivery, not yet paid');
    });

    rigTest('the trip panel says in words where each item stands',
        (tester, rig) async {
      await openTripPage(tester, rig, items: [
        itemJson(id: 'a', name: 'Cement bag 50 kg', status: 'delivered'),
        itemJson(
            id: 'b',
            name: 'TMT bar 12 mm',
            status: 'not_delivered',
            note: 'Damaged'),
        itemJson(id: 'c', name: 'Wall putty 20 kg'),
      ]);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Problem'), findsOneWidget);
      expect(find.text('To check'), findsOneWidget);
      expect(find.byType(ItemProgressBar), findsOneWidget);
      expect(textOf(tester, 'items_card_action'), 'Check items');
    });
  });

  group('the invoice', () {
    rigTest('is offered with its number, and only when the company sent one',
        (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl, number: 'INV-1001');
      expect(find.byKey(const Key('invoice_card')), findsOneWidget);
      expect(textOf(tester, 'invoice_title'), 'Invoice INV-1001');
      for (final action in ['download', 'whatsapp', 'share']) {
        expect(find.byKey(Key('invoice_$action')), findsOneWidget);
      }
    });

    rigTest('without a number it is simply "Invoice"', (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl);
      expect(textOf(tester, 'invoice_title'), 'Invoice');
    });

    rigTest('no invoice, no card', (tester, rig) async {
      await openTripPage(tester, rig);
      expect(find.byKey(const Key('invoice_card')), findsNothing);
    });

    rigTest('Download opens the invoice link', (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl, number: 'INV-1001');
      await tester.tap(find.byKey(const Key('invoice_download')));
      await tester.pumpAndSettle();
      expect(rig.invoice.downloads, [invoiceUrl]);
    });

    rigTest(
        'WhatsApp opens the customer\'s chat with a message carrying the link',
        (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl, number: 'INV-1001');
      await tester.tap(find.byKey(const Key('invoice_whatsapp')));
      await tester.pumpAndSettle();

      final sent = rig.invoice.whatsApps.single;
      expect(sent.phone, '+919888800002', reason: 'the drop contact');
      expect(
          sent.message, 'Hi Asha, here is your invoice INV-1001: $invoiceUrl');
    });

    rigTest(
        'Share hands over the file, named after the company\'s own file name',
        (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl, number: 'INV-1001');
      await tester.tap(find.byKey(const Key('invoice_share')));
      await tester.pumpAndSettle();

      final shared = rig.invoice.shares.single;
      expect(shared.url, invoiceUrl);
      expect(shared.fileName, 'INV-1001.pdf');
      expect(shared.message, contains(invoiceUrl));
    });

    rigTest('a failure is explained and the buttons come back',
        (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl, number: 'INV-1001');
      rig.invoice.problem = 'WhatsApp isn’t available on this phone.';

      await tester.tap(find.byKey(const Key('invoice_whatsapp')));
      await tester.pumpAndSettle();

      expect(
          find.text('WhatsApp isn’t available on this phone.'), findsOneWidget);
      expect(tappable(tester, 'invoice_share'), isTrue);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest(
        'while a file is being fetched, the buttons are locked and one shows progress',
        (tester, rig) async {
      await openTripPage(tester, rig, invoice: invoiceUrl, number: 'INV-1001');
      rig.invoice.gate = Completer<void>();

      await tester.tap(find.byKey(const Key('invoice_share')));
      await tester.pump();

      expect(tappable(tester, 'invoice_download'), isFalse);
      expect(tappable(tester, 'invoice_whatsapp'), isFalse);
      expect(tappable(tester, 'invoice_share'), isFalse);
      expect(
          find.descendant(
              of: find.byKey(const Key('invoice_share')),
              matching: find.byType(CircularProgressIndicator)),
          findsOneWidget);

      rig.invoice.gate!.complete();
      await tester.pumpAndSettle();
      expect(tappable(tester, 'invoice_share'), isTrue);
    });

    rigTest('it stays available on a finished trip', (tester, rig) async {
      tester.view.physicalSize = const Size(1080, 3000);
      final done = Trip.fromJson(tripJson(
          status: 'completed',
          paymentMode: 'prepaid',
          paymentStatus: 'paid',
          invoiceUrl: invoiceUrl,
          invoiceNumber: 'INV-1001',
          driverEarning: '89.30'));
      rig.repo.profileValue = fakeProfile();
      rig.repo.tripsById[done.id] = done;
      await rig.cubit.load();
      await tester.pumpWidget(rig.app(DriverRoutes.trip(done.id)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invoice_card')), findsOneWidget);
    });
  });

  group('what the driver earned', () {
    rigTest('is on the finished trip', (tester, rig) async {
      tester.view.physicalSize = const Size(1080, 3000);
      final done = Trip.fromJson(tripJson(
          status: 'completed',
          paymentMode: 'prepaid',
          paymentStatus: 'paid',
          driverEarning: '89.30'));
      rig.repo.profileValue = fakeProfile();
      rig.repo.tripsById[done.id] = done;
      await rig.cubit.load();
      await tester.pumpWidget(rig.app(DriverRoutes.trip(done.id)));
      await tester.pumpAndSettle();

      expect(find.text('You earned'), findsOneWidget);
      expect(find.text('₹89.30'), findsOneWidget);
    });

    rigTest('is celebrated when the delivery is completed',
        (tester, rig) async {
      tester.view.physicalSize = const Size(1080, 3000);
      rig.repo.profileValue = fakeProfile(online: true);
      final trip = fakeTrip(
          status: 'in_progress', paymentMode: 'prepaid', paymentStatus: 'paid');
      rig.repo.activeTripValue = trip;
      rig.repo.tripsById[trip.id] = trip;
      rig.repo.actionResult = (
        Trip.fromJson(tripJson(
            status: 'completed',
            paymentMode: 'prepaid',
            paymentStatus: 'paid',
            driverEarning: '89.30')),
        null
      );
      await rig.cubit.load();
      await tester.pumpWidget(rig.app(DriverRoutes.trip(trip.id)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete delivery'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Complete')));
      await tester.pumpAndSettle();

      expect(
          find.descendant(
              of: find.byKey(const Key('completed_earning')),
              matching: find.text('You earned ₹89.30')),
          findsOneWidget);
    });
  });
}
