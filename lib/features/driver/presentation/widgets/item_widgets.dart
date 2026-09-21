import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

/// The state of every item at a glance: one segment per item — green
/// delivered, red problem, grey still to check. A very long list would make
/// hairline segments, so past [maxSegments] it draws proportional blocks.
class ItemProgressBar extends StatelessWidget {
  const ItemProgressBar({
    super.key,
    required this.items,
    this.height = 8,
    this.maxSegments = 16,
  });

  final List<TripItem> items;
  final double height;
  final int maxSegments;

  static Color colorOf(ItemStatus status) => switch (status) {
        ItemStatus.delivered => DriverColors.green,
        ItemStatus.notDelivered => DriverColors.red,
        _ => DriverColors.line,
      };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final segments = items.length <= maxSegments
        ? [for (final item in items) (colorOf(item.status), 1)]
        : [
            for (final status in [
              ItemStatus.delivered,
              ItemStatus.notDelivered,
              ItemStatus.pending,
            ])
              if (items.any((i) => i.status == status))
                (
                  colorOf(status),
                  items.where((i) => i.status == status).length
                ),
          ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Row(children: [
        for (var i = 0; i < segments.length; i++)
          Expanded(
            flex: segments[i].$2,
            child: Padding(
              padding: EdgeInsets.only(right: i == segments.length - 1 ? 0 : 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: height,
                color: segments[i].$1,
              ),
            ),
          ),
      ]),
    );
  }
}

/// "× 4 bags" — how many to hand over, the fact the driver actually needs, so
/// it's a chip, not fine print.
class QuantityChip extends StatelessWidget {
  const QuantityChip(this.label, {super.key, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
        decoration: BoxDecoration(
          color: DriverColors.blue.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(compact ? 8 : 9),
        ),
        child: Text('× $label',
            style: TextStyle(
                color: DriverColors.blue,
                fontSize: compact ? 12.5 : 14.5,
                fontWeight: FontWeight.w800)),
      );
}

/// Where one item stands, in words — "To check", "Delivered", "Problem" —
/// so nobody has to decode a coloured icon.
class ItemStatusChip extends StatelessWidget {
  const ItemStatusChip(this.status, {super.key});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = switch (status) {
      ItemStatus.delivered => (
          'Delivered',
          DriverColors.green,
          Icons.check_rounded
        ),
      ItemStatus.notDelivered => (
          'Problem',
          DriverColors.red,
          Icons.priority_high_rounded
        ),
      _ => (
          'To check',
          DriverColors.muted,
          Icons.radio_button_unchecked_rounded
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// "3 delivered · 1 problem · 2 to check" — only the parts that aren't zero.
String itemTally(List<TripItem> items) {
  int count(ItemStatus s) => items.where((i) => i.status == s).length;
  final parts = [
    if (count(ItemStatus.delivered) > 0)
      '${count(ItemStatus.delivered)} delivered',
    if (count(ItemStatus.notDelivered) > 0)
      '${count(ItemStatus.notDelivered)} problem${count(ItemStatus.notDelivered) == 1 ? '' : 's'}',
    if (count(ItemStatus.pending) > 0) '${count(ItemStatus.pending)} to check',
  ];
  return parts.join(' · ');
}
