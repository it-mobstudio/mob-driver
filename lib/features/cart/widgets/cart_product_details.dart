import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/shared/quantity_stepper.dart';

class CartProductDetails extends StatelessWidget {
  const CartProductDetails({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onQtyInputChanged,
    required this.onDelete,
    this.showQuantityControl = true,
    this.showDelete = true,
    this.isBusy = false,
  });

  final CartItem item;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<String> onQtyInputChanged;
  final VoidCallback onDelete;
  final bool showQuantityControl;
  final bool showDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            height: 26,
            width: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.qty}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8EEF5)),
            ),
            child: item.isNetworkImage
                ? Image.network(
                    item.imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/Image-coming-soon.png',
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(item.imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹ ${item.unitPrice.toStringAsFixed(0)} /unit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6C7C8C),
                  ),
                ),
                if (showDelete) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: isBusy ? null : onDelete,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: isBusy
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isBusy
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.lineTotal.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (showQuantityControl) ...[
                const SizedBox(height: 8),
                QuantityStepper(
                  value: item.qty,
                  onDecrement: () => onQtyChanged(item.qty - 1),
                  onIncrement: () => onQtyChanged(item.qty + 1),
                  onInputChanged: onQtyInputChanged,
                  isBusy: isBusy,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
