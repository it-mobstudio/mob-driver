import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/otp_input.dart';
import 'package:m_o_b_demand_side/shared/widgets/test_mode_otp_hint.dart';
import '/index.dart';

/// The backend refuses a second OTP for the same number for 30 s
/// (`OTP_THROTTLE_SECONDS`), so the resend button unlocks on the same clock.
const int kOtpResendSeconds = 30;
const int kOtpLength = 6;

class OTPVerificationWidget extends StatefulWidget {
  const OTPVerificationWidget({
    super.key,
    required this.phoneNumber,
    this.debugOtp,
  });

  /// Full international number, e.g. `+919000000000`.
  final String phoneNumber;

  /// Set only when the backend echoes the OTP (non-production).
  final String? debugOtp;

  static String routeName = 'OTPVerification';
  static String routePath = '/otp-verification';

  @override
  State<OTPVerificationWidget> createState() => _OTPVerificationWidgetState();
}

class _OTPVerificationWidgetState extends State<OTPVerificationWidget> {
  final _otpKey = GlobalKey<OtpInputState>();

  int _resendSeconds = kOtpResendSeconds;
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
    setState(() => _resendSeconds = kOtpResendSeconds);
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
          context.go(DriverDashboardPage.routePath);
        } else if (state is AuthError) {
          _otpKey.currentState?.clear();
          _showDialog(context, 'Could not continue', state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.go(LoginpageWidget.routePath),
                      icon: const AppBackIcon(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      splashRadius: 20,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'OTP verification',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 32 / 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'We have sent a $kOtpLength-digit OTP to ',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A243F),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 21 / 14,
                          ),
                        ),
                        TextSpan(
                          text: formatPhone(widget.phoneNumber),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A243F),
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
                      length: kOtpLength,
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
                        'Resend OTP in ${_resendSeconds}s',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFAFB4C0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 21 / 14,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _resendOtp,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0360E5),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Resend OTP',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0360E5),
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
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }
}
