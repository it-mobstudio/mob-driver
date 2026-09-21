import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';

/// Thin wrapper over the driver endpoints of the delivery backend
/// (`/api/v1/driver/...`). Returns raw JSON maps; the repository turns them
/// into entities and errors into failures.
class DriverRemoteDatasource {
  DriverRemoteDatasource(this._dio);
  final Dio _dio;

  // -- profile / duty ------------------------------------------------------

  Future<Map<String, dynamic>> me() async =>
      asMap((await _dio.get<dynamic>('/driver/me')).data);

  Future<Map<String, dynamic>> vehicles() async =>
      asMap((await _dio.get<dynamic>('/driver/vehicles')).data);

  Future<Map<String, dynamic>> stats({required int utcOffsetMinutes}) async =>
      asMap((await _dio.get<dynamic>(
        '/driver/stats',
        queryParameters: {'utc_offset_minutes': utcOffsetMinutes},
      ))
          .data);

  /// `PATCH driver/me` — the driver's own details.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async =>
      asMap((await _dio.patch<dynamic>('/driver/me', data: body)).data);

  /// Closes the account (`204`).
  Future<void> deleteAccount() => _dio.delete<dynamic>('/driver/me');

  Future<Map<String, dynamic>> uploadPhoto(CapturedPhoto photo) =>
      _multipart('/driver/me/photo', files: {'photo': photo});

  Future<Map<String, dynamic>> submitAadhar({
    required String number,
    required CapturedPhoto front,
    required CapturedPhoto back,
  }) =>
      _multipart(
        '/driver/me/kyc/aadhar',
        fields: {'number': number},
        files: {'front': front, 'back': back},
      );

  Future<Map<String, dynamic>> submitLicence({
    required String number,
    required String expiryDate,
    required CapturedPhoto front,
    CapturedPhoto? back,
  }) =>
      _multipart(
        '/driver/me/kyc/dl',
        fields: {'number': number, 'expiry_date': expiryDate},
        files: {'front': front, if (back != null) 'back': back},
      );

  Future<Map<String, dynamic>> submitPolice(CapturedPhoto document) =>
      _multipart('/driver/me/kyc/police', files: {'document': document});

  // -- wallet --------------------------------------------------------------

  Future<Map<String, dynamic>> wallet({required int utcOffsetMinutes}) async =>
      asMap((await _dio.get<dynamic>(
        '/driver/wallet',
        queryParameters: {'utc_offset_minutes': utcOffsetMinutes},
      ))
          .data);

  Future<Map<String, dynamic>> walletEntries({
    int page = 1,
    List<String> kinds = const [],
  }) async =>
      asMap((await _dio
              .get<dynamic>('/driver/wallet/transactions', queryParameters: {
        'page': page,
        if (kinds.isNotEmpty) 'kind': kinds.join(','),
      }))
          .data);

  Future<Map<String, dynamic>> startDuty({
    required String vehicleId,
    double? latitude,
    double? longitude,
  }) async =>
      asMap((await _dio.post<dynamic>('/driver/duty/start', data: {
        'vehicle_id': vehicleId,
        if (latitude != null && longitude != null) ...{
          'lat': latitude.toStringAsFixed(6),
          'lng': longitude.toStringAsFixed(6),
        },
      }))
          .data);

  Future<Map<String, dynamic>> endDuty() async =>
      asMap((await _dio.post<dynamic>('/driver/duty/end')).data);

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    // Sent as fixed-point strings: the backend field is a 6-decimal
    // DecimalField and rejects longer floats ("no more than 6 decimal
    // places").
    await _dio.post<dynamic>('/driver/location', data: {
      'lat': latitude.toStringAsFixed(6),
      'lng': longitude.toStringAsFixed(6),
    });
  }

  // -- trips ---------------------------------------------------------------

  /// `{"trip": {...}}` or `{"trip": null}`.
  Future<Map<String, dynamic>> activeTrip() async =>
      asMap((await _dio.get<dynamic>('/driver/trips/active')).data);

  Future<Map<String, dynamic>> trips({
    int page = 1,
    List<String> statuses = const [],
  }) async =>
      asMap((await _dio.get<dynamic>('/driver/trips', queryParameters: {
        'page': page,
        if (statuses.isNotEmpty) 'status': statuses.join(','),
      }))
          .data);

  Future<Map<String, dynamic>> trip(String id) async =>
      asMap((await _dio.get<dynamic>('/driver/trips/$id')).data);

  Future<Map<String, dynamic>> navigation(
    String id, {
    required double latitude,
    required double longitude,
  }) async =>
      asMap((await _dio.get<dynamic>(
        '/driver/trips/$id/navigation',
        queryParameters: {
          'lat': latitude.toStringAsFixed(6),
          'lng': longitude.toStringAsFixed(6),
        },
      ))
          .data);

  Future<Map<String, dynamic>> arrive(String id) =>
      _post('/driver/trips/$id/arrive');

  Future<Map<String, dynamic>> start(String id) =>
      _post('/driver/trips/$id/start');

  Future<Map<String, dynamic>> paymentQr(String id) async =>
      asMap((await _dio.get<dynamic>('/driver/trips/$id/payment/qr')).data);

  Future<Map<String, dynamic>> collectPayment(String id) =>
      _post('/driver/trips/$id/payment/collect');

  Future<Map<String, dynamic>> resendDeliveryOtp(String id) =>
      _post('/driver/trips/$id/delivery-otp/resend');

  /// [otp] is required by the backend for COD trips and ignored for prepaid.
  Future<Map<String, dynamic>> complete(String id, {String? otp}) =>
      _post('/driver/trips/$id/complete', {if (otp != null) 'otp': otp});

  Future<Map<String, dynamic>> cancel(String id, {required String reason}) =>
      _post('/driver/trips/$id/cancel', {'reason': reason});

  /// The driver's word on one item (`delivered` / `not_delivered`), with an
  /// optional photo. Answers with the whole trip.
  Future<Map<String, dynamic>> verifyItem(
    String tripId,
    String itemId, {
    required String status,
    String? note,
    CapturedPhoto? photo,
  }) =>
      _multipart(
        '/driver/trips/$tripId/items/$itemId/verify',
        fields: {
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        files: {if (photo != null) 'photo': photo},
      );

  Future<Map<String, dynamic>> resetItem(String tripId, String itemId) async =>
      asMap((await _dio
              .delete<dynamic>('/driver/trips/$tripId/items/$itemId/verify'))
          .data);

  // -- the driver's own vehicles ------------------------------------------------

  Future<Map<String, dynamic>> vehicleTypes() async =>
      asMap((await _dio.get<dynamic>('/driver/vehicle-types')).data);

  Future<Map<String, dynamic>> myVehicles() async =>
      asMap((await _dio.get<dynamic>('/driver/my-vehicles')).data);

  /// Registers a vehicle; the pictures go up as repeated `photos` parts.
  Future<Map<String, dynamic>> addVehicle({
    required String vehicleTypeId,
    required String registrationNumber,
    double? capacityKg,
    List<CapturedPhoto> photos = const [],
  }) async {
    final form = FormData.fromMap({
      'vehicle_type_id': vehicleTypeId,
      'registration_number': registrationNumber,
      if (capacityKg != null) 'capacity_kg': capacityKg.toString(),
      if (photos.isNotEmpty)
        'photos': [
          for (final p in photos)
            MultipartFile.fromBytes(p.bytes,
                filename: p.filename,
                contentType: DioMediaType.parse(p.mimeType)),
        ],
    });
    return asMap(
        (await _dio.post<dynamic>('/driver/my-vehicles', data: form)).data);
  }

  Future<Map<String, dynamic>> updateVehicle(
          String id, Map<String, dynamic> body) async =>
      asMap((await _dio.patch<dynamic>('/driver/my-vehicles/$id', data: body))
          .data);

  Future<Map<String, dynamic>> addVehiclePhoto(
          String id, CapturedPhoto photo) =>
      _multipart('/driver/my-vehicles/$id/photos', files: {'photo': photo});

  Future<Map<String, dynamic>> removeVehiclePhoto(
          String id, String photoId) async =>
      asMap((await _dio
              .delete<dynamic>('/driver/my-vehicles/$id/photos/$photoId'))
          .data);

  /// Retires the vehicle (`204`).
  Future<void> removeVehicle(String id) =>
      _dio.delete<dynamic>('/driver/my-vehicles/$id');

  /// A `multipart/form-data` POST. The pictures go up as bytes with a proper
  /// file name and type — the backend decides what it will accept from those.
  Future<Map<String, dynamic>> _multipart(
    String path, {
    Map<String, String> fields = const {},
    Map<String, CapturedPhoto> files = const {},
  }) async {
    final form = FormData.fromMap({
      ...fields,
      for (final entry in files.entries)
        entry.key: MultipartFile.fromBytes(
          entry.value.bytes,
          filename: entry.value.filename,
          contentType: DioMediaType.parse(entry.value.mimeType),
        ),
    });
    return asMap((await _dio.post<dynamic>(path, data: form)).data);
  }

  Future<Map<String, dynamic>> _post(String path,
          [Map<String, dynamic>? body]) async =>
      asMap((await _dio.post<dynamic>(path, data: body ?? <String, dynamic>{}))
          .data);
}
