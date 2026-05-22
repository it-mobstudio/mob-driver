import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/components/build_wallet_reward.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:go_router/go_router.dart';
import '/features/auth/repositories/auth_repository.dart';
import '/core/auth/auth_session.dart';
import '/index.dart';

class SignupWidget extends StatefulWidget {
  final String phoneNumber;

  const SignupWidget({
    super.key,
    required this.phoneNumber,
  });

  static String routeName = 'Signup';
  static String routePath = '/signup';

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  final AuthRepository _authRepository = const AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralCodeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Form(
                    key: _formKey,
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.primaryText,
                                size: 24,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            'Welcome to mob',
                            style: AppTextStyles.screenTitle,
                          ),
                          const SizedBox(height: 24),
                          _buildSignupFields(),
                          const SizedBox(height: 4),
                          const WalletRewardBanner(),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'By clicking agree and continue you agree to our ',
                                style: AppTextStyles.legalText,
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: AppTextStyles.legalStrong,
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: AppTextStyles.legalMedium,
                                  ),
                                  TextSpan(
                                    text: 'Privacy Statement',
                                    style: AppTextStyles.legalStrong,
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: AppTextStyles.legalMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: AppComponentStyles.buttonHeight,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _onAgreeAndContinue,
                              style: AppComponentStyles.primaryButton,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: AppColors.surface,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : Text(
                                      'Agree and continue',
                                      style: AppTextStyles.buttonLabel,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 21),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSignupFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            if (value.trim().length < 3) {
              return 'Enter valid name';
            }
            return null;
          },
          decoration: AppFormFieldStyles.outlinedDecoration('Name*'),
          style: AppTextStyles.inputText,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) {
              return null;
            }

            final emailRegex = RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            );

            if (!emailRegex.hasMatch(email)) {
              return 'Enter valid email';
            }

            return null;
          },
          onChanged: (_) => setState(() {}),
          decoration: AppFormFieldStyles.outlinedDecoration(
            'Email id',
            suffixIcon: _emailController.text.isEmpty
                ? null
                : IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.cancel,
                      color: AppColors.mutedControl,
                      size: 18,
                    ),
                    onPressed: () {
                      _emailController.clear();
                      setState(() {});
                    },
                  ),
          ),
          style: AppTextStyles.inputText,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: AppComponentStyles.fieldHeight,
          child: TextFormField(
            controller: _referralCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration:
                AppFormFieldStyles.outlinedDecoration('Have a referral code?')
                    .copyWith(
              labelText: null,
              hintText: 'Have a referral code?',
            ),
            style: AppTextStyles.inputText,
          ),
        ),
      ],
    );
  }

  Future<void> _onAgreeAndContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final rawPhone =
        widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();

    final result = await _authRepository.register(
      phone: rawPhone,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      gstin: '',
      businessName: '',
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      if (result.accessToken != null && result.accessToken!.isNotEmpty) {
        await AuthSession.instance.saveSession(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken,
          userDetails: result.userDetails,
          isProFirstTime: true,
        );
      }

      if (!mounted) return;

      context.go(HomepageWidget.routePath);
    } else {
      await showDialog<void>(
        context: context,
        builder: (alertDialogContext) {
          return AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(alertDialogContext),
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }
}
