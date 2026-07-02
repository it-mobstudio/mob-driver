import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        // height: 148,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A3C35), Color(0xFF10534A)],
          ),
        ),
        child: Lottie.asset(
          'assets/lottiejson/mob_banner.json',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
