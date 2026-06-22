import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';

abstract interface class AddressRemoteDatasource {
  Future<dynamic> getAddresses();
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> searchLocations(String query);
  Future<Map<String, dynamic>> getLocationDetails(String placeId);
  Future<Map<String, dynamic>> reverseGeocode(double latitude, double longitude);
}

class AddressRemoteDatasourceImpl implements AddressRemoteDatasource {
  AddressRemoteDatasourceImpl(this._dio)
      : _googleDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  final Dio _dio;
  final Dio _googleDio;

  @override
  Future<dynamic> getAddresses() async {
    final response = await _dio.get<dynamic>(
      '/accounts/mob_user_account/get_address/',
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> createAddress(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/accounts/mob_user_account/create_address/',
      data: payload,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> searchLocations(String query) async {
    _ensureGoogleKey();
    final response = await _googleDio.get<dynamic>(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: {
        'input': query,
        'key': AppConfig.googleMapsApiKey,
        'components': 'country:in',
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> getLocationDetails(String placeId) async {
    _ensureGoogleKey();
    final response = await _googleDio.get<dynamic>(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address,address_component,name',
        'key': AppConfig.googleMapsApiKey,
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    _ensureGoogleKey();
    final response = await _googleDio.get<dynamic>(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'latlng': '$latitude,$longitude',
        'key': AppConfig.googleMapsApiKey,
      },
    );
    return _toMap(response.data);
  }

  void _ensureGoogleKey() {
    if (AppConfig.googleMapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY is not configured. '
        'Stop the app and launch it again from this workspace.',
      );
    }
  }

  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }
}
