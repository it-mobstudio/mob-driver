import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/dashboard_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/edit_profile_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/payout_details_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/profile_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/trips_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';

/// Stand-ins for the screens a page navigates to, so a tap is observable.
List<GoRoute> stubRoutes() => [
      for (final path in [DriverRoutes.editProfile, DriverRoutes.verification, DriverRoutes.payout])
        GoRoute(path: path, builder: (_, __) => Scaffold(body: Text('STUB $path'))),
    ];

/// Once the session ends the screen falls back to its loading skeleton (in the
/// app the sign-out sends the driver to login at that moment). The skeleton
/// shimmers forever, so `pumpAndSettle` can't be used; a few frames will do.
Future<void> settleAfterSessionEnds(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String textOf(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

TextField fieldOf(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)));

Future<void> open(WidgetTester tester, TestRig rig, Widget page, {DriverProfile? profile, double height = 3200}) async {
  tester.view.physicalSize = Size(1080, height);
  rig.repo.profileValue = profile ?? fakeProfile();
  await rig.cubit.load();
  await tester.pumpWidget(rig.host(page, routes: stubRoutes()));
  await tester.pumpAndSettle();
}

DriverProfile withPayout(Map<String, dynamic> payout, {bool eligible = true}) =>
    DriverProfile.fromJson(profileJson(eligible: eligible, payout: payout));

void main() {
  setUpAll(loadAppFonts);

  group('profile', () {
    rigTest('leads with who the driver is and the things they can change', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage());

      expect(textOf(tester, 'profile_name'), 'Seed Driver 1');
      for (final row in ['menu_edit_details', 'menu_documents', 'menu_payout']) {
        expect(find.byKey(Key(row)), findsOneWidget, reason: row);
      }
      expect(find.text('Add a UPI id or bank account'), findsOneWidget);
    });

    rigTest('the payout row says where earnings go once that is set', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage(), profile: withPayout({'upi_id': 'ravi@okhdfc', 'is_set': true}));
      expect(find.text('ravi@okhdfc'), findsOneWidget);
    });

    rigTest('each row opens its screen', (tester, rig) async {
      for (final (row, path) in [
        ('menu_edit_details', DriverRoutes.editProfile),
        ('menu_documents', DriverRoutes.verification),
        ('menu_payout', DriverRoutes.payout),
      ]) {
        await open(tester, rig, const DriverProfilePage());
        await tester.tap(find.byKey(Key(row)));
        await tester.pumpAndSettle();
        expect(find.text('STUB $path'), findsOneWidget, reason: row);
      }
    });

    rigTest('the verification summary opens the documents page', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage());
      await tester.tap(find.text('Aadhaar'));
      await tester.pumpAndSettle();
      expect(find.text('STUB ${DriverRoutes.verification}'), findsOneWidget);
    });

    rigTest('the photo, when there is one, replaces the initial', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage(), profile: DriverProfile.fromJson({...profileJson(), 'profile_photo_url': 'https://cdn.example.com/me.jpg'}));
      expect(find.byType(Image), findsWidgets);
    });
  });

  group('deleting the account', () {
    Future<void> tapDelete(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('delete_account')));
      await tester.tap(find.byKey(const Key('delete_account')));
      await tester.pumpAndSettle();
    }

    rigTest('asks first, and "Keep my account" changes nothing', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage());
      await tapDelete(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('active trip or money left in your wallet'), findsOneWidget);
      await tester.tap(find.text('Keep my account'));
      await tester.pumpAndSettle();

      expect(rig.repo.deleteAccountCalls, 0);
      expect(rig.authRepo.signOutCalls, 0);
    });

    rigTest('confirming deletes the account and signs the driver out', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage());
      await tapDelete(tester);
      await tester.tap(find.byKey(const Key('delete_account_confirm')));
      await settleAfterSessionEnds(tester);

      expect(rig.repo.deleteAccountCalls, 1);
      expect(rig.authRepo.signOutCalls, 1);
      expect(rig.cubit.state.profile, isNull, reason: 'the session forgot the driver');
    });

    rigTest('a refusal (money still owed) is explained and the driver stays signed in', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage());
      rig.repo.deleteAccountFailure = const BusinessFailure('You still have ₹150.00 in your wallet. Ask your company to pay it out first.', code: 'WALLET_BALANCE_PENDING');

      await tapDelete(tester);
      await tester.tap(find.byKey(const Key('delete_account_confirm')));
      await tester.pumpAndSettle();

      expect(find.textContaining('You still have ₹150.00'), findsOneWidget);
      expect(rig.authRepo.signOutCalls, 0);
      expect(rig.cubit.state.profile, isNotNull);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a driver who is on duty is taken off it first', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage(), profile: fakeProfile(online: true));
      await tapDelete(tester);
      await tester.tap(find.byKey(const Key('delete_account_confirm')));
      await settleAfterSessionEnds(tester);

      expect(rig.repo.calls, contains('endDuty'));
      expect(rig.repo.deleteAccountCalls, 1);
    });

    rigTest('and if going off duty is refused, nothing is deleted', (tester, rig) async {
      await open(tester, rig, const DriverProfilePage(), profile: fakeProfile(online: true));
      rig.repo.endDutyFailure = const BusinessFailure('This driver has an active trip.', code: 'DRIVER_HAS_ACTIVE_TRIP');

      await tapDelete(tester);
      await tester.tap(find.byKey(const Key('delete_account_confirm')));
      await tester.pumpAndSettle();

      expect(rig.repo.deleteAccountCalls, 0);
      expect(find.textContaining('active trip'), findsWidgets);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('payout details', () {
    rigTest('UPI: a malformed id is refused, a good one is saved', (tester, rig) async {
      await open(tester, rig, const PayoutDetailsPage());
      expect(find.byKey(const Key('field_upi')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field_upi')), 'not-a-upi-id');
      await tester.tap(find.byKey(const Key('payout_save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid UPI id, like name@bank.'), findsOneWidget);
      expect(rig.repo.profileUpdates, isEmpty);

      await tester.enterText(find.byKey(const Key('field_upi')), ' ravi@okhdfc ');
      await tester.tap(find.byKey(const Key('payout_save')));
      await tester.pumpAndSettle();

      expect(rig.repo.profileUpdates.single.payoutUpiId, 'ravi@okhdfc');
      expect(rig.repo.profileUpdates.single.bankAccountNumber, isNull, reason: 'only the chosen method is sent');
      expect(find.text('Payout details saved.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('bank: holder, account and IFSC are all needed, IFSC is upper-cased', (tester, rig) async {
      await open(tester, rig, const PayoutDetailsPage());
      await tester.tap(find.text('Bank account'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('payout_save')));
      await tester.pumpAndSettle();
      expect(find.text('Enter the account holder’s name.'), findsOneWidget);
      expect(find.text('Enter the account number (9–18 digits).'), findsOneWidget);
      expect(find.text('Enter a valid IFSC code, like HDFC0001234.'), findsOneWidget);
      expect(rig.repo.profileUpdates, isEmpty);

      await tester.enterText(find.byKey(const Key('field_bank_holder')), 'Ravi Kumar');
      await tester.enterText(find.byKey(const Key('field_bank_account')), '12a34-5678 9012');
      await tester.enterText(find.byKey(const Key('field_bank_ifsc')), 'hdfc0001234');
      await tester.tap(find.byKey(const Key('payout_save')));
      await tester.pumpAndSettle();

      final sent = rig.repo.profileUpdates.single;
      expect(sent.bankAccountHolder, 'Ravi Kumar');
      expect(sent.bankAccountNumber, '123456789012', reason: 'digits only');
      expect(sent.bankIfsc, 'HDFC0001234');
      expect(sent.payoutUpiId, isNull);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a saved UPI id is shown and filled in', (tester, rig) async {
      await open(tester, rig, const PayoutDetailsPage(), profile: withPayout({'upi_id': 'ravi@okhdfc', 'is_set': true}));

      expect(find.textContaining('Currently: ravi@okhdfc'), findsOneWidget);
      expect(fieldOf(tester, 'field_upi').controller!.text, 'ravi@okhdfc');
    });

    rigTest('a saved bank account opens on Bank, never shows the number, and can be kept as it is', (tester, rig) async {
      await open(
        tester,
        rig,
        const PayoutDetailsPage(),
        profile: withPayout({'bank_account_holder': 'Ravi Kumar', 'bank_account_last4': '9012', 'bank_ifsc': 'HDFC0001234', 'is_set': true}),
      );

      expect(fieldOf(tester, 'field_bank_holder').controller!.text, 'Ravi Kumar');
      expect(fieldOf(tester, 'field_bank_ifsc').controller!.text, 'HDFC0001234');
      expect(fieldOf(tester, 'field_bank_account').controller!.text, isEmpty, reason: 'the full number is never sent to the phone');
      expect(find.text('Saved account ends 9012. Leave blank to keep it.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('payout_save')));
      await tester.pumpAndSettle();

      expect(rig.repo.profileUpdates.single.bankAccountNumber, isNull, reason: 'blank means keep');
      expect(rig.repo.profileUpdates.single.bankIfsc, 'HDFC0001234');
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('the backend\'s objection is shown on the page', (tester, rig) async {
      await open(tester, rig, const PayoutDetailsPage());
      rig.repo.profileChangeFailure = const BusinessFailure('Enter a valid UPI id, like name@bank.', code: 'VALIDATION_ERROR');

      await tester.enterText(find.byKey(const Key('field_upi')), 'ravi@okhdfc');
      await tester.tap(find.byKey(const Key('payout_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payout_error')), findsOneWidget);
    });
  });

  group('edit details', () {
    rigTest('is filled in with what the driver gave', (tester, rig) async {
      final profile = DriverProfile.fromJson({
        ...profileJson(eligible: false, onboarding: 'under_review'),
        'aadhar_status': 'pending',
        'city': 'Bengaluru',
        'email': 'ravi@example.com',
      });
      await open(tester, rig, const EditProfilePage(), profile: profile);

      expect(fieldOf(tester, 'field_full_name').controller!.text, 'Seed Driver 1');
      expect(fieldOf(tester, 'field_city').controller!.text, 'Bengaluru');
      expect(fieldOf(tester, 'field_email').controller!.text, 'ravi@example.com');
      expect(fieldOf(tester, 'field_emergency_phone').controller!.text, '9999900000');
      expect(fieldOf(tester, 'field_full_name').enabled, isTrue);
    });

    rigTest('changes are saved', (tester, rig) async {
      await open(tester, rig, const EditProfilePage(), profile: DriverProfile.fromJson({...profileJson(eligible: false), 'aadhar_status': 'pending'}));

      await tester.enterText(find.byKey(const Key('field_city')), 'Mysuru');
      await tester.ensureVisible(find.byKey(const Key('details_submit')));
      await tester.tap(find.byKey(const Key('details_submit')));
      await tester.pumpAndSettle();

      expect(rig.repo.profileUpdates.single.city, 'Mysuru');
      expect(find.text('Details saved.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('name and date of birth are locked once the ID is verified — and not sent', (tester, rig) async {
      await open(tester, rig, const EditProfilePage()); // fakeProfile(): Aadhaar verified

      expect(fieldOf(tester, 'field_full_name').enabled, isFalse);
      expect(find.textContaining('match your verified ID'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field_city')), 'Mysuru');
      await tester.ensureVisible(find.byKey(const Key('details_submit')));
      await tester.tap(find.byKey(const Key('details_submit')));
      await tester.pumpAndSettle();

      final sent = rig.repo.profileUpdates.single;
      expect((sent.fullName, sent.dateOfBirth), (null, null));
      expect(sent.city, 'Mysuru');
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('the dashboard while waiting on the company', () {
    Future<void> openDashboard(WidgetTester tester, TestRig rig, DriverProfile profile) => open(
          tester,
          rig,
          DriverDashboardPage(checkLocationPermission: (_) async => true, mapBuilder: stubHomeMap),
          profile: profile,
        );

    rigTest('under review: says so, wears the right badge, and opens the documents', (tester, rig) async {
      await openDashboard(tester, rig, DriverProfile.fromJson(profileJson(eligible: false, onboarding: 'under_review')));

      expect(find.text('Your documents are being reviewed'), findsOneWidget);
      expect(textOf(tester, 'verification_action'), 'View documents');

      await tester.tap(find.byKey(const Key('profile_button')));
      await tester.pumpAndSettle();
      expect(find.text('UNDER REVIEW'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('verification_card')));
      await tester.pumpAndSettle();
      expect(find.text('STUB ${DriverRoutes.verification}'), findsOneWidget);
    });

    rigTest('an approved driver sees no verification card', (tester, rig) async {
      await openDashboard(tester, rig, fakeProfile());
      expect(find.byKey(const Key('verification_card')), findsNothing);

      await tester.tap(find.byKey(const Key('profile_button')));
      await tester.pumpAndSettle();
      expect(find.text('VERIFIED DRIVER'), findsOneWidget);
    });

    rigTest('a licence close to expiry gets a warning; one far off does not', (tester, rig) async {
      String iso(int days) => formatIsoDate(DateTime.now().add(Duration(days: days)));
      DriverProfile expiring(int days) => DriverProfile.fromJson({...profileJson(), 'dl_expiry_date': iso(days)});

      await openDashboard(tester, rig, expiring(10));
      expect(find.byKey(const Key('licence_banner')), findsOneWidget);
      expect(find.textContaining('expires in 10 days'), findsOneWidget);

      await openDashboard(tester, rig, expiring(45));
      expect(find.byKey(const Key('licence_banner')), findsNothing);

      await openDashboard(tester, rig, expiring(0));
      expect(find.textContaining('expires today'), findsOneWidget);

      await openDashboard(tester, rig, expiring(1));
      expect(find.textContaining('expires in 1 day.'), findsOneWidget, reason: 'singular');
    });

    rigTest('today\'s earnings lead the numbers', (tester, rig) async {
      rig.repo.statsValue = const DriverStats(today: PeriodStats(tripsCompleted: 3, earnings: 240.5, totalFare: 300));
      await openDashboard(tester, rig, fakeProfile());
      // Stats live in the sheet the "Today's earnings" banner opens.
      await tester.tap(find.byKey(const Key('summary_banner')));
      await tester.pumpAndSettle();
      expect(textOf(tester, 'stat_earnings'), '₹240.50');
      expect(find.text('You earned'), findsOneWidget);
    });
  });

  group('trip history', () {
    rigTest('each completed trip says what it paid the driver', (tester, rig) async {
      final paid = Trip.fromJson(tripJson(id: 'trip-paid', status: 'completed', driverEarning: '89.30'));
      final cancelled = Trip.fromJson(tripJson(id: 'trip-cancelled', status: 'cancelled'));
      rig.repo.tripsById
        ..[paid.id] = paid
        ..[cancelled.id] = cancelled;
      await open(tester, rig, const DriverTripsPage());

      expect(textOf(tester, 'trip_earning_trip-paid'), 'You earned ₹89.30');
      expect(find.byKey(const Key('trip_earning_trip-cancelled')), findsNothing);
    });
  });
}
