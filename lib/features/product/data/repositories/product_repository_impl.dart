import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/product/data/datasources/product_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._datasource);

  final ProductRemoteDatasource _datasource;

  @override
  Future<(BrowseResultEntity?, AppFailure?)> browseProducts({
    required String categoryName,
    int page = 1,
    bool isProfessional = true,
  }) async {
    try {
      final body = await _datasource.browseProducts(
        categoryName: categoryName,
        page: page,
        isProfessional: isProfessional,
      );
      final data = _data(body);
      final productsRaw = _list(data['results'] ?? data['products'] ?? data['data']);
      final subCatsRaw = _list(data['sub_categories'] ?? data['subCategories']);
      final paginationMap = data['pagination'] is Map
          ? Map<String, dynamic>.from(data['pagination'] as Map)
          : <String, dynamic>{
              'is_next_page': data['next'] != null,
              'next_page': page + 1,
            };

      return (
        BrowseProductsResult(
          products: productsRaw
              .whereType<Map>()
              .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
          subCategories: subCatsRaw
              .whereType<Map>()
              .map((e) => SubCategoryModel.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
          pagination: PaginationModel.fromMap(paginationMap),
        ),
        null,
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<FilterSectionEntity>?, AppFailure?)> getFilters({
    required String search,
    bool isProfessional = true,
  }) async {
    try {
      final raw = await _datasource.getFilters(
        search: search,
        isProfessional: isProfessional,
      );
      final list = raw is List
          ? raw
          : (raw is Map ? (_list((raw as Map)['data'] ?? (raw)['results'])) : <dynamic>[]);
      final filters = list
          .whereType<Map>()
          .map((e) => BrowseFilterSection.fromMap(Map<String, dynamic>.from(e)))
          .where((f) => f.key.isNotEmpty)
          .toList();
      return (filters, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(ProductDetailsEntity?, AppFailure?)> getProductDetail({
    required String slug,
    String? mobSku,
  }) async {
    try {
      final body = await _datasource.getProductDetail(slug: slug, mobSku: mobSku);
      final data = _data(body);
      final productRaw = data['product'];
      final productMap = productRaw is Map
          ? Map<String, dynamic>.from(productRaw)
          : data;
      final similarRaw = _list(data['similar_products'] ?? data['similarProducts']);
      return (
        ProductDetailsResult(
          product: ProductModel.fromMap(productMap),
          similarProducts: similarRaw
              .whereType<Map>()
              .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
        ),
        null,
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<ProductEntity>?, AppFailure?)> searchProducts({
    required String query,
    int page = 1,
  }) async {
    try {
      final raw = await _datasource.searchProducts(query: query, page: page);
      final body = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final data = _data(body);
      final list = _list(data['results'] ?? data['products'] ?? data['data'] ?? data);
      final products = list
          .whereType<Map>()
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return (products, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> body) {
    if (body['data'] is Map) return Map<String, dynamic>.from(body['data'] as Map);
    return body;
  }

  List<dynamic> _list(dynamic v) => v is List ? v : const [];
}
