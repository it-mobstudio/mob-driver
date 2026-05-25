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
            Row(
              children: [
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: SizedBox(
                      height: 100,
                      child: Image.asset(
                        'assets/images/Leftside.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: SizedBox(
                      height: 100,
                      child: Image.asset(
                        'assets/images/Rightside.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 75,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.50, 0.00),
                    end: Alignment(0.50, 1.00),
                    colors: [
                      Color(0xFF121212),
                      Color(0x00131313),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SvgPicture.asset(
                'assets/images/Qwiklogo.svg',
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
