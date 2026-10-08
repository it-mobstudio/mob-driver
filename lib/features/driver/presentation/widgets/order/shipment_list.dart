import 'package:flutter/material.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/dashed_border.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/widgets/photo_widgets.dart';

/// `6 items in shipment` with a chevron that folds the list away.
class ShipmentHeader extends StatelessWidget {
  const ShipmentHeader({
    super.key,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
          child: Row(children: [
            Expanded(
              child: Text(
                  tr('{count} {p0} in shipment',
                      {'count': count, 'p0': count == 1 ? 'item' : 'items'}),
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            IconButton(
              key: const Key('order_details_items_toggle'),
              onPressed: onToggle,
              icon: AnimatedRotation(
                turns: expanded ? .5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
          ]),
        ),
      );
}

/// The items, separated by dashed rules. [photoSlotFor] adds a camera slot
/// under an item (orders wanting a photo per item); null leaves it plain.
class ShipmentItemList extends StatelessWidget {
  const ShipmentItemList({super.key, required this.items, this.photoSlotFor});

  final List<TripItem> items;
  final Widget? Function(TripItem item)? photoSlotFor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const DashedDivider(),
            ShipmentItemRow(
                item: items[i], photoSlot: photoSlotFor?.call(items[i])),
          ],
        ]),
      );
}

/// Picture, name (two lines), the variant line in grey and the `x 2` chip.
class ShipmentItemRow extends StatelessWidget {
  const ShipmentItemRow({super.key, required this.item, this.photoSlot});

  final TripItem item;
  final Widget? photoSlot;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetworkThumb(item.imageUrl, size: 52, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600)),
              if (item.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(item.notes!,
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
              if ((item.driverNote ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                    key: Key('item_driver_note_${item.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: item.status == ItemStatus.notDelivered
                              ? AppColors.red
                              : AppColors.muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                            item.status == ItemStatus.notDelivered
                                ? tr('Not delivered · {p0}',
                                    {'p0': item.driverNote!.trim()})
                                : item.driverNote!.trim(),
                            style: TextStyle(
                                color: item.status == ItemStatus.notDelivered
                                    ? AppColors.red
                                    : AppColors.muted,
                                fontSize: 12,
                                height: 1.3)),
                      ),
                    ]),
              ],
              if (photoSlot != null) ...[
                const SizedBox(height: 10),
                photoSlot!,
              ],
            ]),
          ),
          const SizedBox(width: 10),
          _ShipmentQuantity(item.quantity),
        ]),
      );
}

/// `x 13` in a soft grey pill.
class _ShipmentQuantity extends StatelessWidget {
  const _ShipmentQuantity(this.quantity);
  final int quantity;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10)),
        child: Text('x $quantity',
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      );
}
