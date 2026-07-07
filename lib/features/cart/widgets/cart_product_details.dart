import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:m_o_b_demand_side/shared/quantity_stepper.dart';

class CartProductDetails extends StatelessWidget {
  const CartProductDetails({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onQtyInputChanged,
    required this.onDelete,
    this.index,
    this.showQuantityControl = true,
    this.showDelete = true,
    this.isBusy = false,
  });

  final CartItem item;
  final int? index;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<String> onQtyInputChanged;
  final VoidCallback onDelete;
  final bool showQuantityControl;
  final bool showDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final removeColor =
        isBusy ? const Color(0xFFBBBBBB) : const Color(0xFF767C8F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Item row: index · image · name+price ──────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Item index number
            SizedBox(
              width: 20,
              child: Text(
                '${index != null ? index! + 1 : item.qty}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A243F),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Product image
            SizedBox(
              width: 68,
              height: 68,
              child: item.isNetworkImage
                  ? CachedNetworkImage(
                      imageUrl: item.imageAsset,
                      fit: BoxFit.contain,
                      memCacheWidth: 136,
                      placeholder: (_, __) => const ImageShimmer(),
                      errorWidget: (_, __, ___) =>
                          const ProductImagePlaceholder(),
                    )
                  : const ProductImagePlaceholder(),
            ),
            const SizedBox(width: 10),
            // Product name + unit price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A243F),
                      height: 20 / 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${item.unitPrice.toStringAsFixed(0)} /unit',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8A8A),
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Line total
            Text(
              '₹${item.lineTotal.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: const Color(0xFF0A243F),
              ),
            ),
          ],
        ),

        // ── Actions row: Remove · Stepper ─────────────────────────────
        if (showDelete || showQuantityControl) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (showDelete)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isBusy ? null : onDelete,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/trash.svg',
                        width: 14,
                        height: 14,
                        colorFilter:
                            ColorFilter.mode(removeColor, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Remove',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: removeColor,
                          decoration: TextDecoration.underline,
                          decorationColor: removeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (showQuantityControl)
                QuantityStepper(
                  value: item.qty,
                  width: 108,
                  onDecrement: () => onQtyChanged(item.qty - 1),
                  onIncrement: () => onQtyChanged(item.qty + 1),
                  onInputChanged: onQtyInputChanged,
                  isBusy: isBusy,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
