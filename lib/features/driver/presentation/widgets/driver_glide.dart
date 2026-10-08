import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/svg_marker.dart';

/// Moves the driver's vehicle on the map the way ride apps do: between two
/// GPS fixes it *drives* there instead of jumping, and it turns to face the
/// way it's going. Standing still (or GPS wobble of a few metres) keeps the
/// last heading, so a parked vehicle doesn't spin.
///
/// Owned by a map's State: call [moveTo] with every new fix, read [position]
/// and [bearing] when building the markers; [onTick] is called while it
/// moves (at most every [minTickGap], and once on arrival) so the map can
/// redraw.
class DriverGlide {
  DriverGlide({
    required TickerProvider vsync,
    required VoidCallback onTick,
    this.minTickGap = const Duration(milliseconds: 66),
  }) : _controller = AnimationController(vsync: vsync, duration: _glide) {
    _controller.addListener(() {
      final elapsed = _controller.lastElapsedDuration;
      final last = _lastTick;
      final due = elapsed == null || // placed at once, not animated
          _controller.value >= 1 || // arrived: draw the exact end point
          last == null ||
          elapsed < last || // a new glide started
          elapsed - last >= minTickGap;
      if (!due) return;
      _lastTick = elapsed;
      onTick();
    });
  }

  /// Each redraw re-sends every marker to the native map over the platform
  /// channel. ~15 a second still looks like driving, and costs a low-end
  /// phone a quarter of what 60 does.
  final Duration minTickGap;
  Duration? _lastTick;

  /// A little under the usual gap between fixes, so the vehicle arrives just
  /// before the next one and never visibly waits or lags behind.
  static const _glide = Duration(milliseconds: 1100);

  /// Movement smaller than this is GPS noise, not driving: don't turn for it.
  static const _turnThresholdMeters = 4.0;

  /// Further than this in one step is a relocation (first real fix, the app
  /// coming back from the background): jump there rather than race across.
  static const _jumpMeters = 800.0;

  final AnimationController _controller;
  LatLng? _from;
  LatLng? _to;
  double _fromBearing = 0;
  double _toBearing = 0;

  double get _t => Curves.easeInOut.transform(_controller.value);

  /// Where to draw the vehicle right now (null until the first fix).
  LatLng? get position {
    final to = _to, from = _from;
    if (to == null) return null;
    if (from == null) return to;
    final t = _t;
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  /// Which way the vehicle faces, in degrees clockwise from north.
  double get bearing {
    final turn = _shortestTurn(_fromBearing, _toBearing);
    return (_fromBearing + turn * _t) % 360;
  }

  /// Head for [target]. [animate] false (or reduce-motion) places it at once.
  void moveTo(LatLng target, {bool animate = true}) {
    if (target == _to) return;
    final current = position;
    if (current == null) {
      _from = null;
      _to = target;
      _controller.value = 1;
      return;
    }
    final meters = distanceMeters(current, target);
    _fromBearing = bearing;
    _toBearing = meters >= _turnThresholdMeters
        ? bearingBetween(current, target)
        : _fromBearing;
    if (!animate || meters > _jumpMeters) {
      _from = null;
      _to = target;
      _fromBearing = _toBearing;
      _controller.value = 1;
      return;
    }
    _from = current;
    _to = target;
    _controller.forward(from: 0);
  }

  void dispose() => _controller.dispose();

  // -- geometry --------------------------------------------------------------

  /// Where to aim the camera so [point] shows [pixelsUp] screen pixels above
  /// the map's centre at [zoom]. Only needed on the web, whose Google map
  /// ignores `GoogleMap.padding` — without it the driver sits dead centre,
  /// hidden under the bottom panel.
  static LatLng aimAbove(LatLng point, double pixelsUp, double zoom) {
    final metersPerPixel =
        156543.03392 * math.cos(_rad(point.latitude)) / math.pow(2, zoom);
    final degrees = pixelsUp * metersPerPixel / 111320;
    return LatLng(point.latitude - degrees, point.longitude);
  }

  static double _rad(double deg) => deg * math.pi / 180;

  /// Initial compass bearing from [a] to [b], 0–360°.
  static double bearingBetween(LatLng a, LatLng b) {
    final lat1 = _rad(a.latitude), lat2 = _rad(b.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Great-circle distance in metres.
  static double distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude),
        dLng = _rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earth * math.asin(math.sqrt(h));
  }

  /// The signed turn (−180…180°) from [from] to [to] — so 350° → 10° turns
  /// 20° right, not 340° left.
  static double _shortestTurn(double from, double to) =>
      ((to - from + 540) % 360) - 180;
}

/// The vehicle picture turned to a bearing, for the web (its map can't
/// rotate a marker). Pictures are drawn per 10° as they're first needed;
/// until one is ready the nearest one already drawn is used.
class WebVehicleIcons {
  WebVehicleIcons(this.asset, {required this.width, required this.onReady});

  final String asset;
  final double width;
  final VoidCallback onReady;

  final Map<int, BitmapDescriptor> _ready = {};
  final Set<int> _pending = {};
  BitmapDescriptor? _last;

  BitmapDescriptor? forBearing(double bearing) {
    final step = ((bearing / 10).round() * 10) % 360;
    final hit = _ready[step];
    if (hit != null) return _last = hit;
    if (_pending.add(step)) {
      SvgMarkers.rotated(asset, width: width, degrees: step).then((icon) {
        _ready[step] = icon;
        _pending.remove(step);
        onReady();
      });
    }
    return _last;
  }
}
