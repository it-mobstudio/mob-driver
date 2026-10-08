import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/image_decode.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(this.name, {super.key, this.size = 44, this.photoUrl});
  final String name;
  final double size;

  /// The driver's own photo, when they've added one; the initial otherwise (and
  /// if the picture can't be loaded).
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final radius = BorderRadius.circular(size * .32);
    final initial = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: AppColors.blueSoft, borderRadius: radius),
      child: Text(trimmed.isEmpty ? 'D' : trimmed.substring(0, 1).toUpperCase(),
          style: TextStyle(
              color: AppColors.blue,
              fontSize: size * .4,
              fontWeight: FontWeight.w800)),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty) return initial;
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: thumbPixels(context, size),
        errorBuilder: (_, __, ___) => initial,
      ),
    );
  }
}
