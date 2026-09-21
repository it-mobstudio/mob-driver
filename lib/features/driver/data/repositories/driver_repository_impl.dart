import 'dart:async';

import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/local/driver_snapshot_cache.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';
import 'package:m_o_b_demand_side/features/driver/domain/repositories/driver_repository.dart';

class DriverRepositoryImpl implements DriverRepository {
  DriverRepositoryImpl(
    this._remote, {
    DriverSnapshotCache? cache,
    DateTime Function()? now,
  })  : _cache = cache,
        _now = now ?? DateTime.now;

  final DriverRemoteDatasource _remote;
  final DriverSnapshotCache? _cache;
  final DateTime Function() _now;

  Future<(T?, AppFailure?)> _guard<T>(Future<T> Function() body) async {
    try {
      return (await body(), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<({DriverProfile? profile, DriverStats? stats})>
      cachedSnapshot() async {
    final cache = _cache;
    if (cache == null) return (profile: null, stats: null);
    try {
      final stored = await cache.read();
      return (
        profile: stored.me == null ? null : DriverProfile.fromJson(stored.me!),
        stats:
            stored.stats == null ? null : DriverStats.fromJson(stored.stats!),
      );
    } catch (_) {
      return (profile: null, stats: null);
    }
  }

  @override
  Future<void> clearCache() async => _cache?.clear();

  /// Parses a `driver/me` answer and keeps the on-device copy in step, so the
  /// next launch doesn't paint a profile from before this change.
  DriverProfile _adoptProfile(Map<String, dynamic> json) {
    unawaited(_cache?.saveProfile(json) ?? Future<void>.value());
    return DriverProfile.fromJson(json);
  }

  @override
  Future<(DriverProfile?, AppFailure?)> profile() =>
      _guard(() async => _adoptProfile(await _remote.me()));

  @override
  Future<(DriverProfile?, AppFailure?)> updateProfile(ProfileUpdate update) =>
      _guard(() async =>
          _adoptProfile(await _remote.updateProfile(update.toJson())));

  @override
  Future<(DriverProfile?, AppFailure?)> uploadPhoto(CapturedPhoto photo) =>
      _guard(() async => _adoptProfile(await _remote.uploadPhoto(photo)));

  @override
  Future<(DriverProfile?, AppFailure?)> submitAadhar({
    required String number,
    required CapturedPhoto front,
    required CapturedPhoto back,
  }) =>
      _guard(() async => _adoptProfile(await _remote.submitAadhar(
          number: number, front: front, back: back)));

  @override
  Future<(DriverProfile?, AppFailure?)> submitLicence({
    required String number,
    required DateTime expiry,
    required CapturedPhoto front,
    CapturedPhoto? back,
  }) =>
      _guard(() async => _adoptProfile(await _remote.submitLicence(
            number: number,
            expiryDate: formatIsoDate(expiry),
            front: front,
            back: back,
          )));

  @override
  Future<(DriverProfile?, AppFailure?)> submitPolice(CapturedPhoto document) =>
      _guard(() async => _adoptProfile(await _remote.submitPolice(document)));

  @override
  Future<AppFailure?> deleteAccount() async {
    final (_, failure) = await _guard(() => _remote.deleteAccount());
    if (failure == null) await clearCache();
    return failure;
  }

  @override
  Future<(WalletSummary?, AppFailure?)> wallet() =>
      _guard(() async => WalletSummary.fromJson(await _remote.wallet(
            utcOffsetMinutes: _now().timeZoneOffset.inMinutes,
          )));

  @override
  Future<(Paged<WalletEntry>?, AppFailure?)> walletEntries({
    int page = 1,
    List<WalletKind> kinds = const [],
  }) =>
      _guard(() async {
        final body = await _remote.walletEntries(
          page: page,
          kinds: kinds.map((k) => k.wire).toList(),
        );
        return Paged<WalletEntry>(
          items: asMapList(body['results']).map(WalletEntry.fromJson).toList(),
          count: readInt(body['count']) ?? 0,
          hasNext: readString(body['next']) != null,
        );
      });

  @override
  Future<(List<DriverVehicle>?, AppFailure?)> availableVehicles() =>
      _guard(() async => asMapList((await _remote.vehicles())['vehicles'])
          .map(DriverVehicle.fromJson)
          .toList());

  @override
  Future<(DriverStats?, AppFailure?)> stats() => _guard(() async {
        final json = await _remote.stats(
          // The server runs in UTC; tell it where the driver's day starts.
          utcOffsetMinutes: _now().timeZoneOffset.inMinutes,
        );
        unawaited(_cache?.saveStats(json) ?? Future<void>.value());
        return DriverStats.fromJson(json);
      });

  @override
  Future<(DriverProfile?, AppFailure?)> startDuty({
    required String vehicleId,
    double? latitude,
    double? longitude,
  }) =>
      _guard(() async => DriverProfile.fromJson(await _remote.startDuty(
            vehicleId: vehicleId,
            latitude: latitude,
            longitude: longitude,
          )));

  @override
  Future<(DriverProfile?, AppFailure?)> endDuty() =>
      _guard(() async => DriverProfile.fromJson(await _remote.endDuty()));

  @override
  Future<AppFailure?> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    final (_, failure) = await _guard(
        () => _remote.sendLocation(latitude: latitude, longitude: longitude));
    return failure;
  }

  @override
  Future<(Trip?, AppFailure?)> activeTrip() => _guard<Trip?>(() async {
        final trip = (await _remote.activeTrip())['trip'];
        return trip is Map
            ? Trip.fromJson(Map<String, dynamic>.from(trip))
            : null;
      });

  @override
  Future<(Paged<Trip>?, AppFailure?)> trips({
    int page = 1,
    List<TripStatus> statuses = const [],
  }) =>
      _guard(() async {
        final body = await _remote.trips(
          page: page,
          statuses: statuses.map((s) => s.wire).toList(),
        );
        return Paged<Trip>(
          items: asMapList(body['results']).map(Trip.fromJson).toList(),
          count: readInt(body['count']) ?? 0,
          hasNext: readString(body['next']) != null,
        );
      });

  @override
  Future<(Trip?, AppFailure?)> trip(String id) =>
      _guard(() async => Trip.fromJson(await _remote.trip(id)));

  @override
  Future<(NavRoute?, AppFailure?)> navigation(
    String id, {
    required double latitude,
    required double longitude,
  }) =>
      _guard(() async => NavRoute.fromJson(await _remote.navigation(
            id,
            latitude: latitude,
            longitude: longitude,
          )));

  @override
  Future<(Trip?, AppFailure?)> arrive(String id) =>
      _guard(() async => Trip.fromJson(await _remote.arrive(id)));

  @override
  Future<(Trip?, AppFailure?)> start(String id) =>
      _guard(() async => Trip.fromJson(await _remote.start(id)));

  @override
  Future<(PaymentQr?, AppFailure?)> paymentQr(String id) =>
      _guard(() async => PaymentQr.fromJson(await _remote.paymentQr(id)));

  @override
  Future<(DeliveryOtpSent?, AppFailure?)> collectPayment(String id) => _guard(
      () async => DeliveryOtpSent.fromJson(await _remote.collectPayment(id)));

  @override
  Future<(DeliveryOtpSent?, AppFailure?)> resendDeliveryOtp(String id) =>
      _guard(() async =>
          DeliveryOtpSent.fromJson(await _remote.resendDeliveryOtp(id)));

  @override
  Future<(Trip?, AppFailure?)> complete(String id, {String? otp}) =>
      _guard(() async => Trip.fromJson(await _remote.complete(id, otp: otp)));

  @override
  Future<(Trip?, AppFailure?)> cancel(String id, {required String reason}) =>
      _guard(
          () async => Trip.fromJson(await _remote.cancel(id, reason: reason)));

  @override
  Future<(Trip?, AppFailure?)> verifyItem(
    String tripId,
    String itemId, {
    required ItemStatus status,
    String? note,
    CapturedPhoto? photo,
  }) =>
      _guard(() async => Trip.fromJson(await _remote.verifyItem(
            tripId,
            itemId,
            status: status.wire,
            note: note,
            photo: photo,
          )));

  @override
  Future<(Trip?, AppFailure?)> resetItem(String tripId, String itemId) =>
      _guard(
          () async => Trip.fromJson(await _remote.resetItem(tripId, itemId)));
}
