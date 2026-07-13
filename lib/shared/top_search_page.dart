import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/brand_product_search_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:m_o_b_demand_side/shared/rotating_search_hint.dart';
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
  static const _defaultRecentSearches = <String>[
    'Fevicol',
    'Cement',
    'Wall putty',
    'Asian paints',
    'Greenply',
    'Greenply',
    'Bricks',
    'Kajaria tiles',
  ];
  static const _defaultCategorySuggestions = <String>[
    'Cement',
    'Cement mixer',
    'Sustainable cement',
    'White cement',
    'Cement board',
    'Ready mix cement',
  ];
  static const _defaultProductSuggestions = <_FallbackProductSuggestion>[
    _FallbackProductSuggestion(
      title: 'JK Cement White Max Portland',
      asset: 'assets/images/Brands/zuari.webp',
    ),
    _FallbackProductSuggestion(
      title: 'Ultratech Cement',
      asset: 'assets/images/Brands/ultratech.webp',
    ),
    _FallbackProductSuggestion(
      title: 'MOB Ready Mix Cement',
      asset: 'assets/images/moblogo.svg',
    ),
    _FallbackProductSuggestion(
      title: 'MOB Ultra Cement',
      asset: 'assets/images/Mobitem.svg',
    ),
    _FallbackProductSuggestion(
      title: 'Neoseal Solvent Cement',
      asset: 'assets/images/Brands/Roff.webp',
    ),
  ];
  // "Trending in your area" — hidden for now, kept for easy restoration.
  // static const _trendingItems = <_TrendingSearchItem>[
  //   _TrendingSearchItem(
  //     label: 'Ultratech\nCement',
  //     asset: 'assets/images/Brands/ultratech.webp',
  //   ),
  //   _TrendingSearchItem(
  //     label: 'Garden\nchair',
  //     asset: 'assets/images/Brands/featherlite.webp',
  //   ),
  //   _TrendingSearchItem(
  //     label: 'Cement',
  //     asset: 'assets/images/Brands/zuari.webp',
  //   ),
  //   _TrendingSearchItem(
  //     label: 'Coffee\ntable',
  //     asset: 'assets/images/Brands/ikea-logo.webp',
  //   ),
  //   _TrendingSearchItem(
  //     label: 'Indoor\nplants',
  //     asset: 'assets/images/Brands/greenply.webp',
  //   ),
  // ];
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

  void _onSearchChanged(String value) {
    setState(() => query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _loadSuggestions(value);
    });
  }

  void _clearQuery() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      query = '';
      _suggestions = [];
      _brandSuggestions = [];
      _error = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _searchHeader(context),
          if (query.isEmpty) _searchHistoryView() else _suggestionsView(),
        ],
      ),
    );
  }

  Widget _searchHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8F2EF),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 20,
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackIcon(color: Color(0xFF0A243F)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD0D4DC),
                      width: 0.5,
                    ),
                  ),
                  // RotatingSearchHint can't live in TextField.hintText
                  // (that only accepts a plain String), so it's laid over
                  // an otherwise-identical, borderless/unfilled field and
                  // hidden the instant there's real text — same pattern as
                  // brand_product_search_page.dart. The white fill/border
                  // moved to this outer Container since the TextField's own
                  // opaque `fillColor` would otherwise paint over the hint
                  // stacked beneath it.
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        if (value.text.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: RotatingSearchHint(),
                          ),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: _submitSearch,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A243F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 20 / 14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF767C8F),
                                      size: 18,
                                    ),
                                    onPressed: _clearQuery,
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchHistoryView() {
    final recentSearches = history.isEmpty ? _defaultRecentSearches : history;
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Recently searched'),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _clearHistory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0360E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: recentSearches.take(8).map(_recentChip).toList(),
            ),
          ),
          // "Trending in your area" — hidden for now, kept for easy
          // restoration. Re-add _trendingItems/_trendingTile/
          // _TrendingSearchItem (commented out below) to bring it back.
          // const SizedBox(height: 24),
          // Padding(
          //   padding: const EdgeInsets.only(right: 16),
          //   child: _sectionTitle('Trending in your area'),
          // ),
          // const SizedBox(height: 12),
          // SizedBox(
          //   height: 112,
          //   child: ListView.separated(
          //     scrollDirection: Axis.horizontal,
          //     padding: const EdgeInsets.only(right: 16),
          //     itemCount: _trendingItems.length,
          //     separatorBuilder: (_, __) => const SizedBox(width: 12),
          //     itemBuilder: (context, index) {
          //       final item = _trendingItems[index];
          //       return _trendingTile(item);
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF0A243F),
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 22 / 15,
      ),
    );
  }

  Widget _recentChip(String term) {
    return GestureDetector(
      onTap: () => _submitSearch(term),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDEDEDE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              size: 12,
              color: Color(0xFF767C8F),
            ),
            const SizedBox(width: 8),
            Text(
              term,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "Trending in your area" — hidden for now, kept for easy restoration.
  // Widget _trendingTile(_TrendingSearchItem item) {
  //   return GestureDetector(
  //     onTap: () => _submitSearch(item.label.replaceAll('\n', ' ')),
  //     child: SizedBox(
  //       width: 68,
  //       child: Column(
  //         children: [
  //           Container(
  //             width: 68,
  //             height: 68,
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(16),
  //               border: Border.all(color: const Color(0xFFDEDEDE)),
  //             ),
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(8),
  //               child: Image.asset(
  //                 item.asset,
  //                 fit: BoxFit.contain,
  //                 errorBuilder: (_, __, ___) => const Icon(
  //                   Icons.image_outlined,
  //                   color: Color(0xFF767C8F),
  //                   size: 24,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             item.label,
  //             maxLines: 2,
  //             overflow: TextOverflow.ellipsis,
  //             textAlign: TextAlign.center,
  //             style: GoogleFonts.inter(
  //               color: const Color(0xFF0A243F),
  //               fontSize: 12,
  //               fontWeight: FontWeight.w500,
  //               height: 18 / 12,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _suggestionsView() {
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

    final showsBrandSuggestions = _brandSuggestions.isNotEmpty;
    final categoryTerms = showsBrandSuggestions
        ? _brandSuggestions.take(6).toList()
        : _defaultCategorySuggestions;

    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 1),
          _suggestionSectionHeader('CATEGORIES'),
          ...categoryTerms.map(
            (term) => _categorySuggestionRow(
              term,
              onTap: showsBrandSuggestions
                  ? () => _openBrand(term)
                  : () => _submitSearch(term),
            ),
          ),
          _suggestionSectionHeader('CATEGORIES'),
          if (_suggestions.isNotEmpty) ...[
            ..._suggestions.take(8).map(_productTile),
          ] else ...[
            ..._defaultProductSuggestions.map(_fallbackProductTile),
          ],
        ],
      ),
    );
  }

  Widget _suggestionSectionHeader(String label) {
    return Container(
      height: 32,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0x4DDEDEDE),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 18 / 12,
        ),
      ),
    );
  }

  Widget _categorySuggestionRow(String term, {required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                term,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
            const Icon(
              Icons.search,
              size: 16,
              color: Color(0xFF767C8F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productTile(ProductModel r) {
    return _productSuggestionRow(
      title: r.title,
      image: r.primaryImageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: r.primaryImageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 80,
                placeholder: (_, __) => const ImageShimmer(),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.image, color: Color(0xFF767C8F)),
              ),
            )
          : const Icon(Icons.image_outlined, color: Color(0xFF767C8F)),
      onTap: () => _openProduct(r),
    );
  }

  Widget _fallbackProductTile(_FallbackProductSuggestion item) {
    return _productSuggestionRow(
      title: item.title,
      image: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.asset.endsWith('.svg')
            ? SvgPicture.asset(
                item.asset,
                fit: BoxFit.contain,
              )
            : Image.asset(
                item.asset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: Color(0xFF767C8F),
                ),
              ),
      ),
      onTap: () => _submitSearch(item.title),
    );
  }

  Widget _productSuggestionRow({
    required String title,
    required Widget image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: image,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
            const Icon(
              Icons.search,
              size: 16,
              color: Color(0xFF767C8F),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackProductSuggestion {
  const _FallbackProductSuggestion({
    required this.title,
    required this.asset,
  });

  final String title;
  final String asset;
}

/* "Trending in your area" — hidden for now, kept for easy restoration.
class _TrendingSearchItem {
  const _TrendingSearchItem({
    required this.label,
    required this.asset,
  });

  final String label;
  final String asset;
}
*/
