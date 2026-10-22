import 'package:flutter/material.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';

/// The trip-fare / unloading-bonus split — shared by the incoming-order
/// offer screen and the order-details screen, so the two numbers always
/// read the same way. A single full-width chip when there's no bonus.
class FareChips extends StatelessWidget {
  const FareChips({
    super.key,
    required this.tripFare,
    required this.bonus,
    this.extraBonus,
    this.currency = 'INR',
  });

  final double? tripFare;

  /// Null (not just zero) hides the second chip entirely.
  final double? bonus;

  /// The company's later top-up for heavier loads; its own cell when set.
  final double? extraBonus;
  final String currency;

  /// A zero bonus has no cell of its own once the extra one is there.
  bool get showBonus => bonus != null && (bonus! > 0 || extraBonus == null);

  static const _rule = Color(0xFFE7D6AE);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: AppColors.orangeSoft,
            borderRadius: BorderRadius.circular(16)),
        // The cells are as tall as the tallest label, with their amounts all
        // on one line at the top, so a label that wraps never pushes its
        // amount out of line with the others.
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _cell(tr('Trip fare'), tripFare)),
            if (showBonus) ...[
              _divider,
              Expanded(
                  child: _cell(tr('Unloading bonus'), bonus,
                      key: const Key('fare_bonus'))),
            ],
            if (extraBonus != null) ...[
              _divider,
              Expanded(
                  child: _cell(tr('Extra loading bonus'), extraBonus,
                      key: const Key('fare_extra_bonus'))),
            ],
          ]),
        ),
      );

  Widget get _divider => Container(
      width: 1, margin: const EdgeInsets.symmetric(vertical: 12), color: _rule);

  Widget _cell(String label, double? value, {Key? key}) => Padding(
        key: key,
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 14),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatMoneyShort(value, currency: currency),
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.muted, fontSize: 12, height: 1.2)),
        ]),
      );
}
