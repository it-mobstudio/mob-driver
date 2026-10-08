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
    this.currency = 'INR',
  });

  final double? tripFare;

  /// Null (not just zero) hides the second chip entirely.
  final double? bonus;
  final String currency;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: AppColors.orangeSoft,
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _cell(tr('Trip fare'), tripFare)),
          if (bonus != null) ...[
            Container(width: 1, height: 46, color: const Color(0xFFE7D6AE)),
            Expanded(
                child: _cell(tr('Unloading bonus'), bonus,
                    key: const Key('fare_bonus'))),
          ],
        ]),
      );

  Widget _cell(String label, double? value, {Key? key}) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(formatMoneyShort(value, currency: currency),
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ]),
      );
}
