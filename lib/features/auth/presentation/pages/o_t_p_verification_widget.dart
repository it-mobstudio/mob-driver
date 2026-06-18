import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import '/index.dart';

class OTPVerificationWidget extends StatefulWidget {
  final String phoneNumber;
  const OTPVerificationWidget({super.key, required this.phoneNumber});

  static String routeName = 'OTPVerification';
  static String routePath = '/otp-verification';

  @override
  State<OTPVerificationWidget> createState() => _OTPVerificationWidgetState();
}

class _OTPVerificationWidgetState extends State<OTPVerificationWidget> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  int _resendSeconds = 40;
  Timer? _timer;

  String get _rawPhone => widget.phoneNumber
      .replaceAll('+91', '')
      .replaceAll(' ', '')
      .trim();

  @override
  void initState() {
    super.initState();
    for (final focusNode in _otpFocusNodes) {
      focusNode.addListener(() {
        if (mounted) setState(() {});
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AuthSession.instance.isAuthenticated) {
        context.go(AuthSession.instance.needsRegistration
            ? SignupWidget.routePath
            : HomepageWidget.routePath);
      }
    });
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpDigitChanged(int index, String val) {
    if (val.isNotEmpty && index < 3) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    } else if (val.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
    }
    if (_otpControllers.every((c) => c.text.isNotEmpty)) {
      final otp = _otpControllers.map((c) => c.text).join();
      context.read<AuthBloc>().add(
            AuthOtpVerifyRequested(emailOrPhone: _rawPhone, otp: otp),
          );
    }
  }

  void _resendOtp() {
    for (final c in _otpControllers) { c.clear(); }
    _otpFocusNodes.first.requestFocus();
    context.read<AuthBloc>().add(
          AuthOtpSendRequested(emailOrPhone: _rawPhone, isPhone: true),
        );
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 40);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds == 0) {
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
        if (state is AuthVerified) {
          if (state.isNewAccount) {
            context.go(
              SignupWidget.routePath,
              extra: {'phoneNumber': widget.phoneNumber},
            );
          } else if (SelectedAddressStore.hasSelectedAddress) {
            context.go(HomepageWidget.routePath);
          } else {
            context.go(
              AddressSelectionWidget.routePath,
              extra: {'returnToHome': true},
            );
          }
        } else if (state is AuthOtpSent) {
          _startResendTimer();
        } else if (state is AuthError) {
          _showDialog(context, 'OTP Failed', state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              leading: IconButton(
                icon: Image.asset(
                  'assets/images/back-arrow.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () => context.go(LoginpageWidget.routePath),
              ),
              elevation: 0.0,
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'OTP Verification',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A243F),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: 'OTP has been sent to ',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0A243F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            for (int i = 0; i < 4; i++) ...[
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _otpFocusNodes[i].hasFocus
                                          ? const Color(0xFF0A243F)
                                          : const Color(0xFFB5B5B5),
                                      width:
                                          _otpFocusNodes[i].hasFocus ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      controller: _otpControllers[i],
                                      focusNode: _otpFocusNodes[i],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      maxLength: 1,
                                      enabled: !isLoading,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0A243F),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) =>
                                          _onOtpDigitChanged(i, val),
                                    ),
                                  ),
                                ),
                              ),
                              if (i < 3) const SizedBox(width: 16),
                            ],
                          ],
                        ),
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
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
