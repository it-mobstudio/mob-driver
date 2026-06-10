import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';

abstract interface class AddressRemoteDatasource {
  Future<dynamic> getAddresses();
  Future<dynamic> createAddress(Map<String, dynamic> data);
  Future<Map<String, dynamic>> searchLocations(String query);
  Future<Map<String, dynamic>> getPlaceDetails(String placeId);
}

class AddressRemoteDatasourceImpl implements AddressRemoteDatasource {
  AddressRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getAddresses() async {
    final response =
        await _dio.get<dynamic>('/accounts/mob_user_account/get_address/');
    return response.data;
  }

  @override
  Future<dynamic> createAddress(Map<String, dynamic> data) async {
    final response = await _dio.post<dynamic>(
      '/accounts/mob_user_account/create_address/',
      data: data,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> searchLocations(String query) async {
    final response = await _dio.get<dynamic>(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: {
        'input': query,
        'key': AppConfig.googleMapsApiKey,
        'components': 'country:in',
      },
      options: Options(headers: const {'Authorization': null}),
    );
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final response = await _dio.get<dynamic>(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address,address_components,name',
        'key': AppConfig.googleMapsApiKey,
      },
      options: Options(headers: const {'Authorization': null}),
    );
    return response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
  }
}
