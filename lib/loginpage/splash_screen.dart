import 'dart:async';
import 'package:flutter/material.dart';
import 'loginpage_widget.dart'; // Ensure this import is correct

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () { // Reduced timer for testing
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) =>
                LoginpageWidget()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Optional: Get screen dimensions for debugging
    // final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width;
    // print("Screen Height: $screenHeight, Screen Width: $screenWidth");

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              // You can experiment with alignment if the default center crop isn't what you want
              // alignment: Alignment.center, // Default
              // alignment: Alignment.topCenter, // If you want to prioritize showing the top
              // alignment: Alignment.bottomCenter, // If you want to prioritize showing the bottom (but it might still crop if too tall)
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
