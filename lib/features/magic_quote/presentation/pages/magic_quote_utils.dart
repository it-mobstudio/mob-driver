/// Small parsing/formatting helpers shared across the Magic Quote screens.
/// Mirrors the web app's `MagicQuote/utils.js`. Payload-shape parsing that's
/// also needed outside the UI (e.g. by the websocket layer) lives in
/// `lib/features/rfq/domain/utils/magic_quote_status.dart` instead.
library;

const magicQuoteMatchStatusLabels = {
  'exact_match': 'Exact Match',
  'brand_match': 'Brand Match',
  'alternative_match': 'Alternative Match',
  'seller_match': 'Seller Match',
  'manual_review': 'Manual Review',
  'not_matched': 'Not Matched',
};

String formatInr(num value) {
  final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  final parts = text.split('.');
  final integer = parts.first;
  if (integer.length <= 3) return '₹$text';
  final lastThree = integer.substring(integer.length - 3);
  final leading = integer.substring(0, integer.length - 3);
  final grouped = leading.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (_) => ',',
  );
  return '₹$grouped,$lastThree${parts.length > 1 ? '.${parts.last}' : ''}';
}

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> payload) {
  final rawItems = payload['items'];
  if (rawItems is! List) return const [];
  return rawItems.whereType<Map>().map((item) {
    return Map<String, dynamic>.from(item);
  }).toList(growable: false);
}

Map<String, dynamic> mapValueOf(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String stringValueOf(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}

num moneyValueOf(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

String firstNonEmptyOf(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
