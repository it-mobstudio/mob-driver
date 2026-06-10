import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';

abstract interface class ProductRepository {
  Future<(BrowseResultEntity?, AppFailure?)> browseProducts({
    required String categoryName,
    int page = 1,
    bool isProfessional = true,
  });

  Future<(List<FilterSectionEntity>?, AppFailure?)> getFilters({
    required String search,
    bool isProfessional = true,
  });

  Future<(ProductDetailsEntity?, AppFailure?)> getProductDetail({
    required String slug,
    String? mobSku,
  });

  Future<(List<ProductEntity>?, AppFailure?)> searchProducts({
    required String query,
    int page = 1,
  });
}
