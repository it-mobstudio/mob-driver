import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import 'package:mob_driver/core/constants/app_assets.dart';

/// Shown while the app starts: the animated mark over the MOB logo, laid out
/// on a 375×812 design frame and scaled to the screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _background = Color(0xFF022454);
  static const _designSize = Size(375, 812);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        body: LayoutBuilder(builder: (context, constraints) {
          final scaleX = constraints.maxWidth / _designSize.width;
          final scaleY = constraints.maxHeight / _designSize.height;
          final animationSize = 150 * scaleX;
          final logoSize = Size(176 * scaleX, 48 * scaleX);

          return Stack(fit: StackFit.expand, children: [
            Positioned(
              top: 218 * scaleY,
              left: (constraints.maxWidth - animationSize) / 2,
              child: SizedBox.square(
                dimension: animationSize,
                child:
                    Lottie.asset(AppAssets.splashAnimation, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 378 * scaleY,
              left: (constraints.maxWidth - logoSize.width) / 2,
              child: SizedBox.fromSize(
                size: logoSize,
                child: SvgPicture.asset(AppAssets.mobLogo),
              ),
            ),
          ]);
        }),
      );
}
