import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/buttons.dart';

/// A quiet secondary action: soft grey fill, no outline — next to a dark
/// primary (Map) it reads as the lesser choice without shouting.
class TonalButton extends StatelessWidget {
  const TonalButton(
      {super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => PressScale(
        enabled: onPressed != null,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            foregroundColor: AppColors.ink,
            minimumSize: const Size.fromHeight(44),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 17),
              const SizedBox(width: 6),
            ],
            Text(label),
          ]),
        ),
      );
}
