import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/address/data/datasources/address_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl(this._datasource);

  final AddressRemoteDatasource _datasource;

  @override
  Future<(List<AddressEntity>?, AppFailure?)> getAddresses() async {
    try {
      final raw = await _datasource.getAddresses();
      final maps = _extractList(raw);
      return (maps.map(AddressEntity.fromMap).toList(), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AddressEntity?, AppFailure?)> createAddress(AddressEntity address) async {
    try {
      final raw = await _datasource.createAddress(address.toMap());
      if (raw is Map && raw['status'] == false) {
        return (
          null,
          BusinessFailure(raw['message']?.toString() ?? 'Unable to save address.'),
        );
      }
      final map = _extractMap(raw);
      return (map.isEmpty ? address : AddressEntity.fromMap(map), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<LocationSuggestion>?, AppFailure?)> searchLocations(String query) async {
    if (query.trim().length < 3) {
      return (const <LocationSuggestion>[], null);
    }
    try {
      final body = await _datasource.searchLocations(query.trim());
      final status = body['status']?.toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        return (
          null,
          BusinessFailure(body['error_message']?.toString() ?? 'Location search failed.'),
        );
      }
      final predictions = body['predictions'] is List
          ? body['predictions'] as List
          : const <dynamic>[];
      return (
        predictions
            .whereType<Map>()
            .map((item) => LocationSuggestion.fromMap(Map<String, dynamic>.from(item)))
            .toList(),
        null,
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(PlaceDetails?, AppFailure?)> getPlaceDetails(String placeId) async {
    try {
      final body = await _datasource.getPlaceDetails(placeId);
      if (body['status']?.toString() != 'OK' || body['result'] is! Map) {
        return (
          null,
          BusinessFailure(body['error_message']?.toString() ?? 'Place details unavailable.'),
        );
      }
      final result = Map<String, dynamic>.from(body['result'] as Map);
      final geometry = result['geometry'] is Map
          ? Map<String, dynamic>.from(result['geometry'] as Map)
          : <String, dynamic>{};
      final location = geometry['location'] is Map
          ? Map<String, dynamic>.from(geometry['location'] as Map)
          : <String, dynamic>{};
      final components = result['address_components'] is List
          ? result['address_components'] as List
          : const <dynamic>[];

      String component(List<String> types) {
        for (final raw in components.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final itemTypes = map['types'] is List
              ? (map['types'] as List).map((e) => e.toString()).toList()
              : const <String>[];
          if (types.any(itemTypes.contains)) return (map['long_name'] ?? '').toString();
        }
        return '';
      }

      return (
        PlaceDetails(
          latitude: _double(location['lat']),
          longitude: _double(location['lng']),
          formattedAddress: (result['formatted_address'] ?? '').toString(),
          city: component(const ['locality', 'administrative_area_level_2']),
          state: component(const ['administrative_area_level_1']),
          pincode: component(const ['postal_code']),
          sublocality: component(const [
            'sublocality_level_1',
            'sublocality',
            'neighborhood',
          ]),
          locationName: (result['name'] ?? '').toString(),
        ),
        null,
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map) {
      for (final key in const ['data', 'addresses', 'results']) {
        final value = raw[key];
        if (value is List) {
          return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        if (value is Map) return [Map<String, dynamic>.from(value)];
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is! Map) return {};
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    return data is Map ? Map<String, dynamic>.from(data) : map;
  }

  double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}
