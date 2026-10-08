import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

class LoginTopBanner extends StatelessWidget {
  const LoginTopBanner({super.key, required this.height});

  final double height;

  // The artwork's own proportions (width / height).
  static const _truckAspect = 293 / 142;
  static const _personAspect = 249 / 244;

  @override
  Widget build(BuildContext context) {
    final headlineStyle = GoogleFonts.inter(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -.4,
      height: 1.3,
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
        child: LayoutBuilder(builder: (context, constraints) {
          // Everything is placed as a share of the banner itself — not the
          // window, which is wider than the banner on a tablet or the web.
          // On a banner that's wide for its height the artwork follows the
          // height instead, so it never outgrows the banner.
          final unit = constraints.maxWidth < height * 1.05
              ? constraints.maxWidth
              : height * 1.05;
          final truckWidth = unit * .74;
          final personWidth = unit * .65;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF05080F),
                      Color(0xFF0F2244),
                      Color(0xFF1C3D73),
                    ],
                    stops: [0, .5, 1],
                  ),
                ),
              ),
              // The truck sits on the banner's bottom edge, its cab near the
              // left; the driver stands in front of its box.
              Positioned(
                left: unit * .058,
                bottom: 0,
                width: truckWidth,
                height: truckWidth / _truckAspect,
                child: Image.asset(
                  'assets/images/vehicles/tata_ace.png',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                width: personWidth,
                height: personWidth / _personAspect,
                child: Image.asset(
                  'assets/images/vehicles/person.png',
                  fit: BoxFit.fill,
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Sign up in minutes.\n'),
                          TextSpan(
                            text: 'Start earning',
                            style: headlineStyle.copyWith(
                              color: DriverColors.mint,
                            ),
                          ),
                          const TextSpan(text: ' today.'),
                        ],
                      ),
                      style: headlineStyle,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
