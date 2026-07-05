import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _nameController.text = _firstString(user, const [
      'full_name',
      'fullName',
      'name',
      'first_name',
      'username',
    ]);
    _phoneController.text = _formatPhone(_rawPhone);
    _emailController.text = _firstString(user, const ['email', 'email_id']);
    _nameFocusNode.addListener(_onFieldFocusChanged);
    _emailFocusNode.addListener(_onFieldFocusChanged);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFieldFocusChanged);
    _emailFocusNode.removeListener(_onFieldFocusChanged);
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onFieldFocusChanged() {
    if (mounted) setState(() {});
  }

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
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          context.go(
            AddressSelectionWidget.routePath,
            extra: {
              'returnToHome': true,
              'showReferralBonus': false,
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
            backgroundColor: const Color(0xFFF0F0F0),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A243F),
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const AppBackIcon(),
              ),
              centerTitle: true,
              title: Text(
                'Personal info',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 22 / 15,
                ),
              ),
              toolbarHeight: 60,
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 343),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _SignupAvatar(
                                    onEdit: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Profile image upload coming soon',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 40),
                                  _SignupField(
                                    label: 'Name',
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
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
                                  _SignupField(
                                    label: 'Business mobile',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    readOnly: true,
                                  ),
                                  const SizedBox(height: 20),
                                  _SignupField(
                                    label: 'Email',
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _SignupBottomBar(
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameController.text.trim(),
            phone: _rawPhone,
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
          ),
        );
  }
}

class _SignupAvatar extends StatelessWidget {
  const _SignupAvatar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const CircleAvatar(
            radius: 52,
            backgroundColor: Color(0xFFF0F0F0),
            child: Icon(
              Icons.person,
              color: Color(0xFF969696),
              size: 58,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFCBD3DE)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.edit,
                    size: 17,
                    color: Color(0xFF0A243F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode?.hasFocus ?? false;
    final textColor =
        readOnly ? const Color(0x7F0A243F) : const Color(0xFF0A243F);
    final labelColor =
        isFocused ? const Color(0xFF0A243F) : const Color(0xFF767C8F);

    return SizedBox(
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: isFocused ? 1.5 : 1,
                    color: isFocused
                        ? const Color(0xFF0A243F)
                        : const Color(0xFFDFE4EC),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned.fill(
            left: 16,
            right: 16,
            top: 0,
            child: Center(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                readOnly: readOnly,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                validator: validator,
                cursorColor: const Color(0xFF0A243F),
                cursorHeight: 14,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 2),
                  errorStyle: TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: -7,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$label*',
                  style: GoogleFonts.inter(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 14 / 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 9),
            blurRadius: 24,
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 343),
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
                      'Update profile',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 21 / 14,
                      ),
                    ),
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

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10) return digits.substring(digits.length - 10);
  return phone;
}
