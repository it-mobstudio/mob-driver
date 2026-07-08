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
      final list = _extractList(raw);
      return (
        list
            .whereType<Map>()
            .map((item) => AddressEntity.fromMap(_normalizeAddressMap(item)))
            .toList(),
        null,
      );
    } on DioException catch (error) {
      return (null, error.toAppFailure());
    } catch (error) {
      return (null, UnknownFailure(error.toString()));
    }
  }

  @override
  Future<(AddressEntity?, AppFailure?)> createAddress(
    AddressEntity address,
  ) async {
    try {
      final body = await _datasource.createAddress(address.toCreatePayload());
      if (body['status'] == false) {
        return (
          null,
          BusinessFailure(_responseMessage(body)),
        );
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (
        _containsAddressData(data)
            ? AddressEntity.fromMap({
                ...address.toCreatePayload(),
                ...data,
              })
            : address,
        null,
      );
    } on DioException catch (error) {
      return (null, _addressFailure(error));
    } catch (error) {
      return (null, UnknownFailure(error.toString()));
    }
  }

  @override
  Future<(AddressEntity?, AppFailure?)> updateAddress(
    AddressEntity address,
  ) async {
    try {
      final payload = {
        ...address.toCreatePayload(),
        'address_id': address.id,
      };
      final body = await _datasource.updateAddress(payload);
      if (body['status'] == false) {
        return (null, BusinessFailure(_responseMessage(body)));
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (
        _containsAddressData(data)
            ? AddressEntity.fromMap({...payload, ...data})
            : address,
        null,
      );
    } on DioException catch (error) {
      return (null, _addressFailure(error));
    } catch (error) {
      return (null, UnknownFailure(error.toString()));
    }
  }

  @override
  Future<(bool, AppFailure?)> deleteAddress(String addressId) async {
    try {
      final body = await _datasource.deleteAddress(addressId);
      if (body['status'] == false) {
        return (false, BusinessFailure(_responseMessage(body)));
      }
      return (true, null);
    } on DioException catch (error) {
      return (false, error.toAppFailure());
    } catch (error) {
      return (false, UnknownFailure(error.toString()));
    }
  }

  @override
  Future<(List<AddressSuggestionEntity>?, AppFailure?)> searchLocations(
    String query,
  ) async {
    try {
      final body = await _datasource.searchLocations(query);
      final status = body['status']?.toString() ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        return (
          null,
          BusinessFailure(
            body['error_message']?.toString() ?? 'Location search failed.',
          ),
        );
      }
      final predictions = body['predictions'] is List
          ? body['predictions'] as List<dynamic>
          : const <dynamic>[];
      final results = predictions
          .whereType<Map>()
          .map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final formatting = item['structured_formatting'] is Map
                ? Map<String, dynamic>.from(
                    item['structured_formatting'] as Map)
                : const <String, dynamic>{};
            return AddressSuggestionEntity(
              placeId: item['place_id']?.toString() ?? '',
              primaryText: formatting['main_text']?.toString() ??
                  item['description']?.toString() ??
                  '',
              secondaryText: formatting['secondary_text']?.toString() ?? '',
            );
          })
          .where((item) => item.placeId.isNotEmpty)
          .toList();
      return (results, null);
    } on DioException catch (error) {
      return (null, error.toAppFailure());
    } catch (error) {
      return (null, UnknownFailure(error.toString()));
    }
  }

  @override
  Future<(AddressLocationEntity?, AppFailure?)> getLocationDetails(
    String placeId,
  ) async {
    try {
      final body = await _datasource.getLocationDetails(placeId);
      if (body['status']?.toString() != 'OK' || body['result'] is! Map) {
        return (
          null,
          BusinessFailure(
            body['error_message']?.toString() ??
                'Unable to fetch location details.',
          ),
        );
      }
      final result = Map<String, dynamic>.from(body['result'] as Map);
      final geometry = result['geometry'] is Map
          ? Map<String, dynamic>.from(result['geometry'] as Map)
          : const <String, dynamic>{};
      final location = geometry['location'] is Map
          ? Map<String, dynamic>.from(geometry['location'] as Map)
          : const <String, dynamic>{};
      final components = result['address_components'] is List
          ? result['address_components'] as List<dynamic>
          : const <dynamic>[];

      return (
        AddressLocationEntity(
          latitude: _toDouble(location['lat']),
          longitude: _toDouble(location['lng']),
          formattedAddress: result['formatted_address']?.toString() ?? '',
          city: _component(
            components,
            const ['locality', 'administrative_area_level_2'],
          ),
          state: _component(
            components,
            const ['administrative_area_level_1'],
          ),
          pincode: _component(components, const ['postal_code']),
          sublocality: _component(
            components,
            const ['sublocality_level_1', 'sublocality'],
          ),
          locationName: result['name']?.toString() ??
              _component(components, const ['route', 'premise']),
        ),
        null,
      );
    } on DioException catch (error) {
      return (null, error.toAppFailure());
    } catch (error) {
      return (null, UnknownFailure(error.toString()));
    }
  }

  @override
  Future<(AddressLocationEntity?, AppFailure?)> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final body = await _datasource.reverseGeocode(latitude, longitude);
      final status = body['status']?.toString() ?? '';
      final results = body['results'] is List
          ? (body['results'] as List).whereType<Map>().toList()
          : const <Map>[];
      if (status != 'OK' || results.isEmpty) {
        return (
          null,
          BusinessFailure(
            body['error_message']?.toString() ??
                'Unable to resolve this address.',
          ),
        );
      }
      final result = Map<String, dynamic>.from(results.first);
      final geometry = result['geometry'] is Map
          ? Map<String, dynamic>.from(result['geometry'] as Map)
          : const <String, dynamic>{};
      final location = geometry['location'] is Map
          ? Map<String, dynamic>.from(geometry['location'] as Map)
          : const <String, dynamic>{};
      final components = result['address_components'] is List
          ? result['address_components'] as List<dynamic>
          : const <dynamic>[];
      final formattedAddress = result['formatted_address']?.toString() ?? '';
      final locationName = _component(
        components,
        const ['premise', 'route'],
      ).isNotEmpty
          ? _component(components, const ['premise', 'route'])
          : _component(
              components,
              const ['sublocality_level_1', 'sublocality'],
            );

      return (
        AddressLocationEntity(
          latitude: location['lat'] == null
              ? latitude
              : _toDouble(location['lat']),
          longitude: location['lng'] == null
              ? longitude
              : _toDouble(location['lng']),
          formattedAddress: formattedAddress,
          city: _component(
            components,
            const ['locality', 'administrative_area_level_2'],
          ),
          state: _component(
            components,
            const ['administrative_area_level_1'],
          ),
          pincode: _component(components, const ['postal_code']),
          sublocality: _component(
            components,
            const ['sublocality_level_1', 'sublocality'],
          ),
          locationName: locationName.isEmpty
              ? formattedAddress.split(',').first.trim()
              : locationName,
        ),
        null,
      );
    } on DioException catch (error) {
      return (null, error.toAppFailure());
    } catch (error) {
      return (null, UnknownFailure(error.toString()));
    }
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      for (final key in const ['data', 'addresses', 'results']) {
        if (raw[key] is List) return raw[key] as List;
        if (raw[key] is Map) {
          final nested = _extractList(raw[key]);
          if (nested.isNotEmpty) return nested;
        }
      }
      if (_containsAddressData(Map<String, dynamic>.from(raw))) return [raw];
    }
    return const [];
  }

  bool _containsAddressData(Map<String, dynamic> map) {
    return map.containsKey('latitude') ||
        map.containsKey('lat') ||
        map.containsKey('formatted_address') ||
        map.containsKey('address_line_1');
  }

  Map<String, dynamic> _normalizeAddressMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final address = map['address'] is Map
        ? Map<String, dynamic>.from(map['address'] as Map)
        : const <String, dynamic>{};
    final location = map['location'] is Map
        ? Map<String, dynamic>.from(map['location'] as Map)
        : const <String, dynamic>{};
    final coordinates = map['coordinates'] is Map
        ? Map<String, dynamic>.from(map['coordinates'] as Map)
        : const <String, dynamic>{};
    return {
      ...address,
      ...location,
      ...coordinates,
      ...map,
    };
  }

  String _component(List<dynamic> components, List<String> acceptedTypes) {
    for (final raw in components.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final types = item['types'] is List
          ? (item['types'] as List).map((type) => type.toString()).toList()
          : const <String>[];
      if (types.any(acceptedTypes.contains)) {
        return item['long_name']?.toString() ?? '';
      }
    }
    return '';
  }

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  AppFailure _addressFailure(DioException error) {
    final raw = error.response?.data;
    if (raw is Map) {
      final body = Map<String, dynamic>.from(raw);
      final message = _responseMessage(body);
      if (message != 'Unable to save address.') {
        return ServerFailure(
          message,
          statusCode: error.response?.statusCode,
        );
      }
    }
    return error.toAppFailure();
  }

  String _responseMessage(Map<String, dynamic> body) {
    for (final key in const ['message', 'error', 'detail']) {
      final value = body[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }

    final errors = body['errors'];
    if (errors is Map) {
      final messages = <String>[];
      errors.forEach((key, value) {
        final text = value is List
            ? value.map((item) => item.toString()).join(', ')
            : value.toString();
        if (text.trim().isNotEmpty) messages.add('$key: $text');
      });
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return 'Unable to save address.';
  }
}
