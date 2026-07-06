import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/brand_product_search_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  static const String routeName = 'SearchPage';
  static const String routePath = '/search';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // --- UI state
  String query = '';
  bool _loading = false;
  String? _error;
  List<ProductModel> _suggestions = [];
  List<String> _brandSuggestions = [];

  // --- local storage (recently searched)
  static const _historyKey = 'search_history_v1';
  List<String> history = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ================= API (live suggestions while typing) =================

  Future<void> _loadSuggestions(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _suggestions = [];
        _brandSuggestions = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final (result, failure) =
          await sl<ProductRepository>().searchSuggestions(query: q);
      if (!mounted) return;
      if (failure != null) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _suggestions = result?.products ?? [];
        _brandSuggestions = result?.brandNames ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  // ================= History (SharedPreferences) =================

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      history = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _saveToHistory(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_historyKey) ?? <String>[];

    // MRU: move to front, unique, max 10
    current.removeWhere((e) => e.toLowerCase() == term.toLowerCase());
    current.insert(0, term);
    if (current.length > 10) current.removeRange(10, current.length);

    await prefs.setStringList(_historyKey, current);
    if (!mounted) return;
    setState(() => history = current);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (!mounted) return;
    setState(() => history = []);
  }

  // ================= Navigation =================

  Future<void> _submitSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    await _saveToHistory(trimmed);
    if (!mounted) return;
    final slug = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    context.push(
      '${BrandProductSearchPage.routePath}/${Uri.encodeComponent(slug.isEmpty ? 'search' : slug)}',
      extra: {'searchTerm': trimmed},
    );
  }

  Future<void> _openProduct(ProductModel product) async {
    await _saveToHistory(query);
    if (!mounted) return;
    if (product.slug.isNotEmpty) {
      context.push('${ProductDetailPage.routePath}/${product.slug}');
    }
  }

  Future<void> _openBrand(String brandName) async {
    await _saveToHistory(brandName);
    if (!mounted) return;
    final slug = brandName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    context.push(
      '${BrandProductSearchPage.routePath}/${Uri.encodeComponent(slug.isEmpty ? 'brand' : slug)}',
      extra: {'brandName': brandName},
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(context),
            if (query.isEmpty) _searchHistoryView() else _suggestionsView(),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: const AppBackIcon(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (val) {
                setState(() => query = val);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _loadSuggestions(val);
                });
              },
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                hintText: 'Search for product, category, brand..',
                filled: true,
                fillColor: const Color(0xFFF2F6F9),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            query = '';
                            _suggestions = [];
                            _brandSuggestions = [];
                            _error = null;
                            _loading = false;
                          });
                        },
                      )
                    : const Icon(Icons.mic_none),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchHistoryView() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently searched',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: _clearHistory,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0360E5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: history
                  .map(
                    (term) => GestureDetector(
                      onTap: () => _submitSearch(term),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F6F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history,
                              size: 14,
                              color: Color(0xFF767C8F),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              term,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0A243F),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _suggestionsView() {
    if (_loading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Expanded(
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (query.trim().length < 2) {
      return const Expanded(child: SizedBox.shrink());
    }

    if (_brandSuggestions.isEmpty && _suggestions.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No matches for "$query".',
            style: GoogleFonts.inter(color: const Color(0xFF767C8F)),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (_brandSuggestions.isNotEmpty) ...[
            _sectionLabel('Brands'),
            ..._brandSuggestions.map(_brandTile),
            const SizedBox(height: 8),
          ],
          if (_suggestions.isNotEmpty) ...[
            _sectionLabel('Products'),
            ..._suggestions.map(_productTile),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF767C8F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _brandTile(String name) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _openBrand(name),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.storefront_outlined, color: Color(0xFF767C8F)),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.search,
        size: 18,
        color: Color(0xFF767C8F),
      ),
    );
  }

  Widget _productTile(ProductModel r) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _openProduct(r),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: r.primaryImageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: r.primaryImageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 80,
                  placeholder: (_, __) => const ImageShimmer(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image, color: Colors.grey),
                ),
              )
            : const Icon(Icons.image, color: Colors.grey),
      ),
      title: Text(
        r.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.search,
        size: 18,
        color: Color(0xFF767C8F),
      ),
    );
  }
}
