import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/core/errors/app_failure.dart';
import 'package:mob_driver/features/auth/domain/repositories/auth_repository.dart';
import 'package:mob_driver/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mob_driver/features/auth/presentation/pages/otp_verification_page.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';

class SessionRepository extends FakeAuthRepository {
  final replacements = <bool>[];
  bool riding = false;

  @override
  Future<(AuthVerifyResult?, AppFailure?)> verifyOtp({
    required String phoneNumber,
    required String otp,
    bool replaceSession = false,
  }) async {
    replacements.add(replaceSession);
    return (
      null,
      riding
          ? const BusinessFailure(
              'A ride is already in progress with this phone number.',
              code: 'DRIVER_RIDE_IN_PROGRESS')
          : const BusinessFailure(
              'Looks like another phone is logged in with this number. Do you want to log out and continue here?',
              code: 'DRIVER_SESSION_EXISTS')
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('another phone requires an explicit confirmation',
      (tester) async {
    final repo = SessionRepository();
    final bloc = AuthBloc(repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
            home: OtpVerificationPage(phoneNumber: '+919000000000'))));
    bloc.add(AuthOtpVerifyRequested(phoneNumber: '+919000000000', otp: '1234'));
    await tester.pumpAndSettle();
    expect(repo.replacements, [false]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Looks like another phone is logged in'),
        findsOneWidget);
    expect(find.text('Log out and continue here'), findsOneWidget);
    repo.riding = true; // A trip can start before the driver confirms.
    await tester.tap(find.byKey(const Key('confirm_session_replacement')));
    await tester.pumpAndSettle();
    expect(repo.replacements, [false, true]);
    expect(find.text('A ride is already in progress with this phone number.'),
        findsOneWidget);
    expect(find.byKey(const Key('confirm_session_replacement')), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
