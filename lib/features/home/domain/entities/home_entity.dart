import 'package:m_o_b_demand_side/features/home/data/models/home_models.dart';
export 'package:m_o_b_demand_side/features/home/data/models/home_models.dart';

// HomeDataModel already acts as the domain entity for this feature.
// Re-exported here so the domain layer is the canonical import path.
typedef HomeEntity = HomeDataModel;
typedef CategoryEntity = HomeCategoryModel;
typedef ProductSectionEntity = HomeProductSectionModel;
