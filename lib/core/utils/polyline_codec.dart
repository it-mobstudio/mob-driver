/// A decoded point of an encoded polyline.
class PolylinePoint {
  const PolylinePoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is PolylinePoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'PolylinePoint($latitude, $longitude)';
}

/// Decodes a Google/Valhalla "encoded polyline" string.
///
/// The backend stores a trip's route as Valhalla's shape, which is encoded at
/// **6** decimal places (`Trip.polyline_precision`) — not the 5 that Google's
/// own APIs (and most Flutter polyline helpers) assume. Decoding it at 5
/// silently yields a route ten times too large that lands in the wrong
/// hemisphere of the map, so the precision must always come from the trip.
///
/// Returns an empty list for a null/empty string, and stops (returning what it
/// decoded so far) rather than throwing if the string is truncated/corrupt —
/// a bad route must never take the trip screen down with it.
List<PolylinePoint> decodePolyline(String? encoded, {int precision = 6}) {
  if (encoded == null || encoded.isEmpty) return const [];

  final factor = _pow10(precision);
  final points = <PolylinePoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  // Reads one zig-zag varint starting at [index]; null if the string ends
  // mid-value.
  int? readValue() {
    var result = 0;
    var shift = 0;
    while (true) {
      if (index >= encoded.length) return null;
      final byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
      if (byte < 0x20) break;
    }
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    final dLat = readValue();
    final dLng = readValue();
    if (dLat == null || dLng == null) break;
    lat += dLat;
    lng += dLng;
    points.add(PolylinePoint(lat / factor, lng / factor));
  }
  return points;
}

double _pow10(int exponent) {
  var value = 1.0;
  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}
