import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:go_router/go_router.dart';
import '/features/auth/repositories/auth_repository.dart';
import '/core/auth/auth_session.dart';
import '/index.dart';

class SignupWidget extends StatefulWidget {
  final String phoneNumber;
  const SignupWidget({super.key, required this.phoneNumber});

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
  final _gstinController = TextEditingController();
  final _businessController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Complete sign up',
                  style: GoogleFonts.interTight(
                    color: const Color(0xFF0A243F),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Name*',
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFF6C7C8C),
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email id',
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFF6C7C8C),
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.phoneNumber,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Business mobile (for OTP)',
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFF6C7C8C),
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF3ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Upgrade to ',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'mob ',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0360E5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PRO',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'adding GSTIN',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFFFA7A1A), size: 20),
                          const SizedBox(width: 8),
                          Text('View RFQ price for items',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6C7C8C),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFFFA7A1A), size: 20),
                          const SizedBox(width: 8),
                          Text('Place order with RFQ price',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6C7C8C),
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gstinController,
                        decoration: InputDecoration(
                          labelText: 'GSTIN',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6C7C8C),
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF0A243F), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _businessController,
                        decoration: InputDecoration(
                          labelText: 'Business name',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6C7C8C),
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF0A243F), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'By clicking agree and continue you agree to our ',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6C7C8C),
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms and Conditions and Privacy Statement.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0360E5),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onAgreeAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0360E5),
                      disabledBackgroundColor:
                          const Color(0xFF0360E5).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Agree and continue',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAgreeAndContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // Strip '+91' and spaces from phone to get raw number
    final rawPhone =
        widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();

    final result = await _authRepository.register(
      phone: rawPhone,
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      gstin: _gstinController.text.trim().isEmpty
          ? null
          : _gstinController.text.trim(),
      businessName: _businessController.text.trim().isEmpty
          ? null
          : _businessController.text.trim(),
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
