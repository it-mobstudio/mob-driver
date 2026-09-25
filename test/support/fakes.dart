import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/invoice_actions.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/geo_stamp.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/order_alert.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/my_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';
import 'package:m_o_b_demand_side/features/driver/domain/repositories/driver_repository.dart';

// -- JSON fixtures: shapes copied from a live run against the backend --------

Map<String, dynamic> tripJson({
  String id = '604807b6-7053-4f5f-bf99-163eb9620dc3',
  String status = 'assigned',
  String paymentMode = 'cod',
  String paymentStatus = 'pending',
  String? polyline = 'ox|vWogs_sCw|Aoh\\ooB_sg@',
  String? cancelledBy,
  String? cancellationReason,
  bool verifyItems = false,
  List<Map<String, dynamic>> items = const [],
  String? invoiceUrl,
  String? invoiceNumber,
  String? driverEarning,
  String? bonusFare,
  String pickupPhoto = 'none',
  String deliveryPhoto = 'none',
}) =>
    {
      'id': id,
      'status': status,
      'reference_id': 'E2E-1',
      'vehicle_type': {
        'id': 'vt-1',
        'name': 'Bike',
        'category': 'two_wheeler',
        'icon_image_url': null,
      },
      'driver': {
        'id': 'd-1',
        'full_name': 'Seed Driver 1',
        'phone_number': '+919000000000'
      },
      'vehicle': {'id': 'v-1', 'registration_number': 'KA01SEED0000'},
      'pickup_address': 'MG Road Metro, Bengaluru',
      'pickup_lat': '12.971600',
      'pickup_lng': '77.594600',
      'pickup_contact_name': 'Shop',
      'pickup_contact_phone': '+919888800001',
      'drop_address': 'Indiranagar 100ft Rd, Bengaluru',
      'drop_lat': '12.978400',
      'drop_lng': '77.640800',
      'drop_contact_name': 'Asha',
      'drop_contact_phone': '+919888800002',
      'distance_meters': 6582,
      'duration_seconds': 947,
      'route_polyline': polyline ?? '',
      'polyline_precision': 6,
      'base_fare': '30.00',
      'distance_fare': '65.82',
      'time_fare': '15.80',
      'surge_multiplier': '1.00',
      'total_fare': '111.62',
      'bonus_fare': bonusFare,
      'currency': 'INR',
      'payment_mode': paymentMode,
      'payment_status': paymentStatus,
      'cod_collected_at': null,
      'invoice_url': invoiceUrl,
      'invoice_number': invoiceNumber ?? '',
      'verify_items': verifyItems,
      'pickup_photo': pickupPhoto,
      'pickup_photo_url': null,
      'delivery_photo': deliveryPhoto,
      'delivery_photo_url': null,
      'items': items,
      'driver_earning': driverEarning,
      'cancellation_reason': cancellationReason ?? '',
      'cancelled_by': cancelledBy ?? '',
      'assigned_at': '2026-09-20T15:58:06.100000Z',
      'arrived_at_pickup_at': null,
      'started_at': null,
      'completed_at': null,
      'cancelled_at': null,
      'created_at': '2026-09-20T15:58:06.000000Z',
      'updated_at': '2026-09-20T15:58:06.000000Z',
    };

Map<String, dynamic> profileJson({
  bool online = false,
  bool eligible = true,
  String? onboarding,
  String fullName = 'Seed Driver 1',
  bool profileComplete = true,
  Map<String, dynamic>? kyc,
  Map<String, dynamic>? payout,
  String aadharStatus = '',
  String? aadharNote,
}) =>
    {
      'id': 'd-1',
      'full_name': fullName,
      'phone_number': '+919000000000',
      'email': null,
      'date_of_birth': profileComplete ? '1994-03-12' : null,
      'address_line': '',
      'city': '',
      'pincode': '',
      'profile_photo_url': null,
      'emergency_contact_name': 'Seed Emergency Contact',
      'emergency_contact_phone': '+919999900000',
      'account_status': 'active',
      'is_profile_complete': profileComplete,
      'onboarding_status':
          onboarding ?? (eligible ? 'approved' : 'under_review'),
      'aadhar_status': aadharStatus.isNotEmpty
          ? aadharStatus
          : (eligible ? 'verified' : 'pending'),
      'dl_status': 'verified',
      'police_status': 'verified',
      'dl_expiry_date': '2027-09-20',
      'dl_allowed_categories': ['two_wheeler'],
      'aadhar_rejection_note': aadharNote,
      'dl_rejection_note': null,
      'police_rejection_note': null,
      'kyc': kyc,
      'payout': payout ??
          {
            'upi_id': null,
            'bank_account_holder': null,
            'bank_account_last4': null,
            'bank_ifsc': null,
            'is_set': false,
          },
      'is_eligible_for_assignment': eligible,
      'current_vehicle_id': online ? 'v-1' : null,
      'current_vehicle': online
          ? {
              'id': 'v-1',
              'registration_number': 'KA01SEED0000',
              'capacity_kg': '20.00',
              'photo_url': null,
              'status': 'active',
              'vehicle_type': {
                'id': 'vt-1',
                'name': 'Bike',
                'category': 'two_wheeler'
              },
            }
          : null,
      'is_online': online,
    };

Map<String, dynamic> itemJson({
  String id = 'i-1',
  String name = 'Cement bag 50 kg',
  int quantity = 4,
  String unit = 'bags',
  String status = 'pending',
  String? imageUrl,
  String? proofImageUrl,
  String? note,
}) =>
    {
      'id': id,
      'position': 0,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'sku': 'SKU-1',
      'notes': '',
      'image_url': imageUrl,
      'unit_price': '380.00',
      'status': status,
      'verified_at': status == 'pending' ? null : '2026-09-21T10:00:00Z',
      'proof_image_url': proofImageUrl,
      'driver_note': note ?? '',
    };

Trip fakeTrip({
  String status = 'assigned',
  String paymentMode = 'cod',
  String paymentStatus = 'pending',
  String id = '604807b6-7053-4f5f-bf99-163eb9620dc3',
  String? bonusFare,
}) =>
    Trip.fromJson(tripJson(
      id: id,
      status: status,
      paymentMode: paymentMode,
      paymentStatus: paymentStatus,
      bonusFare: bonusFare,
    ));

DriverProfile fakeProfile({bool online = false, bool eligible = true}) =>
    DriverProfile.fromJson(profileJson(online: online, eligible: eligible));

// -- fakes -------------------------------------------------------------------

class FakeLocationService implements DriverLocationService {
  GeoPoint? fix = const GeoPoint(12.9716, 77.5946);
  final StreamController<GeoPoint> stream =
      StreamController<GeoPoint>.broadcast();
  int streamListens = 0;

  @override
  Future<GeoPoint?> currentPosition() async => fix;

  @override
  Stream<GeoPoint> positionStream() {
    streamListens++;
    return stream.stream;
  }
}

/// Scriptable repository: set the fields, call the cubit, inspect [calls].
class FakeDriverRepository implements DriverRepository {
  final List<String> calls = [];

  DriverProfile profileValue = fakeProfile();
  AppFailure? profileFailure;
  Trip? activeTripValue;
  AppFailure? activeTripFailure;

  /// While set, `activeTrip()` computes its answer immediately but doesn't
  /// *deliver* it until the gate opens — i.e. a slow response that reflects
  /// the server as it was when the request was made.
  Completer<void>? activeTripGate;
  DriverStats statsValue = const DriverStats();
  List<DriverVehicle> vehiclesValue = const [
    DriverVehicle(
        id: 'v-1',
        registrationNumber: 'KA01SEED0000',
        vehicleTypeName: 'Bike',
        category: 'two_wheeler'),
  ];

  /// What `navigation()` returns (the driver → next-stop leg).
  NavRoute navRouteValue = const NavRoute(target: 'pickup', points: []);
  AppFailure? navigationFailure;

  AppFailure? startDutyFailure;
  AppFailure? endDutyFailure;
  final Map<String, Trip> tripsById = {};

  /// What the next arrive/start/complete/cancel returns.
  (Trip?, AppFailure?) actionResult = (null, null);
  Completer<void>? actionGate;

  /// What the payment screen is handed. Defaults to the local-dev stand-in
  /// (a UPI link to draw); tests of the Razorpay flow swap in an image code.
  PaymentQr paymentQrValue = const PaymentQr(
    payload: 'upi://pay?pa=mob-delivery%40upi&am=111.62&cu=INR',
    amount: 111.62,
    currency: 'INR',
  );
  AppFailure? paymentQrFailure;
  int paymentQrCalls = 0;

  (DeliveryOtpSent?, AppFailure?) collectResult =
      (const DeliveryOtpSent(message: 'sent', debugOtp: '1234'), null);
  (DeliveryOtpSent?, AppFailure?) resendResult =
      (const DeliveryOtpSent(message: 'sent again', debugOtp: '6543'), null);
  final List<({double lat, double lng})> pings = [];

  // -- onboarding ----------------------------------------------------------
  /// What the next profile-changing call answers with (null: the current
  /// [profileValue], as if the backend accepted and echoed it).
  DriverProfile? profileChangeResult;
  AppFailure? profileChangeFailure;
  final List<ProfileUpdate> profileUpdates = [];
  final List<({String number, CapturedPhoto front, CapturedPhoto back})>
      aadharSubmissions = [];
  final List<({String number, DateTime expiry, bool hasBack})>
      licenceSubmissions = [];
  final List<CapturedPhoto> policeSubmissions = [];
  final List<CapturedPhoto> photoUploads = [];
  AppFailure? deleteAccountFailure;
  int deleteAccountCalls = 0;

  // -- wallet --------------------------------------------------------------
  WalletSummary walletValue = const WalletSummary();
  AppFailure? walletFailure;
  List<WalletEntry> walletEntriesValue = const [];
  int walletEntryPageSize = 20;
  final List<String> walletEntryCalls = [];

  // -- items ---------------------------------------------------------------
  /// The trip whose items [verifyItem]/[resetItem] edit; set by
  /// [startItemTrip].
  List<Map<String, dynamic>> itemsJson = [];
  Map<String, dynamic> itemTripExtras = {};
  AppFailure? verifyItemFailure;
  Completer<void>? verifyItemGate;
  final List<({String itemId, ItemStatus status, String? note, bool hasPhoto})>
      itemAnswers = [];

  Trip _itemTrip() => Trip.fromJson(tripJson(
        status: 'in_progress',
        paymentMode: itemTripExtras['cod'] == true ? 'cod' : 'prepaid',
        paymentStatus: itemTripExtras['cod'] == true ? 'pending' : 'paid',
        verifyItems: true,
        items: itemsJson,
        invoiceUrl: itemTripExtras['invoiceUrl'] as String?,
        invoiceNumber: itemTripExtras['invoiceNumber'] as String?,
      ));

  /// Makes an in-progress trip with these items the driver's active trip.
  Trip startItemTrip(List<Map<String, dynamic>> items,
      {String? invoiceUrl, String? invoiceNumber, bool cod = false}) {
    itemsJson = items.map((i) => Map<String, dynamic>.from(i)).toList();
    itemTripExtras = {
      'invoiceUrl': invoiceUrl,
      'invoiceNumber': invoiceNumber,
      'cod': cod,
    };
    final trip = _itemTrip();
    activeTripValue = trip;
    tripsById[trip.id] = trip;
    return trip;
  }

  /// What `cachedSnapshot()` returns (the on-device copy from last launch).
  DriverProfile? cachedProfile;
  DriverStats? cachedStats;
  int clearCacheCalls = 0;

  /// While set, `profile()` doesn't answer until the gate opens — a slow network.
  Completer<void>? profileGate;

  @override
  Future<({DriverProfile? profile, DriverStats? stats})>
      cachedSnapshot() async => (profile: cachedProfile, stats: cachedStats);

  @override
  Future<void> clearCache() async => clearCacheCalls++;

  @override
  Future<(DriverProfile?, AppFailure?)> profile() async {
    calls.add('profile');
    if (profileGate != null) await profileGate!.future;
    return profileFailure == null
        ? (profileValue, null)
        : (null, profileFailure);
  }

  @override
  Future<(List<DriverVehicle>?, AppFailure?)> availableVehicles() async =>
      (vehiclesValue, null);

  // -- the driver's own vehicles ------------------------------------------------
  List<VehicleTypeOption> vehicleTypesValue = const [
    VehicleTypeOption(id: 'vt-bike', name: 'Bike', category: 'two_wheeler', defaultCapacityKg: 20),
    VehicleTypeOption(id: 'vt-tempo', name: 'Tempo', category: 'three_wheeler', defaultCapacityKg: 500),
  ];
  final List<MyVehicle> myVehiclesValue = [];

  /// What the next own-vehicle change answers with (null: it succeeds).
  AppFailure? myVehicleFailure;

  /// What was asked, in order: `add:KA05MN7788:2:vt-bike:35.0`, `photo:v1`, `unphoto:v1:p0`, ...
  final List<String> vehicleCalls = [];
  int _vehicleSeq = 0;

  MyVehicle _rebuilt(MyVehicle v,
          {String? plate, String? typeId, double? capacity, List<VehiclePhotoRef>? photos}) =>
      MyVehicle(
        id: v.id,
        registrationNumber: plate ?? v.registrationNumber,
        vehicleTypeId: typeId ?? v.vehicleTypeId,
        vehicleTypeName: v.vehicleTypeName,
        category: v.category,
        capacityKg: capacity ?? v.capacityKg,
        photoUrl: (photos ?? v.photos).isEmpty ? null : (photos ?? v.photos).first.url,
        photos: photos ?? v.photos,
        isCurrent: v.isCurrent,
      );

  @override
  Future<(List<VehicleTypeOption>?, AppFailure?)> vehicleTypes() async => (vehicleTypesValue, null);

  @override
  Future<(List<MyVehicle>?, AppFailure?)> myVehicles() async => (List.of(myVehiclesValue), null);

  @override
  Future<(MyVehicle?, AppFailure?)> addVehicle({
    required String vehicleTypeId,
    required String registrationNumber,
    double? capacityKg,
    List<CapturedPhoto> photos = const [],
  }) async {
    vehicleCalls.add('add:$registrationNumber:${photos.length}:$vehicleTypeId:$capacityKg');
    if (myVehicleFailure != null) return (null, myVehicleFailure);
    final type = vehicleTypesValue.firstWhere((t) => t.id == vehicleTypeId);
    final id = 'v${++_vehicleSeq}';
    final vehicle = MyVehicle(
      id: id,
      registrationNumber: registrationNumber,
      vehicleTypeId: type.id,
      vehicleTypeName: type.name,
      category: type.category,
      capacityKg: capacityKg ?? type.defaultCapacityKg,
      photoUrl: photos.isEmpty ? null : 'https://cdn.example.com/$id-0.jpg',
      photos: [for (var i = 0; i < photos.length; i++) VehiclePhotoRef(id: '$id-p$i', url: 'https://cdn.example.com/$id-$i.jpg')],
    );
    myVehiclesValue.insert(0, vehicle);
    return (vehicle, null);
  }

  @override
  Future<(MyVehicle?, AppFailure?)> updateVehicle(String id,
      {String? vehicleTypeId, String? registrationNumber, double? capacityKg}) async {
    vehicleCalls.add('update:$id:$registrationNumber:$vehicleTypeId:$capacityKg');
    if (myVehicleFailure != null) return (null, myVehicleFailure);
    final i = myVehiclesValue.indexWhere((v) => v.id == id);
    myVehiclesValue[i] = _rebuilt(myVehiclesValue[i], plate: registrationNumber, typeId: vehicleTypeId, capacity: capacityKg);
    return (myVehiclesValue[i], null);
  }

  @override
  Future<(MyVehicle?, AppFailure?)> addVehiclePhoto(String id, CapturedPhoto photo) async {
    vehicleCalls.add('photo:$id');
    if (myVehicleFailure != null) return (null, myVehicleFailure);
    final i = myVehiclesValue.indexWhere((v) => v.id == id);
    final photos = [...myVehiclesValue[i].photos, VehiclePhotoRef(id: '$id-new${myVehiclesValue[i].photos.length}', url: 'https://cdn.example.com/$id-new.jpg')];
    myVehiclesValue[i] = _rebuilt(myVehiclesValue[i], photos: photos);
    return (myVehiclesValue[i], null);
  }

  @override
  Future<(MyVehicle?, AppFailure?)> removeVehiclePhoto(String id, String photoId) async {
    vehicleCalls.add('unphoto:$id:$photoId');
    if (myVehicleFailure != null) return (null, myVehicleFailure);
    final i = myVehiclesValue.indexWhere((v) => v.id == id);
    myVehiclesValue[i] = _rebuilt(myVehiclesValue[i], photos: [for (final p in myVehiclesValue[i].photos) if (p.id != photoId) p]);
    return (myVehiclesValue[i], null);
  }

  @override
  Future<AppFailure?> removeVehicle(String id) async {
    vehicleCalls.add('remove:$id');
    if (myVehicleFailure != null) return myVehicleFailure;
    myVehiclesValue.removeWhere((v) => v.id == id);
    return null;
  }

  @override
  Future<(DriverStats?, AppFailure?)> stats() async => (statsValue, null);

  Future<(DriverProfile?, AppFailure?)> _profileChange() async {
    if (profileChangeFailure != null) return (null, profileChangeFailure);
    final next = profileChangeResult ?? profileValue;
    profileValue = next;
    return (next, null);
  }

  @override
  Future<(DriverProfile?, AppFailure?)> updateProfile(ProfileUpdate update) {
    calls.add('updateProfile');
    profileUpdates.add(update);
    return _profileChange();
  }

  @override
  Future<(DriverProfile?, AppFailure?)> uploadPhoto(CapturedPhoto photo) {
    calls.add('uploadPhoto');
    photoUploads.add(photo);
    return _profileChange();
  }

  @override
  Future<(DriverProfile?, AppFailure?)> submitAadhar({
    required String number,
    required CapturedPhoto front,
    required CapturedPhoto back,
  }) {
    calls.add('submitAadhar');
    aadharSubmissions.add((number: number, front: front, back: back));
    return _profileChange();
  }

  @override
  Future<(DriverProfile?, AppFailure?)> submitLicence({
    required String number,
    required DateTime expiry,
    required CapturedPhoto front,
    CapturedPhoto? back,
  }) {
    calls.add('submitLicence');
    licenceSubmissions
        .add((number: number, expiry: expiry, hasBack: back != null));
    return _profileChange();
  }

  @override
  Future<(DriverProfile?, AppFailure?)> submitPolice(CapturedPhoto document) {
    calls.add('submitPolice');
    policeSubmissions.add(document);
    return _profileChange();
  }

  @override
  Future<AppFailure?> deleteAccount() async {
    deleteAccountCalls++;
    return deleteAccountFailure;
  }

  @override
  Future<(WalletSummary?, AppFailure?)> wallet() async {
    calls.add('wallet');
    return walletFailure == null ? (walletValue, null) : (null, walletFailure);
  }

  @override
  Future<(Paged<WalletEntry>?, AppFailure?)> walletEntries({
    int page = 1,
    List<WalletKind> kinds = const [],
  }) async {
    walletEntryCalls.add('$page:${kinds.map((k) => k.wire).join(',')}');
    final all = walletEntriesValue
        .where((e) => kinds.isEmpty || kinds.contains(e.kind))
        .toList();
    final start = (page - 1) * walletEntryPageSize;
    final slice = all.skip(start).take(walletEntryPageSize).toList();
    return (
      Paged<WalletEntry>(
        items: slice,
        count: all.length,
        hasNext: start + slice.length < all.length,
      ),
      null
    );
  }

  @override
  Future<(Trip?, AppFailure?)> verifyItem(
    String tripId,
    String itemId, {
    required ItemStatus status,
    String? note,
    CapturedPhoto? photo,
  }) async {
    calls.add('verifyItem:$itemId:${status.wire}');
    itemAnswers.add(
        (itemId: itemId, status: status, note: note, hasPhoto: photo != null));
    if (verifyItemGate != null) await verifyItemGate!.future;
    if (verifyItemFailure != null) return (null, verifyItemFailure);
    final item = itemsJson.firstWhere((i) => i['id'] == itemId);
    item['status'] = status.wire;
    item['verified_at'] = '2026-09-21T10:00:00Z';
    item['driver_note'] = note ?? '';
    if (photo != null) {
      item['proof_image_url'] = 'https://cdn.example.com/proof-$itemId.jpg';
    }
    final trip = _itemTrip();
    activeTripValue = trip;
    tripsById[trip.id] = trip;
    return (trip, null);
  }

  /// Pickup photos sent, as `order` or the item id.
  final List<String> pickupPhotos = [];

  /// Delivery photos sent, as `order` or the item id.
  final List<String> deliveryPhotos = [];
  AppFailure? pickupPhotoFailure;

  @override
  Future<(Trip?, AppFailure?)> addTripPhoto(
    String tripId, {
    required PhotoStage stage,
    required CapturedPhoto photo,
    String? itemId,
  }) async {
    calls.add('${stage.wire}Photo:${itemId ?? 'order'}');
    (stage == PhotoStage.pickup ? pickupPhotos : deliveryPhotos)
        .add(itemId ?? 'order');
    if (pickupPhotoFailure != null) return (null, pickupPhotoFailure);
    final json = tripJsonById[tripId];
    if (json == null) return (tripsById[tripId], null);
    final field = '${stage.wire}_photo_url';
    if (itemId == null) {
      json[field] = 'https://cdn.example.com/${stage.wire}-order.jpg';
    } else {
      final item = (json['items'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((i) => i['id'] == itemId);
      item[field] = 'https://cdn.example.com/${stage.wire}-$itemId.jpg';
    }
    final trip = Trip.fromJson(json);
    tripsById[tripId] = trip;
    if (activeTripValue?.id == tripId) activeTripValue = trip;
    return (trip, null);
  }

  /// Raw JSON of trips whose pickup photos a test wants tracked.
  final Map<String, Map<String, dynamic>> tripJsonById = {};

  @override
  Future<(Trip?, AppFailure?)> resetItem(String tripId, String itemId) async {
    calls.add('resetItem:$itemId');
    if (verifyItemFailure != null) return (null, verifyItemFailure);
    final item = itemsJson.firstWhere((i) => i['id'] == itemId);
    item['status'] = 'pending';
    item['verified_at'] = null;
    item['driver_note'] = '';
    item['proof_image_url'] = null;
    final trip = _itemTrip();
    activeTripValue = trip;
    tripsById[trip.id] = trip;
    return (trip, null);
  }

  @override
  Future<(DriverProfile?, AppFailure?)> startDuty({
    required String vehicleId,
    double? latitude,
    double? longitude,
  }) async {
    calls.add('startDuty:$vehicleId:$latitude,$longitude');
    if (startDutyFailure != null) return (null, startDutyFailure);
    profileValue = fakeProfile(online: true);
    return (profileValue, null);
  }

  @override
  Future<(DriverProfile?, AppFailure?)> endDuty() async {
    calls.add('endDuty');
    if (endDutyFailure != null) return (null, endDutyFailure);
    profileValue = fakeProfile();
    return (profileValue, null);
  }

  @override
  Future<AppFailure?> sendLocation({
    required double latitude,
    required double longitude,
  }) async {
    pings.add((lat: latitude, lng: longitude));
    return null;
  }

  @override
  Future<(Trip?, AppFailure?)> activeTrip() async {
    calls.add('activeTrip');
    final answer = (activeTripValue, activeTripFailure);
    if (activeTripGate != null) await activeTripGate!.future;
    return answer;
  }

  @override
  Future<(Paged<Trip>?, AppFailure?)> trips({
    int page = 1,
    List<TripStatus> statuses = const [],
  }) async {
    calls.add('trips:$page:${statuses.map((s) => s.wire).join(',')}');
    final items = tripsById.values
        .where((t) => statuses.isEmpty || statuses.contains(t.status))
        .toList();
    return (
      Paged<Trip>(items: items, count: items.length, hasNext: false),
      null
    );
  }

  @override
  Future<(Trip?, AppFailure?)> trip(String id) async {
    calls.add('trip:$id');
    final trip = tripsById[id];
    return trip == null
        ? (null, const BusinessFailure('Not found.', code: 'NOT_FOUND'))
        : (trip, null);
  }

  @override
  Future<(NavRoute?, AppFailure?)> navigation(
    String id, {
    required double latitude,
    required double longitude,
  }) async {
    calls.add('navigation:$id');
    return navigationFailure == null
        ? (navRouteValue, null)
        : (null, navigationFailure);
  }

  Future<(Trip?, AppFailure?)> _action(String name, String id) async {
    calls.add('$name:$id');
    if (actionGate != null) await actionGate!.future;
    return actionResult;
  }

  @override
  Future<(Trip?, AppFailure?)> arrive(String id) => _action('arrive', id);

  @override
  Future<(Trip?, AppFailure?)> start(String id) => _action('start', id);

  @override
  Future<(Trip?, AppFailure?)> complete(String id, {String? otp}) =>
      _action('complete[$otp]', id);

  @override
  Future<(Trip?, AppFailure?)> cancel(String id, {required String reason}) =>
      _action('cancel[$reason]', id);

  @override
  Future<(PaymentQr?, AppFailure?)> paymentQr(String id) async {
    paymentQrCalls++;
    return paymentQrFailure == null
        ? (paymentQrValue, null)
        : (null, paymentQrFailure);
  }

  @override
  Future<(DeliveryOtpSent?, AppFailure?)> collectPayment(String id) async {
    calls.add('collect:$id');
    return collectResult;
  }

  @override
  Future<(DeliveryOtpSent?, AppFailure?)> resendDeliveryOtp(String id) async {
    calls.add('resend:$id');
    return resendResult;
  }
}

// -- device fakes ---------------------------------------------------------------

/// A real 1x1 PNG: widgets decode what they're given, so random bytes would
/// raise image errors.
final Uint8List kTinyPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// A camera that "takes" a tiny picture (or fails, or is dismissed).
class FakePhotoCapture implements PhotoCapture {
  /// What the next shot returns; null means the driver backed out.
  CapturedPhoto? next = CapturedPhoto(bytes: kTinyPng, filename: 'shot.jpg');
  PhotoCaptureException? failure;
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<CapturedPhoto?> takePhoto() async {
    cameraCalls++;
    if (failure != null) throw failure!;
    return next;
  }

  @override
  Future<CapturedPhoto?> pickFromGallery() async {
    galleryCalls++;
    if (failure != null) throw failure!;
    return next;
  }

  /// Every stamp put on a photo, in order.
  final List<GeoStamp> stamps = [];

  @override
  Future<CapturedPhoto> geoStamp(CapturedPhoto photo, GeoStamp stamp) async {
    stamps.add(stamp);
    return photo;
  }
}

/// Records what the driver did with the invoice; each action can be made to fail.
class FakeInvoiceActions implements InvoiceActions {
  final List<String> calls = [];
  final List<({String url, String fileName, String? message})> shares = [];
  final List<({String? phone, String message})> whatsApps = [];
  final List<String> downloads = [];
  String? problem;
  Completer<void>? gate;

  Future<String?> _answer() async {
    if (gate != null) await gate!.future;
    return problem;
  }

  @override
  Future<String?> download(String url) {
    calls.add('download');
    downloads.add(url);
    return _answer();
  }

  @override
  Future<String?> shareFile(String url,
      {required String fileName, String? message}) {
    calls.add('share');
    shares.add((url: url, fileName: fileName, message: message));
    return _answer();
  }

  @override
  Future<String?> whatsApp({String? phone, required String message}) {
    calls.add('whatsApp');
    whatsApps.add((phone: phone, message: message));
    return _answer();
  }
}

/// Just enough auth to see whether the driver was signed out.
class FakeAuthRepository implements AuthRepository {
  int signOutCalls = 0;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Future<(OtpRequestResult?, AppFailure?)> sendOtp(
          {required String phoneNumber}) async =>
      (const OtpRequestResult(message: 'sent'), null);

  @override
  Future<(AuthVerifyResult?, AppFailure?)> verifyOtp(
          {required String phoneNumber, required String otp}) async =>
      (null, const UnknownFailure());

  @override
  Future<(bool, AppFailure?)> updateFcmToken(
          {required String emailOrPhone, required String fcmToken}) async =>
      (true, null);
}


/// Records the new-order alarm instead of ringing.
class FakeOrderAlert implements OrderAlert {
  int starts = 0;
  int stops = 0;
  bool get ringing => starts > stops;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async {
    if (ringing) stops++;
  }
}
