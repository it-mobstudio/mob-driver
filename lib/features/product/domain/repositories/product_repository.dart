import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';

abstract interface class ProductRepository {
  Future<(BrowseResultEntity?, AppFailure?)> browseProducts({
    required String categorySlug,
    String? subCategory,
    int page = 1,
    bool isProfessional = true,
    String? sortBy,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  });

  Future<(List<FilterSectionEntity>?, AppFailure?)> getFilters({
    required String category,
    String? subCategory,
  });

  Future<(List<FilterSectionEntity>?, AppFailure?)> getSearchFilters({
    required String query,
    Map<String, dynamic> extraParams = const <String, dynamic>{},
  });

  Future<(ProductDetailsEntity?, AppFailure?)> getProductDetail({
    required String slug,
    String? mobSku,
  });

  Future<(List<ProductEntity>?, AppFailure?)> searchProducts({
    required String query,
    int page = 1,
  });

  /// Typeahead suggestions while typing — brand matches and product
  /// matches from the same /home/product_search/ response (mirrors the
  /// web's CustomAutoComplete grouping: brands first, then products).
  Future<(SearchSuggestionsEntity?, AppFailure?)> searchSuggestions({
    required String query,
  });

  Future<(BrowseResultEntity?, AppFailure?)> searchCatalog({
    required String query,
    int page = 1,
    bool isProfessional = true,
    String? sortBy,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  });

  /// Registers the signed-in user's phone number to be notified when an
  /// out-of-stock product becomes available again.
  Future<(bool, AppFailure?)> notifyOutOfStock({
    required int productId,
    required String phoneNumber,
  });
}
