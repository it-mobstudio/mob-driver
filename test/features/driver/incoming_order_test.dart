import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

const tripId = '604807b6-7053-4f5f-bf99-163eb9620dc3';

Future<void> openOffer(WidgetTester tester, TestRig rig, Trip trip) async {
  rig.repo.profileValue = fakeProfile(online: true);
  rig.repo.activeTripValue = trip;
  rig.repo.tripsById[trip.id] = trip;
  await rig.cubit.load();
  await tester.pumpWidget(rig.app('/driver/trip/${trip.id}/offer'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  rigTest('shows the total, the fare split, and both stops', (tester, rig) async {
    await openOffer(tester, rig, fakeTrip(bonusFare: '100.00'));

    expect(tester.widget<Text>(find.byKey(const Key('offer_total'))).data, '₹211.62');
    expect(find.textContaining('MG Road Metro, Bengaluru'), findsOneWidget);
    expect(find.textContaining('Indiranagar 100ft Rd, Bengaluru'), findsOneWidget);
    expect(find.text('PICKUP'), findsOneWidget);
    expect(find.text('DROP'), findsOneWidget);
    expect(find.byKey(const Key('fare_bonus')), findsOneWidget);
  });

  rigTest('no bonus means a single fare chip and the total is just the fare', (tester, rig) async {
    await openOffer(tester, rig, fakeTrip());

    expect(tester.widget<Text>(find.byKey(const Key('offer_total'))).data, '₹111.62');
    expect(find.byKey(const Key('fare_bonus')), findsNothing);
  });

  rigTest('accepting opens the trip screen', (tester, rig) async {
    await openOffer(tester, rig, fakeTrip());

    await tester.tap(find.byKey(const Key('offer_accept')));
    await tester.pump();
    expect(find.text('Reached pickup'), findsNothing, reason: 'a tap alone does not accept');

    expect(rig.alert.ringing, isTrue, reason: 'rings and vibrates until answered');
    await swipe(tester, 'Accept order');
    expect(find.text('Reached pickup'), findsOneWidget);
    expect(rig.alert.ringing, isFalse);
  });

  rigTest('rejecting cancels the trip and returns to the dashboard', (tester, rig) async {
    rig.repo.actionResult = (fakeTrip(status: 'cancelled'), null);
    await openOffer(tester, rig, fakeTrip());

    await tester.tap(find.byKey(const Key('offer_reject')));
    await tester.pumpAndSettle();

    expect(rig.repo.calls, contains('cancel[Rejected by driver]:$tripId'));
    expect(rig.alert.ringing, isFalse);
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  rigTest('the countdown running out declines it on its own', (tester, rig) async {
    rig.repo.actionResult = (fakeTrip(status: 'cancelled'), null);
    await openOffer(tester, rig, fakeTrip());

    expect(tester.widget<Text>(find.byKey(const Key('swipe_trailing'))).data, '30s');
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();

    expect(rig.repo.calls, contains('cancel[No response from driver]:$tripId'));
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  rigTest('view order details opens the full order details page', (tester, rig) async {
    await openOffer(tester, rig, fakeTrip());

    await tester.tap(find.byKey(const Key('offer_view_details')));
    await tester.pumpAndSettle();

    expect(find.text('Order details'), findsOneWidget);
    expect(find.textContaining('MG Road Metro, Bengaluru'), findsOneWidget);
  });
}
