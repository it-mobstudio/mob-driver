import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/analytics_service.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/app_back_icon.dart';
import 'package:mob_driver/core/widgets/otp_input.dart';
import 'package:mob_driver/core/widgets/test_mode_otp_hint.dart';
import 'package:mob_driver/features/auth/domain/auth_limits.dart';
import 'package:mob_driver/features/auth/presentation/bloc/auth_bloc.dart';

/// The backend refuses a second OTP for the same number for 30 s
/// (`OTP_THROTTLE_SECONDS`), so the resend button unlocks on the same clock.

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    this.debugOtp,
  });

  /// Full international number, e.g. `+919000000000`.
  final String phoneNumber;

  /// Set only when the backend echoes the OTP (non-production).
  final String? debugOtp;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpKey = GlobalKey<OtpInputState>();

  int _resendSeconds = AuthLimits.otpResendSeconds;
  Timer? _timer;
  String? _debugOtp;

  @override
  void initState() {
    super.initState();
    _debugOtp = widget.debugOtp;
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _verify(String otp) {
    context.read<AuthBloc>().add(
          AuthOtpVerifyRequested(phoneNumber: widget.phoneNumber, otp: otp),
        );
  }

  void _resendOtp() {
    _otpKey.currentState?.clear();
    context
        .read<AuthBloc>()
        .add(AuthOtpSendRequested(phoneNumber: widget.phoneNumber));
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = AuthLimits.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds == 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          setState(() => _debugOtp = state.debugOtp);
          _startResendTimer();
        } else if (state is AuthVerified) {
          AnalyticsService.instance.logLogin(method: 'otp').catchError((_) {});
          context.go(AppRoutes.dashboard);
        } else if (state is AuthError) {
          _otpKey.currentState?.clear();
          _showDialog(context, tr('Could not continue'), state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.card,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: AppBackIcon(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      splashRadius: 20,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      tr('OTP verification'),
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 32 / 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: tr('We have sent a {length}-digit OTP to ',
                              {'length': AuthLimits.otpLength}),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 21 / 14,
                          ),
                        ),
                        TextSpan(
                          text: formatPhone(widget.phoneNumber),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 21 / 14,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 32),
                    OtpInput(
                      key: _otpKey,
                      length: AuthLimits.otpLength,
                      enabled: !isLoading,
                      onCompleted: _verify,
                    ),
                    if (_debugOtp != null) ...[
                      const SizedBox(height: 16),
                      TestModeOtpHint(
                        otp: _debugOtp!,
                        onFill: () => _otpKey.currentState?.setCode(_debugOtp!),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_resendSeconds > 0)
                      Text(
                        tr('Resend OTP in {seconds}s',
                            {'seconds': _resendSeconds}),
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 21 / 14,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _resendOtp,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.blue,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          tr('Resend OTP'),
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 21 / 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDialog(
      BuildContext context, String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Ok')),
          ),
        ],
      ),
    );
  }
}
