import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class ProductEvent {}

final class ProductDetailRequested extends ProductEvent {
  ProductDetailRequested({required this.slug, this.mobSku});
  final String slug;
  final String? mobSku;
}

/// Pull-to-refresh — reloads the same product without emitting
/// [ProductLoading] first (unlike [ProductDetailRequested]), so the
/// existing page stays visible under the pull-to-refresh indicator instead
/// of being replaced by the full-page skeleton.
final class ProductDetailRefreshRequested extends ProductEvent {
  ProductDetailRefreshRequested({required this.slug, this.mobSku});
  final String slug;
  final String? mobSku;
}

final class ProductListRequested extends ProductEvent {
  ProductListRequested({
    this.categorySlug,
    this.searchQuery,
    this.subCategory,
    this.page = 1,
    this.isProfessional = true,
    this.sortBy,
    this.queryParameters = const <String, dynamic>{},
  }) : assert(
          categorySlug != null || searchQuery != null,
          'Either categorySlug (browse) or searchQuery (search) is required.',
        );

  /// Browse-by-category mode. Mutually exclusive with [searchQuery].
  final String? categorySlug;

  /// Search mode — when set, results come from the search endpoint instead
  /// of the category browse endpoint.
  final String? searchQuery;
  final String? subCategory;
  final int page;
  final bool isProfessional;
  final String? sortBy;
  final Map<String, dynamic> queryParameters;
}

final class ProductListNextPageRequested extends ProductEvent {}

/// Pull-to-refresh — reloads page 1 with whatever category/subcategory/
/// filters/sort are currently active, without emitting [ProductLoading]
/// first (unlike [ProductListRequested]), so the existing grid stays
/// visible under the pull-to-refresh indicator instead of being replaced
/// by the full-page skeleton.
final class ProductListRefreshRequested extends ProductEvent {}

final class ProductFiltersRequested extends ProductEvent {
  ProductFiltersRequested({
    this.category,
    this.searchQuery,
    this.subCategory,
  }) : assert(
          category != null || searchQuery != null,
          'Either category (browse) or searchQuery (search) is required.',
        );
  final String? category;
  final String? searchQuery;
  final String? subCategory;
}

final class ProductSearchRequested extends ProductEvent {
  ProductSearchRequested({required this.query, this.page = 1});
  final String query;
  final int page;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class ProductState {}

final class ProductInitial extends ProductState {}

final class ProductLoading extends ProductState {}

final class ProductDetailLoaded extends ProductState {
  ProductDetailLoaded({
    required this.product,
    required this.similarProducts,
  });
  final ProductEntity product;
  final List<ProductEntity> similarProducts;
}

final class ProductListLoaded extends ProductState {
  ProductListLoaded({
    required this.products,
    required this.subCategories,
    required this.pagination,
    required this.currentPage,
    this.categorySlug,
    this.searchQuery,
    this.subCategory,
    this.filters = const [],
    this.isLoadingMore = false,
    this.sortBy,
    this.queryParameters = const <String, dynamic>{},
  });
  final List<ProductEntity> products;
  final List<SubCategoryModel> subCategories;
  final PaginationModel pagination;
  final String? categorySlug;
  final String? searchQuery;
  final String? subCategory;
  final int currentPage;
  final List<FilterSectionEntity> filters;
  final bool isLoadingMore;
  final String? sortBy;
  final Map<String, dynamic> queryParameters;

  bool get isSearchMode => searchQuery != null;

  ProductListLoaded copyWith({
    List<ProductEntity>? products,
    PaginationModel? pagination,
    int? currentPage,
    List<FilterSectionEntity>? filters,
    bool? isLoadingMore,
    String? sortBy,
    Map<String, dynamic>? queryParameters,
  }) {
    return ProductListLoaded(
      products: products ?? this.products,
      subCategories: subCategories,
      pagination: pagination ?? this.pagination,
      categorySlug: categorySlug,
      searchQuery: searchQuery,
      subCategory: subCategory,
      currentPage: currentPage ?? this.currentPage,
      filters: filters ?? this.filters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sortBy: sortBy ?? this.sortBy,
      queryParameters: queryParameters ?? this.queryParameters,
    );
  }
}

final class ProductSearchLoaded extends ProductState {
  ProductSearchLoaded({required this.products, required this.query});
  final List<ProductEntity> products;
  final String query;
}

final class ProductError extends ProductState {
  ProductError(this.message);
  final String message;
}

// ── BLoC (factory — fresh per screen) ────────────────────────────────────────

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(this._repository) : super(ProductInitial()) {
    on<ProductDetailRequested>(_onDetail);
    on<ProductDetailRefreshRequested>(_onDetailRefresh);
    on<ProductListRequested>(_onList);
    on<ProductListRefreshRequested>(_onRefresh);
    on<ProductListNextPageRequested>(_onNextPage);
    on<ProductFiltersRequested>(_onFilters);
    on<ProductSearchRequested>(_onSearch);
  }

  final ProductRepository _repository;

  Future<void> _onDetail(
    ProductDetailRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final (result, failure) = await _repository.getProductDetail(
      slug: event.slug,
      mobSku: event.mobSku,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(ProductError(failure.message));
    } else {
      emit(ProductDetailLoaded(
        product: result!.product,
        similarProducts: result.similarProducts,
      ));
    }
  }

  Future<void> _onDetailRefresh(
    ProductDetailRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    final (result, failure) = await _repository.getProductDetail(
      slug: event.slug,
      mobSku: event.mobSku,
    );
    if (failure != null) {
      AppHaptics.error();
      // Keep showing whatever was already on screen on a failed refresh.
      return;
    }
    emit(ProductDetailLoaded(
      product: result!.product,
      similarProducts: result.similarProducts,
    ));
  }

  Future<void> _onList(
    ProductListRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final (result, failure) = event.searchQuery != null
        ? await _repository.searchCatalog(
            query: event.searchQuery!,
            page: event.page,
            isProfessional: event.isProfessional,
            sortBy: event.sortBy,
            queryParameters: event.queryParameters,
          )
        : await _repository.browseProducts(
            categorySlug: event.categorySlug!,
            subCategory: event.subCategory,
            page: event.page,
            isProfessional: event.isProfessional,
            sortBy: event.sortBy,
            queryParameters: event.queryParameters,
          );
    if (failure != null) {
      AppHaptics.error();
      emit(ProductError(failure.message));
    } else {
      emit(ProductListLoaded(
        products: result!.products,
        subCategories: result.subCategories,
        pagination: result.pagination,
        categorySlug: event.categorySlug,
        searchQuery: event.searchQuery,
        subCategory: event.subCategory,
        currentPage: event.page,
        sortBy: event.sortBy,
        queryParameters: event.queryParameters,
      ));
    }
  }

  Future<void> _onRefresh(
    ProductListRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    final current = state;
    if (current is! ProductListLoaded) return;
    final (result, failure) = current.isSearchMode
        ? await _repository.searchCatalog(
            query: current.searchQuery!,
            page: 1,
            sortBy: current.sortBy,
            queryParameters: current.queryParameters,
          )
        : await _repository.browseProducts(
            categorySlug: current.categorySlug!,
            subCategory: current.subCategory,
            page: 1,
            sortBy: current.sortBy,
            queryParameters: current.queryParameters,
          );
    if (failure != null) {
      AppHaptics.error();
      // Keep showing whatever was already on screen on a failed refresh.
      return;
    }
    emit(ProductListLoaded(
      products: result!.products,
      subCategories: result.subCategories,
      pagination: result.pagination,
      categorySlug: current.categorySlug,
      searchQuery: current.searchQuery,
      subCategory: current.subCategory,
      currentPage: 1,
      filters: current.filters,
      sortBy: current.sortBy,
      queryParameters: current.queryParameters,
    ));
  }

  Future<void> _onNextPage(
    ProductListNextPageRequested event,
    Emitter<ProductState> emit,
  ) async {
    final current = state;
    if (current is! ProductListLoaded) return;
    if (!current.pagination.isNextPage || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    final (result, failure) = current.isSearchMode
        ? await _repository.searchCatalog(
            query: current.searchQuery!,
            page: nextPage,
            sortBy: current.sortBy,
            queryParameters: current.queryParameters,
          )
        : await _repository.browseProducts(
            categorySlug: current.categorySlug!,
            subCategory: current.subCategory,
            page: nextPage,
            sortBy: current.sortBy,
            queryParameters: current.queryParameters,
          );
    if (failure != null) {
      AppHaptics.error();
      emit(current.copyWith(isLoadingMore: false));
    } else {
      emit(current.copyWith(
        products: [...current.products, ...result!.products],
        pagination: result.pagination,
        currentPage: nextPage,
        isLoadingMore: false,
      ));
    }
  }

  Future<void> _onFilters(
    ProductFiltersRequested event,
    Emitter<ProductState> emit,
  ) async {
    final (filters, failure) = event.searchQuery != null
        ? await _repository.getSearchFilters(query: event.searchQuery!)
        : await _repository.getFilters(
            category: event.category!,
            subCategory: event.subCategory,
          );
    if (failure != null) {
      AppHaptics.error();
      return;
    }
    final current = state;
    if (current is ProductListLoaded) {
      emit(current.copyWith(filters: filters));
    }
  }

  Future<void> _onSearch(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final (products, failure) = await _repository.searchProducts(
      query: event.query,
      page: event.page,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(ProductError(failure.message));
    } else {
      emit(ProductSearchLoaded(products: products!, query: event.query));
    }
  }
}
