import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePromoBanner extends StatelessWidget {
  const HomePromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF3D0E09)),
            Image.asset(
              'assets/images/bannerBG.png',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF131313),
                    Color(0x00131313),
                  ],
                ),
              ),
            ),
            Center(
              child: SvgPicture.asset(
                'assets/images/Qwiklogo.svg',
                height: 68,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
