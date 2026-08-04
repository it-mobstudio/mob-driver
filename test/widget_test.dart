import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/driver_app.dart';

void main() {
  testWidgets('driver dashboard renders tracking and active trip',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DriverDashboardPage()),
    );

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Start duty'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
  });
}
