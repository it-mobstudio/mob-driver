import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/onboarding_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/verification_page.dart';
import 'package:m_o_b_demand_side/shared/scaffold_with_nav_bar.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';
import 'onboarding_entities_test.dart' show kycJson;

DriverProfile newDriver({
  String status = 'profile_incomplete',
  Map<String, dynamic>? kyc,
  Map<String, dynamic> extra = const {},
}) =>
    DriverProfile.fromJson({
      ...profileJson(
        eligible: false,
        onboarding: status,
        fullName: status == 'profile_incomplete' ? '' : 'Ravi Kumar',
        profileComplete: status != 'profile_incomplete',
        kyc: kyc,
      ),
      // Nobody has been named yet for a driver who has only just signed up.
      if (status == 'profile_incomplete') ...{
        'emergency_contact_name': '',
        'emergency_contact_phone': '',
      },
      // A driver still going through onboarding has nothing verified yet (the
      // base fixture is a fully-verified driver).
      'aadhar_status': 'pending',
      'dl_status': 'pending',
      'police_status': 'pending',
      ...extra,
    });

Future<void> openOnboarding(WidgetTester tester, TestRig rig, DriverProfile profile) async {
  // Tall enough that the whole form is built — a lazy list would leave the
  // lower fields un-findable.
  tester.view.physicalSize = const Size(1080, 4200);
  rig.repo.profileValue = profile;
  await rig.cubit.load();
  await tester.pumpWidget(rig.host(OnboardingPage(capture: rig.capture)));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Photographs whatever tile is tapped, via the source chooser's camera option.
Future<void> takeDocumentPhoto(WidgetTester tester, String tileKey) async {
  await tester.tap(find.byKey(Key(tileKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('photo_source_camera')));
  await tester.pumpAndSettle();
}

bool enabled(WidgetTester tester, String buttonKey) => tester
        .widget<ElevatedButton>(find.descendant(of: find.byKey(Key(buttonKey)), matching: find.byType(ElevatedButton)))
        .onPressed !=
    null;

String textOf(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  setUpAll(loadAppFonts);

  group('step 1: about you', () {
    rigTest('a brand-new driver starts with the details form, not the app', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());

      expect(find.text('Tell us about yourself'), findsOneWidget);
      expect(textOf(tester, 'onboarding_step'), 'Step 1 of 2');
      expect(find.byKey(const Key('field_full_name')), findsOneWidget);
      expect(find.byKey(const Key('field_emergency_phone')), findsOneWidget);
    });

    rigTest('submitting an empty form explains what is missing and sends nothing', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());

      await tapKey(tester, 'details_submit');

      expect(find.text('Enter your full name as on your licence.'), findsOneWidget);
      expect(find.text('Select your date of birth.'), findsOneWidget);
      expect(find.text('Enter a name.'), findsOneWidget);
      expect(find.text('Enter a 10-digit number.'), findsOneWidget);
      expect(rig.repo.profileUpdates, isEmpty);
    });

    rigTest('an error clears the moment it is fixed', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());
      await tapKey(tester, 'details_submit');
      expect(find.text('Enter your full name as on your licence.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('field_full_name')), 'Ravi Kumar');
      await tester.pump();

      expect(find.text('Enter your full name as on your licence.'), findsNothing);
    });

    rigTest('the driver\'s own number cannot be their emergency contact', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());
      await tester.enterText(find.byKey(const Key('field_emergency_phone')), '9000000000'); // +919000000000 is theirs
      await tapKey(tester, 'details_submit');

      expect(find.textContaining('Use someone else'), findsOneWidget);
    });

    rigTest('malformed optional fields are caught too', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());
      await tester.enterText(find.byKey(const Key('field_email')), 'not-an-email');
      await tester.enterText(find.byKey(const Key('field_pincode')), '5600');
      await tapKey(tester, 'details_submit');

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter a 6-digit pincode.'), findsOneWidget);
    });

    rigTest('the phone and pincode fields only take digits', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());
      await tester.enterText(find.byKey(const Key('field_emergency_phone')), '95a5-5 500002xyz');
      await tester.enterText(find.byKey(const Key('field_pincode')), '56-00 01x');
      await tester.pump();

      expect(tester.widget<TextField>(find.descendant(of: find.byKey(const Key('field_emergency_phone')), matching: find.byType(TextField))).controller!.text, '9555500002');
      expect(tester.widget<TextField>(find.descendant(of: find.byKey(const Key('field_pincode')), matching: find.byType(TextField))).controller!.text, '560001');
    });

    rigTest('a filled-in form is saved as entered and moves on to documents', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());
      rig.repo.profileChangeResult = newDriver(status: 'documents_required');

      await tester.enterText(find.byKey(const Key('field_full_name')), '  Ravi Kumar ');
      await tapKey(tester, 'field_dob');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field_city')), 'Bengaluru');
      await tester.enterText(find.byKey(const Key('field_emergency_name')), 'Sunita Kumar');
      await tester.enterText(find.byKey(const Key('field_emergency_phone')), '9555500002');
      await tapKey(tester, 'details_submit');

      final sent = rig.repo.profileUpdates.single;
      expect(sent.fullName, 'Ravi Kumar', reason: 'trimmed');
      expect(sent.city, 'Bengaluru');
      expect(sent.emergencyContactName, 'Sunita Kumar');
      expect(sent.emergencyContactPhone, '+919555500002', reason: 'the +91 is built into the field');
      final age = DateTime.now().difference(sent.dateOfBirth!).inDays / 365.25;
      expect(age, greaterThanOrEqualTo(18));

      expect(find.text('Upload your documents'), findsOneWidget);
      expect(textOf(tester, 'onboarding_step'), 'Step 2 of 2');
    });

    rigTest('the backend\'s reason for refusing is shown and the form stays put', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());
      rig.repo.profileChangeFailure = const BusinessFailure('You must be at least 18 years old.', code: 'VALIDATION_ERROR');

      await tester.enterText(find.byKey(const Key('field_full_name')), 'Ravi Kumar');
      await tapKey(tester, 'field_dob');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field_emergency_name')), 'Sunita');
      await tester.enterText(find.byKey(const Key('field_emergency_phone')), '9555500002');
      await tapKey(tester, 'details_submit');

      expect(find.text('You must be at least 18 years old.'), findsOneWidget);
      expect(find.text('Tell us about yourself'), findsOneWidget);
    });

    rigTest('a saved profile lands on documents next time — progress is the server\'s, not remembered here', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      expect(find.text('Upload your documents'), findsOneWidget);
    });

    rigTest('signing out asks first', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver());

      await tapKey(tester, 'onboarding_sign_out');
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(rig.authRepo.signOutCalls, 0);

      await tapKey(tester, 'onboarding_sign_out');
      await tapKey(tester, 'onboarding_sign_out_confirm');
      expect(rig.authRepo.signOutCalls, 1);
    });
  });

  group('step 2: documents', () {
    rigTest('lists what to upload, marking the police certificate optional', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));

      expect(find.text('Aadhaar card'), findsOneWidget);
      expect(find.text('Driving licence'), findsOneWidget);
      expect(find.text('Police verification'), findsOneWidget);
      expect(find.text('REQUIRED'), findsNWidgets(2));
      expect(find.text('OPTIONAL'), findsNWidgets(2), reason: 'police certificate and profile photo');
    });

    rigTest('"Edit my details" goes back to step 1 with the saved values filled in', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));

      await tapKey(tester, 'onboarding_edit_details');

      expect(find.text('Tell us about yourself'), findsOneWidget);
      expect(tester.widget<TextField>(find.descendant(of: find.byKey(const Key('field_full_name')), matching: find.byType(TextField))).controller!.text, 'Ravi Kumar');
    });

    rigTest('Aadhaar: the button waits for a full number and both sides', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_aadhar');
      expect(find.text('Aadhaar card'), findsWidgets);
      expect(enabled(tester, 'aadhar_submit'), isFalse);

      await tester.enterText(find.byKey(const Key('field_aadhar_number')), '234567890123');
      await tester.pump();
      expect(enabled(tester, 'aadhar_submit'), isFalse, reason: 'no photos yet');

      await takeDocumentPhoto(tester, 'aadhar_front');
      expect(enabled(tester, 'aadhar_submit'), isFalse, reason: 'still no back');

      await takeDocumentPhoto(tester, 'aadhar_back');
      expect(enabled(tester, 'aadhar_submit'), isTrue);
      expect(rig.capture.cameraCalls, 2);
    });

    rigTest('Aadhaar: the number is grouped as typed and submitted as digits only', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_aadhar');
      rig.repo.profileChangeResult = newDriver(status: 'documents_required', kyc: kycJson(dlSubmitted: false));

      await tester.enterText(find.byKey(const Key('field_aadhar_number')), '234567890123');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.descendant(of: find.byKey(const Key('field_aadhar_number')), matching: find.byType(TextField))).controller!.text,
        '2345 6789 0123',
      );
      await takeDocumentPhoto(tester, 'aadhar_front');
      await takeDocumentPhoto(tester, 'aadhar_back');
      await tapKey(tester, 'aadhar_submit');

      final sent = rig.repo.aadharSubmissions.single;
      expect(sent.number, '234567890123');
      expect(sent.front.bytes, isNotEmpty);
      expect(sent.back.bytes, isNotEmpty);

      // The sheet closed, the driver was told, and the card now says it's with the company.
      expect(find.byKey(const Key('aadhar_submit')), findsNothing);
      expect(find.text('Aadhaar submitted for review.'), findsOneWidget);
      expect(find.text('IN REVIEW'), findsOneWidget);
      expect(textOf(tester, 'doc_aadhar_detail'), contains('•••• 0123'));
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a document the backend refuses is explained inside the sheet, which stays open', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_aadhar');
      rig.repo.profileChangeFailure = const BusinessFailure('File is not a valid image.', code: 'INVALID_UPLOAD');

      await tester.enterText(find.byKey(const Key('field_aadhar_number')), '234567890123');
      await takeDocumentPhoto(tester, 'aadhar_front');
      await takeDocumentPhoto(tester, 'aadhar_back');
      await tapKey(tester, 'aadhar_submit');

      expect(find.byKey(const Key('sheet_error')), findsOneWidget);
      expect(find.text('File is not a valid image.'), findsOneWidget);
      expect(find.byKey(const Key('aadhar_submit')), findsOneWidget, reason: 'stay and try again');
      expect(enabled(tester, 'aadhar_submit'), isTrue);
    });

    rigTest('a camera that cannot open says so instead of failing silently', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_aadhar');
      rig.capture.failure = const PhotoCaptureException('Camera or photo access is off. Allow it in Settings to add pictures.');

      await takeDocumentPhoto(tester, 'aadhar_front');

      expect(find.textContaining('Camera or photo access is off'), findsOneWidget);
      expect(enabled(tester, 'aadhar_submit'), isFalse);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('backing out of the camera leaves the tile empty', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_aadhar');
      rig.capture.next = null;

      await takeDocumentPhoto(tester, 'aadhar_front');

      expect(find.text('Front'), findsOneWidget, reason: 'still the empty tile\'s label');
      expect(find.textContaining('Tap to change'), findsNothing);
    });

    rigTest('documents can also come from the gallery', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_aadhar');

      await tester.tap(find.byKey(const Key('aadhar_front')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo_source_gallery')));
      await tester.pumpAndSettle();

      expect((rig.capture.galleryCalls, rig.capture.cameraCalls), (1, 0));
      expect(find.textContaining('Tap to change'), findsOneWidget);
    });

    rigTest('Licence: number, expiry and front are needed; the back is optional', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_licence');
      rig.repo.profileChangeResult = newDriver(status: 'documents_required', kyc: kycJson(aadharSubmitted: false));
      expect(enabled(tester, 'dl_submit'), isFalse);

      await tester.enterText(find.byKey(const Key('field_dl_number')), 'ka01 20110012345');
      await takeDocumentPhoto(tester, 'dl_front');
      expect(enabled(tester, 'dl_submit'), isFalse, reason: 'no expiry yet');

      await tapKey(tester, 'field_dl_expiry');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(enabled(tester, 'dl_submit'), isTrue);

      await tapKey(tester, 'dl_submit');

      final sent = rig.repo.licenceSubmissions.single;
      expect(sent.number, 'ka01 20110012345', reason: 'the backend tidies and upper-cases it');
      expect(sent.expiry.isAfter(DateTime.now()), isTrue);
      expect(sent.hasBack, isFalse);
      expect(find.text('Driving licence submitted for review.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('Licence: a back photo is sent when the driver takes one', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_licence');
      await tester.enterText(find.byKey(const Key('field_dl_number')), 'KA01 20110012345');
      await takeDocumentPhoto(tester, 'dl_front');
      await takeDocumentPhoto(tester, 'dl_back');
      await tapKey(tester, 'field_dl_expiry');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKey(tester, 'dl_submit');

      expect(rig.repo.licenceSubmissions.single.hasBack, isTrue);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('Police certificate: one picture', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));
      await tapKey(tester, 'doc_police');
      expect(enabled(tester, 'police_submit'), isFalse);

      await takeDocumentPhoto(tester, 'police_document');
      await tapKey(tester, 'police_submit');

      expect(rig.repo.policeSubmissions, hasLength(1));
      expect(find.text('Police certificate submitted for review.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    rigTest('a profile photo is optional and goes straight up after it is taken', (tester, rig) async {
      await openOnboarding(tester, rig, newDriver(status: 'documents_required'));

      await tester.tap(find.byKey(const Key('doc_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo_source_camera')));
      await tester.pumpAndSettle();

      expect(rig.repo.photoUploads, hasLength(1));
      expect(find.text('Profile photo updated.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('after the first submission: the documents page', () {
    Future<void> openVerification(WidgetTester tester, TestRig rig, DriverProfile profile) async {
      tester.view.physicalSize = const Size(1080, 3200);
      rig.repo.profileValue = profile;
      await rig.cubit.load();
      await tester.pumpWidget(rig.host(DriverVerificationPage(capture: rig.capture)));
      await tester.pumpAndSettle();
    }

    rigTest('under review: says so, and the documents show as being checked', (tester, rig) async {
      await openVerification(tester, rig, newDriver(status: 'under_review', kyc: kycJson()));

      expect(find.textContaining('being reviewed'), findsOneWidget);
      expect(find.text('IN REVIEW'), findsNWidgets(2));
      expect(textOf(tester, 'doc_licence_detail'), contains('KA01 20110012345'));
    });

    rigTest('sent back: the company\'s reason is shown and the document can be uploaded again', (tester, rig) async {
      await openVerification(
        tester,
        rig,
        newDriver(status: 'action_required', kyc: kycJson(), extra: {
          'aadhar_status': 'rejected',
          'aadhar_rejection_note': 'The photo is blurry',
          'kyc': {
            ...kycJson(),
            'aadhar': {...kycJson()['aadhar'] as Map<String, dynamic>, 'status': 'rejected', 'rejection_note': 'The photo is blurry'},
          },
        }),
      );

      expect(find.textContaining('were sent back'), findsOneWidget);
      expect(find.text('SENT BACK'), findsOneWidget);
      expect(textOf(tester, 'doc_aadhar_detail'), 'The photo is blurry');
      expect(textOf(tester, 'doc_aadhar_action'), 'Upload again');

      await tapKey(tester, 'doc_aadhar');
      expect(find.byKey(const Key('rejection_note')), findsOneWidget);
      expect(find.textContaining('The photo is blurry'), findsWidgets);
    });

    rigTest('verified: a document is done and cannot be reopened', (tester, rig) async {
      await openVerification(tester, rig, DriverProfile.fromJson(profileJson()));

      expect(find.text('VERIFIED'), findsNWidgets(3));
      expect(find.byKey(const Key('doc_aadhar_action')), findsNothing);
      await tester.tap(find.byKey(const Key('doc_aadhar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aadhar_submit')), findsNothing);
      expect(find.textContaining('You’re verified'), findsOneWidget);
    });

    rigTest('a licence about to expire is called out', (tester, rig) async {
      final soon = DateTime.now().add(const Duration(days: 9));
      await openVerification(
        tester,
        rig,
        DriverProfile.fromJson({
          ...profileJson(),
          'dl_expiry_date': '${soon.year}-${soon.month.toString().padLeft(2, '0')}-${soon.day.toString().padLeft(2, '0')}',
        }),
      );

      expect(find.textContaining('Expires in 9 days'), findsOneWidget);
    });
  });

  group('the gate over the app', () {
    Widget shell(TestRig rig) => MultiBlocProvider(
          providers: [BlocProvider<DriverSessionCubit>.value(value: rig.cubit)],
          child: MaterialApp.router(
            theme: testTheme,
            routerConfig: GoRouter(routes: [
              StatefulShellRoute.indexedStack(
                builder: (_, __, navigationShell) => ScaffoldWithNavBar(navigationShell: navigationShell),
                branches: [
                  for (final name in ['today', 'trips', 'wallet', 'vehicle', 'profile'])
                    StatefulShellBranch(routes: [
                      GoRoute(path: '/$name', builder: (_, __) => Scaffold(body: Center(child: Text('PAGE $name')))),
                    ]),
                ],
              ),
            ], initialLocation: '/today'),
          ),
        );

    rigTest('a driver who still has to set up sees set-up, not the app', (tester, rig) async {
      rig.repo.profileValue = newDriver();
      await rig.cubit.load();
      await tester.pumpWidget(shell(rig));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding')), findsOneWidget);
      expect(find.text('Tell us about yourself'), findsOneWidget);
    });

    rigTest('the moment the company holds the ball, set-up gives way to the app', (tester, rig) async {
      rig.repo.profileValue = newDriver(status: 'documents_required');
      await rig.cubit.load();
      await tester.pumpWidget(shell(rig));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboarding')), findsOneWidget);

      rig.repo.profileChangeResult = newDriver(status: 'under_review', kyc: kycJson());
      await rig.cubit.submitPolice(CapturedPhoto(bytes: kTinyPng));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding')), findsNothing);
      expect(find.text('PAGE today'), findsOneWidget);
    });

    rigTest('an approved driver never sees set-up, just the branch underneath', (tester, rig) async {
      rig.repo.profileValue = fakeProfile();
      await rig.cubit.load();
      await tester.pumpWidget(shell(rig));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding')), findsNothing);
      expect(find.text('PAGE today'), findsOneWidget);
    });

    rigTest('nothing is forced on a driver whose profile has not loaded yet', (tester, rig) async {
      await tester.pumpWidget(shell(rig));
      await tester.pump();
      expect(find.byKey(const Key('onboarding')), findsNothing);
    });
  });
}
