import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginTopBanner extends StatelessWidget {
  const LoginTopBanner({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(size.width * 0.085),
          bottomRight: Radius.circular(size.width * 0.085),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/Loginimage.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            Positioned(
              top: topPadding + 24,
              left: 16,
              child: SvgPicture.asset(
                'assets/images/moblogo.svg',
                width: 108,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: topPadding + 72,
              left: 16,
              child: SvgPicture.asset(
                'assets/images/delivery.svg',
                width: 178,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
