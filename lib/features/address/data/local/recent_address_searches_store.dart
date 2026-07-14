import 'dart:convert';

import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local MRU list of past location searches (place name + placeId),
/// shown on [LocationSearchPage] before the user types — same
/// SharedPreferences-list pattern as the product search history in
/// `lib/shared/top_search_page.dart`, just JSON-encoded per entry since each
/// one needs more than a bare string.
class RecentAddressSearchesStore {
  RecentAddressSearchesStore._();

  static const _key = 'recent_address_searches_v1';
  static const _maxEntries = 10;

  static Future<List<AddressSuggestionEntity>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((entry) {
          try {
            final decoded = jsonDecode(entry);
            if (decoded is Map) {
              return AddressSuggestionEntity(
                placeId: decoded['placeId']?.toString() ?? '',
                primaryText: decoded['primaryText']?.toString() ?? '',
                secondaryText: decoded['secondaryText']?.toString() ?? '',
              );
            }
          } catch (_) {}
          return null;
        })
        .whereType<AddressSuggestionEntity>()
        .where((suggestion) => suggestion.placeId.isNotEmpty)
        .toList();
  }

  static Future<void> add(AddressSuggestionEntity suggestion) async {
    if (suggestion.placeId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];

    // MRU: move to front, unique by placeId, max 10.
    current.removeWhere((entry) {
      try {
        final decoded = jsonDecode(entry);
        return decoded is Map && decoded['placeId'] == suggestion.placeId;
      } catch (_) {
        return false;
      }
    });
    current.insert(
      0,
      jsonEncode({
        'placeId': suggestion.placeId,
        'primaryText': suggestion.primaryText,
        'secondaryText': suggestion.secondaryText,
      }),
    );
    if (current.length > _maxEntries) {
      current.removeRange(_maxEntries, current.length);
    }
    await prefs.setStringList(_key, current);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
