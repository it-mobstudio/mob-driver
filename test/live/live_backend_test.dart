// Drives the app's REAL data layer (the same datasource + repository classes
// the screens use) against a REAL running backend — the one thing the other
// tests can't prove: that what the Flutter code sends and parses actually
// matches what the Django server accepts and returns.
//
// Skipped by default. To run (needs the backend up with seeded drivers and,
// for routing, Valhalla or a stand-in on VALHALLA_URL):
//
//   LIVE_API=http://127.0.0.1:8000/api/v1/ \
//   LIVE_PHONE=+919000000001 \
//   LIVE_CLIENT_ID=<api client id> LIVE_CLIENT_SECRET=<api client secret> \
//   flutter test test/live/live_backend_test.dart
//
// (Create the API client with `manage.py create_api_client`, and the drivers
// with `manage.py seed_drivers`.)
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';

final _env = Platform.environment;
final _api = _env['LIVE_API'];
final _skip = _api == null ? 'set LIVE_API (see the header of this file) to run against a live backend' : null;

const _pickup = (lat: 12.9716, lng: 77.5946);
const _drop = (lat: 12.9784, lng: 77.6408);

void main() {
  late Dio driverDio;
  late Dio companyDio;
  late DriverRepositoryImpl repo;
  late Map<String, dynamic> vehicleType;

  Future<Trip> bookTrip({String mode = 'cod'}) async {
    final response = await companyDio.post<Map<String, dynamic>>('/trips', data: {
      'vehicle_type_id': vehicleType['vehicle_type_id'],
      'payment_mode': mode,
      'reference_id': 'FLUTTER-LIVE-${DateTime.now().millisecondsSinceEpoch}',
      'pickup': {'address': 'MG Road Metro, Bengaluru', 'lat': _pickup.lat, 'lng': _pickup.lng, 'contact_name': 'Shop', 'contact_phone': '+919888800001'},
      'drop': {'address': 'Indiranagar 100ft Rd, Bengaluru', 'lat': _drop.lat, 'lng': _drop.lng, 'contact_name': 'Asha', 'contact_phone': '+919888800002'},
    });
    expect(response.data!['status'], 'assigned', reason: 'the online driver at the pickup should have been matched');
    return Trip.fromJson(response.data!);
  }

  setUpAll(() async {
    if (_api == null) return;
    driverDio = Dio(BaseOptions(baseUrl: _api!, connectTimeout: const Duration(seconds: 10)));
    companyDio = Dio(BaseOptions(baseUrl: _api!, connectTimeout: const Duration(seconds: 10)));

    // -- company side: authenticate as an API client, pick a vehicle type ----
    final token = await companyDio.post<Map<String, dynamic>>('/auth/client-token',
        data: {'client_id': _env['LIVE_CLIENT_ID'], 'client_secret': _env['LIVE_CLIENT_SECRET']});
    companyDio.options.headers['Authorization'] = 'Bearer ${token.data!['access']}';
    final estimate = await companyDio.post<Map<String, dynamic>>('/trips/estimate', data: {
      'pickup': {'address': 'p', 'lat': _pickup.lat, 'lng': _pickup.lng},
      'drop': {'address': 'd', 'lat': _drop.lat, 'lng': _drop.lng},
    });
    vehicleType = Map<String, dynamic>.from((estimate.data!['estimates'] as List).first as Map);

    // -- driver side: the app's own login datasource ---------------------------
    final auth = AuthRemoteDatasourceImpl(driverDio);
    final phone = _env['LIVE_PHONE'] ?? '+919000000001';
    final otp = (await auth.requestOtp(phoneNumber: phone))['otp'] as String?;
    expect(otp, isNotNull, reason: 'backend must run with DRIVER_OTP_DEBUG_RESPONSE=True for this test');
    final session = await auth.verifyOtp(phoneNumber: phone, otp: otp!);
    driverDio.options.headers['Authorization'] = 'Bearer ${session['accessToken']}';

    repo = DriverRepositoryImpl(DriverRemoteDatasource(driverDio));
  });

  test('the whole delivery, driven through the app\'s data layer', () async {
    // Profile + vehicle picker.
    final (profile, profileFailure) = await repo.profile();
    expect(profileFailure, isNull);
    expect(profile!.isEligible, isTrue);
    print('driver: ${profile.fullName}, KYC ok, allowed: ${profile.allowedCategories}');

    final (vehicles, _) = await repo.availableVehicles();
    expect(vehicles, isNotEmpty);
    final vehicle = vehicles!.firstWhere((v) => v.isCurrent, orElse: () => vehicles.first);
    print('vehicle: ${vehicle.registrationNumber} (${vehicle.categoryLabel})');

    // Go on duty with a GPS fix at the pickup.
    final (onDuty, dutyFailure) = await repo.startDuty(vehicleId: vehicle.id, latitude: _pickup.lat, longitude: _pickup.lng);
    expect(dutyFailure, isNull, reason: dutyFailure?.message);
    expect(onDuty!.isOnline, isTrue);
    expect(onDuty.currentVehicle?.id, vehicle.id);
    expect(await repo.sendLocation(latitude: _pickup.lat, longitude: _pickup.lng), isNull);

    // Nothing yet...
    expect((await repo.activeTrip()).$1, isNull);

    // ...then the company books a COD trip and it lands on this driver.
    final booked = await bookTrip();
    final (active, _) = await repo.activeTrip();
    expect(active?.id, booked.id);
    expect(active!.status, TripStatus.assigned);
    expect(active.isCod, isTrue);
    expect(active.totalFare, greaterThan(0));

    // The polyline: decoded at the trip's own precision, it must start/end at the pickup/drop.
    final (detail, _) = await repo.trip(booked.id);
    expect(detail?.routePolyline, isNotEmpty);
    final points = (await repo.navigation(booked.id, latitude: 12.95, longitude: 77.58)).$1!;
    expect(points.target, 'pickup');
    expect(points.points.length, greaterThan(2));
    print('navigation leg: ${points.points.length} pts, ${points.distanceMeters} m to pickup');

    // Lifecycle.
    expect((await repo.arrive(booked.id)).$1?.status, TripStatus.arrivedAtPickup);
    final started = (await repo.start(booked.id)).$1!;
    expect(started.status, TripStatus.inProgress);
    expect(started.needsPaymentCollection, isTrue);

    // Scan-to-pay QR, then payment + the customer's OTP.
    final (qr, _) = await repo.paymentQr(booked.id);
    expect(qr!.payload, startsWith('upi://pay?'));
    expect(qr.amount, closeTo(started.totalFare!, 0.01));

    final (early, earlyFailure) = await repo.complete(booked.id, otp: '123456');
    expect(early, isNull);
    expect(earlyFailure?.code, 'PAYMENT_NOT_COLLECTED');

    final (sent, _) = await repo.collectPayment(booked.id);
    expect(sent!.message, contains('OTP'));
    final otp = sent.debugOtp;
    expect(otp, isNotNull, reason: 'test-mode backend echoes the OTP');

    expect((await repo.resendDeliveryOtp(booked.id)).$2?.code, 'OTP_ALREADY_REQUESTED', reason: 'resend is throttled right after a send');

    final wrong = await repo.complete(booked.id, otp: otp == '000000' ? '111111' : '000000');
    expect(wrong.$1, isNull);
    expect(wrong.$2?.code, 'INVALID_DELIVERY_OTP');
    expect(wrong.$2, isA<BusinessFailure>());

    final (done, doneFailure) = await repo.complete(booked.id, otp: otp);
    expect(doneFailure, isNull, reason: doneFailure?.message);
    expect(done!.status, TripStatus.completed);
    expect(done.isPaid, isTrue);
    expect((await repo.activeTrip()).$1, isNull);

    // History + stats reflect it.
    final (history, _) = await repo.trips(statuses: [TripStatus.completed]);
    expect(history!.items.any((t) => t.id == booked.id), isTrue);
    final (stats, _) = await repo.stats();
    expect(stats!.today.tripsCompleted, greaterThanOrEqualTo(1));
    expect(stats.today.codCollected, greaterThan(0));
    print('stats today: ${stats.today.tripsCompleted} trips, ₹${stats.today.totalFare}');
  }, skip: _skip);

  test('a driver can cancel before pickup, and the app sees the reason', () async {
    final booked = await bookTrip(mode: 'prepaid');
    final (cancelled, failure) = await repo.cancel(booked.id, reason: 'Vehicle breakdown');
    expect(failure, isNull, reason: failure?.message);
    expect(cancelled!.status, TripStatus.cancelled);
    expect(cancelled.cancelledBy, 'driver');
    expect(cancelled.cancellationReason, 'Vehicle breakdown');
    expect((await repo.activeTrip()).$1, isNull);
  }, skip: _skip);

  test('when the COMPANY cancels, the driver\'s active trip disappears and the detail says why', () async {
    final booked = await bookTrip();
    expect((await repo.activeTrip()).$1?.id, booked.id);

    await companyDio.post<dynamic>('/trips/${booked.id}/cancel', data: {'reason': 'Order cancelled by customer'});

    expect((await repo.activeTrip()).$1, isNull);
    final (final_, _) = await repo.trip(booked.id);
    expect(final_!.status, TripStatus.cancelled);
    expect(final_.cancelledByCompany, isTrue);
    expect(final_.cancellationReason, 'Order cancelled by customer');
  }, skip: _skip);

  test('the backend\'s rules come back as typed, readable failures', () async {
    final booked = await bookTrip();

    // Out-of-order step.
    final (_, startFailure) = await repo.start(booked.id);
    expect(startFailure?.code, 'INVALID_TRIP_STATUS_TRANSITION');
    expect(startFailure?.message, isNotEmpty);

    // Can't go offline mid-trip.
    final (_, offlineFailure) = await repo.endDuty();
    expect(offlineFailure?.code, 'DRIVER_HAS_ACTIVE_TRIP');

    // Someone else's / non-existent trip.
    final (_, missing) = await repo.trip('00000000-0000-0000-0000-000000000000');
    expect(missing, isNotNull);

    await repo.cancel(booked.id, reason: 'cleanup');
    expect((await repo.endDuty()).$1?.isOnline, isFalse);
  }, skip: _skip);
}
