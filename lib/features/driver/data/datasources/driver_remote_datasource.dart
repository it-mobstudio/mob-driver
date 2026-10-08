import 'package:dio/dio.dart';
import 'package:mob_driver/core/utils/json_readers.dart';
import 'package:mob_driver/features/driver/data/datasources/driver_endpoints.dart';
import 'package:mob_driver/features/driver/domain/entities/captured_photo.dart';

typedef Json = Map<String, dynamic>;

/// The driver API of the delivery backend. Returns raw JSON; the repository
/// turns it into entities, and errors into failures.
class DriverRemoteDatasource {
  DriverRemoteDatasource(this._dio);

  final Dio _dio;

  // -- profile and documents -----------------------------------------------

  Future<Json> me() => _get(DriverEndpoints.me);

  Future<Json> updateProfile(Json body) => _patch(DriverEndpoints.me, body);

  /// Closes the account (`204`).
  Future<void> deleteAccount() => _dio.delete<dynamic>(DriverEndpoints.me);

  Future<Json> uploadPhoto(CapturedPhoto photo) =>
      _multipart(DriverEndpoints.photo, files: {'photo': photo});

  Future<Json> submitAadhar({
    required String number,
    required CapturedPhoto front,
    required CapturedPhoto back,
  }) =>
      _multipart(
        DriverEndpoints.aadhaar,
        fields: {'number': number},
        files: {'front': front, 'back': back},
      );

  Future<Json> submitLicence({
    required String number,
    required String expiryDate,
    required CapturedPhoto front,
    CapturedPhoto? back,
  }) =>
      _multipart(
        DriverEndpoints.licence,
        fields: {'number': number, 'expiry_date': expiryDate},
        files: {'front': front, if (back != null) 'back': back},
      );

  Future<Json> submitPolice(CapturedPhoto document) =>
      _multipart(DriverEndpoints.police, files: {'document': document});

  Future<Json> stats({required int utcOffsetMinutes}) => _get(
        DriverEndpoints.stats,
        query: {'utc_offset_minutes': utcOffsetMinutes},
      );

  // -- duty ------------------------------------------------------------------

  Future<Json> vehicles() => _get(DriverEndpoints.dutyVehicles);

  Future<Json> startDuty({
    required String vehicleId,
    double? latitude,
    double? longitude,
  }) =>
      _post(DriverEndpoints.startDuty, {
        'vehicle_id': vehicleId,
        if (latitude != null && longitude != null)
          ..._coordinates(latitude, longitude),
      });

  Future<Json> endDuty() => _post(DriverEndpoints.endDuty);

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
  }) =>
      _post(DriverEndpoints.location, _coordinates(latitude, longitude));

  // -- wallet ----------------------------------------------------------------

  Future<Json> wallet({required int utcOffsetMinutes}) => _get(
        DriverEndpoints.wallet,
        query: {'utc_offset_minutes': utcOffsetMinutes},
      );

  Future<Json> walletEntries({int page = 1, List<String> kinds = const []}) =>
      _get(DriverEndpoints.walletTransactions, query: {
        'page': page,
        if (kinds.isNotEmpty) 'kind': kinds.join(','),
      });

  // -- trips -----------------------------------------------------------------

  /// `{"trip": {...}}` or `{"trip": null}`.
  Future<Json> activeTrip() => _get(DriverEndpoints.activeTrip);

  Future<Json> trips({int page = 1, List<String> statuses = const []}) =>
      _get(DriverEndpoints.trips, query: {
        'page': page,
        if (statuses.isNotEmpty) 'status': statuses.join(','),
      });

  Future<Json> trip(String id) => _get(DriverEndpoints.trip(id));

  Future<Json> navigation(
    String id, {
    required double latitude,
    required double longitude,
  }) =>
      _get(DriverEndpoints.navigation(id),
          query: _coordinates(latitude, longitude));

  Future<Json> arrive(String id) => _post(DriverEndpoints.arrive(id));

  Future<Json> start(String id) => _post(DriverEndpoints.start(id));

  Future<Json> paymentQr(String id) => _get(DriverEndpoints.paymentQr(id));

  /// [method]: `qr` (the customer scanned the code — the server checks with
  /// the payment provider) or `cash` (they paid the driver directly; the fare
  /// is debited from the driver's wallet).
  Future<Json> collectPayment(String id, {String method = 'qr'}) =>
      _post(DriverEndpoints.collectPayment(id), {'method': method});

  Future<Json> resendDeliveryOtp(String id) =>
      _post(DriverEndpoints.resendDeliveryOtp(id));

  /// [otp] is required by the backend for COD trips and ignored for prepaid.
  Future<Json> complete(String id, {String? otp}) =>
      _post(DriverEndpoints.complete(id), {if (otp != null) 'otp': otp});

  Future<Json> cancel(String id, {required String reason}) =>
      _post(DriverEndpoints.cancel(id), {'reason': reason});

  /// The driver's word on one item (`delivered` / `not_delivered`), with an
  /// optional photo. Answers with the whole trip.
  Future<Json> verifyItem(
    String tripId,
    String itemId, {
    required String status,
    String? note,
    CapturedPhoto? photo,
  }) =>
      _multipart(
        DriverEndpoints.verifyItem(tripId, itemId),
        fields: {
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        files: {if (photo != null) 'photo': photo},
      );

  Future<Json> resetItem(String tripId, String itemId) =>
      _delete(DriverEndpoints.verifyItem(tripId, itemId));

  /// A camera photo at the pickup or the drop ([stage] is `pickup` or
  /// `delivery`) — of the whole order, or of one item ([itemId]). Answers
  /// with the whole trip.
  Future<Json> addTripPhoto(
    String tripId, {
    required String stage,
    required CapturedPhoto photo,
    String? itemId,
  }) =>
      _multipart(
        DriverEndpoints.tripPhoto(tripId, stage),
        fields: {if (itemId != null) 'item_id': itemId},
        files: {'photo': photo},
      );

  /// Takes back one photo of the whole order. Answers with the whole trip.
  Future<Json> removeTripPhoto(String tripId, String photoId) =>
      _delete(DriverEndpoints.tripPhotoById(tripId, photoId));

  // -- in-between stops (each answers with the whole trip) ------------------

  Future<Json> arriveAtStop(String tripId, String stopId) =>
      _post(DriverEndpoints.arriveAtStop(tripId, stopId));

  /// Of what's collected / handed over at the stop, or of one item.
  Future<Json> addStopPhoto(
    String tripId,
    String stopId, {
    required CapturedPhoto photo,
    String? itemId,
  }) =>
      _multipart(
        DriverEndpoints.stopPhoto(tripId, stopId),
        fields: {if (itemId != null) 'item_id': itemId},
        files: {'photo': photo},
      );

  Future<Json> finishStop(String tripId, String stopId) =>
      _post(DriverEndpoints.finishStop(tripId, stopId));

  // -- the driver's own vehicles --------------------------------------------

  Future<Json> vehicleTypes() => _get(DriverEndpoints.vehicleTypes);

  Future<Json> myVehicles() => _get(DriverEndpoints.myVehicles);

  /// Registers a vehicle; the pictures go up as repeated `photos` parts.
  Future<Json> addVehicle({
    required String vehicleTypeId,
    required String registrationNumber,
    double? capacityKg,
    List<CapturedPhoto> photos = const [],
  }) async {
    final form = FormData.fromMap({
      'vehicle_type_id': vehicleTypeId,
      'registration_number': registrationNumber,
      if (capacityKg != null) 'capacity_kg': capacityKg.toString(),
      if (photos.isNotEmpty) 'photos': [for (final p in photos) _file(p)],
    });
    return asMap(
        (await _dio.post<dynamic>(DriverEndpoints.myVehicles, data: form))
            .data);
  }

  Future<Json> updateVehicle(String id, Json body) =>
      _patch(DriverEndpoints.myVehicle(id), body);

  Future<Json> addVehiclePhoto(String id, CapturedPhoto photo) =>
      _multipart(DriverEndpoints.myVehiclePhotos(id), files: {'photo': photo});

  Future<Json> removeVehiclePhoto(String id, String photoId) =>
      _delete(DriverEndpoints.myVehiclePhoto(id, photoId));

  /// Retires the vehicle (`204`).
  Future<void> removeVehicle(String id) =>
      _dio.delete<dynamic>(DriverEndpoints.myVehicle(id));

  // -- transport -------------------------------------------------------------

  Future<Json> _get(String path, {Json? query}) async =>
      asMap((await _dio.get<dynamic>(path, queryParameters: query)).data);

  Future<Json> _post(String path, [Json? body]) async => asMap(
      (await _dio.post<dynamic>(path, data: body ?? <String, dynamic>{})).data);

  Future<Json> _patch(String path, Json body) async =>
      asMap((await _dio.patch<dynamic>(path, data: body)).data);

  Future<Json> _delete(String path) async =>
      asMap((await _dio.delete<dynamic>(path)).data);

  /// A `multipart/form-data` POST. Pictures go up as bytes with a file name
  /// and type; the backend decides what it accepts.
  Future<Json> _multipart(
    String path, {
    Map<String, String> fields = const {},
    Map<String, CapturedPhoto> files = const {},
  }) async {
    final form = FormData.fromMap({
      ...fields,
      for (final MapEntry(:key, :value) in files.entries) key: _file(value),
    });
    return asMap((await _dio.post<dynamic>(path, data: form)).data);
  }

  static MultipartFile _file(CapturedPhoto photo) => MultipartFile.fromBytes(
        photo.bytes,
        filename: photo.filename,
        contentType: DioMediaType.parse(photo.mimeType),
      );

  /// The backend's coordinate fields are 6-decimal DecimalFields that refuse
  /// longer floats, so they're sent as fixed-point strings.
  static Json _coordinates(double latitude, double longitude) => {
        'lat': latitude.toStringAsFixed(6),
        'lng': longitude.toStringAsFixed(6),
      };
}
