import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

class LoginTopBanner extends StatelessWidget {
  const LoginTopBanner({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(32)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/Loginimage.webp',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xA6001533),
                      Color(0x44001533),
                      Color(0xF2001533),
                    ],
                    stops: [0, .45, 1],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/images/moblogo.svg',
                              width: 108,
                              semanticsLabel: 'MOB',
                            ),
                            const SizedBox(width: 10),
                            const Text('Go',
                                style: TextStyle(
                                  color: DriverColors.mint,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                )),
                          ],
                        ),
                        if (height > 220) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Your fleet. On the move.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
