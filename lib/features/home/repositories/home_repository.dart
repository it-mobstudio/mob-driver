import '/backend/api_requests/api_calls.dart';
import '/features/home/models/home_models.dart';

class HomeRepository {
  const HomeRepository();

  Future<List<HomeCategoryModel>> getCategories() async {
    final response = await HomeDataCall.call();
    if (response.jsonBody is! Map) {
      return const <HomeCategoryModel>[];
    }
    final body = Map<String, dynamic>.from(response.jsonBody as Map);
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};
    final categoriesRaw =
        data['categories'] is List ? data['categories'] as List : <dynamic>[];
    return categoriesRaw
        .whereType<Map>()
        .map((e) => HomeCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}
