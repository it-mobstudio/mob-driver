import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';

class HomeCategoryModel {
  const HomeCategoryModel({
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.index,
    List<HomeSubCategoryModel>? subCategories,
  }) : subCategories = subCategories ?? const <HomeSubCategoryModel>[];

  final String name;
  final String slug;
  final String imageUrl;
  final int index;
  final List<HomeSubCategoryModel> subCategories;

  factory HomeCategoryModel.fromMap(Map<String, dynamic> map) {
    final rawSubCategories = _listValue(
      map['sub_category'] ??
          map['sub_categories'] ??
          map['subCategories'] ??
          map['sub_category2'] ??
          map['sub_categories2'],
    );
    return HomeCategoryModel(
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      imageUrl: map['image']?.toString() ?? '',
      index: int.tryParse(map['index']?.toString() ?? '0') ?? 0,
      subCategories: rawSubCategories
          .whereType<Map>()
          .map((item) => HomeSubCategoryModel.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.name.isNotEmpty)
          .toList(),
    );
  }
}

class HomeSubCategoryModel {
  const HomeSubCategoryModel({
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.index,
  });

  final String name;
  final String slug;
  final String imageUrl;
  final int index;

  factory HomeSubCategoryModel.fromMap(Map<String, dynamic> map) {
    return HomeSubCategoryModel(
      name: (map['sub_category_name'] ??
              map['name'] ??
              map['title'] ??
              map['display_name'] ??
              '')
          .toString(),
      slug: (map['slug'] ??
              map['sub_category_slug'] ??
              map['category_slug'] ??
              map['sub_category'] ??
              '')
          .toString(),
      imageUrl:
          (map['image'] ?? map['image_url'] ?? map['icon'] ?? '').toString(),
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
    final productsRaw = map['products'] is List
        ? List<dynamic>.from(map['products'] as List)
        : <dynamic>[];
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

List<dynamic> _listValue(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  return const <dynamic>[];
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
