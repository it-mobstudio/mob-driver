import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  static const String routeName = 'SearchPage';
  static const String routePath = '/search';
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String query = '';

  List<String> history = ['Fevicol', 'Cement', 'Wall putty', 'Asian paints'];
  List<String> trending = ['Ultratech Cement', 'Garden chair', 'Cement', 'Coffee table'];
  List<String> categories = ['Cement mixer', 'Sustainable cement', 'Ready mix cement'];
  List<String> productResults = ['JK Cement White Max', 'Ultratech Cement'];

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
                // TODO: API call for live results
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
                    setState(() => query = '');
                  },
                )
                    : const Icon(Icons.mic),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
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
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map((term) => Chip(
              label: Text(term),
              backgroundColor: const Color(0xFFF2F6F9),
            ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text("Trending in your area",
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                return Column(
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
                    Text(trending[i],
                        style: GoogleFonts.inter(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResultsView() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          if (categories.isNotEmpty) ...[
            Text("CATEGORIES",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            ...categories
                .map((c) => ListTile(
              title: Text(c),
              trailing: const Icon(Icons.search),
            ))
                .toList(),
            const SizedBox(height: 16),
          ],
          if (productResults.isNotEmpty) ...[
            Text("PRODUCTS",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            ...productResults
                .map((p) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image),
              ),
              title: Text(p),
              trailing: const Icon(Icons.search),
            ))
                .toList(),
          ],
        ],
      ),
    );
  }
}
