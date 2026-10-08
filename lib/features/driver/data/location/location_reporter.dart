import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:mob_driver/features/driver/data/location/driver_location_service.dart';

/// While the driver is on duty: follows the GPS and tells the backend where
/// they are — straight away once they've moved [minMoveMeters] (but not more
/// often than every [minGap]), and every [heartbeat] regardless, so the
/// backend knows a driver waiting in one spot is still there.
class LocationReporter {
  LocationReporter({
    required DriverLocationService location,
    required this.send,
    required this.onAvailabilityChanged,
    this.heartbeat = const Duration(seconds: 30),
    this.minMoveMeters = 25,
    this.minGap = const Duration(seconds: 5),
  }) : _location = location;

  final DriverLocationService _location;

  /// Delivers one fix to the backend. Failures are the caller's to swallow:
  /// the next movement or heartbeat sends a fresher fix anyway.
  final Future<void> Function(GeoPoint fix) send;

  /// The GPS stopped (false) or started again (true) giving fixes.
  final void Function(bool available) onAvailabilityChanged;

  final Duration heartbeat;
  final double minMoveMeters;
  final Duration minGap;

  /// The latest fix, for widgets that follow the driver live (the maps).
  final ValueNotifier<GeoPoint?> position = ValueNotifier(null);

  StreamSubscription<GeoPoint>? _positions;
  Timer? _heartbeat;
  bool _sendingHeartbeat = false;
  bool? _available;
  GeoPoint? _lastSent;
  DateTime? _lastSentAt;

  bool get isRunning => _heartbeat != null;

  /// Where the driver is now: the latest fix, else a fresh one. Null when
  /// none can be had.
  Future<GeoPoint?> currentFix() async {
    final known = position.value;
    if (known != null) return known;
    final fresh = await _location.currentPosition();
    if (fresh != null) position.value = fresh;
    return fresh;
  }

  /// A fix the caller got some other way (going on duty), so the maps don't
  /// wait for the stream's first one.
  void useFix(GeoPoint fix) => position.value = fix;

  void start() {
    if (isRunning) return;
    _listen();
    _heartbeat = Timer.periodic(heartbeat, (_) => _sendHeartbeat());
    unawaited(_sendHeartbeat());
  }

  void stop() {
    _heartbeat?.cancel();
    _heartbeat = null;
    unawaited(_positions?.cancel());
    _positions = null;
    _lastSent = null;
    _lastSentAt = null;
  }

  /// Signed out: forget where this driver was.
  void reset() {
    stop();
    position.value = null;
    _available = null;
  }

  void dispose() {
    stop();
    position.dispose();
  }

  void _listen() {
    unawaited(_positions?.cancel());
    _positions = _location.positionStream().listen(
      (fix) {
        position.value = fix;
        _setAvailable(true);
        if (_movedEnough(fix)) unawaited(_send(fix));
      },
      onError: (Object _) => _setAvailable(false),
      // A stream that ends (permission revoked) is re-opened on the next
      // heartbeat rather than left dead.
      onDone: () => _positions = null,
    );
  }

  Future<void> _sendHeartbeat() async {
    if (!isRunning || _sendingHeartbeat) return;
    if (_positions == null) _listen();
    _sendingHeartbeat = true;
    try {
      final fix = await currentFix();
      if (fix == null) {
        _setAvailable(false);
        return;
      }
      _setAvailable(true);
      await _send(fix);
    } finally {
      _sendingHeartbeat = false;
    }
  }

  Future<void> _send(GeoPoint fix) {
    _lastSent = fix;
    _lastSentAt = DateTime.now();
    return send(fix);
  }

  bool _movedEnough(GeoPoint fix) {
    final sent = _lastSent, at = _lastSentAt;
    if (!isRunning || sent == null || at == null) return false;
    if (DateTime.now().difference(at) < minGap) return false;
    return metersBetween(sent, fix) >= minMoveMeters;
  }

  void _setAvailable(bool available) {
    if (_available == available) return;
    _available = available;
    onAvailabilityChanged(available);
  }

  /// Great-circle distance between two fixes.
  static double metersBetween(GeoPoint a, GeoPoint b) {
    const earthRadius = 6371000.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final dLat = radians(b.latitude - a.latitude);
    final dLng = radians(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(radians(a.latitude)) *
            math.cos(radians(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }
}
