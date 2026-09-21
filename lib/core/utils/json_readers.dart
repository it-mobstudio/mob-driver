// Tolerant readers for backend JSON.
//
// DRF serialises `DecimalField`s as **strings** ("85.00", "12.975000") but a
// raw `Decimal` dropped into a plain `Response({...})` goes out as a JSON
// **number**, and the two styles both appear in this API. Every numeric read
// therefore accepts either.

Map<String, dynamic> asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> asMapList(dynamic value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : <Map<String, dynamic>>[];

String? readString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty || text == 'null' ? null : text;
}

double? readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

int? readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final text = value.trim();
    return int.tryParse(text) ?? double.tryParse(text)?.toInt();
  }
  return null;
}

bool readBool(dynamic value, {bool fallback = false}) =>
    value is bool ? value : fallback;

DateTime? readDateTime(dynamic value) {
  final text = readString(value);
  return text == null ? null : DateTime.tryParse(text)?.toLocal();
}
