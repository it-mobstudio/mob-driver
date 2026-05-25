import '/backend/api_requests/api_calls.dart';
import '/features/home/models/home_models.dart';

class HomeRepository {
  const HomeRepository();

  Future<HomeDataModel> getHomeData() async {
    final response = await HomeDataCall.call();
    if (response.jsonBody is! Map) {
      return HomeDataModel.empty;
    }
    final body = Map<String, dynamic>.from(response.jsonBody as Map);
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};
    final categoriesRaw =
        data['categories'] is List ? data['categories'] as List : <dynamic>[];
    final categories = categoriesRaw
        .whereType<Map>()
        .map((e) => HomeCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return HomeDataModel(categories: categories);
  }

  Future<List<HomeCategoryModel>> getCategories() async {
    return (await getHomeData()).categories;
  }
}
