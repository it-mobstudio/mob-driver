import 'package:m_o_b_demand_side/components/login_top_banner.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';

import '/features/auth/repositories/auth_repository.dart';
import '/core/app_runtime/flutter_flow_util.dart';
import '/core/auth/auth_session.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'loginpage_model.dart';
export 'loginpage_model.dart';

/// LoginPage
class LoginpageWidget extends StatefulWidget {
  const LoginpageWidget({super.key});

  static String routeName = 'Loginpage';
  static String routePath = '/loginpage';

  @override
  State<LoginpageWidget> createState() => _LoginpageWidgetState();
}

class _LoginpageWidgetState extends State<LoginpageWidget> {
  final AuthRepository _authRepository = const AuthRepository();
  LoginpageModel? _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = LoginpageModel();
    _model?.mobileNumberTextController ??= TextEditingController();
    _model?.mobileNumberFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (AuthSession.instance.isAuthenticated) {
        context.go(HomepageWidget.routePath);
      }
    });
  }

  @override
  void dispose() {
    _model?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _model!;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const LoginTopBanner(),
              const SizedBox(height: 32),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Log in or sign up',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB5B5B5)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Text(
                              '+91',
                              style: GoogleFonts.inter(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: TextFormField(
                                  controller: model.mobileNumberTextController,
                                  focusNode: model.mobileNumberFocusNode,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter mobile number',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.inputHint,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                    isDense: false,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  style: GoogleFonts.inter(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final mobile =
                                model.mobileNumberTextController.text.trim();
                            if (mobile.isEmpty || mobile.length != 10) {
                              await showDialog<void>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: const Text('Invalid Number'),
                                    content: const Text(
                                        'Please enter a valid 10-digit mobile number.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(alertDialogContext),
                                        child: const Text('Ok'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }
                            final parsedMobile = int.tryParse(mobile);
                            if (parsedMobile == null) {
                              await showDialog<void>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: const Text('Invalid Number'),
                                    content: const Text(
                                        'Please enter a valid 10-digit mobile number.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(alertDialogContext),
                                        child: const Text('Ok'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }
                            final otpResult = await _authRepository.sendOtp(
                              emailOrPhone: parsedMobile,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            if (otpResult.success) {
                              context.go(
                                OTPVerificationWidget.routePath,
                                extra: {'phoneNumber': '+91 $mobile'},
                              );
                            } else {
                              if (!context.mounted) {
                                return;
                              }
                              await showDialog<void>(
                                context: context,
                                builder: (alertDialogContext) {
                                  return AlertDialog(
                                    title: const Text('Login Failed'),
                                    content: Text(otpResult.message),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(alertDialogContext),
                                        child: const Text('Ok'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.inter(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
