import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
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
  LoginpageModel? _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = LoginpageModel();
    _model?.mobileNumberTextController ??= TextEditingController();
    _model?.mobileNumberFocusNode ??= FocusNode();
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFC1EBD9),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 48),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Image.asset(
                        'assets/images/login_top_items.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        // height: 100,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      'Construction & interior materials delivered same day',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Color(0xFF0A243F),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Log in or sign up',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Color(0xFF6C7C8C),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Text(
                        '+91',
                        style: GoogleFonts.inter(
                          color: Color(0xFF0A243F),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 12),
                        width: 1,
                        height: 24,
                        color: Color(0xFFAFB4C0),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: model.mobileNumberTextController,
                          focusNode: model.mobileNumberFocusNode,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter mobile number',
                            hintStyle: GoogleFonts.inter(
                              color: Color(0xFFAFB4C0),
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: GoogleFonts.inter(
                            color: Color(0xFF0A243F),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final mobile =
                          model.mobileNumberTextController.text.trim();
                      if (mobile.isEmpty || mobile.length != 10) {
                        await showDialog(
                          context: context,
                          builder: (alertDialogContext) {
                            return AlertDialog(
                              title: Text('Invalid Number'),
                              content: Text(
                                  'Please enter a valid 10-digit mobile number.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(alertDialogContext),
                                  child: Text('Ok'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }
                      final parsedMobile = int.tryParse(mobile);
                      if (parsedMobile == null) {
                        await showDialog(
                          context: context,
                          builder: (alertDialogContext) {
                            return AlertDialog(
                              title: Text('Invalid Number'),
                              content: Text(
                                  'Please enter a valid 10-digit mobile number.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(alertDialogContext),
                                  child: Text('Ok'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }
                      model.status = await LoginOTPCall.call(
                        emailOrPhone: parsedMobile,
                      );
                      final responseJson = model.status?.jsonBody;
                      final status =
                          responseJson is Map && responseJson['status'] == true;
                      final message =
                          responseJson is Map && responseJson['message'] != null
                              ? responseJson['message'].toString()
                              : 'Failed to send OTP. Please try again.';
                      if (status) {
                        if (mounted) {
                          // Use GoRouter navigation to OTPVerificationWidget and pass mobile number
                          context.go(
                            OTPVerificationWidget.routePath,
                            extra: {'phoneNumber': '+91 $mobile'},
                          );
                        }
                      } else {
                        await showDialog(
                          context: context,
                          builder: (alertDialogContext) {
                            return AlertDialog(
                              title: Text('Login Failed'),
                              content: Text(message),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(alertDialogContext),
                                  child: Text('Ok'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0360E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Or',
                style: GoogleFonts.inter(
                  color: Color(0xFF6C7C8C),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/google_icon.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                  SizedBox(width: 24),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/email_icon.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
