import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginTopBanner extends StatelessWidget {
  const LoginTopBanner({
    super.key,
    required this.height,
    this.onSkip,
  });

  final double height;
  final VoidCallback? onSkip;

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
              top: topPadding + 24,
              right: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSkip,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 22 / 15,
                    ),
                  ),
                ),
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
