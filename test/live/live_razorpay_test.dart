// The Razorpay "scan to pay" flow, driven through the app's REAL data layer
// against a REAL running backend — with the local Razorpay stand-in
// (mob-delivery-backend/scripts/dev_razorpay_stub.py) where Razorpay would be.
//
// What it proves: that the app parses what the backend really sends for a
// Razorpay code, that the code's image is reachable, that a payment made at
// "Razorpay" reaches the trip by webhook OR by the driver's "Check payment",
// and that the driver's word alone never marks a trip paid.
//
// What it does NOT prove: that real Razorpay accepts the backend's requests.
// The stub is built from Razorpay's public docs. Try that with Razorpay TEST keys.
//
// Skipped by default. To run, start the stub and a backend on a THROWAWAY
// database (DEBUG=True) pointed at it:
//
//   python scripts/dev_razorpay_stub.py        # STUB_WEBHOOK_URL=<backend>/api/v1/webhooks/razorpay
//   PAYMENT_PROVIDER=razorpay RAZORPAY_KEY_ID=rzp_test_stub RAZORPAY_KEY_SECRET=stub_secret \
//   RAZORPAY_WEBHOOK_SECRET=stub_webhook_secret RAZORPAY_API_BASE=http://127.0.0.1:8003/v1 \
//   python manage.py runserver 127.0.0.1:8011
//
//   LIVE_API=http://127.0.0.1:8011/api/v1/ LIVE_RAZORPAY_STUB=http://127.0.0.1:8003 \
//   LIVE_CLIENT_ID=... LIVE_CLIENT_SECRET=... LIVE_PHONE=+919000000002 \
//   flutter test test/live/live_razorpay_test.dart
//
// (README → "Razorpay locally" has the whole recipe.)
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';

final _env = Platform.environment;
final _api = _env['LIVE_API'];
final _stub = _env['LIVE_RAZORPAY_STUB'];
final _skip = _api == null || _stub == null
    ? 'set LIVE_API and LIVE_RAZORPAY_STUB (see the header of this file) to run against a live backend + the Razorpay stand-in'
    : null;

const _pickup = (lat: 12.9716, lng: 77.5946);
const _drop = (lat: 12.9784, lng: 77.6408);

void main() {
  late Dio driverDio;
  late Dio companyDio;
  late Dio plainDio; // no credentials, never throws on 4xx: a phone's browser, or Razorpay itself
  late DriverRepositoryImpl repo;
  late Map<String, dynamic> vehicleType;

  Future<Trip> bookTrip() async {
    final response = await companyDio.post<Map<String, dynamic>>('/trips', data: {
      'vehicle_type_id': vehicleType['vehicle_type_id'],
      'payment_mode': 'cod',
      'reference_id': 'RZP-LIVE-${DateTime.now().millisecondsSinceEpoch}',
      'pickup': {'address': 'MG Road Metro, Bengaluru', 'lat': _pickup.lat, 'lng': _pickup.lng, 'contact_name': 'Shop', 'contact_phone': '+919888800001'},
      'drop': {'address': 'Indiranagar 100ft Rd, Bengaluru', 'lat': _drop.lat, 'lng': _drop.lng, 'contact_name': 'Asha', 'contact_phone': '+919888800002'},
    });
    expect(response.data!['status'], 'assigned', reason: 'the online driver at the pickup should have been matched');
    return Trip.fromJson(response.data!);
  }

  /// A booked trip taken to "in progress", ready to be paid.
  Future<Trip> tripInProgress() async {
    final booked = await bookTrip();
    expect((await repo.arrive(booked.id)).$1?.status, TripStatus.arrivedAtPickup);
    final (started, failure) = await repo.start(booked.id);
    expect(failure, isNull, reason: failure?.message);
    return started!;
  }

  /// The provider's payment id, as the company sees it on the trip.
  Future<String> companyReference(String tripId) async {
    final response = await companyDio.get<Map<String, dynamic>>('/trips/$tripId');
    return (response.data!['payment_reference'] as String?) ?? '';
  }

  /// "The customer pays" at the stand-in Razorpay. Returns what the stand-in did.
  Future<Map<String, dynamic>> pay(String qrId, {int? paise, bool webhook = true}) async {
    final query = <String, String>{if (paise != null) 'amount': '$paise', if (!webhook) 'webhook': '0'};
    final response = await plainDio.post<Map<String, dynamic>>('$_stub/simulate/$qrId', queryParameters: query);
    expect(response.statusCode, 200, reason: 'the stand-in should know the code: ${response.data}');
    return response.data!;
  }

  setUpAll(() async {
    if (_skip != null) return;
    driverDio = Dio(BaseOptions(baseUrl: _api!, connectTimeout: const Duration(seconds: 10)));
    companyDio = Dio(BaseOptions(baseUrl: _api!, connectTimeout: const Duration(seconds: 10)));
    plainDio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), validateStatus: (_) => true));

    final token = await companyDio.post<Map<String, dynamic>>('/auth/client-token',
        data: {'client_id': _env['LIVE_CLIENT_ID'], 'client_secret': _env['LIVE_CLIENT_SECRET']});
    companyDio.options.headers['Authorization'] = 'Bearer ${token.data!['access']}';
    final estimate = await companyDio.post<Map<String, dynamic>>('/trips/estimate', data: {
      'pickup': {'address': 'p', 'lat': _pickup.lat, 'lng': _pickup.lng},
      'drop': {'address': 'd', 'lat': _drop.lat, 'lng': _drop.lng},
    });
    vehicleType = Map<String, dynamic>.from((estimate.data!['estimates'] as List).first as Map);

    final auth = AuthRemoteDatasourceImpl(driverDio);
    final phone = _env['LIVE_PHONE'] ?? '+919000000002';
    final otp = (await auth.requestOtp(phoneNumber: phone))['otp'] as String?;
    expect(otp, isNotNull, reason: 'backend must run with DRIVER_OTP_DEBUG_RESPONSE=True for this test');
    final session = await auth.verifyOtp(phoneNumber: phone, otp: otp!);
    driverDio.options.headers['Authorization'] = 'Bearer ${session['accessToken']}';
    repo = DriverRepositoryImpl(DriverRemoteDatasource(driverDio));

    // On duty, with a fix at the pickup, so trips land on this driver.
    final (vehicles, _) = await repo.availableVehicles();
    final vehicle = vehicles!.firstWhere((v) => v.isCurrent, orElse: () => vehicles.first);
    final (onDuty, dutyFailure) = await repo.startDuty(vehicleId: vehicle.id, latitude: _pickup.lat, longitude: _pickup.lng);
    expect(dutyFailure, isNull, reason: dutyFailure?.message);
    expect(onDuty!.isOnline, isTrue);
  });

  tearDownAll(() async {
    if (_skip != null) return;
    await repo.endDuty();
  });

  test('a payment made at Razorpay reaches the trip by webhook — the driver never claims it', () async {
    final trip = await tripInProgress();

    final (qr, failure) = await repo.paymentQr(trip.id);
    expect(failure, isNull, reason: failure?.message);
    expect(qr!.provider, 'razorpay');
    expect(qr.paymentIsVerified, isTrue);
    expect(qr.hasImage, isTrue);
    expect(qr.payload, isNull, reason: 'Razorpay gives an image, not a link to draw');
    expect(qr.reference, startsWith('qr_'));
    expect(qr.amount, closeTo(trip.totalFare!, 0.005));
    expect(qr.expiresAt!.isAfter(DateTime.now()), isTrue);
    print('Razorpay code ${qr.reference}: ₹${qr.amount}, image ${qr.imageUrl}');

    // The image is really served, at a URL the phone can reach.
    final image = await plainDio.get<List<int>>(qr.imageUrl!, options: Options(responseType: ResponseType.bytes));
    expect(image.statusCode, 200);
    expect(image.headers.value('content-type'), 'image/png');

    // Asking again — the screen reopened — gives the SAME code, not a second one.
    expect((await repo.paymentQr(trip.id)).$1?.reference, qr.reference);

    // Nothing is paid, so nothing is claimed: the driver's tap is refused…
    final (_, notYet) = await repo.collectPayment(trip.id);
    expect(notYet?.code, 'PAYMENT_NOT_RECEIVED');
    expect(notYet?.message, isNotEmpty);
    // …and the trip can't be finished without the payment.
    expect((await repo.complete(trip.id, otp: '123456')).$2?.code, 'PAYMENT_NOT_COLLECTED');
    expect((await repo.trip(trip.id)).$1?.isPaid, isFalse);

    // A payment far short of the fare doesn't count either.
    await pay(qr.reference!, paise: 100, webhook: true);
    expect((await repo.trip(trip.id)).$1?.isPaid, isFalse, reason: '₹1 is not ₹${qr.amount}');

    // The customer pays properly; Razorpay's webhook reaches the backend.
    final paid = await pay(qr.reference!);
    expect((paid['webhook'] as Map)['status'], 200, reason: 'the backend accepted the signed webhook: $paid');
    final (after, _) = await repo.trip(trip.id);
    expect(after!.isPaid, isTrue, reason: 'this is what the payment screen\'s polling picks up');
    expect(await companyReference(trip.id), startsWith('pay_'), reason: 'Razorpay\'s payment id, kept for reconciliation');

    // The server sent the customer their OTP by itself: asking to resend is throttled…
    expect((await repo.resendDeliveryOtp(trip.id)).$2?.code, 'OTP_ALREADY_REQUESTED');
    // …and a fresh code request now says the trip is paid.
    expect((await repo.paymentQr(trip.id)).$2?.code, 'ALREADY_PAID');
    expect((await repo.collectPayment(trip.id)).$2?.code, 'ALREADY_PAID');

    // The customer says the SMS never came. After the 30 s throttle the driver
    // can have it sent again — and that finishes the delivery.
    await Future<void>.delayed(const Duration(seconds: 31));
    final (resent, resendFailure) = await repo.resendDeliveryOtp(trip.id);
    expect(resendFailure, isNull, reason: resendFailure?.message);
    expect(resent!.debugOtp, isNotNull, reason: 'test-mode backend echoes the OTP');
    final (done, doneFailure) = await repo.complete(trip.id, otp: resent.debugOtp);
    expect(doneFailure, isNull, reason: doneFailure?.message);
    expect(done!.status, TripStatus.completed);
    expect((await repo.activeTrip()).$1, isNull);
  }, skip: _skip, timeout: const Timeout(Duration(seconds: 120)));

  test('with no webhook at all, the driver\'s "Check payment" finds the payment at Razorpay and the trip completes', () async {
    final trip = await tripInProgress();
    final qr = (await repo.paymentQr(trip.id)).$1!;

    final (_, notYet) = await repo.collectPayment(trip.id);
    expect(notYet?.code, 'PAYMENT_NOT_RECEIVED');

    final paid = await pay(qr.reference!, webhook: false);
    expect(paid['webhook'], isNull, reason: 'no webhook was sent');
    expect((await repo.trip(trip.id)).$1?.isPaid, isFalse, reason: 'the server has not been told yet');

    final (sent, failure) = await repo.collectPayment(trip.id);
    expect(failure, isNull, reason: failure?.message);
    expect(sent!.message, contains('OTP'));
    expect(sent.debugOtp, isNotNull, reason: 'test-mode backend echoes the OTP');
    expect((await repo.trip(trip.id)).$1?.isPaid, isTrue);
    expect(await companyReference(trip.id), startsWith('pay_'), reason: 'Razorpay\'s payment id, kept for reconciliation');

    final (done, doneFailure) = await repo.complete(trip.id, otp: sent.debugOtp);
    expect(doneFailure, isNull, reason: doneFailure?.message);
    expect(done!.status, TripStatus.completed);
    expect(done.isPaid, isTrue);
  }, skip: _skip);

  test('the webhook endpoint needs no login but refuses anything not signed by Razorpay', () async {
    final base = _api!.endsWith('/') ? _api! : '$_api/';
    final forged = await plainDio.post<Map<String, dynamic>>('${base}webhooks/razorpay',
        data: '{"event":"qr_code.credited","payload":{"payment":{"entity":{"id":"pay_fake","amount":100}}}}',
        options: Options(headers: {'X-Razorpay-Signature': 'deadbeef', 'Content-Type': 'application/json'}));
    expect(forged.statusCode, 400);
    expect(forged.data!['error']['code'], 'INVALID_SIGNATURE');

    final unsigned = await plainDio.post<Map<String, dynamic>>('${base}webhooks/razorpay', data: {'event': 'qr_code.credited'});
    expect(unsigned.statusCode, 400);
    expect(unsigned.data!['error']['code'], 'INVALID_SIGNATURE');
  }, skip: _skip);
}
