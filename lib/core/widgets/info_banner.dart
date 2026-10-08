import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';

class InfoBanner extends StatelessWidget {
  InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    Color? color,
    this.action,
    this.solid = false,
  }) : color = color ?? AppColors.orange;

  final String text;
  final IconData icon;
  final Color color;
  final Widget? action;

  /// Paint the tint over white, for banners that sit on a dark header.
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: solid
              ? Color.alphaBlend(color.withValues(alpha: .1), AppColors.card)
              : color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600)),
          ),
          if (action != null) action!,
        ]),
      );
}
