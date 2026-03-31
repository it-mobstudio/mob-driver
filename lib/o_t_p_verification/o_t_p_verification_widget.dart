import '/core/app_runtime/flutter_flow_util.dart';
import '/features/auth/repositories/auth_repository.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'dart:async';
import 'o_t_p_verification_model.dart';
export 'o_t_p_verification_model.dart';
import '/core/auth/auth_session.dart';

/// OTP Verification Screen
class OTPVerificationWidget extends StatefulWidget {
  final String phoneNumber;
  const OTPVerificationWidget({super.key, required this.phoneNumber});

  static String routeName = 'OTPVerification';
  static String routePath = '/otp-verification';

  @override
  State<OTPVerificationWidget> createState() => _OTPVerificationWidgetState();
}

class _OTPVerificationWidgetState extends State<OTPVerificationWidget> {
  final AuthRepository _authRepository = const AuthRepository();
  late OTPVerificationModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // OTP input controllers
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  int _resendSeconds = 40;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OTPVerificationModel());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
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
                      'OTP\nVerification',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                                  width: _otpFocusNodes[i].hasFocus ? 1.5 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _otpControllers[i],
                                  focusNode: _otpFocusNodes[i],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0A243F),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (val) async {
                                    if (val.isNotEmpty && i < 3) {
                                      FocusScope.of(context)
                                          .requestFocus(_otpFocusNodes[i + 1]);
                                    } else if (val.isEmpty && i > 0) {
                                      FocusScope.of(context)
                                          .requestFocus(_otpFocusNodes[i - 1]);
                                    }
                                    // If all OTP fields are filled, call OTP API
                                    if (_otpControllers
                                        .every((c) => c.text.isNotEmpty)) {
                                      final otp = _otpControllers
                                          .map((c) => c.text)
                                          .join();
                                      // Remove '+91' and spaces from phone number
                                      String phone = widget.phoneNumber
                                          .replaceAll('+91', '')
                                          .replaceAll(' ', '');
                                      final verifyResult =
                                          await _authRepository.verifyOtp(
                                        phone: phone,
                                        otp: otp,
                                      );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      if (verifyResult.success) {
                                        if (verifyResult.newAccount) {
                                          context.go(SignupWidget.routePath,
                                              extra: {
                                                'phoneNumber':
                                                    widget.phoneNumber
                                              });
                                        } else {
                                          if (verifyResult.accessToken !=
                                                  null &&
                                              verifyResult
                                                  .accessToken!.isNotEmpty) {
                                            await AuthSession.instance
                                                .saveSession(
                                              accessToken:
                                                  verifyResult.accessToken!,
                                              refreshToken:
                                                  verifyResult.refreshToken,
                                              userDetails:
                                                  verifyResult.userDetails,
                                              isProFirstTime: true,
                                            );
                                          }
                                          if (!context.mounted) {
                                            return;
                                          }
                                          context.go(HomepageWidget.routePath);
                                        }
                                      } else {
                                        if (!context.mounted) {
                                          return;
                                        }
                                        await showDialog<void>(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return AlertDialog(
                                              title: const Text('OTP Failed'),
                                              content:
                                                  Text(verifyResult.message),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          alertDialogContext),
                                                  child: const Text('Ok'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (i < 3) const SizedBox(width: 16),
                        ]
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _resendSeconds > 0
                          ? 'Resend OTP in ${_resendSeconds}s'
                          : 'Resend OTP',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFAFB4C0),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
  }
}
