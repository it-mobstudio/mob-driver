import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/repositories/magic_quote_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';

/// "Pick a replacement" bottom sheet: filter chips + a horizontal carousel
/// of alternative products for the current item's SKU, with a REPLACE
/// action per card. Mirrors the web's swap section in QuoteItemRow.jsx +
/// useSwapProducts.js (the chip-dropdown filter UI is implemented here as
/// a stacked filter-options sheet instead of an absolutely-positioned
/// dropdown, since that's the natural mobile equivalent).
class SwapProductSheet extends StatefulWidget {
  const SwapProductSheet({
    super.key,
    required this.productRepository,
    required this.magicQuoteRepository,
    required this.itemId,
    required this.mobSku,
    required this.city,
    required this.onReplaced,
  });

  final ProductRepository productRepository;
  final MagicQuoteRepository magicQuoteRepository;
  final String itemId;
  final String mobSku;
  final String city;
  final void Function(Map<String, dynamic>? payload) onReplaced;

  @override
  State<SwapProductSheet> createState() => _SwapProductSheetState();
}

class _SwapProductSheetState extends State<SwapProductSheet> {
  final _scrollController = ScrollController();

  List<ProductEntity> _products = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _nextPage = 1;

  List<FilterSectionEntity> _filters = const [];
  bool _isLoadingFilters = true;
  final Map<String, List<String>> _filterValues = {};

  String _replacingSku = '';

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _search();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFilters() async {
    setState(() => _isLoadingFilters = true);
    final (filters, failure) = await widget.productRepository.getSearchFilters(
      query: widget.mobSku,
      extraParams: {
        'mob_sku': widget.mobSku,
        if (widget.city.isNotEmpty) 'city': widget.city,
      },
    );
    if (!mounted) return;
    setState(() {
      _isLoadingFilters = false;
      if (failure == null && filters != null) {
        _filters = filters.take(4).toList();
      }
    });
  }

  Map<String, dynamic> _filterQueryParams() {
    final params = <String, dynamic>{};
    for (final entry in _filterValues.entries) {
      if (entry.value.isNotEmpty) params[entry.key] = entry.value.join(',');
    }
    return params;
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _products = const [];
      _hasNext = false;
      _nextPage = 1;
    });
    final (result, failure) = await widget.productRepository.searchCatalog(
      query: '',
      page: 1,
      queryParameters: {'mob_sku': widget.mobSku, ..._filterQueryParams()},
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (failure == null && result != null) {
        _products = result.products;
        _hasNext = result.pagination.isNextPage;
        _nextPage = result.pagination.nextPage;
      }
    });
  }

  Future<void> _loadMore() async {
    if (!_hasNext || _isLoadingMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    final (result, failure) = await widget.productRepository.searchCatalog(
      query: '',
      page: _nextPage,
      queryParameters: {'mob_sku': widget.mobSku, ..._filterQueryParams()},
    );
    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (failure == null && result != null) {
        _products = [..._products, ...result.products];
        _hasNext = result.pagination.isNextPage;
        _nextPage = result.pagination.nextPage;
      }
    });
  }

  Future<void> _replace(ProductEntity product) async {
    if (_replacingSku.isNotEmpty) return;
    setState(() => _replacingSku = product.mobSku);
    final (payload, failure) = await widget.magicQuoteRepository.replaceMagicQuoteItem(
      itemId: widget.itemId,
      mobSku: product.mobSku,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _replacingSku = '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    widget.onReplaced(payload);
    Navigator.of(context).pop();
  }

  Future<void> _openFilterOptions(FilterSectionEntity filter) async {
    final selected = List<String>.from(_filterValues[filter.key] ?? const []);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filter.label,
                        style: GoogleFonts.inter(
                          color: MagicQuoteColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: filter.options.map((option) {
                              final isChecked = selected.contains(option.value);
                              return CheckboxListTile(
                                value: isChecked,
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selected.add(option.value);
                                    } else {
                                      selected.remove(option.value);
                                    }
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(
                                  option.count > 0
                                      ? '${option.label} (${option.count})'
                                      : option.label,
                                  style: GoogleFonts.inter(
                                    color: MagicQuoteColors.navy,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: MagicQuoteColors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Apply',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {
      if (selected.isEmpty) {
        _filterValues.remove(filter.key);
      } else {
        _filterValues[filter.key] = selected;
      }
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: MagicQuoteColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Pick a replacement',
                    style: GoogleFonts.inter(
                      color: MagicQuoteColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _filterChipsRow(),
                ],
              ),
            ),
            Flexible(child: _resultsCarousel()),
          ],
        ),
      ),
    );
  }

  Widget _filterChipsRow() {
    if (_isLoadingFilters) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_filters.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final count = _filterValues[filter.key]?.length ?? 0;
          return OutlinedButton(
            onPressed: () => _openFilterOptions(filter),
            style: OutlinedButton.styleFrom(
              backgroundColor: count > 0 ? const Color(0xFFEAF2FF) : Colors.white,
              side: BorderSide(
                color: count > 0 ? MagicQuoteColors.blue : MagicQuoteColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  style: GoogleFonts.inter(
                    color: count > 0 ? MagicQuoteColors.blue : MagicQuoteColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: const BoxDecoration(
                      color: MagicQuoteColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: MagicQuoteColors.muted),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _resultsCarousel() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No products found', style: GoogleFonts.inter(color: MagicQuoteColors.muted)),
        ),
      );
    }
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final product in _products) _productCard(product),
          if (_isLoadingMore)
            const SizedBox(
              width: 150,
              height: 230,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _productCard(ProductEntity product) {
    final price = product.vendorPricing.vendorSellingPrice;
    final mrp = product.maximumRetailPrice;
    final discountPercent =
        mrp > price && price > 0 ? (((mrp - price) / mrp) * 100).round() : 0;
    final isReplacing = _replacingSku == product.mobSku;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MagicQuoteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 90,
              width: double.infinity,
              color: const Color(0xFFF7F9FC),
              child: product.primaryImageUrl.isEmpty
                  ? const Icon(Icons.inventory_2_outlined, color: MagicQuoteColors.navy)
                  : Image.network(
                      product.primaryImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.inventory_2_outlined, color: MagicQuoteColors.navy),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: MagicQuoteColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (discountPercent > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$discountPercent% OFF',
              style: GoogleFonts.inter(
                color: const Color(0xFF169B58),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatInr(price),
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (mrp > price) ...[
                const SizedBox(width: 6),
                Text(
                  formatInr(mrp),
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.muted,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              onPressed: isReplacing ? null : () => _replace(product),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.zero,
                backgroundColor: MagicQuoteColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isReplacing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'REPLACE',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
