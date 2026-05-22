import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/index.dart';
import '/core/app_runtime/flutter_flow_util.dart';

class LoginTopBanner extends StatelessWidget {
  const LoginTopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(size.width * 0.08),
        bottomRight: Radius.circular(size.width * 0.08),
      ),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/Loginimage.webp',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: topPadding + size.height * 0.02,
            left: size.width * 0.05,
            right: size.width * 0.05,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/moblogo.svg',
                      height: size.height * 0.032,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        context.go(HomepageWidget.routePath);
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.025),
                SvgPicture.asset(
                  'assets/images/delivery.svg',
                  height: size.height * 0.09,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
