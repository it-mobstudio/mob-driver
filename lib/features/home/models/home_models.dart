class HomeCategoryModel {
  const HomeCategoryModel({
    required this.name,
    required this.slug,
    required this.imageUrl,
  });

  final String name;
  final String slug;
  final String imageUrl;

  factory HomeCategoryModel.fromMap(Map<String, dynamic> map) {
    return HomeCategoryModel(
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      imageUrl: map['image']?.toString() ?? '',
    );
  }
}
