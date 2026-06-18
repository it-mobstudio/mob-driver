import 'dart:convert';

import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedAddressStore {
  SelectedAddressStore._();

  static const _key = 'selected_delivery_address';
  static AddressEntity? _cached;

  static AddressEntity? get cached => _cached;

  static Future<void> initialize() async {
    _cached = await read();
  }

  static Future<AddressEntity?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AddressEntity.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  static Future<void> save(AddressEntity address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(address.toMap()));
    _cached = address;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cached = null;
  }
}
