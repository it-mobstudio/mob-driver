import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';

import '../../support/fakes.dart';
import '../../support/scripted_adapter.dart';

/// Runs the REAL datasource + repository against scripted responses and checks
/// what actually goes over the wire — the paths, methods, query strings and
/// bodies the Django backend (drivers/urls.py, trips/urls.py) expects.
void main() {
  late ScriptedAdapter http;
  late DriverRepositoryImpl repo;
  const id = '604807b6-7053-4f5f-bf99-163eb9620dc3';

  setUp(() {
    http = ScriptedAdapter();
    repo = DriverRepositoryImpl(
      DriverRemoteDatasource(scriptedDio(http)),
      // A driver in IST: 5 h 30 min east of UTC.
      now: () => DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).copyWith(isUtc: false),
    );
  });

  test('profile → GET driver/me', () async {
    http.on('GET', '/driver/me', profileJson(online: true));
    final (profile, failure) = await repo.profile();
    expect(failure, isNull);
    expect(profile?.currentVehicle?.registrationNumber, 'KA01SEED0000');
  });

  test('vehicles → GET driver/vehicles', () async {
    http.on('GET', '/driver/vehicles', {
      'vehicles': [
        {
          'id': 'v-1',
          'registration_number': 'KA01SEED0000',
          'capacity_kg': '20.00',
          'photo_url': null,
          'status': 'active',
          'vehicle_type': {'id': 't', 'name': 'Bike', 'category': 'two_wheeler', 'icon_image_url': null},
          'is_current': true,
        }
      ]
    });
    final (vehicles, _) = await repo.availableVehicles();
    expect(vehicles, hasLength(1));
    expect(vehicles!.single.isCurrent, isTrue);
    expect(vehicles.single.categoryLabel, '2 wheeler');
  });

  test('stats → GET driver/stats?utc_offset_minutes=<device offset>', () async {
    http.on('GET', '/driver/stats', {'today': <String, dynamic>{}, 'all_time': <String, dynamic>{}});
    await repo.stats();
    expect(http.lastRequest('GET', '/driver/stats').queryParameters.keys, ['utc_offset_minutes']);
    expect(http.lastRequest('GET', '/driver/stats').queryParameters['utc_offset_minutes'], isA<int>());
  });

  test('startDuty → POST driver/duty/start with the vehicle and a 6-decimal fix', () async {
    http.on('POST', '/driver/duty/start', profileJson(online: true));
    await repo.startDuty(vehicleId: 'v-1', latitude: 12.97160123456, longitude: 77.5946);

    final body = http.lastRequest('POST', '/driver/duty/start').data as Map;
    expect(body['vehicle_id'], 'v-1');
    // The backend column is a 6-decimal DecimalField: a longer float is a 400.
    expect(body['lat'], '12.971601');
    expect(body['lng'], '77.594600');
  });

  test('startDuty without a fix sends no coordinates at all (not nulls)', () async {
    http.on('POST', '/driver/duty/start', profileJson(online: true));
    await repo.startDuty(vehicleId: 'v-1');
    expect((http.lastRequest('POST', '/driver/duty/start').data as Map).keys, ['vehicle_id']);
  });

  test('endDuty → POST driver/duty/end', () async {
    http.on('POST', '/driver/duty/end', profileJson());
    final (profile, _) = await repo.endDuty();
    expect(profile?.isOnline, isFalse);
  });

  test('location ping → POST driver/location as fixed-point strings', () async {
    http.on('POST', '/driver/location', {'message': 'Location updated.'});
    final failure = await repo.sendLocation(latitude: 12.9716, longitude: 77.5946123456789);
    expect(failure, isNull);
    final body = http.lastRequest('POST', '/driver/location').data as Map;
    expect(body, {'lat': '12.971600', 'lng': '77.594612'});
  });

  test('a location ping failure is reported, not thrown', () async {
    http.on('POST', '/driver/location', {'success': false, 'error': {'code': 'X', 'message': 'nope'}}, status: 400);
    final failure = await repo.sendLocation(latitude: 1, longitude: 1);
    expect(failure?.message, 'nope');
  });

  group('trips', () {
    test('active with a trip / with none', () async {
      http.on('GET', '/driver/trips/active', {'trip': tripJson()});
      expect((await repo.activeTrip()).$1?.id, id);

      http.on('GET', '/driver/trips/active', {'trip': null});
      final (trip, failure) = await repo.activeTrip();
      expect(trip, isNull);
      expect(failure, isNull, reason: '"no trip" is an answer, not an error');
    });

    test('history → GET driver/trips?page=N&status=a,b, parsing the paginated envelope', () async {
      http.on('GET', '/driver/trips', {
        'count': 41,
        'next': 'http://test/api/v1/driver/trips?page=3',
        'previous': null,
        'results': [tripJson(status: 'completed', paymentStatus: 'paid')],
      });
      final (page, _) = await repo.trips(page: 2, statuses: [TripStatus.completed, TripStatus.cancelled]);

      final q = http.lastRequest('GET', '/driver/trips').queryParameters;
      expect(q['page'], 2);
      expect(q['status'], 'completed,cancelled');
      expect(page?.count, 41);
      expect(page?.hasNext, isTrue);
      expect(page?.items.single.status, TripStatus.completed);
    });

    test('history without a filter sends no status param; the last page has no next', () async {
      http.on('GET', '/driver/trips', {'count': 1, 'next': null, 'previous': null, 'results': <dynamic>[]});
      final (page, _) = await repo.trips();
      expect(http.lastRequest('GET', '/driver/trips').queryParameters.containsKey('status'), isFalse);
      expect(page?.hasNext, isFalse);
    });

    test('detail → GET driver/trips/{id}', () async {
      http.on('GET', '/driver/trips/$id', tripJson());
      expect((await repo.trip(id)).$1?.pickup.address, 'MG Road Metro, Bengaluru');
    });

    test('navigation → GET driver/trips/{id}/navigation?lat&lng, polyline decoded at the stated precision', () async {
      http.on('GET', '/driver/trips/$id/navigation', {
        'target': 'pickup',
        'target_lat': 12.9716,
        'target_lng': 77.5946,
        'polyline': 'ox|vWogs_sCw|Aoh\\ooB_sg@',
        'polyline_precision': 6,
        'distance_meters': 3739,
        'duration_seconds': 538,
      });
      final (route, _) = await repo.navigation(id, latitude: 12.95, longitude: 77.58);

      final q = http.lastRequest('GET', '/driver/trips/$id/navigation').queryParameters;
      expect(q, {'lat': '12.950000', 'lng': '77.580000'});
      expect(route?.points, hasLength(3));
      expect(route?.points.first.latitude, closeTo(12.975, 1e-6));
    });

    test('lifecycle: arrive, start → POST with an empty body', () async {
      http.on('POST', '/driver/trips/$id/arrive', tripJson(status: 'arrived_at_pickup'));
      http.on('POST', '/driver/trips/$id/start', tripJson(status: 'in_progress'));

      expect((await repo.arrive(id)).$1?.status, TripStatus.arrivedAtPickup);
      expect((await repo.start(id)).$1?.status, TripStatus.inProgress);
      expect(http.lastRequest('POST', '/driver/trips/$id/arrive').data, isEmpty);
    });

    test('payment QR → GET .../payment/qr', () async {
      http.on('GET', '/driver/trips/$id/payment/qr', {
        'qr_payload': 'upi://pay?pa=mob-delivery%40upi&pn=MOB+Delivery&am=111.62&cu=INR&tn=Trip+$id',
        'amount': 111.62,
        'currency': 'INR',
      });
      final (qr, _) = await repo.paymentQr(id);
      expect(qr?.payload, startsWith('upi://pay?'));
      expect(qr?.amount, 111.62);
    });

    test('payment QR from Razorpay → the hosted image, reference and closing time', () async {
      http.on('GET', '/driver/trips/$id/payment/qr', {
        'provider': 'razorpay',
        'reference': 'qr_Nx4a1',
        'qr_payload': null,
        'image_url': 'https://rzp.io/qr/qr_Nx4a1.png',
        'amount': '111.62',
        'currency': 'INR',
        'expires_at': '2026-09-21T10:15:00Z',
      });
      final (qr, failure) = await repo.paymentQr(id);
      expect(failure, isNull);
      expect(qr?.provider, 'razorpay');
      expect(qr?.imageUrl, 'https://rzp.io/qr/qr_Nx4a1.png');
      expect(qr?.reference, 'qr_Nx4a1');
      expect(qr?.amount, 111.62);
      expect(qr!.expiresAt!.isAtSameMomentAs(DateTime.utc(2026, 9, 21, 10, 15)), isTrue, reason: 'same instant; the app shows it in local time');
    });

    test('collect payment before the customer has paid → a typed, readable "not yet"', () async {
      http.on('POST', '/driver/trips/$id/payment/collect', {
        'success': false,
        'error': {'code': 'PAYMENT_NOT_RECEIVED', 'message': 'The customer\u2019s payment hasn\u2019t arrived yet.'},
      }, status: 409);
      final (sent, failure) = await repo.collectPayment(id);
      expect(sent, isNull);
      expect(failure?.code, 'PAYMENT_NOT_RECEIVED');
      expect(failure, isA<BusinessFailure>());
      expect(failure?.message, contains('hasn\u2019t arrived'));
    });

    test('payment provider outages (503) come back as a failure with the server\u2019s words', () async {
      http.on('GET', '/driver/trips/$id/payment/qr', {
        'success': false,
        'error': {'code': 'PAYMENT_PROVIDER_UNAVAILABLE', 'message': 'Couldn\u2019t reach the payment provider. Please try again in a moment.'},
      }, status: 503);
      final (qr, failure) = await repo.paymentQr(id);
      expect(qr, isNull);
      expect(failure?.code, 'PAYMENT_PROVIDER_UNAVAILABLE');
      expect(failure?.message, contains('payment provider'));
    });

    test('collect payment → POST .../payment/collect, surfacing the test-mode OTP if echoed', () async {
      http.on('POST', '/driver/trips/$id/payment/collect', {
        'message': 'Payment collected. An OTP was sent to +919888800002 to finalize the trip.',
        'otp': '3874',
      });
      final (sent, _) = await repo.collectPayment(id);
      expect(sent?.debugOtp, '3874');
      expect(sent?.message, contains('+919888800002'));
    });

    test('resend OTP → POST .../delivery-otp/resend', () async {
      http.on('POST', '/driver/trips/$id/delivery-otp/resend', {'message': 'A new OTP was sent.'});
      final (sent, _) = await repo.resendDeliveryOtp(id);
      expect(sent?.debugOtp, isNull, reason: 'production never echoes it');
    });

    test('complete → POST .../complete {otp}; prepaid sends no otp key', () async {
      http.on('POST', '/driver/trips/$id/complete', tripJson(status: 'completed', paymentStatus: 'paid'));

      await repo.complete(id, otp: '1234');
      expect(http.lastRequest('POST', '/driver/trips/$id/complete').data, {'otp': '1234'});

      await repo.complete(id);
      expect(http.lastRequest('POST', '/driver/trips/$id/complete').data, isEmpty);
    });

    test('cancel → POST .../cancel {reason}', () async {
      http.on('POST', '/driver/trips/$id/cancel', tripJson(status: 'cancelled', cancelledBy: 'driver', cancellationReason: 'Vehicle breakdown'));
      final (trip, _) = await repo.cancel(id, reason: 'Vehicle breakdown');
      expect(http.lastRequest('POST', '/driver/trips/$id/cancel').data, {'reason': 'Vehicle breakdown'});
      expect(trip?.cancellationReason, 'Vehicle breakdown');
    });
  });

  CapturedPhoto photo(String name, [int size = 4]) =>
      CapturedPhoto(bytes: Uint8List.fromList(List.filled(size, 7)), filename: name);

  /// The multipart body the request would send, as (fields, {name: file}).
  (Map<String, String>, Map<String, MultipartFile>) form(RequestOptions request) {
    final data = request.data as FormData;
    return (
      {for (final f in data.fields) f.key: f.value},
      {for (final f in data.files) f.key: f.value},
    );
  }

  group('onboarding', () {
    test('updateProfile → PATCH driver/me with only the fields that were set', () async {
      http.on('PATCH', '/driver/me', profileJson(eligible: false));
      final (profile, failure) = await repo.updateProfile(ProfileUpdate(
        fullName: 'Ravi Kumar',
        dateOfBirth: DateTime(1994, 3, 12),
        emergencyContactPhone: '+919555500002',
      ));

      expect(failure, isNull);
      expect(profile, isNotNull);
      expect(http.lastRequest('PATCH', '/driver/me').data, {
        'full_name': 'Ravi Kumar',
        'date_of_birth': '1994-03-12',
        'emergency_contact_phone': '+919555500002',
      });
    });

    test('a validation error surfaces the field message, not the generic one', () async {
      http.on('PATCH', '/driver/me', {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Request could not be processed.',
          'details': {'date_of_birth': ['You must be at least 18 years old.']},
        },
      }, status: 400);

      final (profile, failure) = await repo.updateProfile(ProfileUpdate(dateOfBirth: DateTime(2015, 1, 1)));

      expect(profile, isNull);
      expect(failure?.message, 'You must be at least 18 years old.');
    });

    test('a locked name comes back with its code so the screen can explain it', () async {
      http.on('PATCH', '/driver/me', {
        'success': false,
        'error': {'code': 'PROFILE_LOCKED', 'message': 'Your name and date of birth can\'t be changed after your ID is verified.'},
      }, status: 409);
      final (_, failure) = await repo.updateProfile(const ProfileUpdate(fullName: 'Someone Else'));
      expect(failure?.code, 'PROFILE_LOCKED');
    });

    test('submitAadhar → multipart POST driver/me/kyc/aadhar: number, front, back', () async {
      http.on('POST', '/driver/me/kyc/aadhar', profileJson(eligible: false));
      final (profile, failure) = await repo.submitAadhar(
        number: '234567890123',
        front: photo('front.jpg'),
        back: photo('back.png'),
      );

      expect(failure, isNull);
      expect(profile, isNotNull);
      final (fields, files) = form(http.lastRequest('POST', '/driver/me/kyc/aadhar'));
      expect(fields, {'number': '234567890123'});
      expect(files.keys, unorderedEquals(['front', 'back']));
      expect(files['front']!.filename, 'front.jpg');
      expect(files['front']!.contentType?.mimeType, 'image/jpeg');
      expect(files['back']!.contentType?.mimeType, 'image/png');
      expect(files['front']!.length, 4);
    });

    test('submitLicence → multipart with the number, expiry (ISO) and front; back only when taken', () async {
      http.on('POST', '/driver/me/kyc/dl', profileJson(eligible: false));

      await repo.submitLicence(number: 'KA01 20110012345', expiry: DateTime(2027, 3, 1), front: photo('dl.jpg'));
      var (fields, files) = form(http.lastRequest('POST', '/driver/me/kyc/dl'));
      expect(fields, {'number': 'KA01 20110012345', 'expiry_date': '2027-03-01'});
      expect(files.keys, ['front']);

      await repo.submitLicence(number: 'KA01 20110012345', expiry: DateTime(2027, 3, 1), front: photo('dl.jpg'), back: photo('dl2.jpg'));
      (fields, files) = form(http.lastRequest('POST', '/driver/me/kyc/dl'));
      expect(files.keys, unorderedEquals(['front', 'back']));
    });

    test('submitPolice → the file goes under "document"; the photo under "photo"', () async {
      http.on('POST', '/driver/me/kyc/police', profileJson(eligible: false));
      http.on('POST', '/driver/me/photo', profileJson(eligible: false));

      await repo.submitPolice(photo('pcc.jpg'));
      await repo.uploadPhoto(photo('me.jpg'));

      expect(form(http.lastRequest('POST', '/driver/me/kyc/police')).$2.keys, ['document']);
      expect(form(http.lastRequest('POST', '/driver/me/photo')).$2.keys, ['photo']);
    });

    test('a rejected upload says why', () async {
      http.on('POST', '/driver/me/kyc/aadhar', {
        'success': false,
        'error': {'code': 'INVALID_UPLOAD', 'message': 'File is not a valid image.'},
      }, status: 400);
      final (_, failure) = await repo.submitAadhar(number: '234567890123', front: photo('f.jpg'), back: photo('b.jpg'));
      expect((failure?.code, failure?.message), ('INVALID_UPLOAD', 'File is not a valid image.'));
    });

    test('deleteAccount → DELETE driver/me; a refusal carries the reason', () async {
      http.on('DELETE', '/driver/me', '', status: 204);
      expect(await repo.deleteAccount(), isNull);
      expect(http.requests.last.method, 'DELETE');

      http.on('DELETE', '/driver/me', {
        'success': false,
        'error': {'code': 'WALLET_BALANCE_PENDING', 'message': 'You still have ₹150.00 in your wallet.'},
      }, status: 409);
      final failure = await repo.deleteAccount();
      expect(failure?.code, 'WALLET_BALANCE_PENDING');
    });
  });

  group('wallet', () {
    test('wallet → GET driver/wallet?utc_offset_minutes=<device offset>', () async {
      http.on('GET', '/driver/wallet', {
        'balance': '260.00',
        'currency': 'INR',
        'today': {'earnings': '150.00', 'trips': 1},
        'week': {'earnings': '275.00', 'trips': 4},
        'month': {'earnings': '295.00', 'trips': 5},
        'lifetime': {'earnings': '305.00', 'trips': 6, 'payouts': '40.00'},
        'last_7_days': [
          {'date': '2026-09-23', 'earnings': '150.00', 'trips': 1}
        ],
      });

      final (summary, failure) = await repo.wallet();

      expect(failure, isNull);
      expect(summary?.balance, 260);
      expect(summary?.lifetimePayouts, 40);
      expect(http.lastRequest('GET', '/driver/wallet').queryParameters.keys, ['utc_offset_minutes']);
      expect(http.lastRequest('GET', '/driver/wallet').queryParameters['utc_offset_minutes'], isA<int>());
    });

    test('statement → GET driver/wallet/transactions with page and comma-separated kinds', () async {
      http.on('GET', '/driver/wallet/transactions', {
        'count': 3,
        'next': 'http://x/api/v1/driver/wallet/transactions?page=2',
        'previous': null,
        'results': [
          {'id': 'w1', 'kind': 'payout', 'amount': '-40.00', 'balance_after': '60.00', 'reference': 'UTR1', 'created_at': '2026-09-23T08:00:00Z'},
        ],
      });

      final (page, failure) = await repo.walletEntries(page: 2, kinds: [WalletKind.payout, WalletKind.bonus]);

      expect(failure, isNull);
      expect((page?.count, page?.hasNext), (3, true));
      expect(page?.items.single.kind, WalletKind.payout);
      final query = http.lastRequest('GET', '/driver/wallet/transactions').queryParameters;
      expect(query, {'page': 2, 'kind': 'payout,bonus'});
    });

    test('no kind filter → no kind parameter', () async {
      http.on('GET', '/driver/wallet/transactions', {'count': 0, 'next': null, 'results': <dynamic>[]});
      await repo.walletEntries();
      expect(http.lastRequest('GET', '/driver/wallet/transactions').queryParameters.containsKey('kind'), isFalse);
    });
  });

  group('item verification', () {
    const itemId = 'i-1';

    test('verifyItem → multipart POST .../items/{id}/verify with status, note and the photo', () async {
      http.on('POST', '/driver/trips/$id/items/$itemId/verify',
          tripJson(status: 'in_progress', verifyItems: true, items: [itemJson(status: 'not_delivered', note: 'Damaged')]));

      final (trip, failure) = await repo.verifyItem(id, itemId,
          status: ItemStatus.notDelivered, note: 'Damaged', photo: photo('proof.jpg'));

      expect(failure, isNull);
      expect(trip?.items.single.status, ItemStatus.notDelivered);
      final (fields, files) = form(http.lastRequest('POST', '/driver/trips/$id/items/$itemId/verify'));
      expect(fields, {'status': 'not_delivered', 'note': 'Damaged'});
      expect(files.keys, ['photo']);
      expect(files['photo']!.contentType?.mimeType, 'image/jpeg');
    });

    test('a plain "delivered" sends just the status — no note, no photo', () async {
      http.on('POST', '/driver/trips/$id/items/$itemId/verify', tripJson(status: 'in_progress', verifyItems: true, items: [itemJson(status: 'delivered')]));
      await repo.verifyItem(id, itemId, status: ItemStatus.delivered);
      final (fields, files) = form(http.lastRequest('POST', '/driver/trips/$id/items/$itemId/verify'));
      expect(fields, {'status': 'delivered'});
      expect(files, isEmpty);
    });

    test('addTripPhoto → multipart POST .../pickup-photo or .../delivery-photo, item_id only per item', () async {
      http.on('POST', '/driver/trips/$id/pickup-photo',
          {...tripJson(pickupPhoto: 'order'), 'pickup_photo_url': 'https://cdn.example.com/p.jpg'});
      final (trip, failure) = await repo.addTripPhoto(id, stage: PhotoStage.pickup, photo: photo('p.jpg'));
      expect(failure, isNull);
      expect(trip?.hasPhotos(PhotoStage.pickup), isTrue);
      var (fields, files) = form(http.lastRequest('POST', '/driver/trips/$id/pickup-photo'));
      expect(fields, isEmpty);
      expect(files.keys, ['photo']);

      http.on('POST', '/driver/trips/$id/delivery-photo',
          tripJson(status: 'in_progress', deliveryPhoto: 'per_item', items: [itemJson()]));
      await repo.addTripPhoto(id, stage: PhotoStage.delivery, photo: photo('d.jpg'), itemId: itemId);
      (fields, files) = form(http.lastRequest('POST', '/driver/trips/$id/delivery-photo'));
      expect(fields, {'item_id': itemId});
      expect(files.keys, ['photo']);
    });

    test('resetItem → DELETE .../items/{id}/verify', () async {
      http.on('DELETE', '/driver/trips/$id/items/$itemId/verify', tripJson(status: 'in_progress', verifyItems: true, items: [itemJson()]));
      final (trip, failure) = await repo.resetItem(id, itemId);
      expect(failure, isNull);
      expect(trip?.items.single.status, ItemStatus.pending);
      expect(http.requests.last.method, 'DELETE');
    });

    test('collecting payment or completing before verifying is refused with a code the screen can act on', () async {
      final refusal = {
        'success': false,
        'error': {'code': 'ITEMS_NOT_VERIFIED', 'message': 'Verify every item on this order before continuing.'},
      };
      http.on('POST', '/driver/trips/$id/payment/collect', refusal, status: 409);
      http.on('POST', '/driver/trips/$id/complete', refusal, status: 409);

      final (_, collect) = await repo.collectPayment(id);
      final (_, complete) = await repo.complete(id);

      expect(collect?.code, 'ITEMS_NOT_VERIFIED');
      expect(complete?.code, 'ITEMS_NOT_VERIFIED');
    });

    test('a completed trip carries what it paid the driver', () async {
      http.on('POST', '/driver/trips/$id/complete', tripJson(status: 'completed', paymentStatus: 'paid', driverEarning: '89.30'));
      final (trip, _) = await repo.complete(id);
      expect(trip?.driverEarning, 89.3);
    });
  });

  group('errors carry the backend\'s message and code through the repository', () {
    test('wrong delivery OTP', () async {
      http.on('POST', '/driver/trips/$id/complete', {
        'success': false,
        'error': {'code': 'INVALID_DELIVERY_OTP', 'message': 'The delivery OTP is invalid or has expired.'},
      }, status: 400);
      final (trip, failure) = await repo.complete(id, otp: '0000');
      expect(trip, isNull);
      expect(failure?.code, 'INVALID_DELIVERY_OTP');
      expect(failure?.message, 'The delivery OTP is invalid or has expired.');
    });

    test('an unreachable server is a network failure', () async {
      // No route scripted for this path and the adapter returns 404 with a plain body.
      final (_, failure) = await repo.profile();
      expect(failure, isNotNull);
    });
  });
}
