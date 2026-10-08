import 'package:equatable/equatable.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/utils/json_readers.dart';

/// Mirrors the backend's `TripStatus` (core/choices.py).
enum TripStatus {
  requested('requested', 'Requested'),
  noDriverAvailable('no_driver_available', 'No driver available'),
  assigned('assigned', 'Assigned'),
  arrivedAtPickup('arrived_at_pickup', 'At pickup'),
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  unknown('unknown', 'Unknown');

  const TripStatus(this.wire, this._label);
  final String wire;
  final String _label;

  /// In the driver's language.
  String get label => tr(_label);

  static TripStatus parse(String? value) => TripStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => TripStatus.unknown,
      );

  /// The driver is currently on this trip (matches the backend's
  /// `driver/trips/active` filter).
  bool get isActive =>
      this == assigned || this == arrivedAtPickup || this == inProgress;

  bool get isFinished => this == completed || this == cancelled;
}

enum PaymentMode {
  prepaid,
  cod;

  static PaymentMode parse(String? value) =>
      value == 'cod' ? PaymentMode.cod : PaymentMode.prepaid;
}

/// Which camera photos the company wants taken at a stop (backend
/// `PickupPhotoMode`, used for both `pickup_photo` and `delivery_photo`).
enum PickupPhotoMode {
  none('none'),
  order('order'),
  perItem('per_item'),
  both('both');

  const PickupPhotoMode(this.wire);
  final String wire;

  /// A photo of the whole order is part of it.
  bool get wantsOrderPhoto => this == order || this == both;

  /// A photo of every item is part of it.
  bool get wantsItemPhotos => this == perItem || this == both;

  static PickupPhotoMode parse(String? value) =>
      PickupPhotoMode.values.firstWhere((mode) => mode.wire == value,
          orElse: () => PickupPhotoMode.none);
}

/// One photo of the whole order, on the server. A stop can have several; a
/// wrong one is removed by its [id].
class OrderPhoto extends Equatable {
  const OrderPhoto({required this.id, required this.url});

  /// The backend's list (`[{id, url}]`), or — from a backend that only knows
  /// one photo per stop — that one [fallbackUrl], which can't be removed.
  static List<OrderPhoto> listFrom(dynamic json, {String? fallbackUrl}) {
    if (json is List) {
      return [
        for (final row in asMapList(json))
          if ((readString(row['url']) ?? '').isNotEmpty)
            OrderPhoto(
                id: readString(row['id']) ?? '', url: readString(row['url'])!),
      ];
    }
    return (fallbackUrl ?? '').isEmpty
        ? const []
        : [OrderPhoto(id: '', url: fallbackUrl!)];
  }

  final String id;
  final String url;

  bool get canRemove => id.isNotEmpty;

  @override
  List<Object?> get props => [id, url];
}

/// Where a proof photo is taken: at the pickup before the delivery starts, or
/// at the drop before it's finished.
enum PhotoStage {
  pickup('pickup', 'Pickup'),
  delivery('delivery', 'Delivery');

  const PhotoStage(this.wire, this._label);

  /// Also the endpoint: `driver/trips/{id}/<wire>-photo`.
  final String wire;
  final String _label;

  /// In the driver's language.
  String get label => tr(_label);
}

/// What the driver has said about one item at the drop.
enum ItemStatus {
  pending('pending'),
  delivered('delivered'),
  notDelivered('not_delivered');

  const ItemStatus(this.wire);
  final String wire;

  static ItemStatus parse(String? value) => ItemStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => ItemStatus.pending,
      );
}

/// One line of the goods on a trip: what the company says is being delivered,
/// and — when the company asked for verification — what the driver said
/// happened to it (the delivery history).
class TripItem extends Equatable {
  const TripItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unit,
    this.sku,
    this.notes,
    this.imageUrl,
    this.unitPrice,
    this.status = ItemStatus.pending,
    this.verifiedAt,
    this.proofImageUrl,
    this.pickupPhotoUrl,
    this.deliveryPhotoUrl,
    this.driverNote,
    this.pickupStopId,
    this.dropStopId,
  });

  factory TripItem.fromJson(Map<String, dynamic> json) => TripItem(
        id: readString(json['id']) ?? '',
        name: readString(json['name']) ?? tr('Item'),
        quantity: readInt(json['quantity']) ?? 1,
        unit: readString(json['unit']),
        sku: readString(json['sku']),
        notes: readString(json['notes']),
        imageUrl: readString(json['image_url']),
        unitPrice: readDouble(json['unit_price']),
        status: ItemStatus.parse(readString(json['status'])),
        verifiedAt: readDateTime(json['verified_at']),
        proofImageUrl: readString(json['proof_image_url']),
        pickupPhotoUrl: readString(json['pickup_photo_url']),
        deliveryPhotoUrl: readString(json['delivery_photo_url']),
        driverNote: readString(json['driver_note']),
        pickupStopId: readString(json['pickup_stop']),
        dropStopId: readString(json['drop_stop']),
      );

  final String id;
  final String name;
  final int quantity;
  final String? unit;
  final String? sku;
  final String? notes;
  final String? imageUrl;
  final double? unitPrice;
  final ItemStatus status;
  final DateTime? verifiedAt;
  final String? proofImageUrl;

  /// Taken at the pickup, on orders that want one photo per item.
  final String? pickupPhotoUrl;

  /// Taken at the drop, on orders that want one delivery photo per item.
  final String? deliveryPhotoUrl;
  final String? driverNote;

  /// The in-between stop ([TripWaypoint.id]) where this item is collected /
  /// handed over; null for the main pickup / the final drop.
  final String? pickupStopId;
  final String? dropStopId;

  String? stopId(PhotoStage stage) =>
      stage == PhotoStage.pickup ? pickupStopId : dropStopId;

  String? photoUrl(PhotoStage stage) =>
      stage == PhotoStage.pickup ? pickupPhotoUrl : deliveryPhotoUrl;

  bool get isPending => status == ItemStatus.pending;

  /// `4 bags`, or just `4`.
  String get quantityLabel =>
      (unit ?? '').isEmpty ? '$quantity' : '$quantity $unit';

  @override
  List<Object?> get props => [
        id,
        name,
        quantity,
        unit,
        sku,
        notes,
        imageUrl,
        unitPrice,
        status,
        verifiedAt,
        proofImageUrl,
        pickupPhotoUrl,
        deliveryPhotoUrl,
        driverNote,
        pickupStopId,
        dropStopId,
      ];
}

enum WaypointStatus {
  pending('pending'),
  arrived('arrived'),
  done('done');

  const WaypointStatus(this.wire);
  final String wire;

  static WaypointStatus parse(String? value) => WaypointStatus.values
      .firstWhere((s) => s.wire == value, orElse: () => WaypointStatus.pending);
}

/// One stop of the trip in visiting order (backend `stops[]`): the first is
/// the main pickup, the last the final drop, and any in between are extra
/// pickups / drops the driver works through while the delivery is in
/// progress.
class TripWaypoint extends Equatable {
  const TripWaypoint({
    required this.id,
    required this.position,
    required this.isPickup,
    required this.address,
    this.latitude,
    this.longitude,
    this.contactName,
    this.contactPhone,
    this.notes,
    this.reference,
    this.status = WaypointStatus.pending,
    this.photos = const [],
  });

  factory TripWaypoint.fromJson(Map<String, dynamic> json) => TripWaypoint(
        id: readString(json['id']) ?? '',
        position: readInt(json['position']) ?? 0,
        isPickup: readString(json['kind']) == 'pickup',
        address: readString(json['address']) ?? '',
        latitude: readDouble(json['lat']),
        longitude: readDouble(json['lng']),
        contactName: readString(json['contact_name']),
        contactPhone: readString(json['contact_phone']),
        notes: readString(json['notes']),
        reference: readString(json['reference']),
        status: WaypointStatus.parse(readString(json['status'])),
        photos: OrderPhoto.listFrom(json['photos'],
            fallbackUrl: readString(json['photo_url'])),
      );

  final String id;
  final int position;
  final bool isPickup;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? contactName;
  final String? contactPhone;
  final String? notes;

  /// A drop's own number when the trip has several (`OD…_01`).
  final String? reference;
  final WaypointStatus status;

  /// The photos of what was collected / handed over here (orders wanting a
  /// photo of the order at each stop), oldest first.
  final List<OrderPhoto> photos;

  bool get isDone => status == WaypointStatus.done;
  bool get isArrived => status == WaypointStatus.arrived;

  /// Which of the trip's photo rules apply here.
  PhotoStage get stage => isPickup ? PhotoStage.pickup : PhotoStage.delivery;

  /// `Stop 2`, counting the main pickup as stop 1.
  String get label => 'Stop ${position + 1}';

  String get kindLabel => isPickup ? tr('Pickup') : tr('Drop');

  /// The same place as a [TripStop], for the navigation / call helpers.
  TripStop get asStop => TripStop(
        address: address,
        latitude: latitude,
        longitude: longitude,
        contactName: contactName,
        contactPhone: contactPhone,
      );

  @override
  List<Object?> get props =>
      [id, position, isPickup, address, status, photos, contactName];
}

/// One end of a trip — the pickup or the drop.
class TripStop extends Equatable {
  const TripStop({
    required this.address,
    this.latitude,
    this.longitude,
    this.contactName,
    this.contactPhone,
  });

  factory TripStop.fromJson(
    Map<String, dynamic> json, {
    required String prefix,
  }) =>
      TripStop(
        address: readString(json['${prefix}_address']) ?? '',
        latitude: readDouble(json['${prefix}_lat']),
        longitude: readDouble(json['${prefix}_lng']),
        contactName: readString(json['${prefix}_contact_name']),
        contactPhone: readString(json['${prefix}_contact_phone']),
      );

  final String address;

  /// Null on trip-history rows, which the backend sends without coordinates.
  final double? latitude;
  final double? longitude;
  final String? contactName;
  final String? contactPhone;

  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props =>
      [address, latitude, longitude, contactName, contactPhone];
}

class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.paymentMode,
    required this.isPaid,
    this.referenceId,
    this.orderNumber,
    this.notes,
    this.voiceNoteUrl,
    this.voiceNoteSeconds,
    this.vehicleTypeName,
    this.vehicleRegistration,
    this.distanceMeters,
    this.durationSeconds,
    this.routePolyline,
    this.polylinePrecision = 6,
    this.baseFare,
    this.distanceFare,
    this.timeFare,
    this.surgeMultiplier,
    this.totalFare,
    this.bonusFare,
    this.currency = 'INR',
    this.codCollectedAt,
    this.invoiceUrl,
    this.invoiceNumber,
    this.verifyItems = false,
    this.pickupPhoto = PickupPhotoMode.none,
    this.pickupPhotos = const [],
    this.deliveryPhoto = PickupPhotoMode.none,
    this.deliveryPhotos = const [],
    this.deliveryOtp = false,
    this.items = const [],
    this.stops = const [],
    this.driverEarning,
    this.cancellationReason,
    this.cancelledBy,
    this.assignedAt,
    this.arrivedAtPickupAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
  });

  /// Parses both the full `TripSerializer` shape and the lighter list-row
  /// shape used by trip history (which has no coordinates or polyline).
  factory Trip.fromJson(Map<String, dynamic> json) {
    final vehicleType = asMap(json['vehicle_type']);
    final vehicle = asMap(json['vehicle']);
    return Trip(
      id: readString(json['id']) ?? '',
      status: TripStatus.parse(readString(json['status'])),
      referenceId: readString(json['reference_id']),
      orderNumber: readString(json['order_number']),
      notes: readString(json['notes']),
      voiceNoteUrl: readString(json['voice_note_url']),
      voiceNoteSeconds: readInt(json['voice_note_seconds']),
      vehicleTypeName: readString(vehicleType['name']),
      vehicleRegistration: readString(vehicle['registration_number']),
      pickup: TripStop.fromJson(json, prefix: 'pickup'),
      drop: TripStop.fromJson(json, prefix: 'drop'),
      distanceMeters: readInt(json['distance_meters']),
      durationSeconds: readInt(json['duration_seconds']),
      routePolyline: readString(json['route_polyline']),
      polylinePrecision: readInt(json['polyline_precision']) ?? 6,
      baseFare: readDouble(json['base_fare']),
      distanceFare: readDouble(json['distance_fare']),
      timeFare: readDouble(json['time_fare']),
      surgeMultiplier: readDouble(json['surge_multiplier']),
      totalFare: readDouble(json['total_fare']),
      bonusFare: readDouble(json['bonus_fare']),
      currency: readString(json['currency']) ?? 'INR',
      paymentMode: PaymentMode.parse(readString(json['payment_mode'])),
      isPaid: readString(json['payment_status']) == 'paid',
      codCollectedAt: readDateTime(json['cod_collected_at']),
      invoiceUrl: readString(json['invoice_url']),
      invoiceNumber: readString(json['invoice_number']),
      verifyItems: readBool(json['verify_items']),
      pickupPhoto: PickupPhotoMode.parse(readString(json['pickup_photo'])),
      pickupPhotos: OrderPhoto.listFrom(json['pickup_photos'],
          fallbackUrl: readString(json['pickup_photo_url'])),
      deliveryPhoto: PickupPhotoMode.parse(readString(json['delivery_photo'])),
      deliveryPhotos: OrderPhoto.listFrom(json['delivery_photos'],
          fallbackUrl: readString(json['delivery_photo_url'])),
      deliveryOtp: readBool(json['delivery_otp']),
      items: asMapList(json['items']).map(TripItem.fromJson).toList(),
      stops: asMapList(json['stops']).map(TripWaypoint.fromJson).toList(),
      driverEarning: readDouble(json['driver_earning']),
      cancellationReason: readString(json['cancellation_reason']),
      cancelledBy: readString(json['cancelled_by']),
      assignedAt: readDateTime(json['assigned_at']),
      arrivedAtPickupAt: readDateTime(json['arrived_at_pickup_at']),
      startedAt: readDateTime(json['started_at']),
      completedAt: readDateTime(json['completed_at']),
      cancelledAt: readDateTime(json['cancelled_at']),
      createdAt: readDateTime(json['created_at']),
    );
  }

  final String id;
  final TripStatus status;
  final String? referenceId;

  /// Our order number, `OD20260925000123`.
  final String? orderNumber;

  /// The company's note for the driver about the whole order.
  final String? notes;

  /// A short (≤ 30 s) spoken note from the dispatcher.
  final String? voiceNoteUrl;
  final int? voiceNoteSeconds;

  bool get hasVoiceNote => (voiceNoteUrl ?? '').isNotEmpty;
  final String? vehicleTypeName;
  final String? vehicleRegistration;
  final TripStop pickup;
  final TripStop drop;
  final int? distanceMeters;
  final int? durationSeconds;
  final String? routePolyline;

  /// Decimal places the [routePolyline] was encoded at (Valhalla: 6).
  final int polylinePrecision;
  final double? baseFare;
  final double? distanceFare;
  final double? timeFare;
  final double? surgeMultiplier;
  final double? totalFare;

  /// An extra flat amount for this trip specifically (e.g. for unloading
  /// heavy goods), on top of [totalFare] — never charged to the customer.
  /// Null (not just zero) when none was set at booking.
  final double? bonusFare;
  final String currency;
  final PaymentMode paymentMode;
  final bool isPaid;
  final DateTime? codCollectedAt;

  /// The goods' invoice (a PDF or image the company hosts), if it sent one.
  final String? invoiceUrl;
  final String? invoiceNumber;

  /// The company asked the driver to confirm every item at the drop.
  final bool verifyItems;

  /// The photos owed at the pickup: none, of the whole order (at least one,
  /// in [pickupPhotos]), or one per item (`items[].pickupPhotoUrl`).
  final PickupPhotoMode pickupPhoto;
  final List<OrderPhoto> pickupPhotos;

  /// The same at the drop, owed before payment / completion.
  final PickupPhotoMode deliveryPhoto;
  final List<OrderPhoto> deliveryPhotos;

  /// A prepaid trip that still needs the customer's delivery OTP to finish
  /// (COD trips always do).
  final bool deliveryOtp;
  final List<TripItem> items;

  /// Every stop in visiting order (empty on trip-history rows).
  final List<TripWaypoint> stops;

  /// The extra pickups / drops between the main pickup and the final drop.
  List<TripWaypoint> get inBetweenStops =>
      stops.length > 2 ? stops.sublist(1, stops.length - 1) : const [];

  bool get hasInBetweenStops => inBetweenStops.isNotEmpty;

  /// The in-between stop the driver is on or heading to, while the delivery
  /// is in progress; null once they're all done (the final drop is next).
  TripWaypoint? get nextStop => status != TripStatus.inProgress
      ? null
      : inBetweenStops.where((s) => !s.isDone).firstOrNull;

  /// The items handled at [stop] — collected at a pickup, handed over at a
  /// drop — or, with no stop, at the main pickup ([stage] pickup) / the final
  /// drop ([stage] delivery).
  List<TripItem> itemsAt(PhotoStage stage, {TripWaypoint? stop}) => [
        for (final item in items)
          if (item.stopId(stop?.stage ?? stage) == stop?.id) item
      ];

  /// What this trip paid the driver (set once it's completed).
  final double? driverEarning;
  final String? cancellationReason;

  /// `company`, `driver` or `system`.
  final String? cancelledBy;
  final DateTime? assignedAt;
  final DateTime? arrivedAtPickupAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;

  bool get isCod => paymentMode == PaymentMode.cod;

  /// The driver must collect the fare from the customer (scan-to-pay QR)
  /// before the delivery can be finished.
  bool get needsPaymentCollection =>
      status == TripStatus.inProgress && isCod && !isPaid;

  /// Only the customer's OTP is left: a paid COD trip, or a prepaid trip that
  /// asked for one.
  bool get needsDeliveryOtp =>
      status == TripStatus.inProgress && (isCod ? isPaid : deliveryOtp);

  bool get hasNotes => (notes ?? '').trim().isNotEmpty;

  bool get hasInvoice => (invoiceUrl ?? '').isNotEmpty;
  bool get hasItems => items.isNotEmpty;

  int get pendingItemCount => items.where((i) => i.isPending).length;
  int get resolvedItemCount => items.length - pendingItemCount;

  /// The company asked for verification and the driver still owes answers —
  /// until that's done the backend won't take payment or complete the trip.
  bool get needsItemVerification =>
      status == TripStatus.inProgress &&
      verifyItems &&
      itemsAt(PhotoStage.delivery).any((i) => i.isPending);

  /// Items handed over at [stop] that still need the driver's answer.
  int pendingItemsAt(TripWaypoint stop) => verifyItems && !stop.isPickup
      ? itemsAt(stop.stage, stop: stop).where((i) => i.isPending).length
      : 0;

  /// `#MOB9867855HJ` — the company's order number, else a short trip id.
  String get displayReference {
    if ((orderNumber ?? '').isNotEmpty) return '#$orderNumber';
    if ((referenceId ?? '').isNotEmpty) return '#$referenceId';
    return '#${id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()}';
  }

  /// What a proof photo shows, for its geo stamp: `#MOB98… · Pickup · Tap`.
  String photoCaption(String stage, [TripItem? item]) =>
      [displayReference, stage, if (item != null) item.name].join(' · ');

  PickupPhotoMode photoMode(PhotoStage stage) =>
      stage == PhotoStage.pickup ? pickupPhoto : deliveryPhoto;

  // The photo helpers below are about the main pickup / final drop, or — with
  // [stop] — one in-between stop, under the same rules for its kind.

  List<OrderPhoto> orderPhotos(PhotoStage stage, {TripWaypoint? stop}) =>
      stop != null
          ? stop.photos
          : stage == PhotoStage.pickup
              ? pickupPhotos
              : deliveryPhotos;

  /// The company asked for photos at this stop.
  bool wantsPhotos(PhotoStage stage, {TripWaypoint? stop}) =>
      switch (photoMode(stage)) {
        PickupPhotoMode.none => false,
        PickupPhotoMode.order || PickupPhotoMode.both => true,
        PickupPhotoMode.perItem => itemsAt(stage, stop: stop).isNotEmpty,
      };

  bool orderPhotoMissing(PhotoStage stage, {TripWaypoint? stop}) =>
      photoMode(stage).wantsOrderPhoto &&
      orderPhotos(stage, stop: stop).isEmpty;

  int missingItemPhotos(PhotoStage stage, {TripWaypoint? stop}) =>
      photoMode(stage).wantsItemPhotos
          ? itemsAt(stage, stop: stop)
              .where((i) => (i.photoUrl(stage) ?? '').isEmpty)
              .length
          : 0;

  /// Photos still owed at this stop (0 when none were asked for).
  int missingPhotos(PhotoStage stage, {TripWaypoint? stop}) =>
      (orderPhotoMissing(stage, stop: stop) ? 1 : 0) +
      missingItemPhotos(stage, stop: stop);

  /// Every photo asked for at this stop is on the server — until then the
  /// backend won't start (pickup) or finish (delivery) the trip, or finish
  /// the in-between [stop].
  bool hasPhotos(PhotoStage stage, {TripWaypoint? stop}) =>
      missingPhotos(stage, stop: stop) == 0;

  bool get wantsPickupPhotos => wantsPhotos(PhotoStage.pickup);
  bool get hasPickupPhotos => hasPhotos(PhotoStage.pickup);

  /// At the drop with delivery photos still to take.
  bool get needsDeliveryPhotos =>
      status == TripStatus.inProgress && !hasPhotos(PhotoStage.delivery);

  /// The backend only lets a trip be cancelled before pickup.
  bool get canCancel =>
      status == TripStatus.assigned || status == TripStatus.arrivedAtPickup;

  bool get cancelledByCompany => cancelledBy == 'company';

  @override
  List<Object?> get props => [
        id,
        status,
        isPaid,
        totalFare,
        bonusFare,
        routePolyline,
        codCollectedAt,
        invoiceUrl,
        invoiceNumber,
        notes,
        voiceNoteUrl,
        verifyItems,
        pickupPhoto,
        pickupPhotos,
        deliveryPhoto,
        deliveryPhotos,
        deliveryOtp,
        items,
        stops,
        driverEarning,
        arrivedAtPickupAt,
        startedAt,
        completedAt,
        cancelledAt,
        cancellationReason,
      ];
}
