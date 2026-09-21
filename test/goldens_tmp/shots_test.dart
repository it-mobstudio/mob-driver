// Temporary: renders the item screens to PNGs so the design can be judged by eye.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/harness.dart';

List<Map<String, dynamic>> mixed() => [
      itemJson(id: 'a', name: 'Cement bag 50 kg', quantity: 4, unit: 'bags', status: 'delivered'),
      itemJson(id: 'b', name: 'TMT bar 12 mm', quantity: 20, unit: 'pcs', status: 'not_delivered', note: 'Damaged in transit'),
      itemJson(id: 'c', name: 'Wall putty 20 kg', quantity: 2, unit: 'bags'),
      itemJson(id: 'd', name: 'PVC pipe 1 inch', quantity: 12, unit: 'pcs'),
    ];

List<Map<String, dynamic>> fresh() => [
      itemJson(id: 'a', name: 'Cement bag 50 kg', quantity: 4, unit: 'bags'),
      itemJson(id: 'b', name: 'TMT bar 12 mm', quantity: 20, unit: 'pcs'),
      itemJson(id: 'c', name: 'Wall putty 20 kg', quantity: 2, unit: 'bags'),
    ];

void main() {
  setUpAll(loadAppFonts);

  Future<void> shot(WidgetTester tester, TestRig rig, String route, List<Map<String, dynamic>> items, String file) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    rig.repo.profileValue = fakeProfile(online: true);
    final trip = rig.repo.startItemTrip(items, invoiceUrl: 'https://x/INV-1001.pdf', invoiceNumber: 'INV-1001');
    await rig.cubit.load();
    await tester.pumpWidget(rig.app(route == 'items' ? DriverRoutes.items(trip.id) : DriverRoutes.trip(trip.id)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('$file.png'));
  }

  rigTest('checklist: fresh', (t, rig) => shot(t, rig, 'items', fresh(), 'items_fresh'));
  rigTest('checklist: mixed', (t, rig) => shot(t, rig, 'items', mixed(), 'items_mixed'));
  rigTest('trip panel with items', (t, rig) => shot(t, rig, 'trip', mixed(), 'trip_panel'));
}
