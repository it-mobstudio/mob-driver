import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
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
  bool _isApplyingOtp = false;
  String? _lastSubmittedOtp;

  String get _rawPhone =>
      widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();

  @override
  void initState() {
    super.initState();
    for (final focusNode in _otpFocusNodes) {
      focusNode.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpDigitChanged(int index, String value) {
    if (_isApplyingOtp) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      _applyOtpDigits(index, digits);
      _verifyIfComplete();
      return;
    }

    if (digits != value) {
      _setDigit(index, digits);
      return;
    }

    if (digits.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    _lastSubmittedOtp = null;
    _verifyIfComplete();
  }

  void _applyOtpDigits(int startIndex, String digits) {
    _isApplyingOtp = true;
    final chars = digits.split('');
    var charIndex = 0;
    for (var i = startIndex; i < _otpControllers.length; i++) {
      _setDigit(i, charIndex < chars.length ? chars[charIndex] : '');
      charIndex++;
    }
    _isApplyingOtp = false;

    final nextEmpty = _otpControllers.indexWhere((c) => c.text.isEmpty);
    if (nextEmpty == -1) {
      _otpFocusNodes.last.requestFocus();
    } else {
      _otpFocusNodes[nextEmpty].requestFocus();
    }
    _lastSubmittedOtp = null;
  }

  void _setDigit(int index, String value) {
    final text = value.isEmpty ? '' : value.characters.first;
    _otpControllers[index].value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _verifyIfComplete() {
    if (_otpControllers.every((c) => c.text.isNotEmpty)) {
      final otp = _otpControllers.map((c) => c.text).join();
      if (_lastSubmittedOtp == otp) return;
      _lastSubmittedOtp = otp;
      context.read<AuthBloc>().add(
            AuthOtpVerifyRequested(emailOrPhone: _rawPhone, otp: otp),
          );
    }
  }

  void _resendOtp() {
    _clearOtp();
    _otpFocusNodes.first.requestFocus();
    context.read<AuthBloc>().add(
          AuthOtpSendRequested(emailOrPhone: _rawPhone, isPhone: true),
        );
  }

  void _clearOtp() {
    _isApplyingOtp = true;
    for (final c in _otpControllers) {
      c.clear();
    }
    _isApplyingOtp = false;
    _lastSubmittedOtp = null;
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
        if (state is AuthOtpSent) {
          _startResendTimer();
        } else if (state is AuthVerified) {
          if (state.isNewAccount) {
            context.go(
              SignupWidget.routePath,
              extra: {'phoneNumber': widget.phoneNumber},
            );
          } else {
            context.go(HomepageWidget.routePath);
          }
        } else if (state is AuthError) {
          _clearOtp();
          _otpFocusNodes.first.requestFocus();
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
                icon: const AppBackIcon(),
                onPressed: () => context.go(LoginpageWidget.routePath),
              ),
              elevation: 0.0,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 344),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'OTP verification',
                          textAlign: TextAlign.left,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A243F),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'We have sent an OTP to ',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0A243F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 21 / 14,
                                ),
                              ),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0A243F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 21 / 14,
                                ),
                              ),
                              TextSpan(
                                text: ' ',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0A243F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 21 / 14,
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
                                          : const Color(0xFFDFE4EC),
                                      width: _otpFocusNodes[i].hasFocus
                                          ? 1.5
                                          : 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: TextField(
                                      controller: _otpControllers[i],
                                      focusNode: _otpFocusNodes[i],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      enabled: !isLoading,
                                      showCursor: false,
                                      onTap: () {
                                        _otpControllers[i].selection =
                                            TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              _otpControllers[i].text.length,
                                        );
                                      },
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0A243F),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        height: 30 / 20,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.zero,
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
