import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/shared/login_top_banner.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';
import '/index.dart';

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

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocusNode.dispose();
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
        .add(AuthOtpSendRequested(emailOrPhone: mobile, isPhone: true));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          context.go(
            OTPVerificationWidget.routePath,
            extra: {'phoneNumber': '+91 ${_mobileController.text.trim()}'},
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
                          AppTextField(
                            controller: _mobileController,
                            focusNode: _mobileFocusNode,
                            hintText: 'Enter mobile number',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            prefixIcon: const _PhonePrefix(),
                            showClearButton: false,
                            onFieldSubmitted: (_) => _submit(context),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading ? null : () => _submit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : Text(
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
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 24),
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
