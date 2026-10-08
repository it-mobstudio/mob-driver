import 'package:mob_driver/core/theme/app_colors.dart';

/// A calm map for driving: soft neutral land, white roads, business pins and
/// transit hidden, so the route, the stops and the driver stand out. The same
/// style the customer booking web app uses, so both look like one product.
const String kMobMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#f5f5f3"}]},
  {"elementType": "labels.icon", "stylers": [{"saturation": -100}, {"lightness": 25}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#5f6368"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#f5f5f3"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#eceeea"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#dcefd9"}]},
  {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#ffffff"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#e6e6e3"}]},
  {"featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [{"color": "#7b7f86"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#dde8f5"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#c3d6ec"}]},
  {"featureType": "road.local", "elementType": "labels.text.fill", "stylers": [{"color": "#9aa0a6"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#cfe6f5"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#8ab4cf"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]}
]
''';

/// [kMobMapStyle] for dark mode: the same calm map, at night.
const String kMobMapStyleDark = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1b2430"}]},
  {"elementType": "labels.icon", "stylers": [{"saturation": -100}, {"lightness": -40}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a96a8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1b2430"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#1f3329"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#2c3848"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212b38"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3a4a5e"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f1b29"}]}
]
''';

/// The map style for the appearance in use.
String get currentMapStyle =>
    AppColors.isDark ? kMobMapStyleDark : kMobMapStyle;
