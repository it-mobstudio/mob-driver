import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

class CityView {
  const CityView(this.centre, this.zoom);

  final LatLng centre;
  final double zoom;
}

const _known = <String, CityView>{
  'bengaluru': CityView(LatLng(12.9716, 77.5946), 10.8),
  'bangalore': CityView(LatLng(12.9716, 77.5946), 10.8),
  'mysuru': CityView(LatLng(12.2958, 76.6394), 12),
  'mysore': CityView(LatLng(12.2958, 76.6394), 12),
  'pune': CityView(LatLng(18.5204, 73.8567), 11),
  'poona': CityView(LatLng(18.5204, 73.8567), 11),
  'mumbai': CityView(LatLng(19.0760, 72.8777), 10.4),
  'bombay': CityView(LatLng(19.0760, 72.8777), 10.4),
  'navi mumbai': CityView(LatLng(19.0330, 73.0297), 11.2),
  'thane': CityView(LatLng(19.2183, 72.9781), 11.6),
  'delhi': CityView(LatLng(28.6139, 77.2090), 10.2),
  'new delhi': CityView(LatLng(28.6139, 77.2090), 10.2),
  'gurugram': CityView(LatLng(28.4595, 77.0266), 11.2),
  'gurgaon': CityView(LatLng(28.4595, 77.0266), 11.2),
  'noida': CityView(LatLng(28.5355, 77.3910), 11.4),
  'hyderabad': CityView(LatLng(17.3850, 78.4867), 10.6),
  'chennai': CityView(LatLng(13.0827, 80.2707), 10.8),
  'madras': CityView(LatLng(13.0827, 80.2707), 10.8),
  'kolkata': CityView(LatLng(22.5726, 88.3639), 11),
  'calcutta': CityView(LatLng(22.5726, 88.3639), 11),
  'ahmedabad': CityView(LatLng(23.0225, 72.5714), 11),
  'jaipur': CityView(LatLng(26.9124, 75.7873), 11.2),
  'lucknow': CityView(LatLng(26.8467, 80.9462), 11.2),
  'chandigarh': CityView(LatLng(30.7333, 76.7794), 11.8),
  'kochi': CityView(LatLng(9.9312, 76.2673), 11.4),
  'coimbatore': CityView(LatLng(11.0168, 76.9558), 11.4),
  'mangaluru': CityView(LatLng(12.9141, 74.8560), 12),
  'mangalore': CityView(LatLng(12.9141, 74.8560), 12),
  'hubballi': CityView(LatLng(15.3647, 75.1240), 12),
  'hubli': CityView(LatLng(15.3647, 75.1240), 12),
  'nagpur': CityView(LatLng(21.1458, 79.0882), 11.4),
  'indore': CityView(LatLng(22.7196, 75.8577), 11.4),
  'surat': CityView(LatLng(21.1702, 72.8311), 11.2),
  'visakhapatnam': CityView(LatLng(17.6868, 83.2185), 11.2),
};
const _lookedUpZoom = 11.0;

final _lookups = <String, Future<CityView?>>{};
Future<CityView?> cityViewFor(String? city) {
  final key = (city ?? '').trim().toLowerCase();
  if (key.isEmpty) return Future.value();
  final known = _known[key];
  if (known != null) return Future.value(known);
  if (kIsWeb) return Future.value();
  return _lookups[key] ??= () async {
    try {
      final hits = await Geocoding()
          .locationFromAddress('$city, India')
          .timeout(const Duration(seconds: 6));
      if (hits.isEmpty) return null;
      return CityView(
          LatLng(hits.first.latitude, hits.first.longitude), _lookedUpZoom);
    } catch (_) {
      _lookups.remove(key);
      return null;
    }
  }();
}
