import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedAddressStore {
  SelectedAddressStore._();

  static const _key = 'selected_delivery_address';
  static AddressEntity? _cached;
  static final ChangeNotifier _notifier = ChangeNotifier();

  static AddressEntity? get cached => _cached;

  static void addListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }

  static void removeListener(VoidCallback listener) {
    _notifier.removeListener(listener);
  }

  static Future<void> initialize() async {
    _cached = await read();
  }

  static Future<AddressEntity?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      _cached = null;
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _cached = AddressEntity.fromMap(Map<String, dynamic>.from(decoded));
        return _cached;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> save(AddressEntity address) async {
    final changed = !_sameAddress(_cached, address);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(address.toMap()));
    _cached = address;
    if (changed) _notifier.notifyListeners();
  }

  static Future<void> clear() async {
    final changed = _cached != null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cached = null;
    if (changed) _notifier.notifyListeners();
  }

  static bool _sameAddress(AddressEntity? previous, AddressEntity next) {
    if (previous == null) return false;
    return jsonEncode(previous.toMap()) == jsonEncode(next.toMap());
  }
}
