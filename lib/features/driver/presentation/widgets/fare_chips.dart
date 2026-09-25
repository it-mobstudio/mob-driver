import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

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
            color: const Color(0xFFFBEEDA), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: _cell('Trip fare', tripFare)),
          if (bonus != null) ...[
            Container(width: 1, height: 46, color: const Color(0xFFE7D6AE)),
            Expanded(
                child: _cell('Unloading bonus', bonus,
                    key: const Key('fare_bonus'))),
          ],
        ]),
      );

  Widget _cell(String label, double? value, {Key? key}) => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(formatMoneyShort(value, currency: currency),
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(color: DriverColors.muted, fontSize: 12)),
        ]),
      );
}
