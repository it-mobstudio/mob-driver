import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/repositories/magic_quote_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

/// "Add more items" bottom sheet: debounced product search (reusing the
/// same catalog search the brand/product search pages already use) with
/// infinite scroll, and a tap-to-add action per result. Mirrors the web's
/// MagicQuote/AddMorePicker.jsx.
class AddMoreItemsSheet extends StatefulWidget {
  const AddMoreItemsSheet({
    super.key,
    required this.productRepository,
    required this.magicQuoteRepository,
    required this.quoteId,
    required this.onAdded,
  });

  final ProductRepository productRepository;
  final MagicQuoteRepository magicQuoteRepository;
  final String quoteId;
  final void Function(
    Map<String, dynamic>? payload,
    Map<String, dynamic>? addedItem,
  ) onAdded;

  @override
  State<AddMoreItemsSheet> createState() => _AddMoreItemsSheetState();
}

class _AddMoreItemsSheetState extends State<AddMoreItemsSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<ProductEntity> _products = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNext = false;
  int _nextPage = 1;
  String _query = '';
  String _addingSku = '';

  @override
  void initState() {
    super.initState();
    _search('');
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
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

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() {
      _query = query;
      _isLoading = true;
      _products = const [];
      _hasNext = false;
      _nextPage = 1;
    });
    final (result, failure) =
        await widget.productRepository.searchCatalog(query: query, page: 1);
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
      query: _query,
      page: _nextPage,
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

  Future<void> _addProduct(ProductEntity product) async {
    if (_addingSku.isNotEmpty) return;
    setState(() => _addingSku = product.mobSku);
    final (payload, addedItem, failure) = await widget.magicQuoteRepository.addMagicQuoteItem(
      quoteId: widget.quoteId,
      mobSku: product.mobSku,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _addingSku = '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    widget.onAdded(payload, addedItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                    'Add more items',
                    style: GoogleFonts.inter(
                      color: MagicQuoteColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: _onQueryChanged,
                    style: GoogleFonts.inter(color: MagicQuoteColors.navy, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products by name, brand, type',
                      hintStyle: GoogleFonts.inter(color: MagicQuoteColors.muted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: MagicQuoteColors.muted),
                      filled: true,
                      fillColor: const Color(0xFFF7F9FC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: MagicQuoteColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: MagicQuoteColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: MagicQuoteColors.blue, width: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(child: _resultsList()),
          ],
        ),
      ),
    );
  }

  Widget _resultsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text('No products found', style: GoogleFonts.inter(color: MagicQuoteColors.muted)),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1, color: MagicQuoteColors.border),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _productRow(_products[index]);
      },
    );
  }

  Widget _productRow(ProductEntity product) {
    final isAdding = _addingSku == product.mobSku;
    final img = product.primaryImageUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: const Color(0xFFF7F9FC),
              child: img.isEmpty
                  ? const Icon(Icons.inventory_2_outlined, color: MagicQuoteColors.navy)
                  : Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.inventory_2_outlined, color: MagicQuoteColors.navy),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (product.brandName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.brandName,
                    style: GoogleFonts.inter(color: MagicQuoteColors.muted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatInr(product.vendorPricing.vendorSellingPrice),
            style: GoogleFonts.inter(
              color: MagicQuoteColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: isAdding ? null : () => _addProduct(product),
              icon: isAdding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle, color: MagicQuoteColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
