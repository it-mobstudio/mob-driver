import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

enum ProductSortOption {
  popularity,
  priceLowToHigh,
  priceHighToLow,
  // ratings,
}

extension ProductSortOptionLabel on ProductSortOption {
  String get label {
    switch (this) {
      case ProductSortOption.popularity:
        return 'Popularity';
      case ProductSortOption.priceLowToHigh:
        return 'Price - low to high';
      case ProductSortOption.priceHighToLow:
        return 'Price - high to low';
      // case ProductSortOption.ratings:
      // return 'Ratings';
    }
  }
}

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({
    super.key,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  final ProductSortOption selectedOption;
  final ValueChanged<ProductSortOption> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    'Sort by',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 22 / 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF0A243F),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7E7)),
            const SizedBox(height: 14),
            ...ProductSortOption.values.map(
              (option) => _SortOptionRow(
                option: option,
                selected: option == selectedOption,
                onTap: () {
                  onOptionSelected(option);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SortOptionRow extends StatelessWidget {
  const _SortOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ProductSortOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0360E5) : const Color(0xFF676A6C);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: _SortOptionIcon(option: option, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
              ),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortOptionIcon extends StatelessWidget {
  const _SortOptionIcon({required this.option, required this.color});

  final ProductSortOption option;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (option) {
      case ProductSortOption.popularity:
        return Icon(Icons.local_fire_department_outlined,
            size: 16, color: color);
      case ProductSortOption.priceLowToHigh:
        return _RupeeArrowIcon(color: color, upward: false);
      case ProductSortOption.priceHighToLow:
        return _RupeeArrowIcon(color: color, upward: true);
      // case ProductSortOption.ratings:
      // return Icon(Icons.star_border_rounded, size: 18, color: color);
    }
  }
}

class _RupeeArrowIcon extends StatelessWidget {
  const _RupeeArrowIcon({required this.color, required this.upward});

  final Color color;
  final bool upward;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 1,
          child: Text(
            '₹',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
        Positioned(
          right: -1,
          top: upward ? 0 : 2,
          child: Icon(
            upward ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF0354A3) : const Color(0xFF7E868A),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0354A3),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
