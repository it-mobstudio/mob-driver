import '/backend/api_requests/api_calls.dart';
import '/features/products/models/product_models.dart';

class ProductsRepository {
  const ProductsRepository();

  Future<BrowseProductsResult> browseProducts({
    required String categorySlug,
    required int page,
  }) async {
    final response = await BrowseProductsCall.call(
      categoryName: categorySlug,
      page: page,
    );
    final data = _extractDataMap(response.jsonBody);

    final products = (data['results'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final subCategories = (data['sub_categories'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => SubCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final pagination = data['pagination'] is Map
        ? PaginationModel.fromMap(
            Map<String, dynamic>.from(data['pagination'] as Map),
          )
        : const PaginationModel(isNextPage: false, nextPage: 0);

    return BrowseProductsResult(
      products: products,
      subCategories: subCategories,
      pagination: pagination,
    );
  }

  Future<ProductDetailsResult> getProductDetails({
    required String slug,
    String? mobSku,
  }) async {
    final response = await ProductDetailsCall.call(
      slug: slug,
      mobSku: mobSku,
    );
    final data = _extractDataMap(response.jsonBody);
    final productMap = data['product'] is Map
        ? Map<String, dynamic>.from(data['product'] as Map)
        : <String, dynamic>{};
    if (productMap.isEmpty) {
      throw StateError('No product data found.');
    }
    final similarProducts = (data['similar_products'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return ProductDetailsResult(
      product: ProductModel.fromMap(productMap),
      similarProducts: similarProducts,
    );
  }

  Future<List<ProductModel>> searchProducts({
    required String query,
  }) async {
    final response = await ProductSearchCall.call(query: query);
    final data = _extractDataMap(response.jsonBody);
    return (data['results'] as List? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _extractDataMap(dynamic jsonBody) {
    if (jsonBody is! Map) {
      return <String, dynamic>{};
    }
    final bodyMap = Map<String, dynamic>.from(jsonBody);
    if (bodyMap['data'] is! Map) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(bodyMap['data'] as Map);
  }
}
