import 'package:flutter/material.dart';
import 'package:mob_driver/core/constants/app_assets.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/features/driver/presentation/widgets/trip/fare_chips.dart';

/// `You'll receive ₹420`, the trip-fare / bonus split, and the
/// heavy-unloading note when there's a bonus.
class EarningsSummary extends StatelessWidget {
  const EarningsSummary({
    super.key,
    required this.tripFare,
    this.bonus,
    this.currency = 'INR',
  });

  final double? tripFare;

  /// Null or zero: no bonus chip, no banner.
  final double? bonus;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final hasBonus = bonus != null && bonus! > 0;
    final total = (tripFare ?? 0) + (hasBonus ? bonus! : 0);
    return Column(children: [
      Text(tr('You’ll receive'),
          style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(formatMoneyShort(total, currency: currency),
          key: const Key('order_details_total'),
          style: TextStyle(
              color: AppColors.ink, fontSize: 30, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      FareChips(
          tripFare: tripFare,
          bonus: hasBonus ? bonus : null,
          currency: currency),
      if (hasBonus) ...[
        const SizedBox(height: 12),
        const HeavyUnloadingBanner(),
      ],
    ]);
  }
}

class HeavyUnloadingBanner extends StatelessWidget {
  const HeavyUnloadingBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('heavy_unloading_banner'),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
            color: AppColors.redSoft,
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Heavy unloading'),
                  style: TextStyle(
                      color: AppColors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(tr('Additional unloading fee included for this delivery'),
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 12, height: 1.35)),
            ]),
          ),
          const SizedBox(width: 10),
          Image.asset(AppAssets.heavyLoading,
              width: 64, height: 64, fit: BoxFit.contain),
        ]),
      );
}
