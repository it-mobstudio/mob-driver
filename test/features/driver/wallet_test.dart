import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/wallet_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

WalletSummary summary({double balance = 260, WalletPeriod today = const WalletPeriod(earnings: 150, trips: 1)}) {
  final now = DateTime.now();
  return WalletSummary(
    balance: balance,
    today: today,
    week: const WalletPeriod(earnings: 275, trips: 4),
    month: const WalletPeriod(earnings: 295, trips: 5),
    lifetime: const WalletPeriod(earnings: 305, trips: 6),
    lifetimePayouts: 40,
    last7Days: [
      for (var i = 6; i >= 0; i--)
        DayEarning(
          date: DateTime(now.year, now.month, now.day).subtract(Duration(days: i)),
          earnings: switch (i) { 0 => 150.0, 1 => 95.0, 3 => 20.0, _ => 0.0 },
          trips: i == 0 ? 1 : 0,
        ),
    ],
  );
}

WalletEntry entry(
  String id,
  WalletKind kind,
  double amount, {
  DateTime? at,
  String? description,
  String? reference,
  double balanceAfter = 100,
}) =>
    WalletEntry(
      id: id,
      kind: kind,
      amount: amount,
      balanceAfter: balanceAfter,
      description: description,
      reference: reference,
      createdAt: at ?? DateTime.now(),
    );

Future<void> openWallet(
  WidgetTester tester,
  TestRig rig, {
  WalletSummary? wallet,
  List<WalletEntry> entries = const [],
  DriverProfile? profile,
}) async {
  tester.view.physicalSize = const Size(1080, 3600);
  rig.repo.walletValue = wallet ?? summary();
  rig.repo.walletEntriesValue = entries;
  rig.repo.profileValue = profile ?? fakeProfile();
  await rig.cubit.load();
  await tester.pumpWidget(rig.host(
    const DriverWalletPage(),
    routes: [GoRoute(path: DriverRoutes.payout, builder: (_, __) => const Scaffold(body: Text('PAYOUT PAGE')))],
  ));
  await tester.pumpAndSettle();
}

String textOf(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  setUpAll(loadAppFonts);

  group('the overview', () {
    rigTest('leads with the balance and what was earned today', (tester, rig) async {
      await openWallet(tester, rig);

      expect(textOf(tester, 'wallet_balance'), '₹260.00');
      expect(textOf(tester, 'wallet_today'), '₹150.00');
      expect(find.text('Wallet balance'), findsOneWidget);
      expect(find.text('Earned today'), findsOneWidget);
      expect(find.text('1 trip'), findsWidgets, reason: 'singular for one');
    });

    rigTest('shows this week, this month and all time with their trip counts', (tester, rig) async {
      await openWallet(tester, rig);

      expect(textOf(tester, 'wallet_week'), '₹275.00');
      expect(textOf(tester, 'wallet_month'), '₹295.00');
      expect(textOf(tester, 'wallet_lifetime'), '₹305.00');
      expect(find.text('4 trips'), findsOneWidget);
      expect(find.text('5 trips'), findsOneWidget);
      expect(find.text('6 trips'), findsOneWidget);
    });

    rigTest('says how much has been paid out so far — only once something has', (tester, rig) async {
      await openWallet(tester, rig);
      expect(textOf(tester, 'wallet_payouts'), 'Paid out so far: ₹40.00');
    });

    rigTest('a wallet with no payouts yet does not mention them', (tester, rig) async {
      await openWallet(tester, rig, wallet: const WalletSummary(balance: 10));
      expect(find.byKey(const Key('wallet_payouts')), findsNothing);
    });

    rigTest('the last seven days are charted, each earning day labelled', (tester, rig) async {
      await openWallet(tester, rig);

      expect(find.byKey(const Key('wallet_chart')), findsOneWidget);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('₹150'), findsOneWidget);
      expect(find.text('₹95'), findsOneWidget);
      expect(find.text('₹20'), findsOneWidget);
      // Seven weekday initials sit under the bars.
      final chart = find.byKey(const Key('wallet_chart'));
      final initials = find.descendant(of: chart, matching: find.byType(Text));
      expect(initials, findsWidgets);
    });

    rigTest('a brand-new wallet is all zeroes, not blank', (tester, rig) async {
      await openWallet(tester, rig, wallet: const WalletSummary());
      expect(textOf(tester, 'wallet_balance'), '₹0.00');
      expect(textOf(tester, 'wallet_today'), '₹0.00');
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    rigTest('an unreachable backend offers a retry that recovers', (tester, rig) async {
      rig.repo.walletFailure = const NetworkFailure();
      await openWallet(tester, rig);
      expect(find.text('Couldn’t load your wallet'), findsOneWidget);

      rig.repo.walletFailure = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'wallet_balance'), '₹260.00');
    });
  });

  group('the statement', () {
    rigTest('rows are grouped by day, with direction, kind and running balance', (tester, rig) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      await openWallet(tester, rig, entries: [
        entry('a', WalletKind.tripEarning, 68, description: 'Delivery to Indiranagar', balanceAfter: 260),
        entry('b', WalletKind.payout, -40, reference: 'UTR998877', balanceAfter: 192, at: now.subtract(const Duration(minutes: 5))),
        entry('c', WalletKind.bonus, 25, at: yesterday, balanceAfter: 232),
        entry('d', WalletKind.penalty, -10, at: yesterday, balanceAfter: 207),
      ]);

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(textOf(tester, 'wallet_amount_a'), '+₹68.00');
      expect(textOf(tester, 'wallet_amount_b'), '−₹40.00');
      expect(textOf(tester, 'wallet_amount_c'), '+₹25.00');
      expect(textOf(tester, 'wallet_amount_d'), '−₹10.00');
      expect(find.text('Delivery to Indiranagar'), findsOneWidget);
      expect(find.textContaining('Ref UTR998877'), findsOneWidget);
      expect(find.text('Bal ₹260.00'), findsOneWidget);
    });

    rigTest('money in is green and money out is red', (tester, rig) async {
      await openWallet(tester, rig, entries: [
        entry('a', WalletKind.tripEarning, 68),
        entry('b', WalletKind.payout, -40),
      ]);

      Color colour(String id) => tester.widget<Text>(find.byKey(Key('wallet_amount_$id'))).style!.color!;
      expect(colour('a'), const Color(0xFF16A36A));
      expect(colour('b'), const Color(0xFFD94D3D));
    });

    rigTest('the filter chips ask the backend for just those kinds', (tester, rig) async {
      await openWallet(tester, rig, entries: [
        entry('a', WalletKind.tripEarning, 68),
        entry('b', WalletKind.bonus, 25),
        entry('c', WalletKind.payout, -40),
      ]);
      expect(rig.repo.walletEntryCalls.last, '1:');

      await tester.tap(find.byKey(const Key('wallet_filter_earnings')));
      await tester.pumpAndSettle();
      expect(rig.repo.walletEntryCalls.last, '1:trip_earning,bonus');
      expect(find.byKey(const Key('wallet_entry_a')), findsOneWidget);
      expect(find.byKey(const Key('wallet_entry_b')), findsOneWidget);
      expect(find.byKey(const Key('wallet_entry_c')), findsNothing);

      await tester.tap(find.byKey(const Key('wallet_filter_payouts')));
      await tester.pumpAndSettle();
      expect(rig.repo.walletEntryCalls.last, '1:payout');
      expect(find.byKey(const Key('wallet_entry_c')), findsOneWidget);
      expect(find.byKey(const Key('wallet_entry_a')), findsNothing);

      await tester.tap(find.byKey(const Key('wallet_filter_all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wallet_entry_a')), findsOneWidget);
      expect(find.byKey(const Key('wallet_entry_c')), findsOneWidget);
    });

    rigTest('more rows load as the driver scrolls to the end', (tester, rig) async {
      rig.repo.walletEntryPageSize = 10;
      await openWallet(tester, rig, entries: [
        for (var i = 0; i < 25; i++) entry('e$i', WalletKind.tripEarning, 10.0 + i, at: DateTime.now().subtract(Duration(minutes: i))),
      ]);
      expect(rig.repo.walletEntryCalls, ['1:']);

      await tester.scrollUntilVisible(find.byKey(const Key('wallet_entry_e24')), 400, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(rig.repo.walletEntryCalls, ['1:', '2:', '3:']);
      expect(find.byKey(const Key('wallet_entry_e24')), findsOneWidget);
    });

    rigTest('an empty statement says what will appear', (tester, rig) async {
      await openWallet(tester, rig);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.textContaining('after each delivery'), findsOneWidget);
    });

    rigTest('pulling down refreshes both the numbers and the statement', (tester, rig) async {
      await openWallet(tester, rig, entries: [entry('a', WalletKind.tripEarning, 68)]);
      final before = rig.repo.calls.where((c) => c == 'wallet').length;

      rig.repo.walletValue = summary(balance: 999);
      rig.repo.walletEntriesValue = [entry('a', WalletKind.tripEarning, 68), entry('z', WalletKind.bonus, 100)];
      await tester.fling(find.byType(Scrollable).first, const Offset(0, 500), 1000);
      await tester.pumpAndSettle();

      expect(rig.repo.calls.where((c) => c == 'wallet').length, before + 1);
      expect(textOf(tester, 'wallet_balance'), '₹999.00');
      expect(find.byKey(const Key('wallet_entry_z')), findsOneWidget);
    });

    rigTest('finishing a trip elsewhere in the app refreshes the wallet on its own', (tester, rig) async {
      await openWallet(tester, rig);
      expect(textOf(tester, 'wallet_balance'), '₹260.00');

      // The session refreshes its stats when a trip completes; that's the cue.
      rig.repo.walletValue = summary(balance: 348.5);
      rig.repo.statsValue = const DriverStats(allTime: PeriodStats(tripsCompleted: 7));
      await rig.cubit.load(silent: true);
      await tester.pumpAndSettle();

      expect(textOf(tester, 'wallet_balance'), '₹348.50');
    });
  });

  group('where payouts go', () {
    rigTest('no payout details yet: a prompt that opens the form', (tester, rig) async {
      await openWallet(tester, rig);

      expect(find.byKey(const Key('wallet_payout_prompt')), findsOneWidget);
      await tester.tap(find.byKey(const Key('wallet_add_payout')));
      await tester.pumpAndSettle();
      expect(find.text('PAYOUT PAGE'), findsOneWidget);
    });

    rigTest('with a UPI id saved, it says where payouts go and offers to change it', (tester, rig) async {
      await openWallet(
        tester,
        rig,
        profile: DriverProfile.fromJson(profileJson(payout: {'upi_id': 'ravi@okhdfc', 'is_set': true})),
      );

      expect(find.byKey(const Key('wallet_payout_prompt')), findsNothing);
      expect(find.text('Payouts go to ravi@okhdfc'), findsOneWidget);

      await tester.tap(find.byKey(const Key('wallet_payout_set')));
      await tester.pumpAndSettle();
      expect(find.text('PAYOUT PAGE'), findsOneWidget);
    });

    rigTest('a bank account is shown masked', (tester, rig) async {
      await openWallet(
        tester,
        rig,
        profile: DriverProfile.fromJson(profileJson(payout: {
          'bank_account_holder': 'Ravi Kumar',
          'bank_account_last4': '9012',
          'bank_ifsc': 'HDFC0001234',
          'is_set': true,
        })),
      );
      expect(find.text('Payouts go to HDFC0001234 · ••••9012'), findsOneWidget);
    });
  });
}
