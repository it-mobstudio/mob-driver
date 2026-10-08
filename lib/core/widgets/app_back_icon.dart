import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mob_driver/core/constants/app_assets.dart';

import 'package:mob_driver/core/theme/app_colors.dart';

class AppBackIcon extends StatelessWidget {
  AppBackIcon({
    super.key,
    this.size = 16,
    Color? color,
  }) : color = color ?? AppColors.ink;

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.back,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
