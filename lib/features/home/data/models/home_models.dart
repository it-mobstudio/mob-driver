import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';

class HomeCategoryModel {
  const HomeCategoryModel({
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.index,
  });

  final String name;
  final String slug;
  final String imageUrl;
  final int index;

  factory HomeCategoryModel.fromMap(Map<String, dynamic> map) {
    return HomeCategoryModel(
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      imageUrl: map['image']?.toString() ?? '',
      index: int.tryParse(map['index']?.toString() ?? '0') ?? 0,
    );
  }
}

class HomeProductSectionModel {
  const HomeProductSectionModel({
    required this.id,
    required this.title,
    required this.products,
  });

  final String id;
  final String title;
  final List<ProductModel> products;

  factory HomeProductSectionModel.fromMap(Map<String, dynamic> map) {
    final productsRaw =
        map['products'] is List ? List<dynamic>.from(map['products'] as List) : <dynamic>[];
    return HomeProductSectionModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      products: productsRaw
          .whereType<Map>()
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class HomeDataModel {
  const HomeDataModel({
    required this.categories,
    required this.productSections,
  });

  final List<HomeCategoryModel> categories;
  final List<HomeProductSectionModel> productSections;

  static const empty = HomeDataModel(
    categories: <HomeCategoryModel>[],
    productSections: <HomeProductSectionModel>[],
  );
}
