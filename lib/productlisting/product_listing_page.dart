import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/core/network/app_error.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';
import 'package:m_o_b_demand_side/productdetails/product_detail_page.dart';
import 'package:m_o_b_demand_side/rfq/rfq_form_page.dart';
import 'package:m_o_b_demand_side/widgets/error_state_view.dart';
import 'package:m_o_b_demand_side/widgets/skeleton_loader.dart';
import '../widgets/main_scaffold.dart';
import 'filter_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import '../components/product_card.dart';

class ProductListingPage extends StatefulWidget {
  final String category;
  final String slug;
  static const String routeName = '/ProductListingPage';
  static const String routePath = '/productlisting';

  const ProductListingPage(
      {super.key, required this.category, required this.slug});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  final ProductsRepository _productsRepository = const ProductsRepository();
  final ScrollController _scrollController = ScrollController();
  final List<ProductModel> _products = [];
  List<SubCategoryModel> _subCategories = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _loadMoreFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_loadMoreFailed &&
        _hasMore) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _productsRepository.browseProducts(
        categorySlug: widget.slug,
        page: _currentPage,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _products.addAll(response.products);
        _subCategories = response.subCategories;
        _hasMore = response.pagination.isNextPage;
        if (_hasMore) {
          _currentPage = response.pagination.nextPage > 0
              ? response.pagination.nextPage
              : _currentPage + 1;
        }
        _loadMoreFailed = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      if (_products.isEmpty) {
        setState(() {
          _error = userMessageFromError(
            e,
            fallbackMessage: 'Unable to load products. Please try again.',
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadMoreFailed = true;
        });
      }
    }
  }

  Future<void> _retryInitialLoad() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _products.clear();
      _currentPage = 1;
      _hasMore = true;
      _loadMoreFailed = false;
      _error = null;
    });
    await _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category.isEmpty) {
      return const MainScaffold(
        currentIndex: 0,
        child: Center(child: Text('No category selected.')),
      );
    }

    // Use sub_categories from API
    return MainScaffold(
      currentIndex: 0,
      showLocationheader: false,
      showBackButton: true,
      headerBackgroundColor: const Color(0xFFE8F2EF),
      searchHintText: 'Search for product, category, brand..',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _subCategoryList(_subCategories),
          _filterRow(context),
          Expanded(
            child: _error != null
                ? ErrorStateView(
                    message: _error!,
                    onRetry: _retryInitialLoad,
                  )
                : _products.isEmpty && _isLoading
                    ? const ProductGridSkeleton()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: (_products.length / 2).ceil() +
                            (_hasMore
                                ? 2
                                : 1), // +1 for bottom card, +1 for loader if hasMore
                        itemBuilder: (context, index) {
                          if (_hasMore &&
                              index == (_products.length / 2).ceil()) {
                            if (_isLoading) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (_loadMoreFailed) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: OutlinedButton.icon(
                                    onPressed: _fetchProducts,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry loading more'),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          if (index ==
                              (_products.length / 2).ceil() +
                                  (_hasMore ? 1 : 0)) {
                            return _bottomCard(context);
                          }
                          int i = index * 2;
                          return Row(
                            children: <Widget>[
                              Expanded(
                                child: ProductCard(
                                  product: _products[i],
                                  onTap: () {
                                    final slug = _products[i].slug;
                                    GoRouter.of(context).go(
                                        '${ProductDetailPage.routePath}/$slug');
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              if (i + 1 < _products.length)
                                Expanded(
                                  child: ProductCard(
                                    product: _products[i + 1],
                                    onTap: () {
                                      final slug = _products[i + 1].slug;
                                      GoRouter.of(context).go(
                                          '${ProductDetailPage.routePath}/$slug');
                                    },
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _subCategoryList(List<SubCategoryModel> subs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            widget.category,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: const Color(0xFF0A243F),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: subs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final sub = subs[index];
              final name = sub.name;
              final image = sub.image;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 73,
                    height: 73,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: (image.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              memCacheWidth: 146,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.chair_outlined, size: 28),
                            ),
                          )
                        : const Icon(Icons.chair_outlined, size: 28),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 73,
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A243F)),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          color: const Color(0xFFF1F1F2),
          height: 12,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _filterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _filterChip('Filter', icon: Icons.tune_rounded, onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => const FilterBottomSheet(),
            );
          }),
          const SizedBox(width: 8),
          _filterChip('Sort by', icon: Icons.keyboard_arrow_down_rounded),
          const SizedBox(width: 8),
          _filterChip('Same day delivery'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDEDEDE)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A243F),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: const Color(0xFF0A243F)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      height: 138,
      decoration: BoxDecoration(
        color: const Color(0xFFF8E6B6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Can't find what you're looking for?",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Suggest the item you want and we will try to add it.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A243F).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    GoRouter.of(context).go(RfqFormPage.routePath);
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF0A243F)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Send a request',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
