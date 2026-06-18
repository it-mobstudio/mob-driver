import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/shared/build_wallet_reward.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
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
  String _lastValidatedReferralCode = '';
  String _lastSubmittedReferralCode = '';

  String _normalizeReferralCode(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

  String get _rawPhone {
    final fromRoute =
        widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();
    if (fromRoute.isNotEmpty) return fromRoute;
    final user = AuthSession.instance.userDetails ?? const {};
    for (final key in const ['phone_number', 'phoneNumber', 'mobile', 'phone']) {
      final value = user[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value.replaceAll('+91', '').replaceAll(' ', '').trim();
      }
    }
    return '';
  }

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
    final normalized = _normalizeReferralCode(value);
    if (value != normalized) {
      _referralCodeController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() {
      _isReferralValid = null;
      _referralMessage = '';
      _lastValidatedReferralCode = '';
    });
    _referralDebounce?.cancel();
    if (normalized.isEmpty) return;
    _referralDebounce = Timer(
      const Duration(milliseconds: 700),
      () {
        _checkReferralCode();
      },
    );
  }

  Future<bool> _checkReferralCode({bool force = false}) async {
    final code = _normalizeReferralCode(_referralCodeController.text);
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _isReferralValid = null;
          _referralMessage = '';
          _lastValidatedReferralCode = '';
        });
      }
      return true;
    }
    if (!RegExp(r'^[A-Z0-9]{4,20}$').hasMatch(code)) {
      if (mounted) {
        setState(() {
          _isReferralValid = false;
          _referralMessage = 'Please enter a valid referral code format';
          _lastValidatedReferralCode = '';
        });
      }
      return false;
    }
    if (!force && code == _lastValidatedReferralCode && _isReferralValid == true) {
      return true;
    }
    setState(() => _isCheckingReferral = true);
    final (isValid, message, failure) =
        await sl<AuthRepository>().checkReferralCode(code: code);
    if (!mounted) return false;
    final valid = failure == null && isValid;
    setState(() {
      _isCheckingReferral = false;
      _isReferralValid = failure == null ? valid : false;
      _referralMessage = failure == null
          ? message
          : 'Unable to validate referral code';
      _lastValidatedReferralCode = valid ? code : '';
    });
    return valid;
  }

  Future<void> _onAgreeAndContinue(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final referralCode = _normalizeReferralCode(_referralCodeController.text);
    if (referralCode.isNotEmpty) {
      final isValid = await _checkReferralCode(force: true);
      if (!isValid) return;
    }
    _lastSubmittedReferralCode = referralCode;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          name: _nameController.text.trim(),
          phone: _rawPhone,
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          referralCode: referralCode.isNotEmpty ? referralCode : null,
        ));
  }

  void _onRegistrationSuccess(BuildContext context) {
    final usedValidReferral =
        _lastSubmittedReferralCode.isNotEmpty && _isReferralValid == true;
    context.go(
      AddressSelectionWidget.routePath,
      extra: {
        'returnToHome': true,
        'showReferralBonus': usedValidReferral,
      },
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(20),
            ],
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
