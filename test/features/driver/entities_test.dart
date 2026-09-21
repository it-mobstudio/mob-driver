// JSON fixtures are literals on purpose; `const` adds nothing in a test.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';

import '../../support/fakes.dart';

void main() {
  group('Trip.fromJson (payload captured from the live backend)', () {
    test('parses the full trip, decimals-as-strings included', () {
      final trip = Trip.fromJson(tripJson());

      expect(trip.id, '604807b6-7053-4f5f-bf99-163eb9620dc3');
      expect(trip.status, TripStatus.assigned);
      expect(trip.pickup.address, 'MG Road Metro, Bengaluru');
      expect(trip.pickup.latitude, 12.9716);
      expect(trip.drop.longitude, 77.6408);
      expect(trip.drop.contactPhone, '+919888800002');
      expect(trip.totalFare, 111.62);
      expect(trip.distanceMeters, 6582);
      expect(trip.polylinePrecision, 6);
      expect(trip.vehicleTypeName, 'Bike');
      expect(trip.vehicleRegistration, 'KA01SEED0000');
      expect(trip.isCod, isTrue);
      expect(trip.isPaid, isFalse);
      expect(trip.assignedAt, isNotNull);
      expect(trip.completedAt, isNull);
    });

    test('a history row has no coordinates or polyline, and that is fine', () {
      final trip = Trip.fromJson({
        'id': 't-1',
        'status': 'completed',
        'pickup_address': 'A',
        'drop_address': 'B',
        'total_fare': '85.00',
        'currency': 'INR',
        'payment_mode': 'prepaid',
        'payment_status': 'paid',
        'distance_meters': 4200,
        'completed_at': '2026-09-20T10:00:00Z',
      });

      expect(trip.pickup.hasCoordinates, isFalse);
      expect(trip.routePolyline, isNull);
      expect(trip.status, TripStatus.completed);
      expect(trip.isCod, isFalse);
      expect(trip.isPaid, isTrue);
    });

    test('an empty cancelled_by / reason (how the backend sends "none") reads as null', () {
      final trip = Trip.fromJson(tripJson());
      expect(trip.cancelledBy, isNull);
      expect(trip.cancellationReason, isNull);
      expect(trip.cancelledByCompany, isFalse);
    });

    test('an unknown status does not crash', () {
      expect(TripStatus.parse('teleporting'), TripStatus.unknown);
      expect(TripStatus.parse(null), TripStatus.unknown);
    });

    test('numbers arrive either as strings or as JSON numbers', () {
      final asNumbers = Trip.fromJson({...tripJson(), 'pickup_lat': 12.9716, 'total_fare': 111.62});
      expect(asNumbers.pickup.latitude, 12.9716);
      expect(asNumbers.totalFare, 111.62);
    });
  });

  group('Trip stage helpers', () {
    test('COD in progress: collect payment, then delivery OTP', () {
      final unpaid = fakeTrip(status: 'in_progress');
      expect(unpaid.needsPaymentCollection, isTrue);
      expect(unpaid.needsDeliveryOtp, isFalse);

      final paid = fakeTrip(status: 'in_progress', paymentStatus: 'paid');
      expect(paid.needsPaymentCollection, isFalse);
      expect(paid.needsDeliveryOtp, isTrue);
    });

    test('prepaid needs neither', () {
      final trip = fakeTrip(status: 'in_progress', paymentMode: 'prepaid', paymentStatus: 'paid');
      expect(trip.needsPaymentCollection, isFalse);
      expect(trip.needsDeliveryOtp, isFalse);
    });

    test('cancellable only before the delivery starts (backend rule)', () {
      expect(fakeTrip(status: 'assigned').canCancel, isTrue);
      expect(fakeTrip(status: 'arrived_at_pickup').canCancel, isTrue);
      expect(fakeTrip(status: 'in_progress').canCancel, isFalse);
      expect(fakeTrip(status: 'completed').canCancel, isFalse);
    });

    test('isActive matches the backend\'s "active trip" statuses', () {
      expect(TripStatus.assigned.isActive, isTrue);
      expect(TripStatus.arrivedAtPickup.isActive, isTrue);
      expect(TripStatus.inProgress.isActive, isTrue);
      expect(TripStatus.requested.isActive, isFalse);
      expect(TripStatus.completed.isActive, isFalse);
    });

    test('equal trips compare equal, so an unchanged poll does not rebuild the UI', () {
      expect(fakeTrip(), fakeTrip());
      expect(fakeTrip(), isNot(fakeTrip(status: 'arrived_at_pickup')));
      expect(fakeTrip(), isNot(fakeTrip(paymentStatus: 'paid')));
    });
  });

  group('DriverProfile', () {
    test('parses an on-duty driver with their vehicle', () {
      final profile = fakeProfile(online: true);
      expect(profile.fullName, 'Seed Driver 1');
      expect(profile.isOnline, isTrue);
      expect(profile.isEligible, isTrue);
      expect(profile.currentVehicle?.registrationNumber, 'KA01SEED0000');
      expect(profile.currentVehicle?.categoryLabel, '2 wheeler');
      expect(profile.licenceExpiry, DateTime(2027, 9, 20));
      expect(profile.allowedCategories, ['two_wheeler']);
      expect(profile.blockers, isEmpty);
    });

    test('an ineligible driver explains what is blocking them', () {
      final profile = DriverProfile.fromJson({
        ...profileJson(eligible: false),
        'aadhar_status': 'rejected',
        'aadhar_rejection_note': 'Blurry scan',
        'police_status': 'pending',
      });
      expect(profile.isEligible, isFalse);
      expect(profile.blockers, contains('Aadhaar was rejected: Blurry scan'));
      expect(profile.blockers, contains('Police verification is pending.'));
    });

    test('a locked account is called out', () {
      final profile = DriverProfile.fromJson({...profileJson(), 'account_status': 'locked_dl_expired'});
      expect(profile.blockers.single, contains('licence expired'));
    });
  });

  test('DriverStats parses today and all-time', () {
    final stats = DriverStats.fromJson({
      'today': {'trips_completed': 2, 'trips_cancelled': 1, 'total_fare': '185.00', 'cod_collected': '85.00', 'distance_meters': 8400},
      'all_time': {'trips_completed': 9, 'trips_cancelled': 1, 'total_fare': '900.50', 'cod_collected': '400.00', 'distance_meters': 40000},
    });
    expect(stats.today.tripsCompleted, 2);
    expect(stats.today.totalFare, 185.0);
    expect(stats.allTime.totalFare, 900.5);
    expect(DriverStats.fromJson({}).today.tripsCompleted, 0);
  });

  test('PaymentQr accepts the amount as a JSON number (how the backend sends it)', () {
    final qr = PaymentQr.fromJson({
      'qr_payload': 'upi://pay?pa=mob-delivery%40upi&am=111.62&cu=INR',
      'amount': 111.62,
      'currency': 'INR',
    });
    expect(qr.amount, 111.62);
    expect(qr.payload, startsWith('upi://pay?'));
  });

  test('PaymentQr from Razorpay carries the hosted image, is verifiable, and knows when it lapses', () {
    final qr = PaymentQr.fromJson({
      'provider': 'razorpay',
      'reference': 'qr_Nx4a1',
      'image_url': 'https://rzp.io/qr/qr_Nx4a1.png',
      'qr_payload': null,
      'amount': '111.62',
      'currency': 'INR',
      'expires_at': '2026-09-21T10:15:00Z',
    });
    expect(qr.provider, 'razorpay');
    expect(qr.paymentIsVerified, isTrue);
    expect(qr.hasImage, isTrue);
    expect(qr.payload, isNull);
    expect(qr.reference, 'qr_Nx4a1');
    expect(qr.amount, 111.62);
    expect(qr.isExpiredAt(DateTime.utc(2026, 9, 21, 10, 14, 59)), isFalse);
    expect(qr.isExpiredAt(DateTime.utc(2026, 9, 21, 10, 15)), isTrue, reason: 'valid until, not including, the closing time');
  });

  test('a PaymentQr with no provider is the local stand-in: nothing verifies it and it never lapses', () {
    final qr = PaymentQr.fromJson({'qr_payload': 'upi://pay?pa=x', 'amount': 5, 'currency': 'INR'});
    expect(qr.provider, 'upi_static');
    expect(qr.paymentIsVerified, isFalse);
    expect(qr.hasImage, isFalse);
    expect(qr.isExpiredAt(DateTime.utc(2100)), isFalse);
    expect(PaymentQr.fromJson({'image_url': '', 'amount': 1}).hasImage, isFalse, reason: 'an empty URL is no image');
  });

  test('NavRoute decodes its polyline at the precision the backend states', () {
    final route = NavRoute.fromJson({
      'target': 'pickup',
      'target_lat': 12.9716,
      'target_lng': 77.5946,
      'polyline': 'ox|vWogs_sCw|Aoh\\ooB_sg@',
      'polyline_precision': 6,
      'distance_meters': 3739,
      'duration_seconds': 538,
    });
    expect(route.target, 'pickup');
    expect(route.points, hasLength(3));
    expect(route.points.first.latitude, closeTo(12.975, 1e-6));
    expect(route.distanceMeters, 3739);
  });

  test('DeliveryOtpSent exposes the debug OTP only when the backend sent one', () {
    expect(DeliveryOtpSent.fromJson({'message': 'ok', 'otp': '123456'}).debugOtp, '123456');
    expect(DeliveryOtpSent.fromJson({'message': 'ok'}).debugOtp, isNull);
  });
}
