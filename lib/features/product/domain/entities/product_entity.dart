import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
export 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';

// ProductModel and all its sub-types already serve as domain entities.
// Re-exported from the canonical domain path.
typedef ProductEntity = ProductModel;
typedef ProductDetailsEntity = ProductDetailsResult;
typedef BrowseResultEntity = BrowseProductsResult;
typedef FilterSectionEntity = BrowseFilterSection;
