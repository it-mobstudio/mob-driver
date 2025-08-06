import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'o_t_p_verification_model.dart';
export 'o_t_p_verification_model.dart';

/// OTP Verification Screen
class OTPVerificationWidget extends StatefulWidget {
  final String phoneNumber;
  const OTPVerificationWidget({super.key, required this.phoneNumber});

  static String routeName = 'OTPVerification';
  static String routePath = '/OTPVerification';

  @override
  State<OTPVerificationWidget> createState() => _OTPVerificationWidgetState();
}

class _OTPVerificationWidgetState extends State<OTPVerificationWidget> {
  late OTPVerificationModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // OTP input controllers
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  int _resendSeconds = 40;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OTPVerificationModel());
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() {
          _resendSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Color(0xFF0A243F)),
            onPressed: () => context.go('/loginpage'),
          ),
          elevation: 0.0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),
                Text(
                  'OTP Verification',
                  style: GoogleFonts.interTight(
                    color: Color(0xFF0A243F),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    text: 'OTP has been sent to ',
                    style: GoogleFonts.inter(
                      color: Color(0xFF0A243F),
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: widget.phoneNumber,
                        style: GoogleFonts.inter(
                          color: Color(0xFF0A243F),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(4, (i) {
                    return Container(
                      width: 56,
                      height: 56,
                      margin: EdgeInsets.only(right: i < 3 ? 16 : 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _otpFocusNodes[i].hasFocus
                              ? Color(0xFF0A243F)
                              : Color(0xFFAFB4C0),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _otpControllers[i],
                          focusNode: _otpFocusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: GoogleFonts.interTight(
                            color: Color(0xFF0A243F),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 3) {
                              FocusScope.of(context)
                                  .requestFocus(_otpFocusNodes[i + 1]);
                            } else if (val.isEmpty && i > 0) {
                              FocusScope.of(context)
                                  .requestFocus(_otpFocusNodes[i - 1]);
                            }
                            // If all OTP fields are filled, navigate to signup
                            if (_otpControllers
                                .every((c) => c.text.isNotEmpty)) {
                              context.go('/signup',
                                  extra: {'phoneNumber': widget.phoneNumber});
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 24),
                Text(
                  _resendSeconds > 0
                      ? 'Resend OTP in ${_resendSeconds}s'
                      : 'Resend OTP',
                  style: GoogleFonts.inter(
                    color: Color(0xFFAFB4C0),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
