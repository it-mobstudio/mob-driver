// The new driver journey, driven through the app's REAL data layer against a
// REAL running backend: sign-up → onboarding (real multipart photo uploads) →
// the company's review → an order with an invoice and items → verifying them
// with photos → getting paid → a payout → deleting the account.
//
// It proves what unit tests can't: that the multipart bodies, field names and
// JSON the Flutter code sends and parses are what Django actually accepts and
// returns — including absolute media URLs that resolve, and error codes the
// screens branch on.
//
// Skipped by default. To run, start a backend on a THROWAWAY database with
// DEBUG=True, DRIVER_SIGNUP_COMPANY_ID=<company id> and Valhalla (or
// scripts/dev_valhalla_stub.py) up, one company with an API client and an admin
// (manage.py bootstrap_company / create_api_client), and a vehicle for drivers
// to take (manage.py seed_drivers --offline), then:
//
//   LIVE_API=http://127.0.0.1:8011/api/v1/ \
//   LIVE_CLIENT_ID=... LIVE_CLIENT_SECRET=... \
//   LIVE_ADMIN_EMAIL=... LIVE_ADMIN_PASSWORD=... \
//   flutter test test/live/live_onboarding_test.dart
//
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';

import '../support/fakes.dart' show kTinyPng;

final _env = Platform.environment;
final _api = _env['LIVE_API'];
final _skip = _api == null || _env['LIVE_ADMIN_EMAIL'] == null
    ? 'set LIVE_API, LIVE_CLIENT_*, LIVE_ADMIN_* (see the header of this file) to run against a live backend'
    : null;

const _pickup = (lat: 12.9716, lng: 77.5946);
const _drop = (lat: 12.9784, lng: 77.6408);

CapturedPhoto _png(String name) => CapturedPhoto(bytes: kTinyPng, filename: name);

String _codeOf(DioException e) => ((e.response?.data as Map?)?['error'] as Map?)?['code']?.toString() ?? '';

void main() {
  late Dio driverDio;
  late Dio companyDio;
  late Dio adminDio;
  late Dio publicDio; // no credentials: what a phone's browser/share sheet would fetch with
  late DriverRepositoryImpl repo;
  late AuthRemoteDatasourceImpl auth;

  final phone = _env['LIVE_NEW_PHONE'] ?? '+919555512345';

  Future<DriverRepositoryImpl> signIn() async {
    final otp = (await auth.requestOtp(phoneNumber: phone))['otp'] as String?;
    expect(otp, isNotNull, reason: 'backend must run with DRIVER_OTP_DEBUG_RESPONSE=True for this test');
    final session = await auth.verifyOtp(phoneNumber: phone, otp: otp!);
    driverDio.options.headers['Authorization'] = 'Bearer ${session['accessToken']}';
    return DriverRepositoryImpl(DriverRemoteDatasource(driverDio));
  }

  setUpAll(() async {
    if (_api == null) return;
    Dio make() => Dio(BaseOptions(baseUrl: _api!, connectTimeout: const Duration(seconds: 10)));
    driverDio = make();
    companyDio = make();
    adminDio = make();
    publicDio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), responseType: ResponseType.bytes));
    auth = AuthRemoteDatasourceImpl(driverDio);

    final client = await companyDio.post<Map<String, dynamic>>('/auth/client-token',
        data: {'client_id': _env['LIVE_CLIENT_ID'], 'client_secret': _env['LIVE_CLIENT_SECRET']});
    companyDio.options.headers['Authorization'] = 'Bearer ${client.data!['access']}';

    final admin = await adminDio
        .post<Map<String, dynamic>>('/auth/login', data: {'email': _env['LIVE_ADMIN_EMAIL'], 'password': _env['LIVE_ADMIN_PASSWORD']});
    adminDio.options.headers['Authorization'] = 'Bearer ${admin.data!['access']}';
  });

  test('a new driver, from first login to the wallet and back out', () async {
    // ── 1. First login creates the account, empty ──────────────────────────
    repo = await signIn();
    var (profile, failure) = await repo.profile();
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.onboardingStatus, OnboardingStatus.profileIncomplete);
    expect(profile.onboardingStatus.needsSetup, isTrue);
    expect(profile.fullName, isEmpty);
    expect(profile.isEligible, isFalse);
    final driverId = profile.id;
    print('signed up $phone as $driverId → ${profile.onboardingStatus.wire}');

    // ── 2. Details: the server's validation reaches the screen as words ─────
    var (_, refused) = await repo.updateProfile(ProfileUpdate(dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 10))));
    expect(refused?.message, contains('18'), reason: 'under-age is explained, not "400"');
    (_, refused) = await repo.updateProfile(ProfileUpdate(emergencyContactPhone: phone));
    expect(refused?.message, contains('someone else'), reason: 'your own number is not an emergency contact');

    (profile, failure) = await repo.updateProfile(ProfileUpdate(
      fullName: 'Ravi Kumar',
      dateOfBirth: DateTime(1994, 3, 12),
      email: 'ravi@example.com',
      city: 'Bengaluru',
      pincode: '560001',
      emergencyContactName: 'Sunita Kumar',
      emergencyContactPhone: '+919555500002',
    ));
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.isProfileComplete, isTrue);
    expect(profile.onboardingStatus, OnboardingStatus.documentsRequired);
    expect(profile.onboardingStatus.needsSetup, isTrue, reason: 'still has documents to give');

    // ── 3. Documents: real multipart uploads ────────────────────────────────
    final (_, notAnImage) = await repo.submitAadhar(
      number: '234567890123',
      front: CapturedPhoto(bytes: Uint8List.fromList(utf8.encode('definitely not a jpeg')), filename: 'front.jpg'),
      back: _png('back.png'),
    );
    expect(notAnImage?.code, 'INVALID_UPLOAD');

    (profile, failure) = await repo.uploadPhoto(_png('me.png'));
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.photoUrl, startsWith('http'));

    (profile, failure) = await repo.submitAadhar(number: '234567890123', front: _png('front.png'), back: _png('back.png'));
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.aadhar.submitted, isTrue);
    expect(profile.aadhar.reference, '•••• 0123', reason: 'only the last four digits are kept');
    expect(profile.onboardingStatus, OnboardingStatus.documentsRequired, reason: 'no licence yet');

    // The scan URLs the server hands back are absolute and actually load.
    final scan = await publicDio.get<List<int>>(profile.aadhar.frontUrl!);
    expect(scan.statusCode, 200);
    expect(scan.headers.value('content-type'), startsWith('image/'));
    print('aadhaar front served from ${profile.aadhar.frontUrl}');

    (_, refused) = await repo.submitLicence(number: 'KA01 20110012345', expiry: DateTime.now().subtract(const Duration(days: 3)), front: _png('dl.png'));
    expect(refused?.message, contains('expired'));

    (profile, failure) = await repo.submitLicence(
      number: 'ka01 20110012345',
      expiry: DateTime.now().add(const Duration(days: 400)),
      front: _png('dl.png'),
      back: _png('dl-back.png'),
    );
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.drivingLicence.reference, 'KA01 20110012345');
    expect(profile.onboardingStatus, OnboardingStatus.underReview);
    expect(profile.onboardingStatus.needsSetup, isFalse, reason: 'now it is the company\'s turn');

    // ── 4. Payout details ──────────────────────────────────────────────────
    (profile, failure) = await repo.updateProfile(const ProfileUpdate(payoutUpiId: 'ravi@okhdfc'));
    expect(profile!.payout.summary, 'ravi@okhdfc');
    (_, refused) = await repo.updateProfile(const ProfileUpdate(bankAccountNumber: '123456789012'));
    expect(refused, isNotNull, reason: 'a bank account only counts as a whole');

    // ── 5. Not approved yet: nothing to drive, and cannot go on duty ────────
    final (noVehicles, _) = await repo.availableVehicles();
    expect(noVehicles, isEmpty, reason: 'no verified licence category yet, so no vehicle can be matched to them');
    final fleet = await adminDio.get<Map<String, dynamic>>('/vehicles', queryParameters: {'page_size': 100});
    final freeVehicle = (fleet.data!['results'] as List).cast<Map<String, dynamic>>().firstWhere((v) => v['registration_number'] == 'KA01FREE0001');
    final (_, tooSoon) = await repo.startDuty(vehicleId: freeVehicle['id'] as String, latitude: _pickup.lat, longitude: _pickup.lng);
    expect(tooSoon?.code, 'DRIVER_NOT_ELIGIBLE');

    // ── 6. The company reviews: reject one, the driver fixes it, approve ────
    await adminDio.patch<dynamic>('/drivers/$driverId/kyc/aadhar', data: {'status': 'rejected', 'note': 'The photo is blurry'});
    (profile, _) = await repo.profile();
    expect(profile!.onboardingStatus, OnboardingStatus.actionRequired);
    expect(profile.aadhar.status, KycStatus.rejected);
    expect(profile.aadhar.rejectionNote, 'The photo is blurry');
    expect(profile.rejectedDocuments.single.$1, 'Aadhaar');
    expect(profile.aadhar.needsUpload, isTrue);

    (profile, failure) = await repo.submitAadhar(number: '234567890123', front: _png('front2.png'), back: _png('back2.png'));
    expect(failure, isNull, reason: failure?.message);
    expect(profile!.aadhar.status, KycStatus.pending, reason: 're-submitting puts it back in review');
    expect(profile.aadhar.rejectionNote, isNull);
    expect(profile.onboardingStatus, OnboardingStatus.underReview);

    await adminDio.patch<dynamic>('/drivers/$driverId/kyc/aadhar', data: {'status': 'verified'});
    await adminDio.patch<dynamic>('/drivers/$driverId/kyc/police', data: {'status': 'verified'});
    final expiry = DateTime.now().add(const Duration(days: 400));
    await adminDio.patch<dynamic>('/drivers/$driverId/kyc/dl', data: {
      'status': 'verified',
      'expiry_date': '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}',
      'allowed_categories': ['two_wheeler'],
    });
    (profile, _) = await repo.profile();
    expect(profile!.onboardingStatus, OnboardingStatus.approved);
    expect(profile.isEligible, isTrue);
    expect(profile.identityLocked, isTrue);
    (_, refused) = await repo.updateProfile(const ProfileUpdate(fullName: 'Someone Else'));
    expect(refused?.code, 'PROFILE_LOCKED', reason: 'the name matches the verified ID now');
    print('approved by the company → ${profile.onboardingStatus.wire}');

    // ── 7. On duty; the company books an order with an invoice and items ────
    final choices = (await repo.availableVehicles()).$1!;
    expect(choices, isNotEmpty, reason: 'approval unlocked the vehicles this licence covers');
    final vehicle = choices.firstWhere((v) => v.registrationNumber == 'KA01FREE0001');
    final (onDuty, dutyFailure) = await repo.startDuty(vehicleId: vehicle.id, latitude: _pickup.lat, longitude: _pickup.lng);
    expect(dutyFailure, isNull, reason: dutyFailure?.message);
    expect(onDuty!.isOnline, isTrue);

    final upload = await companyDio.post<Map<String, dynamic>>('/uploads',
        data: FormData.fromMap({
          'purpose': 'trip_invoice',
          'file': MultipartFile.fromBytes(utf8.encode('%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF'), filename: 'INV-LIVE-1.pdf'),
        }));
    final invoiceUrl = upload.data!['url'] as String;
    expect(invoiceUrl, startsWith('http'), reason: 'an uploaded invoice comes back absolute, usable as invoice_url as-is');

    final estimate = await companyDio.post<Map<String, dynamic>>('/trips/estimate', data: {
      'pickup': {'address': 'p', 'lat': _pickup.lat, 'lng': _pickup.lng},
      'drop': {'address': 'd', 'lat': _drop.lat, 'lng': _drop.lng},
    });
    final vehicleTypeId = ((estimate.data!['estimates'] as List).first as Map)['vehicle_type_id'];

    final booking = await companyDio.post<Map<String, dynamic>>('/trips', data: {
      'vehicle_type_id': vehicleTypeId,
      'payment_mode': 'cod',
      'reference_id': 'FLUTTER-LIVE-${DateTime.now().millisecondsSinceEpoch}',
      'invoice_url': invoiceUrl,
      'invoice_number': 'INV-LIVE-1',
      'verify_items': true,
      'items': [
        {'name': 'Cement bag 50 kg', 'quantity': 4, 'unit': 'bags', 'sku': 'CEM-50', 'unit_price': '380.00'},
        {'name': 'TMT bar 12 mm', 'quantity': 20, 'unit': 'pcs', 'notes': 'Fe500D'},
      ],
      'pickup': {'address': 'MG Road Metro, Bengaluru', 'lat': _pickup.lat, 'lng': _pickup.lng, 'contact_name': 'Shop', 'contact_phone': '+919888800001'},
      'drop': {'address': 'Indiranagar 100ft Rd, Bengaluru', 'lat': _drop.lat, 'lng': _drop.lng, 'contact_name': 'Asha', 'contact_phone': '+919888800002'},
    });
    expect(booking.data!['status'], 'assigned', reason: 'the only online driver should have been matched');
    final tripId = booking.data!['id'] as String;

    final (active, _) = await repo.activeTrip();
    expect(active!.id, tripId);
    expect(active.verifyItems, isTrue);
    expect(active.invoiceNumber, 'INV-LIVE-1');
    expect(active.invoiceUrl, invoiceUrl);
    expect(active.items.map((i) => i.name), ['Cement bag 50 kg', 'TMT bar 12 mm']);
    expect(active.items.first.quantityLabel, '4 bags');
    expect(active.items.first.unitPrice, 380);
    expect(active.driverEarning, isNull, reason: 'nothing is earned until it is delivered');

    // What the phone's Download / Share buttons would fetch.
    final invoice = await publicDio.get<List<int>>(active.invoiceUrl!);
    expect(invoice.statusCode, 200);
    expect(String.fromCharCodes(invoice.data!.take(5)), '%PDF-');
    print('invoice served: ${invoice.data!.length} bytes from ${active.invoiceUrl}');

    // ── 8. At the drop: payment and completion wait for the items ──────────
    expect((await repo.arrive(tripId)).$1?.status, TripStatus.arrivedAtPickup);
    final (started, _) = await repo.start(tripId);
    expect(started!.needsItemVerification, isTrue);

    expect((await repo.collectPayment(tripId)).$2?.code, 'ITEMS_NOT_VERIFIED', reason: 'no money is taken before the items are checked');
    expect((await repo.complete(tripId, otp: '1234')).$2?.code, 'ITEMS_NOT_VERIFIED');

    final first = started.items.first;
    final second = started.items.last;

    var (trip, itemFailure) = await repo.verifyItem(tripId, first.id, status: ItemStatus.delivered, photo: _png('proof.png'));
    expect(itemFailure, isNull, reason: itemFailure?.message);
    expect(trip!.items.first.status, ItemStatus.delivered);
    expect(trip.items.first.verifiedAt, isNotNull);
    expect(trip.resolvedItemCount, 1);
    expect(trip.needsItemVerification, isTrue, reason: 'one item still to go');
    final proof = await publicDio.get<List<int>>(trip.items.first.proofImageUrl!);
    expect(proof.statusCode, 200, reason: 'the proof photo is served at the absolute URL the app was given');
    expect(proof.headers.value('content-type'), startsWith('image/'));

    // "Not delivered" needs a reason…
    (_, itemFailure) = await repo.verifyItem(tripId, second.id, status: ItemStatus.notDelivered);
    expect(itemFailure?.message, contains('what happened'));
    // …and a mis-tap can be undone.
    (trip, _) = await repo.verifyItem(tripId, second.id, status: ItemStatus.delivered);
    expect(trip!.resolvedItemCount, 2);
    (trip, _) = await repo.resetItem(tripId, second.id);
    expect(trip!.items.last.status, ItemStatus.pending);
    expect((await repo.collectPayment(tripId)).$2?.code, 'ITEMS_NOT_VERIFIED', reason: 'taking an answer back re-blocks payment');

    (trip, itemFailure) = await repo.verifyItem(tripId, second.id, status: ItemStatus.notDelivered, note: 'Damaged in transit', photo: _png('damage.png'));
    expect(itemFailure, isNull, reason: itemFailure?.message);
    expect(trip!.needsItemVerification, isFalse, reason: '"not delivered" is an answer — it unblocks the trip');
    expect(trip.items.last.driverNote, 'Damaged in transit');

    // ── 9. Payment, OTP, completion — and the driver is paid ───────────────
    final (sent, _) = await repo.collectPayment(tripId);
    expect(sent!.debugOtp, isNotNull);
    final (done, doneFailure) = await repo.complete(tripId, otp: sent.debugOtp);
    expect(doneFailure, isNull, reason: doneFailure?.message);
    expect(done!.status, TripStatus.completed);
    final fare = done.totalFare!;
    final earning = done.driverEarning!;
    expect(earning, closeTo(fare * 0.8, 0.011), reason: 'DRIVER_EARNING_PERCENT defaults to 80');
    print('fare ₹$fare → driver earned ₹$earning');

    // ── 10. The company keeps the delivery history ─────────────────────────
    final company = await companyDio.get<Map<String, dynamic>>('/trips/$tripId');
    final items = (company.data!['items'] as List).cast<Map<String, dynamic>>();
    expect(items.map((i) => i['status']), ['delivered', 'not_delivered']);
    expect(items.first['proof_image_url'], startsWith('http'));
    expect(items.last['driver_note'], 'Damaged in transit');
    expect(company.data!.containsKey('driver_earning'), isFalse, reason: 'what a driver earns is not the company-facing trip\'s business');

    // ── 11. The wallet ─────────────────────────────────────────────────────
    var (wallet, _) = await repo.wallet();
    expect(wallet!.balance, closeTo(earning, 0.001));
    expect(wallet.today.earnings, closeTo(earning, 0.001));
    expect(wallet.today.trips, 1);
    expect(wallet.lifetime.trips, 1);
    expect(wallet.last7Days, hasLength(7));
    expect(wallet.last7Days.last.earnings, closeTo(earning, 0.001), reason: 'today is the last bar');
    expect(wallet.last7Days.first.earnings, 0);

    var (page, _) = await repo.walletEntries();
    expect(page!.count, 1);
    final row = page.items.single;
    expect((row.kind, row.isCredit), (WalletKind.tripEarning, true));
    expect(row.amount, closeTo(earning, 0.001));
    expect(row.description, startsWith('Delivery to'));

    final (stats, _) = await repo.stats();
    expect(stats!.today.earnings, closeTo(earning, 0.001));
    expect((await repo.trips(statuses: [TripStatus.completed])).$1!.items.first.driverEarning, closeTo(earning, 0.001));

    // ── 12. The company pays part of it out; the statement shows it ────────
    String? overpay;
    try {
      await adminDio.post<dynamic>('/drivers/$driverId/wallet/transactions',
          data: {'kind': 'payout', 'amount': (earning + 1).toStringAsFixed(2)});
    } on DioException catch (e) {
      overpay = _codeOf(e);
    }
    expect(overpay, 'INSUFFICIENT_BALANCE', reason: 'you cannot pay out more than is owed');

    await adminDio.post<dynamic>('/drivers/$driverId/wallet/transactions',
        data: {'kind': 'payout', 'amount': '20.00', 'reference': 'UTR-LIVE-1', 'description': 'Weekly payout'});
    (wallet, _) = await repo.wallet();
    expect(wallet!.balance, closeTo(earning - 20, 0.001));
    expect(wallet.lifetimePayouts, 20);

    (page, _) = await repo.walletEntries(kinds: [WalletKind.payout]);
    final payout = page!.items.single;
    expect((payout.kind, payout.isCredit, payout.amount, payout.reference), (WalletKind.payout, false, -20.0, 'UTR-LIVE-1'));
    expect((await repo.walletEntries()).$1!.count, 2, reason: 'the earning and the payout, newest first');
    expect((await repo.walletEntries()).$1!.items.first.kind, WalletKind.payout);

    // ── 13. Leaving: money owed blocks deletion until it is paid out ───────
    await repo.endDuty();
    final blocked = await repo.deleteAccount();
    expect(blocked?.code, 'WALLET_BALANCE_PENDING');
    expect(blocked?.message, contains('wallet'));

    await adminDio.post<dynamic>('/drivers/$driverId/wallet/transactions',
        data: {'kind': 'payout', 'amount': (earning - 20).toStringAsFixed(2), 'reference': 'UTR-LIVE-2'});
    expect(await repo.deleteAccount(), isNull);

    final (gone, afterDelete) = await repo.profile();
    expect(gone, isNull);
    expect(afterDelete, isA<AuthFailure>(), reason: 'the old session is dead');
    print('account deleted; the old session is refused');

    // The number is free again: signing in creates a brand-new, empty driver.
    final again = await signIn();
    final (fresh, _) = await again.profile();
    expect(fresh!.id, isNot(driverId));
    expect(fresh.onboardingStatus, OnboardingStatus.profileIncomplete);
  }, skip: _skip, timeout: const Timeout(Duration(minutes: 3)));
}
