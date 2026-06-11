import 'package:dio/dio.dart';

abstract interface class AddressRemoteDatasource {
  Future<List<Map<String, dynamic>>> getAddresses();
}

class AddressRemoteDatasourceImpl implements AddressRemoteDatasource {
  AddressRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final response = await _dio.get<dynamic>('/accounts/mob_user_account/get_address/');
    return _extractList(response.data);
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    dynamic list = raw;
    if (raw is Map) {
      list = raw['data'] ?? raw['addresses'] ?? raw['results'] ?? raw;
    }
    if (list is List) {
      return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (list is Map) {
      final inner = list['results'] ?? list['addresses'];
      if (inner is List) {
        return inner.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return const [];
  }
}
