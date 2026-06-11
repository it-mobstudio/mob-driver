import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/address/data/datasources/address_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl(this._datasource);

  final AddressRemoteDatasource _datasource;

  @override
  Future<(List<UserAddressEntity>?, AppFailure?)> getAddresses() async {
    try {
      final maps = await _datasource.getAddresses();
      final addresses = maps
          .map(_buildAddress)
          .where((a) => a.hasAddress)
          .toList();
      return (addresses, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  UserAddressEntity _buildAddress(Map<String, dynamic> m) {
    final parts = [
      _str(m, const ['address_line_1', 'address1', 'address']),
      _str(m, const ['address_line_2', 'address2']),
      _str(m, const ['city']),
      _str(m, const ['state']),
      _str(m, const ['pincode', 'zip_code', 'zip']),
    ].where((v) => v.isNotEmpty).toList();

    return UserAddressEntity(
      id: _str(m, const ['id', 'address_id']),
      name: _str(m, const ['name', 'full_name', 'recipient_name']),
      address: parts.join(', '),
      phone: _str(m, const ['phone', 'phone_number', 'mobile', 'contact_number']),
      tag: _str(m, const ['tag', 'type', 'address_type', 'label'], fallback: 'Address'),
      pincode: _str(m, const ['pincode', 'zip_code', 'zip']),
      project: _str(m, const ['project_name', 'project']),
      gstNumber: _str(m, const ['gst_number', 'gst_no', 'gstin']),
    );
  }

  String _str(Map<String, dynamic> map, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }
}
