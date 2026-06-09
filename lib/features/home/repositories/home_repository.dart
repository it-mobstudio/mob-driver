import '/backend/api_requests/api_calls.dart';
import '/features/home/models/home_models.dart';

class HomeRepository {
  const HomeRepository();

  Future<HomeDataModel> getHomeData() async {
    final responses = await Future.wait([
      HomeDataCall.call(),
      HomeProductSectionsCall.call(),
    ]);

    final homeResponse = responses[0];
    final productSectionsResponse = responses[1];

    final categories = _parseCategories(homeResponse.jsonBody);
    final productSections = _parseProductSections(productSectionsResponse.jsonBody);

    return HomeDataModel(
      categories: categories,
      productSections: productSections,
    );
  }

  Future<List<HomeCategoryModel>> getCategories() async {
    return (await getHomeData()).categories;
  }

  List<HomeCategoryModel> _parseCategories(dynamic jsonBody) {
    if (jsonBody is! Map) {
      return const <HomeCategoryModel>[];
    }
    final body = Map<String, dynamic>.from(jsonBody as Map);
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};
    final categoriesRaw =
        data['categories'] is List ? data['categories'] as List : <dynamic>[];
    return categoriesRaw
        .whereType<Map>()
        .map((e) => HomeCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  List<HomeProductSectionModel> _parseProductSections(dynamic jsonBody) {
    final sectionsRaw = _extractSectionsList(jsonBody);
    return sectionsRaw
        .whereType<Map>()
        .map((e) => HomeProductSectionModel.fromMap(Map<String, dynamic>.from(e)))
        .where((section) => section.title.isNotEmpty && section.products.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractSectionsList(dynamic jsonBody) {
    if (jsonBody is List) {
      return List<dynamic>.from(jsonBody);
    }
    if (jsonBody is! Map) {
      return const <dynamic>[];
    }

    final body = Map<String, dynamic>.from(jsonBody as Map);
    if (body['data'] is List) {
      return List<dynamic>.from(body['data'] as List);
    }
    if (body['homepageProductsData'] is List) {
      return List<dynamic>.from(body['homepageProductsData'] as List);
    }

    final data = body['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['homepageProductsData'] is List) {
        return List<dynamic>.from(dataMap['homepageProductsData'] as List);
      }
      if (dataMap['results'] is List) {
        return List<dynamic>.from(dataMap['results'] as List);
      }
    }

    return const <dynamic>[];
  }
}
