import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  // A getter, not a cached field: it has to follow light/dark.
  static BoxDecoration get _decoration => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.line),
    // One soft shadow: the border already outlines the card, and every
    // blurred layer is paid for on each frame the card is on screen.
    boxShadow: const [
      BoxShadow(color: Color(0x0A001533), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Container(padding: padding, decoration: _decoration, child: child);
    }
    // Ink (not a decorated Container) so the tap ripple paints *above* the
    // white card instead of being hidden beneath it.
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(title,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) trailing!,
      ]);
}

/// One `label ...... value` line.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value,
      {super.key, this.valueColor, this.bold = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? AppColors.ink,
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ),
        ]),
      );
}
