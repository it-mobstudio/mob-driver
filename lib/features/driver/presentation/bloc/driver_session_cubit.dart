import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';
import 'package:m_o_b_demand_side/features/driver/domain/repositories/driver_repository.dart';

enum SessionLoad { initial, loading, ready, failed }

class DriverSessionState extends Equatable {
  const DriverSessionState({
    this.load = SessionLoad.initial,
    this.profile,
    this.stats = const DriverStats(),
    this.activeTrip,
    this.dutyBusy = false,
    this.tripBusy = false,
    this.loadError,
    this.locationUnavailable = false,
    this.tripKnown = false,
  });

  final SessionLoad load;
  final DriverProfile? profile;
  final DriverStats stats;
  final Trip? activeTrip;

  /// Going on/off duty is in flight.
  final bool dutyBusy;

  /// A trip action (arrive/start/complete/...) is in flight.
  final bool tripBusy;
  final String? loadError;

  /// On duty but the GPS/permission is failing — the driver isn't being
  /// tracked, so they won't be matched to trips.
  final bool locationUnavailable;

  /// Whether [activeTrip] reflects a real answer from the backend yet. The
  /// profile can be painted from the local cache immediately, but a trip is
  /// time-critical — until the backend has answered, the dashboard shows a
  /// placeholder rather than claiming "no active trip".
  final bool tripKnown;

  bool get isOnline => profile?.isOnline ?? false;

  /// The driver still has to give their details / upload documents before the
  /// app is any use to them. False until the profile is known, so a driver
  /// isn't flashed the sign-up flow while it loads.
  bool get needsOnboarding => profile?.onboardingStatus.needsSetup ?? false;

  DriverSessionState copyWith({
    SessionLoad? load,
    DriverProfile? profile,
    DriverStats? stats,
    Trip? activeTrip,
    bool clearActiveTrip = false,
    bool? dutyBusy,
    bool? tripBusy,
    String? loadError,
    bool clearLoadError = false,
    bool? locationUnavailable,
    bool? tripKnown,
  }) =>
      DriverSessionState(
        load: load ?? this.load,
        profile: profile ?? this.profile,
        stats: stats ?? this.stats,
        activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
        dutyBusy: dutyBusy ?? this.dutyBusy,
        tripBusy: tripBusy ?? this.tripBusy,
        loadError: clearLoadError ? null : (loadError ?? this.loadError),
        locationUnavailable: locationUnavailable ?? this.locationUnavailable,
        tripKnown: tripKnown ?? this.tripKnown,
      );

  @override
  List<Object?> get props => [
        load,
        profile,
        stats,
        activeTrip,
        dutyBusy,
        tripBusy,
        loadError,
        locationUnavailable,
        tripKnown,
      ];
}

/// Things that happen *to* the driver rather than because of something they
/// tapped — surfaced as one-shot events so the UI can react (alert, navigate)
/// exactly once.
sealed class DriverEvent {
  const DriverEvent(this.trip);
  final Trip trip;
}

/// The backend matched a new trip to this driver.
final class NewTripAssigned extends DriverEvent {
  const NewTripAssigned(super.trip);
}

/// The active trip stopped being active without the driver finishing it
/// here — the company cancelled it. [trip] is its final state.
final class TripEndedExternally extends DriverEvent {
  const TripEndedExternally(super.trip);
}

/// Owns everything that has to keep working while the driver is on duty,
/// independent of which screen is showing: the profile/duty state, the
/// periodic location pings that make them assignable, and polling for a newly
/// assigned (or externally cancelled) trip. The backend assigns trips
/// synchronously to the nearest online driver and has no push channel wired
/// up, so polling `driver/trips/active` is how a trip reaches the app.
class DriverSessionCubit extends Cubit<DriverSessionState> {
  DriverSessionCubit({
    required DriverRepository repository,
    required DriverLocationService location,
    this.pingInterval = const Duration(seconds: 10),
    this.pollInterval = const Duration(seconds: 5),
  })  : _repo = repository,
        _location = location,
        super(const DriverSessionState());

  final DriverRepository _repo;
  final DriverLocationService _location;
  final Duration pingInterval;
  final Duration pollInterval;

  final _events = StreamController<DriverEvent>.broadcast();
  Stream<DriverEvent> get events => _events.stream;

  GeoPoint? _lastPosition;
  GeoPoint? get lastPosition => _lastPosition;

  /// The driver's latest fix, for widgets that follow it live (the trip map).
  /// Kept out of [DriverSessionState] so a GPS tick doesn't rebuild every
  /// screen listening to the cubit.
  final ValueNotifier<GeoPoint?> position = ValueNotifier<GeoPoint?>(null);

  set _fix(GeoPoint? value) {
    _lastPosition = value;
    position.value = value;
  }

  StreamSubscription<GeoPoint>? _positionSub;
  Timer? _pingTimer;
  Timer? _pollTimer;
  bool _working = false;
  bool _loading = false;
  bool _pinging = false;
  bool _polling = false;

  /// Bumped around every driver-initiated trip action. A poll that started
  /// before an action finished carries stale data; comparing epochs lets it
  /// be discarded instead of resurrecting a trip the driver just completed.
  int _epoch = 0;

  void _set(DriverSessionState next) {
    if (!isClosed) emit(next);
  }

  // -- loading -------------------------------------------------------------

  /// Fetches profile, active trip and stats together. [silent] refreshes
  /// without flipping the screen back to a spinner.
  Future<void> load({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    final firstLoad = state.profile == null;
    if (!silent || firstLoad) {
      _set(state.copyWith(load: SessionLoad.loading, clearLoadError: true));
    }

    final epoch = _epoch;
    // Started together, awaited together.
    final profileCall = _repo.profile();
    final tripCall = _repo.activeTrip();
    final statsCall = _repo.stats();

    if (firstLoad) {
      // While the network answers, paint whatever we knew last time (a local
      // read — milliseconds) so a relaunch opens on the dashboard, not a
      // spinner. Only the profile/stats: a trip is never guessed at.
      final cached = await _repo.cachedSnapshot();
      if (!isClosed && state.profile == null && cached.profile != null) {
        _set(state.copyWith(
          load: SessionLoad.ready,
          profile: cached.profile,
          stats: cached.stats,
        ));
      }
    }

    final (profile, profileFailure) = await profileCall;
    final (trip, tripFailure) = await tripCall;
    final (stats, _) = await statsCall;
    _loading = false;
    if (isClosed) return;

    if (profile == null) {
      // A refresh that fails keeps showing what we have (fresh or cached);
      // there's only an error screen if we have nothing at all.
      if (state.profile == null) {
        _set(state.copyWith(
          load: SessionLoad.failed,
          loadError: profileFailure?.message ?? 'Could not load your profile.',
        ));
      }
      return;
    }

    // The driver acted while this was in flight — its view of the trip is
    // newer than ours.
    final keepLocalTrip = epoch != _epoch;
    final resolvedTrip =
        tripFailure != null || keepLocalTrip ? state.activeTrip : trip;
    _set(DriverSessionState(
      load: SessionLoad.ready,
      profile: profile,
      stats: stats ?? state.stats,
      activeTrip: resolvedTrip,
      dutyBusy: state.dutyBusy,
      tripBusy: state.tripBusy,
      locationUnavailable: state.locationUnavailable,
      // Best knowledge we're going to get this round — even if the trip call
      // failed, hanging a placeholder there forever helps nobody.
      tripKnown: true,
    ));

    if (profile.isOnline || resolvedTrip != null) {
      _startBackgroundWork();
    } else {
      _stopBackgroundWork();
    }
  }

  Future<void> _refreshStats() async {
    final (stats, _) = await _repo.stats();
    if (stats != null) _set(state.copyWith(stats: stats));
  }

  /// Signed out (or the shell went away): stop tracking and forget
  /// everything, so the next driver on this device starts clean.
  void reset() {
    _stopBackgroundWork();
    _fix = null;
    _epoch++;
    // Personal data must not outlive the session it belonged to.
    unawaited(_repo.clearCache());
    _set(const DriverSessionState());
  }

  // -- onboarding: details and documents ---------------------------------------

  /// Runs one of the profile-changing calls and adopts the profile it answers
  /// with, so every screen (and the onboarding gate) sees the change at once.
  /// Returns null on success.
  Future<AppFailure?> _profileCall(
    Future<(DriverProfile?, AppFailure?)> Function() call,
  ) async {
    final (profile, failure) = await call();
    if (profile == null) return failure ?? const UnknownFailure();
    _set(state.copyWith(profile: profile, load: SessionLoad.ready));
    return null;
  }

  Future<AppFailure?> updateProfile(ProfileUpdate update) =>
      _profileCall(() => _repo.updateProfile(update));

  Future<AppFailure?> uploadPhoto(CapturedPhoto photo) =>
      _profileCall(() => _repo.uploadPhoto(photo));

  Future<AppFailure?> submitAadhar({
    required String number,
    required CapturedPhoto front,
    required CapturedPhoto back,
  }) =>
      _profileCall(
          () => _repo.submitAadhar(number: number, front: front, back: back));

  Future<AppFailure?> submitLicence({
    required String number,
    required DateTime expiry,
    required CapturedPhoto front,
    CapturedPhoto? back,
  }) =>
      _profileCall(() => _repo.submitLicence(
            number: number,
            expiry: expiry,
            front: front,
            back: back,
          ));

  Future<AppFailure?> submitPolice(CapturedPhoto document) =>
      _profileCall(() => _repo.submitPolice(document));

  /// Closes the account, then forgets everything. Null on success — the
  /// caller signs the driver out.
  Future<AppFailure?> deleteAccount() async {
    final failure = await _repo.deleteAccount();
    if (failure == null) reset();
    return failure;
  }

  // -- wallet ----------------------------------------------------------------

  Future<(WalletSummary?, AppFailure?)> loadWallet() => _repo.wallet();

  /// One page of the wallet statement, newest first.
  Future<(Paged<WalletEntry>?, AppFailure?)> loadWalletEntries({
    int page = 1,
    List<WalletKind> kinds = const [],
  }) =>
      _repo.walletEntries(page: page, kinds: kinds);

  // -- duty ----------------------------------------------------------------

  Future<(List<DriverVehicle>?, AppFailure?)> loadVehicles() =>
      _repo.availableVehicles();

  /// Puts the driver on duty with [vehicleId]. Returns null on success.
  Future<AppFailure?> goOnline(String vehicleId) async {
    if (state.dutyBusy) return null;
    _set(state.copyWith(dutyBusy: true));

    final position = await _location.currentPosition();
    if (position == null) {
      _set(state.copyWith(dutyBusy: false));
      return const BusinessFailure(
        'Could not get your location. Turn on GPS and try again.',
      );
    }
    _fix = position;

    final (profile, failure) = await _repo.startDuty(
      vehicleId: vehicleId,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (profile == null) {
      _set(state.copyWith(dutyBusy: false));
      return failure ?? const UnknownFailure();
    }

    _set(state.copyWith(
      profile: profile,
      dutyBusy: false,
      locationUnavailable: false,
    ));
    _startBackgroundWork();
    unawaited(_pollActiveTrip());
    return null;
  }

  /// Takes the driver off duty. Returns null on success; the backend refuses
  /// while a trip is active (`DRIVER_HAS_ACTIVE_TRIP`).
  Future<AppFailure?> goOffline() async {
    if (state.dutyBusy) return null;
    _set(state.copyWith(dutyBusy: true));

    final (profile, failure) = await _repo.endDuty();
    if (profile == null) {
      _set(state.copyWith(dutyBusy: false));
      return failure ?? const UnknownFailure();
    }

    _set(state.copyWith(
      profile: profile,
      dutyBusy: false,
      locationUnavailable: false,
    ));
    if (state.activeTrip == null) _stopBackgroundWork();
    return null;
  }

  // -- trip actions --------------------------------------------------------

  Future<(Trip?, AppFailure?)> arrive(String tripId) =>
      _tripAction(() => _repo.arrive(tripId));

  Future<(Trip?, AppFailure?)> startTrip(String tripId) =>
      _tripAction(() => _repo.start(tripId));

  /// [otp] is required for COD trips, ignored for prepaid.
  Future<(Trip?, AppFailure?)> complete(String tripId, {String? otp}) =>
      _tripAction(() => _repo.complete(tripId, otp: otp));

  Future<(Trip?, AppFailure?)> cancel(String tripId, String reason) =>
      _tripAction(() => _repo.cancel(tripId, reason: reason));

  /// The driver's answer for one item at the drop. Goes through the same path
  /// as the other trip actions so a poll that started before it can't put the
  /// old answer back.
  Future<(Trip?, AppFailure?)> verifyItem(
    String tripId,
    String itemId, {
    required ItemStatus status,
    String? note,
    CapturedPhoto? photo,
  }) =>
      _tripAction(() => _repo.verifyItem(tripId, itemId,
          status: status, note: note, photo: photo));

  Future<(Trip?, AppFailure?)> resetItem(String tripId, String itemId) =>
      _tripAction(() => _repo.resetItem(tripId, itemId));

  Future<(Trip?, AppFailure?)> _tripAction(
    Future<(Trip?, AppFailure?)> Function() call,
  ) async {
    if (state.tripBusy) {
      return (null, const BusinessFailure('Please wait a moment…'));
    }
    _epoch++;
    _set(state.copyWith(tripBusy: true));

    final (trip, failure) = await call();
    _epoch++;
    if (trip == null) {
      _set(state.copyWith(tripBusy: false));
      return (null, failure ?? const UnknownFailure());
    }
    _applyTrip(trip);
    _set(state.copyWith(tripBusy: false));
    return (trip, null);
  }

  /// Adopts the server's latest version of a trip the driver just acted on.
  void _applyTrip(Trip trip) {
    if (trip.status.isActive) {
      _set(state.copyWith(activeTrip: trip));
    } else if (state.activeTrip?.id == trip.id) {
      _set(state.copyWith(clearActiveTrip: true));
      unawaited(_refreshStats());
      if (!state.isOnline) _stopBackgroundWork();
    }
  }

  /// Tells the backend the customer has paid (which also texts them the
  /// delivery OTP), then refreshes the trip so the UI moves on to the OTP
  /// step. If the backend says it was already paid, the trip is refreshed
  /// anyway — the local copy was simply stale.
  Future<(DeliveryOtpSent?, AppFailure?)> collectPayment(String tripId) async {
    _epoch++;
    final (sent, failure) = await _repo.collectPayment(tripId);
    if (sent != null || failure?.code == 'ALREADY_PAID') {
      await _refreshTrip(tripId);
    }
    _epoch++;
    return (sent, failure);
  }

  Future<(DeliveryOtpSent?, AppFailure?)> resendDeliveryOtp(String tripId) =>
      _repo.resendDeliveryOtp(tripId);

  Future<(PaymentQr?, AppFailure?)> paymentQr(String tripId) =>
      _repo.paymentQr(tripId);

  Future<(Trip?, AppFailure?)> fetchTrip(String tripId) => _repo.trip(tripId);

  /// One page of the driver's trip history, newest first.
  Future<(Paged<Trip>?, AppFailure?)> loadTrips({
    int page = 1,
    List<TripStatus> statuses = const [],
  }) =>
      _repo.trips(page: page, statuses: statuses);

  Future<void> _refreshTrip(String tripId) => refreshTrip(tripId);

  /// Re-reads one trip from the server and adopts it — how a screen learns
  /// something happened elsewhere (the customer paid, and Razorpay told the
  /// server). Null if the trip couldn't be fetched right now.
  Future<Trip?> refreshTrip(String tripId) async {
    final (trip, _) = await _repo.trip(tripId);
    if (trip != null) _applyTrip(trip);
    return trip;
  }

  /// Route from where the driver is now to the trip's next stop.
  Future<(NavRoute?, AppFailure?)> navigation(String tripId) async {
    final position = _lastPosition ?? await _location.currentPosition();
    if (position == null) {
      return (null, const BusinessFailure('Your location is not available.'));
    }
    _fix = position;
    return _repo.navigation(
      tripId,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  // -- background work -----------------------------------------------------

  void _startBackgroundWork() {
    if (_working || isClosed) return;
    _working = true;
    _listenToPositions();
    _pingTimer = Timer.periodic(pingInterval, (_) => _pingLocation());
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollActiveTrip());
    unawaited(_pingLocation());
  }

  void _stopBackgroundWork() {
    _working = false;
    _pingTimer?.cancel();
    _pollTimer?.cancel();
    _pingTimer = null;
    _pollTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _listenToPositions() {
    _positionSub?.cancel();
    _positionSub = _location.positionStream().listen(
      (point) {
        _fix = point;
        if (state.locationUnavailable) {
          _set(state.copyWith(locationUnavailable: false));
        }
      },
      onError: (Object _) {
        if (!state.locationUnavailable) {
          _set(state.copyWith(locationUnavailable: true));
        }
      },
      // A stream that ends (e.g. after the driver revoked permission) is
      // re-opened on the next ping tick rather than left dead.
      onDone: () => _positionSub = null,
    );
  }

  Future<void> _pingLocation() async {
    if (!_working || _pinging || isClosed) return;
    if (_positionSub == null) _listenToPositions();

    _pinging = true;
    try {
      var position = _lastPosition;
      if (position == null) {
        position = await _location.currentPosition();
        if (position == null) {
          if (!state.locationUnavailable) {
            _set(state.copyWith(locationUnavailable: true));
          }
          return;
        }
        _fix = position;
        // Getting a fix means the GPS/permission problem is over.
        if (state.locationUnavailable) {
          _set(state.copyWith(locationUnavailable: false));
        }
      }
      // Failures are dropped: the next tick sends a fresher fix anyway.
      await _repo.sendLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } finally {
      _pinging = false;
    }
  }

  Future<void> _pollActiveTrip() async {
    if (!_working || _polling || state.tripBusy || isClosed) return;
    _polling = true;
    final epoch = _epoch;
    try {
      final (trip, failure) = await _repo.activeTrip();
      // A transient network error must not look like "the trip vanished".
      if (failure != null || epoch != _epoch || isClosed) return;
      await _reconcileActiveTrip(trip, epoch);
    } finally {
      _polling = false;
    }
  }

  /// Runs one poll immediately (also what the timer calls).
  Future<void> pollNow() => _pollActiveTrip();

  Future<void> _reconcileActiveTrip(Trip? serverTrip, int epoch) async {
    final previous = state.activeTrip;

    if (serverTrip != null) {
      if (previous?.id != serverTrip.id) {
        _set(state.copyWith(activeTrip: serverTrip));
        _events.add(NewTripAssigned(serverTrip));
      } else if (serverTrip != previous) {
        _set(state.copyWith(activeTrip: serverTrip));
      }
      return;
    }

    if (previous == null) return;

    // We had a trip, the server no longer does, and the driver didn't end it
    // from this device (that path clears it itself): the company cancelled.
    final (fresh, _) = await _repo.trip(previous.id);
    if (epoch != _epoch || isClosed) return;
    _set(state.copyWith(clearActiveTrip: true));
    _events.add(TripEndedExternally(fresh ?? previous));
    unawaited(_refreshStats());
  }

  @override
  Future<void> close() {
    _stopBackgroundWork();
    _events.close();
    position.dispose();
    return super.close();
  }
}
