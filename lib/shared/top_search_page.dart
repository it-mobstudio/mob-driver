import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
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
  List<ProductModel> _results = [];

  // --- local storage (recently searched)
  static const _historyKey = 'search_history_v1';
  List<String> history = [];

  // --- optional static sections
  final List<String> trending = [
    'Ultratech Cement',
    'Garden chair',
    'Cement',
    'Coffee table'
  ];

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

  // ================= API =================

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _results = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final (results, _) = await sl<ProductRepository>().searchProducts(query: q);
      if (!mounted) return;
      setState(() {
        _results = results ?? [];
        _loading = false;
      });
      AnalyticsService.instance.logSearch(
        query: q,
        resultCount: _results.length,
      );
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.+\n${e.toString()}';
        _loading = false;
      });
    }
  }

  // ================= History (SharedPreferences) =================

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
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
    setState(() => history = current);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7F5),
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(context),
            const SizedBox(height: 12),
            if (query.isEmpty) _searchHistoryView() else _searchResultsView(),
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
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (val) {
                setState(() => query = val);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _search(val);
                });
              },
              onSubmitted: (val) async {
                await _saveToHistory(val);
                _search(val);
              },
              decoration: InputDecoration(
                hintText: 'Search for product, category, brand...',
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
                            _results = [];
                            _error = null;
                            _loading = false;
                          });
                        },
                      )
                    : const Icon(Icons.mic),
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
          Text("Recently searched",
              style:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map(
                  (term) => InputChip(
                    label: Text(term),
                    backgroundColor: const Color(0xFFF2F6F9),
                    onPressed: () {
                      _controller.text = term;
                      setState(() => query = term);
                      _search(term);
                    },
                    onDeleted: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final cur =
                          prefs.getStringList(_historyKey) ?? <String>[];
                      cur.remove(term);
                      await prefs.setStringList(_historyKey, cur);
                      setState(() => history = cur);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Text("Trending in your area",
              style:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () {
                    final term = trending[i];
                    _controller.text = term;
                    setState(() => query = term);
                    _saveToHistory(term);
                    _search(term);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade300,
                        ),
                        child: const Icon(Icons.image),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 100,
                        child: Text(
                          trending[i],
                          style: GoogleFonts.inter(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResultsView() {
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

    if (_results.isEmpty) {
      return Expanded(
        child: Center(
          child: Text('No results for “$query”.',
              style: GoogleFonts.inter(color: Colors.black54)),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = _results[i];
          return ListTile(
            onTap: () async {
              await _saveToHistory(query);
              if (!context.mounted) {
                return;
              }
              if (r.slug.isNotEmpty) {
                context.push('${ProductDetailPage.routePath}/${r.slug}');
              }
            },
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
            title: Text(r.title),
            subtitle: Text(
              '₹ ${r.vendorPricing.vendorSellingPrice}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            trailing: const Icon(Icons.north_west), // open/preview icon
          );
        },
      ),
    );
  }
}
