import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/map_pins.dart';

/// Everything the trip map draws, already in map coordinates.
class TripMapData {
  const TripMapData({
    required this.status,
    this.pickup,
    this.drop,
    this.driver,
    this.route = const [],
    this.leg = const [],
  });

  final TripStatus status;
  final LatLng? pickup;
  final LatLng? drop;
  final LatLng? driver;

  /// The trip's own pickup → drop polyline (decoded from the backend).
  final List<LatLng> route;

  /// The leg from the driver to the next stop (pickup, then drop).
  final List<LatLng> leg;

  List<LatLng> get _allPoints => [
        ...route,
        ...leg,
        if (pickup != null) pickup!,
        if (drop != null) drop!,
        if (driver != null) driver!,
      ];
}

/// Builds the map for [TripPage]. Injectable so tests can swap the platform
/// view (which can't render under `flutter test`) for something inspectable.
typedef TripMapBuilder = Widget Function(
  BuildContext context,
  TripMapData data,
  double bottomPadding,
);

Widget defaultTripMapBuilder(
        BuildContext context, TripMapData data, double bottomPadding) =>
    TripMap(data: data, bottomPadding: bottomPadding);

class TripMap extends StatefulWidget {
  const TripMap({super.key, required this.data, this.bottomPadding = 0});

  final TripMapData data;

  /// Space at the bottom covered by the trip panel, so Google's logo and the
  /// camera's "centre" stay in the visible part of the map.
  final double bottomPadding;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  static const _fallbackCenter = LatLng(12.9716, 77.5946); // Bengaluru

  GoogleMapController? _controller;
  bool _created = false;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  BitmapDescriptor? _driverIcon;

  /// Re-frame the camera when the *shape* of what's drawn changes (a route or
  /// leg arrived, the trip moved to its next stage) — never on a mere driver
  /// position tick, which would fight the driver panning the map.
  String _framedFor = '';

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    final icons = await Future.wait([
      MapPins.pickup,
      MapPins.drop,
      MapPins.driver,
    ]);
    if (!mounted) return;
    setState(() {
      _pickupIcon = icons[0];
      _dropIcon = icons[1];
      _driverIcon = icons[2];
    });
  }

  @override
  void didUpdateWidget(covariant TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shapeKey(widget.data) != _framedFor) unawaited(_frame());
  }

  String _shapeKey(TripMapData d) =>
      '${d.status.wire}|${d.route.length}|${d.leg.length}|${d.pickup}|${d.drop}';

  Future<void> _frame() async {
    final controller = _controller;
    if (controller == null) return;
    final points = widget.data._allPoints;
    _framedFor = _shapeKey(widget.data);
    if (points.isEmpty) return;

    try {
      if (points.length == 1) {
        await controller
            .animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
        return;
      }
      var south = points.first.latitude, north = south;
      var west = points.first.longitude, east = west;
      for (final p in points) {
        if (p.latitude < south) south = p.latitude;
        if (p.latitude > north) north = p.latitude;
        if (p.longitude < west) west = p.longitude;
        if (p.longitude > east) east = p.longitude;
      }
      await controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(south, west), northeast: LatLng(north, east)),
        72,
      ));
    } catch (_) {
      // The map can refuse a bounds update before it has been laid out (or
      // when every point coincides). Framing is a nicety, never a failure.
    }
  }

  Set<Marker> _markers() {
    final d = widget.data;
    return {
      if (d.pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: d.pickup!,
          icon: _pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(.5, 1),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      if (d.drop != null)
        Marker(
          markerId: const MarkerId('drop'),
          position: d.drop!,
          icon: _dropIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(.5, 1),
          infoWindow: const InfoWindow(title: 'Drop'),
        ),
      if (d.driver != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: d.driver!,
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(.5, 1),
          zIndexInt: 3,
          infoWindow: const InfoWindow(title: 'You'),
        ),
    };
  }

  Set<Polyline> _polylines() {
    final d = widget.data;
    return {
      if (d.route.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          points: d.route,
          color: DriverColors.blue.withValues(alpha: .9),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        )
      else if (d.pickup != null && d.drop != null)
        // No road geometry (routing was unavailable): a dashed straight line
        // still shows which way the delivery runs, without pretending it's a
        // road route.
        Polyline(
          polylineId: const PolylineId('route'),
          points: [d.pickup!, d.drop!],
          color: DriverColors.muted,
          width: 3,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
      if (d.leg.length >= 2)
        Polyline(
          polylineId: const PolylineId('leg'),
          points: d.leg,
          color: DriverColors.green,
          width: 6,
          zIndex: 2,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.data.pickup ?? widget.data.driver ?? _fallbackCenter;
    return Stack(children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(target: start, zoom: 13.5),
        markers: _markers(),
        polylines: _polylines(),
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        myLocationButtonEnabled: false,
        onMapCreated: (controller) {
          _controller = controller;
          if (mounted) setState(() => _created = true);
          // Give the platform view a moment to get its size before framing.
          Future<void>.delayed(const Duration(milliseconds: 350), _frame);
        },
      ),
      // A cover in the map's own colour that fades away once the map exists.
      // (A Flutter widget over the platform view — fading the view itself
      // isn't reliable on Android — so there's no white flash while tiles
      // load, just a soft reveal.)
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: _created ? 0 : 1,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            child: const ColoredBox(color: Color(0xFFE8EDF2)),
          ),
        ),
      ),
      Positioned(
        right: 14,
        top: MediaQuery.paddingOf(context).top + 12,
        child: Material(
          color: Colors.white,
          elevation: 3,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Show whole route',
            icon: const Icon(Icons.center_focus_strong_rounded,
                color: DriverColors.ink),
            onPressed: _frame,
          ),
        ),
      ),
    ]);
  }
}
