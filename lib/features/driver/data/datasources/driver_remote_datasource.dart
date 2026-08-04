import 'dart:typed_data';

import 'package:dio/dio.dart';

class DriverRemoteDatasource {
  DriverRemoteDatasource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> dashboard() async =>
      _map((await _dio.get<dynamic>('/driver/dashboard/')).data);

  Future<Map<String, dynamic>> toggleTracking(bool enabled) async =>
      _map((await _dio.post<dynamic>('/driver/tracking/toggle/',
              data: {'enabled': enabled}))
          .data);

  Future<Map<String, dynamic>> submitLocation({
    int? tripId,
    required double latitude,
    required double longitude,
    double? accuracyM,
    double? speedKph,
    double? heading,
    DateTime? recordedAt,
    String? externalEventId,
  }) async =>
      _map((await _dio.post<dynamic>('/driver/locations/', data: {
        if (tripId != null) 'trip': tripId,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracyM != null) 'accuracy_m': accuracyM,
        if (speedKph != null) 'speed_kph': speedKph,
        if (heading != null) 'heading': heading,
        if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
        'source': 'phone',
        if (externalEventId != null) 'external_event_id': externalEventId,
      }))
          .data);

  Future<Map<String, dynamic>> tripOverview({String? status}) async =>
      _map((await _dio.get<dynamic>('/driver/trip-overview/',
              queryParameters: {if (status != null) 'status': status}))
          .data);

  Future<List<Map<String, dynamic>>> trips() async =>
      _list((await _dio.get<dynamic>('/driver/trips/')).data);

  Future<Map<String, dynamic>> tripDetail(int tripId) async =>
      _map((await _dio.get<dynamic>('/driver/trip-overview/$tripId/')).data);

  Future<String?> drivingRoutePolyline({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String apiKey,
  }) async {
    final response = await Dio().post<dynamic>(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
      options: Options(headers: {
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      }),
      data: {
        'origin': {
          'location': {
            'latLng': {
              'latitude': originLatitude,
              'longitude': originLongitude,
            }
          }
        },
        'destination': {
          'location': {
            'latLng': {
              'latitude': destinationLatitude,
              'longitude': destinationLongitude,
            }
          }
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'polylineQuality': 'HIGH_QUALITY',
      },
    );
    final data = _map(response.data);
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) return null;
    final route = Map<String, dynamic>.from(routes.first as Map);
    final polyline = route['polyline'];
    if (polyline is! Map) return null;
    final encoded = polyline['encodedPolyline']?.toString().trim();
    return encoded == null || encoded.isEmpty ? null : encoded;
  }

  Future<Map<String, dynamic>> vehicle() async =>
      _map((await _dio.get<dynamic>('/driver/vehicle/')).data);

  Future<Map<String, dynamic>> profile() async =>
      _map((await _dio.get<dynamic>('/driver/profile/')).data);

  Future<Map<String, dynamic>> uploadTripProof({
    required int tripId,
    required Uint8List imageBytes,
    required String fileName,
    required String imageType,
    String? caption,
    double? latitude,
    double? longitude,
  }) async =>
      _map((await _dio.post<dynamic>('/driver/trips/$tripId/images/',
              data: FormData.fromMap({
                'image':
                    MultipartFile.fromBytes(imageBytes, filename: fileName),
                'image_type': imageType,
                if (caption != null) 'caption': caption,
                if (latitude != null) 'latitude': latitude,
                if (longitude != null) 'longitude': longitude,
              })))
          .data);

  Future<Map<String, dynamic>> startTrip(int tripId) =>
      _postEmpty('/driver/trips/$tripId/start/');
  Future<Map<String, dynamic>> endTrip(int tripId) =>
      _postEmpty('/driver/trips/$tripId/end/');
  Future<Map<String, dynamic>> endPause(int tripId) =>
      _postEmpty('/driver/trips/$tripId/pause/end/');

  Future<Map<String, dynamic>> startPause(int tripId,
          {required String pauseType, String? note}) async =>
      _map((await _dio
              .post<dynamic>('/driver/trips/$tripId/pause/start/', data: {
        'pause_type': pauseType,
        if (note != null) 'note': note,
      }))
          .data);

  Future<Map<String, dynamic>> reportIssue({
    required int tripId,
    required String issueType,
    required String description,
    String? penaltyAmount,
    String? imagePath,
  }) async {
    final values = <String, dynamic>{
      'issue_type': issueType,
      'description': description,
      if (penaltyAmount != null) 'penalty_amount': penaltyAmount,
      if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
    };
    final data = imagePath == null ? values : FormData.fromMap(values);
    return _map(
        (await _dio.post<dynamic>('/driver/trips/$tripId/issues/', data: data))
            .data);
  }

  Future<Map<String, dynamic>> tripMetrics(int tripId) async =>
      _map((await _dio.get<dynamic>('/driver/trips/$tripId/metrics/')).data);

  Future<Map<String, dynamic>> _postEmpty(String path) async =>
      _map((await _dio.post<dynamic>(path, data: <String, dynamic>{})).data);

  Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  List<Map<String, dynamic>> _list(dynamic raw) => raw is List
      ? raw.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];
}
