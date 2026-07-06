import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBackIcon extends StatelessWidget {
  const AppBackIcon({
    super.key,
    this.size = 16,
    this.color = const Color(0xFF0A243F),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/Back.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
