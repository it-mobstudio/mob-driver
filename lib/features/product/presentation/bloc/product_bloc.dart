import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class ProductEvent {}

final class ProductDetailRequested extends ProductEvent {
  ProductDetailRequested({required this.slug, this.mobSku});
  final String slug;
  final String? mobSku;
}

final class ProductListRequested extends ProductEvent {
  ProductListRequested({
    required this.categoryName,
    this.page = 1,
    this.isProfessional = true,
  });
  final String categoryName;
  final int page;
  final bool isProfessional;
}

final class ProductListNextPageRequested extends ProductEvent {}

final class ProductFiltersRequested extends ProductEvent {
  ProductFiltersRequested({required this.search, this.isProfessional = true});
  final String search;
  final bool isProfessional;
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
    required this.categoryName,
    required this.currentPage,
    this.filters = const [],
    this.isLoadingMore = false,
  });
  final List<ProductEntity> products;
  final List<SubCategoryModel> subCategories;
  final PaginationModel pagination;
  final String categoryName;
  final int currentPage;
  final List<FilterSectionEntity> filters;
  final bool isLoadingMore;

  ProductListLoaded copyWith({
    List<ProductEntity>? products,
    PaginationModel? pagination,
    int? currentPage,
    List<FilterSectionEntity>? filters,
    bool? isLoadingMore,
  }) {
    return ProductListLoaded(
      products: products ?? this.products,
      subCategories: subCategories,
      pagination: pagination ?? this.pagination,
      categoryName: categoryName,
      currentPage: currentPage ?? this.currentPage,
      filters: filters ?? this.filters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
    on<ProductListRequested>(_onList);
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
      emit(ProductError(failure.message));
    } else {
      emit(ProductDetailLoaded(
        product: result!.product,
        similarProducts: result.similarProducts,
      ));
    }
  }

  Future<void> _onList(
    ProductListRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    final (result, failure) = await _repository.browseProducts(
      categoryName: event.categoryName,
      page: event.page,
      isProfessional: event.isProfessional,
    );
    if (failure != null) {
      emit(ProductError(failure.message));
    } else {
      emit(ProductListLoaded(
        products: result!.products,
        subCategories: result.subCategories,
        pagination: result.pagination,
        categoryName: event.categoryName,
        currentPage: event.page,
      ));
    }
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
    final (result, failure) = await _repository.browseProducts(
      categoryName: current.categoryName,
      page: nextPage,
    );
    if (failure != null) {
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
    final (filters, failure) = await _repository.getFilters(
      search: event.search,
      isProfessional: event.isProfessional,
    );
    if (failure != null) return;
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
      emit(ProductError(failure.message));
    } else {
      emit(ProductSearchLoaded(products: products!, query: event.query));
    }
  }
}
