import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/shared/build_wallet_reward.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _referralFocusNode = FocusNode();

  Timer? _referralDebounce;
  bool _isCheckingReferral = false;
  bool? _isReferralValid;
  String _referralMessage = '';

  @override
  void initState() {
    super.initState();
    _referralFocusNode.addListener(() {
      if (!_referralFocusNode.hasFocus) {
        _referralDebounce?.cancel();
        _checkReferralCode();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referralCodeController.dispose();
    _referralFocusNode.dispose();
    _referralDebounce?.cancel();
    super.dispose();
  }

  void _onReferralCodeChanged(String value) {
    setState(() {
      _isReferralValid = null;
      _referralMessage = '';
    });
    _referralDebounce?.cancel();
    if (value.trim().isEmpty) return;
    _referralDebounce =
        Timer(const Duration(milliseconds: 700), _checkReferralCode);
  }

  Future<void> _checkReferralCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _isReferralValid = null;
          _referralMessage = '';
        });
      }
      return;
    }
    setState(() => _isCheckingReferral = true);
    final (isValid, message, failure) =
        await sl<AuthRepository>().checkReferralCode(code: code);
    if (!mounted) return;
    setState(() {
      _isCheckingReferral = false;
      _isReferralValid = failure == null ? isValid : null;
      _referralMessage = failure == null ? message : '';
    });
  }

  void _onAgreeAndContinue(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawPhone =
        widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();
    context.read<AuthBloc>().add(AuthRegisterRequested(
          name: _nameController.text.trim(),
          phone: rawPhone,
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
        ));
  }

  void _onRegistrationSuccess(BuildContext context) {
    final usedValidReferral =
        _isReferralValid == true && _referralCodeController.text.trim().isNotEmpty;
    context.go(
      HomepageWidget.routePath,
      extra: usedValidReferral ? {'showReferralBonus': true} : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          _onRegistrationSuccess(context);
        } else if (state is AuthError) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Registration Failed'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
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
                                  onPressed: isLoading
                                      ? null
                                      : () => _onAgreeAndContinue(context),
                                  style: AppComponentStyles.primaryButton,
                                  child: isLoading
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
      },
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
            if (email.isEmpty) return null;
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(email)) return 'Enter valid email';
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
            focusNode: _referralFocusNode,
            textCapitalization: TextCapitalization.characters,
            onChanged: _onReferralCodeChanged,
            decoration:
                AppFormFieldStyles.outlinedDecoration('Have a referral code?')
                    .copyWith(
              labelText: null,
              hintText: 'Have a referral code?',
              suffixIcon: _isCheckingReferral
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            style: AppTextStyles.inputText,
          ),
        ),
        if (!_isCheckingReferral && _isReferralValid != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _referralMessage,
              style: AppTextStyles.legalText.copyWith(
                color: _isReferralValid == true ? Colors.green : Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}
