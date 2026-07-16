import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/shared/build_wallet_reward.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

class SignupWidget extends StatefulWidget {
  const SignupWidget({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  static String routeName = 'Signup';
  static String routePath = '/signup';

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();

  late final AuthRepository _authRepository;
  Timer? _referralDebounce;
  bool _checkingReferral = false;
  bool _referralVerified = false;
  String? _referralError;
  String? _referralSuccessMessage;
  String _lastCheckedReferral = '';
  // Tracked separately from the controller so the bonus sheet only fires
  // for the code actually submitted with registration — matches web's
  // lastSubmittedReferralCode (CompleteSignUp.jsx).
  String _lastSubmittedReferralCode = '';

  String get _rawPhone {
    final fromRoute =
        widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();
    if (fromRoute.isNotEmpty) return fromRoute;

    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    return _firstString(user, const [
      'phone_number',
      'phoneNumber',
      'business_mobile',
      'mobile',
      'phone',
      'email_or_phone',
    ]).replaceAll('+91', '').replaceAll(' ', '').trim();
  }

  @override
  void initState() {
    super.initState();
    _authRepository = sl<AuthRepository>();
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _nameController.text = _firstString(user, const [
      'full_name',
      'fullName',
      'name',
      'first_name',
      'username',
    ]);
    _emailController.text = _firstString(user, const ['email', 'email_id']);
  }

  @override
  void dispose() {
    _referralDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _onReferralChanged(String value) {
    _referralDebounce?.cancel();
    setState(() {
      _referralVerified = false;
      _referralError = null;
      _referralSuccessMessage = null;
    });
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      _lastCheckedReferral = '';
      return;
    }
    // Covers both typing and pasting — Flutter's TextField doesn't
    // distinguish the two, unlike web's separate onPaste handler.
    _referralDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _checkReferralCode(normalized);
    });
  }

  /// Mirrors web's validateReferral (CompleteSignUp.jsx) — same
  /// /accounts/referral-code-checker/ endpoint via AuthRepository
  /// .checkReferralCode, which already existed but was never wired to any
  /// UI on mobile.
  Future<bool> _checkReferralCode(String code) async {
    if (code == _lastCheckedReferral && _referralVerified) return true;
    setState(() => _checkingReferral = true);
    final (isValid, message, failure) =
        await _authRepository.checkReferralCode(code: code);
    if (!mounted) return false;
    final verified = failure == null && isValid;
    setState(() {
      _checkingReferral = false;
      _lastCheckedReferral = code;
      _referralVerified = verified;
      _referralSuccessMessage = verified
          ? (message.isNotEmpty ? message : 'Valid referral code')
          : null;
      _referralError = verified
          ? null
          : (failure?.message ??
              (message.isNotEmpty ? message : 'Invalid referral code'));
    });
    return verified;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          context.go(
            '${AddressSelectionWidget.routePath}?fromSignup=true',
            extra: {
              'returnToHome': true,
              'showReferralBonus': _lastSubmittedReferralCode.isNotEmpty,
              'showBackButton': false,
            },
          );
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
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: _handleBack,
                              icon: const AppBackIcon(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),

                            // 16 top padding + 36 back icon height = 52 from top
                            const SizedBox(height: 16),

                            Text(
                              'Welcome to mob',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0A243F),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 32 / 24,
                              ),
                            ),

                            const SizedBox(height: 24),

                            AppTextField(
                              label: 'Name*',
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) {
                                  return 'Name is required';
                                }
                                if (name.length < 3) {
                                  return 'Enter valid name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            AppTextField(
                              label: 'Email id',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return null;

                                final emailRegex = RegExp(
                                  r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );

                                if (!emailRegex.hasMatch(email)) {
                                  return 'Enter valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            AppTextField(
                              controller: _referralController,
                              hintText: 'Have a referral code?',
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]'),
                                ),
                              ],
                              onChanged: _onReferralChanged,
                              onFieldSubmitted: (_) {
                                if (!isLoading) _submit();
                              },
                            ),
                            if (_checkingReferral) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Validating referral code...',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF596378),
                                  fontSize: 12,
                                ),
                              ),
                            ] else if (_referralError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _referralError!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFC13615),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else if (_referralSuccessMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _referralSuccessMessage!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF13A05A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],

                            SizedBox(
                              height: _referralSuccessMessage != null ? 8 : 2,
                            ),
                            const WalletRewardBanner(amount: 1000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _SignupBottomBar(
                    isLoading: isLoading,
                    onPressed: (isLoading ||
                            _checkingReferral ||
                            _referralError != null)
                        ? null
                        : _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final referralCode = _referralController.text.trim().toUpperCase();
    // Re-check right before submitting if it hasn't been verified yet (e.g.
    // the user typed fast and hit "done" before the debounce fired) — same
    // last-mile guard web does in handleAggreeAndContinue.
    if (referralCode.isNotEmpty &&
        !(_referralVerified && _lastCheckedReferral == referralCode)) {
      final valid = await _checkReferralCode(referralCode);
      if (!valid || !mounted) return;
    }

    _lastSubmittedReferralCode = referralCode;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            phone: _rawPhone,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            referralCode: referralCode.isEmpty ? null : referralCode,
          ),
        );
  }

  Future<void> _handleBack() async {
    await AuthSession.instance.signOut();
    if (!mounted) return;
    context.go(LoginpageWidget.routePath);
  }
}

class _SignupBottomBar extends StatelessWidget {
  const _SignupBottomBar({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 10 + bottomPadding),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF0360E5),
            disabledBackgroundColor: const Color(0xFF9BBFF1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Agree and continue',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 21 / 14,
                  ),
                ),
        ),
      ),
    );
  }
}

String _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}
