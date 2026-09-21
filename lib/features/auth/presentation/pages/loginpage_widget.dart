import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/shared/login_top_banner.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '/index.dart';

/// The backend matches a driver on their full stored number, so the 10 digits
/// typed here are always sent as `+91XXXXXXXXXX`.
String driverPhoneFromDigits(String digits) => '+91$digits';

class LoginpageWidget extends StatefulWidget {
  const LoginpageWidget({super.key});

  static String routeName = 'Loginpage';
  static String routePath = '/loginpage';

  @override
  State<LoginpageWidget> createState() => _LoginpageWidgetState();
}

class _LoginpageWidgetState extends State<LoginpageWidget> {
  final _mobileController = TextEditingController();
  final _mobileFocusNode = FocusNode();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openExternal(
            'https://mob-demand-side.netlify.app/home/faq?key=termsAndCondition',
          );
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openExternal(
            'https://mob-demand-side.netlify.app/home/faq?key=privacyPolicy',
          );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocusNode.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || mobile.length != 10 || int.tryParse(mobile) == null) {
      _showDialog(context, 'Invalid Number',
          'Please enter a valid 10-digit mobile number.');
      return;
    }
    context
        .read<AuthBloc>()
        .add(AuthOtpSendRequested(phoneNumber: driverPhoneFromDigits(mobile)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          context.go(
            OTPVerificationWidget.routePath,
            extra: {
              'phoneNumber': state.phoneNumber,
              if (state.debugOtp != null) 'debugOtp': state.debugOtp,
            },
          );
        } else if (state is AuthError) {
          _showDialog(context, 'Login Failed', state.message);
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
            body: LayoutBuilder(
              builder: (context, constraints) {
                final headerHeight = constraints.maxHeight * .5;
                final bodyHeight = constraints.maxHeight - headerHeight;

                return Column(
                  children: [
                    LoginTopBanner(height: headerHeight),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ConstrainedBox(
                          // Forces the column to be at least as tall as the
                          // space below the banner, so the legal text is
                          // pushed to the screen bottom (per wireframe) when
                          // there's slack. As the keyboard opens and shrinks
                          // bodyHeight, the enforced minimum shrinks too, so
                          // the content scrolls normally instead of the
                          // legal text getting pinned on top of it.
                          constraints: BoxConstraints(minHeight: bodyHeight),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Text(
                                      'Driver login',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppColors.primaryText,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        height: 24 / 16,
                                      ),
                                    ),
                                  ),
                                  AppTextField(
                                    controller: _mobileController,
                                    focusNode: _mobileFocusNode,
                                    hintText: 'Registered mobile number',
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    prefixIcon: const _PhonePrefix(),
                                    onFieldSubmitted: (_) => _submit(context),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => _submit(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              'Continue',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                height: 21 / 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              _legalText(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDialog(
      BuildContext context, String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (alertDialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertDialogContext),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  Widget _legalText() {
    const regularStyle = TextStyle(
      color: Color(0xFF0A243F),
      fontSize: 11,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 16 / 11,
    );
    const mediumStyle = TextStyle(
      color: Color(0xFF0A243F),
      fontSize: 11,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 16 / 11,
    );
    const linkStyle = TextStyle(
      color: Color(0xFF0A243F),
      fontSize: 11,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      height: 16 / 11,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'By clicking continue you agree to our ',
              style: regularStyle,
            ),
            TextSpan(
              text: 'Terms and Conditions',
              style: linkStyle,
              recognizer: _termsRecognizer,
            ),
            const TextSpan(text: ' and ', style: mediumStyle),
            TextSpan(
              text: 'Privacy Statement',
              style: linkStyle,
              recognizer: _privacyRecognizer,
            ),
            const TextSpan(text: '. ', style: mediumStyle),
          ],
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      TopSnackBar.show(context, message: 'Unable to open link.');
    }
  }
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 10),
      child: Center(
        widthFactor: 1,
        child: Text(
          '+91',
          style: GoogleFonts.inter(
            color: const Color(0xFF0A243F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
