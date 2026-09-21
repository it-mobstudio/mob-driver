import 'package:flutter/material.dart';

/// Shown only when the backend echoes an OTP back (its non-production
/// `DRIVER_OTP_DEBUG_RESPONSE` mode, used because no SMS gateway is wired up
/// yet) — for driver login and for the customer's delivery OTP alike.
/// Clearly labelled so it can't be mistaken for a real feature.
class TestModeOtpHint extends StatelessWidget {
  const TestModeOtpHint({
    super.key,
    required this.otp,
    required this.onFill,
    this.label = 'Test mode · your OTP is ',
  });
  final String otp;
  final VoidCallback onFill;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.science_outlined, size: 18, color: Color(0xFFD88212)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9B6413))),
              TextSpan(
                  text: otp,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFF9B6413))),
            ])),
          ),
          TextButton(
            onPressed: onFill,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30)),
            child: const Text('Fill'),
          ),
        ]),
      );
}
