// The driver's own vehicles and picture, through the app's REAL data layer
// against a REAL backend: several vehicles with several pictures each (real
// multipart with repeated `photos` parts), the pictures being reachable at the
// URLs the app is given, taking one on duty, and the rules around removing it.
//
// Skipped by default. Needs a backend on a THROWAWAY database with DEBUG=True and
// seeded drivers (manage.py seed_drivers):
//
//   LIVE_API=http://127.0.0.1:8011/api/v1/ LIVE_PHONE=+919000000000 \
//   flutter test test/live/live_vehicles_test.dart
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';

import '../support/fakes.dart' show kTinyPng;

final _env = Platform.environment;
final _api = _env['LIVE_API'];
final _skip = _api == null ? 'set LIVE_API (see the header of this file) to run against a live backend' : null;

CapturedPhoto _png(String name) => CapturedPhoto(bytes: kTinyPng, filename: name);

void main() {
  late DriverRepositoryImpl repo;
  late Dio publicDio; // what a phone's image loader would fetch with: no credentials

  setUpAll(() async {
    if (_skip != null) return;
    final dio = Dio(BaseOptions(baseUrl: _api!, connectTimeout: const Duration(seconds: 10)));
    publicDio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), responseType: ResponseType.bytes));
    final auth = AuthRemoteDatasourceImpl(dio);
    final phone = _env['LIVE_PHONE'] ?? '+919000000000';
    final otp = (await auth.requestOtp(phoneNumber: phone))['otp'] as String?;
    expect(otp, isNotNull, reason: 'backend must run with DRIVER_OTP_DEBUG_RESPONSE=True for this test');
    final session = await auth.verifyOtp(phoneNumber: phone, otp: otp!);
    dio.options.headers['Authorization'] = 'Bearer ${session['accessToken']}';
    repo = DriverRepositoryImpl(DriverRemoteDatasource(dio));
  });

  test('a driver adds vehicles with pictures, goes on duty with one, and removes it', () async {
    final (types, typesFailure) = await repo.vehicleTypes();
    expect(typesFailure, isNull, reason: typesFailure?.message);
    final bike = types!.firstWhere((t) => t.category == 'two_wheeler');
    print('vehicle types: ${types.map((t) => t.name).join(', ')}');

    // -- register one with three pictures, and one with none ------------------------------
    final plate = 'KA05LV${DateTime.now().millisecondsSinceEpoch % 10000}';
    var (vehicle, failure) = await repo.addVehicle(
      vehicleTypeId: bike.id,
      registrationNumber: plate.toLowerCase(),
      capacityKg: 35.5,
      photos: [_png('front.png'), _png('side.png'), _png('back.png')],
    );
    expect(failure, isNull, reason: failure?.message);
    expect(vehicle!.registrationNumber, plate, reason: 'upper-cased by the server');
    expect(vehicle.capacityKg, 35.5);
    expect(vehicle.photos, hasLength(3), reason: 'all three parts were read');
    expect(vehicle.photoUrl, vehicle.photos.first.url, reason: 'the first picture is the main one');
    print('registered $plate with ${vehicle.photos.length} pictures');

    for (final photo in vehicle.photos) {
      expect(photo.url, startsWith('http'), reason: 'absolute, so the phone can load it');
      final served = await publicDio.get<List<int>>(photo.url);
      expect(served.statusCode, 200);
      expect(served.headers.value('content-type'), startsWith('image/'));
    }

    final (bare, bareFailure) = await repo.addVehicle(vehicleTypeId: bike.id, registrationNumber: '${plate}B');
    expect(bareFailure, isNull, reason: bareFailure?.message);
    expect(bare!.photos, isEmpty);
    expect(bare.photoUrl, isNull);

    // -- the server's rules reach the screen as words -----------------------------------------
    final (_, duplicate) = await repo.addVehicle(vehicleTypeId: bike.id, registrationNumber: plate);
    expect(duplicate?.message, contains('already exists'));
    final (_, spaced) = await repo.addVehicle(vehicleTypeId: bike.id, registrationNumber: 'KA 05 XX');
    expect(spaced, isNotNull, reason: 'the client filters spaces, but the server would refuse them anyway');

    // -- pictures come and go, the main one following ----------------------------------------------
    var (updated, _) = await repo.addVehiclePhoto(bare.id, _png('one.png'));
    expect(updated!.photos, hasLength(1));
    expect(updated.photoUrl, updated.photos.single.url);
    (updated, _) = await repo.removeVehiclePhoto(vehicle.id, vehicle.photos.first.id);
    expect(updated!.photos, hasLength(2));
    expect(updated.photoUrl, vehicle.photos[1].url, reason: 'the next picture became the main one');

    // -- it is mine, and it is offered for duty ------------------------------------------------------
    final (mine, _) = await repo.myVehicles();
    expect(mine!.map((v) => v.id), containsAll([vehicle.id, bare.id]));
    final (fixed, _) = await repo.updateVehicle(bare.id, registrationNumber: '${plate}C');
    expect(fixed!.registrationNumber, '${plate}C');

    final (offered, _) = await repo.availableVehicles();
    final own = offered!.firstWhere((v) => v.id == vehicle.id);
    expect(own.isOwn, isTrue);
    expect(own.photoUrl, startsWith('http'), reason: 'the picker can show it');

    // -- on duty with it: it can't be removed, off duty it can -----------------------------------------
    final (onDuty, dutyFailure) = await repo.startDuty(vehicleId: vehicle.id, latitude: 12.9716, longitude: 77.5946);
    expect(dutyFailure, isNull, reason: dutyFailure?.message);
    expect(onDuty!.currentVehicle?.id, vehicle.id);
    expect(onDuty.currentVehicle?.photoUrl, startsWith('http'), reason: 'the profile carries a loadable picture');

    final refused = await repo.removeVehicle(vehicle.id);
    expect(refused?.code, 'VEHICLE_ON_DUTY');
    expect(refused?.message, contains('Go off duty'));

    expect((await repo.endDuty()).$2, isNull);
    expect(await repo.removeVehicle(vehicle.id), isNull);
    expect(await repo.removeVehicle(bare.id), isNull);
    final (left, _) = await repo.myVehicles();
    expect(left!.where((v) => v.id == vehicle.id || v.id == bare.id), isEmpty);
    print('removed both; the driver has ${left.length} vehicle(s) left');
  }, skip: _skip);

  test('the driver\'s own picture is served at an absolute URL', () async {
    final (profile, failure) = await repo.uploadPhoto(_png('me.png'));
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.photoUrl, startsWith('http'));
    final served = await publicDio.get<List<int>>(profile.photoUrl!);
    expect(served.statusCode, 200);
    expect(served.headers.value('content-type'), startsWith('image/'));
    print('profile photo served from ${profile.photoUrl}');
  }, skip: _skip);
}
