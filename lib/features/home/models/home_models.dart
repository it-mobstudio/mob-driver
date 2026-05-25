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

class HomeDataModel {
  const HomeDataModel({
    required this.categories,
  });

  final List<HomeCategoryModel> categories;

  static const empty = HomeDataModel(categories: <HomeCategoryModel>[]);
}
