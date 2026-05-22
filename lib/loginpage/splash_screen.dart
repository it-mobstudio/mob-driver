// import 'package:flutter/material.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   Widget build(BuildContext context) {
//     // Optional: Get screen dimensions for debugging
//     // final screenHeight = MediaQuery.of(context).size.height;
//     // final screenWidth = MediaQuery.of(context).size.width;
//     // print("Screen Height: $screenHeight, Screen Width: $screenWidth");

//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset(
//               'assets/images/background.png',
//               fit: BoxFit.cover,
//               // You can experiment with alignment if the default center crop isn't what you want
//               // alignment: Alignment.center, // Default
//               // alignment: Alignment.topCenter, // If you want to prioritize showing the top
//               // alignment: Alignment.bottomCenter, // If you want to prioritize showing the bottom (but it might still crop if too tall)
//             ),
//           ),
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Image.asset(
//                   'assets/images/logo.png',
//                   width: 180,
//                 ),
//                 const SizedBox(height: 16),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022454),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const designWidth = 375.0;
          const designHeight = 812.0;

          final widthScale = constraints.maxWidth / designWidth;
          final heightScale = constraints.maxHeight / designHeight;
          final animationSize = 150 * widthScale;
          final logoWidth = 176 * widthScale;
          final logoHeight = 48 * widthScale;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 218 * heightScale,
                left: (constraints.maxWidth - animationSize) / 2,
                child: SizedBox.square(
                  dimension: animationSize,
                  child: Lottie.asset(
                    'assets/jsons/Splashlottie.json',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 378 * heightScale,
                left: (constraints.maxWidth - logoWidth) / 2,
                child: SizedBox(
                  width: logoWidth,
                  height: logoHeight,
                  child: SvgPicture.asset(
                    'assets/images/moblogo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
