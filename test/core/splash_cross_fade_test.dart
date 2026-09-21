import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/app_runtime/splash_cross_fade.dart';

/// Regression: the cross-fade lives above every MaterialApp, so it is built
/// with NO Directionality ancestor. It once used a Stack with the default
/// directional alignment and threw "No Directionality widget found" every frame
/// — a blank/red screen at launch. `pumpWidget` here gives it exactly that
/// environment (a bare root), unlike the page tests which sit inside a
/// MaterialApp and could never notice.
void main() {
  const splash = ColoredBox(key: Key('splash-layer'), color: Colors.blue);
  const app = ColoredBox(key: Key('app-layer'), color: Colors.red);

  testWidgets('builds with no Directionality above it, on the splash', (tester) async {
    await tester.pumpWidget(const SplashCrossFade(ready: false, splash: splash, app: app));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('splash-layer')), findsOneWidget);
    expect(find.byKey(const Key('app-layer')), findsNothing);
  });

  testWidgets('cross-fades to the app: both present mid-fade, only the app after', (tester) async {
    await tester.pumpWidget(const SplashCrossFade(ready: false, splash: splash, app: app));
    await tester.pumpWidget(const SplashCrossFade(ready: true, splash: splash, app: app));
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('splash-layer')), findsOneWidget, reason: 'still fading out');
    expect(find.byKey(const Key('app-layer')), findsOneWidget, reason: 'already fading in');

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('splash-layer')), findsNothing);
    expect(find.byKey(const Key('app-layer')), findsOneWidget);
  });

  testWidgets('the outgoing and incoming layers fill the screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SplashCrossFade(ready: true, splash: splash, app: app));
    expect(tester.getSize(find.byKey(const Key('app-layer'))), const Size(360, 780));
  });
}
