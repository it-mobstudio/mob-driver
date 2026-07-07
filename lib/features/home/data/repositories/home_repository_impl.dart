import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/home/data/datasources/home_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._datasource);

  final HomeRemoteDatasource _datasource;

  @override
  Future<(HomeEntity?, AppFailure?)> getHomeData() async {
    try {
      final results = await Future.wait([
        _datasource.getHomeData(),
        _datasource.getProductSections(),
      ]);

      final homeBody = results[0] as Map<String, dynamic>;
      final sectionsRaw = results[1];

      final categories = _parseCategories(homeBody);
      final sections = _parseProductSections(sectionsRaw);

      return (HomeEntity(categories: categories, productSections: sections), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(StoreOpenStatusEntity?, AppFailure?)> getStoreOpenStatus() async {
    try {
      final body = await _datasource.getStoreOpenStatus();
      return (
        StoreOpenStatusEntity(
          message: body['message']?.toString() ?? '',
          isOpen: body['is_open'] == true,
          deliveryDate: body['delivery_date']?.toString() ?? '',
        ),
        null,
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  List<CategoryEntity> _parseCategories(Map<String, dynamic> body) {
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};
    final raw = data['categories'] is List ? data['categories'] as List : <dynamic>[];
    return raw
        .whereType<Map>()
        .map((e) => HomeCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  List<ProductSectionEntity> _parseProductSections(dynamic jsonBody) {
    final list = _extractSectionsList(jsonBody);
    return list
        .whereType<Map>()
        .map((e) => HomeProductSectionModel.fromMap(Map<String, dynamic>.from(e)))
        .where((s) => s.title.isNotEmpty && s.products.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractSectionsList(dynamic jsonBody) {
    if (jsonBody is List) return List<dynamic>.from(jsonBody);
    if (jsonBody is! Map) return const [];

    final body = Map<String, dynamic>.from(jsonBody);
    if (body['data'] is List) return List<dynamic>.from(body['data'] as List);
    if (body['homepageProductsData'] is List) {
      return List<dynamic>.from(body['homepageProductsData'] as List);
    }
    final data = body['data'];
    if (data is Map) {
      final dm = Map<String, dynamic>.from(data);
      if (dm['homepageProductsData'] is List) {
        return List<dynamic>.from(dm['homepageProductsData'] as List);
      }
      if (dm['results'] is List) return List<dynamic>.from(dm['results'] as List);
    }
    return const [];
  }
}

