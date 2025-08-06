import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SignupWidget extends StatefulWidget {
  final String phoneNumber;
  const SignupWidget({super.key, required this.phoneNumber});

  static String routeName = 'Signup';
  static String routePath = '/signup';

  @override
  State<SignupWidget> createState() => _SignupWidgetState();
}

class _SignupWidgetState extends State<SignupWidget> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _businessController = TextEditingController();

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
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF0A243F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              Text(
                'Complete sign up',
                style: GoogleFonts.interTight(
                  color: Color(0xFF0A243F),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name*',
                  labelStyle: GoogleFonts.inter(
                    color: Color(0xFF6C7C8C),
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.inter(
                  color: Color(0xFF0A243F),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email id',
                  labelStyle: GoogleFonts.inter(
                    color: Color(0xFF6C7C8C),
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.inter(
                  color: Color(0xFF0A243F),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: widget.phoneNumber,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Business mobile (for OTP)',
                  labelStyle: GoogleFonts.inter(
                    color: Color(0xFF6C7C8C),
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.inter(
                  color: Color(0xFF0A243F),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFFDF3ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Upgrade to ',
                          style: GoogleFonts.inter(
                            color: Color(0xFF0A243F),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'mob ',
                          style: GoogleFonts.inter(
                            color: Color(0xFF0A243F),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF0360E5),
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
                        Text(
                          ' for free by adding GSTIN',
                          style: GoogleFonts.inter(
                            color: Color(0xFF0A243F),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFFFA7A1A), size: 20),
                        SizedBox(width: 8),
                        Text('View RFQ price for items',
                            style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Color(0xFFFA7A1A), size: 20),
                        SizedBox(width: 8),
                        Text('Place order with RFQ price',
                            style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _gstinController,
                      decoration: InputDecoration(
                        labelText: 'GSTIN',
                        labelStyle: GoogleFonts.inter(
                          color: Color(0xFF6C7C8C),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: GoogleFonts.inter(
                        color: Color(0xFF0A243F),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _businessController,
                      decoration: InputDecoration(
                        labelText: 'Business name',
                        labelStyle: GoogleFonts.inter(
                          color: Color(0xFF6C7C8C),
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: GoogleFonts.inter(
                        color: Color(0xFF0A243F),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'By clicking agree and continue you agree to our ',
                  style: GoogleFonts.inter(
                    color: Color(0xFF6C7C8C),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: 'Terms and Conditions and Privacy Statement.',
                      style: GoogleFonts.inter(
                        color: Color(0xFF0360E5),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Handle sign up logic
                    context.go('/address_selection');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0360E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Agree and continue',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
