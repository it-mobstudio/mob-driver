import 'package:m_o_b_demand_side/features/driver/presentation/widgets/map_style.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_glide.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/svg_marker.dart';

/// Everything the home map draws, already in map coordinates.
class DriverMapData {
  const DriverMapData({
    this.driver,
    this.pickup,
    this.drop,
    this.route = const [],
  });

  /// The driver's live position — null until the first GPS fix arrives.
  final LatLng? driver;

  /// An active trip's stops and route, shown alongside the driver so the
  /// vehicle icon sits on the road it's actually driving.
  final LatLng? pickup;
  final LatLng? drop;
  final List<LatLng> route;
}

/// Builds the full-screen map behind [DriverDashboardPage]. Injectable so
/// widget tests can swap the platform view (which can't render under
/// `flutter test`) for something inspectable — the same seam [TripMap] uses.
typedef DriverMapBuilder = Widget Function(
  BuildContext context,
  DriverMapData data,
  double bottomPadding,
  VoidCallback onSos,
);

Widget defaultDriverMapBuilder(BuildContext context, DriverMapData data,
        double bottomPadding, VoidCallback onSos) =>
    DriverMap(data: data, bottomPadding: bottomPadding, onSos: onSos);

class DriverMap extends StatefulWidget {
  const DriverMap({
    super.key,
    required this.data,
    required this.onSos,
    this.bottomPadding = 0,
  });

  final DriverMapData data;
  final VoidCallback onSos;

  /// Space at the bottom covered by the "looking for orders" panel, so the
  /// camera's centre and the floating buttons stay above it.
  final double bottomPadding;

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap>
    with SingleTickerProviderStateMixin {
  static const _fallbackCenter = LatLng(12.9716, 77.5946); // Bengaluru
  static const _vehicleAsset = 'assets/icons/driver_marker.svg';

  GoogleMapController? _controller;
  bool _created = false;

  /// The camera follows the driver until they pan the map themselves; the
  /// recenter button turns following back on. `animateCamera` also fires
  /// `onCameraMoveStarted`, so this flag tells "we moved it" apart from
  /// "the driver moved it" — cleared once that move settles.
  bool _following = true;
  bool _programmaticMove = false;

  BitmapDescriptor? _vehicleIcon;
  BitmapDescriptor? _dotIcon;

  /// Drives the vehicle between fixes and turns it the way it's heading.
  late final DriverGlide _glide = DriverGlide(
    vsync: this,
    onTick: () {
      if (mounted) setState(() {});
    },
  );

  /// The web map can't rotate a marker, so there the picture itself turns.
  late final WebVehicleIcons _webIcons = WebVehicleIcons(
    _vehicleAsset,
    width: 46,
    onReady: () {
      if (mounted) setState(() {});
    },
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadIcons());
    final start = widget.data.driver;
    if (start != null) _glide.moveTo(start, animate: false);
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    final results = await Future.wait([
      SvgMarkers.get(_vehicleAsset, width: 46),
      _dot(),
    ]);
    if (!mounted) return;
    setState(() {
      _vehicleIcon = results[0];
      _dotIcon = results[1];
    });
  }

  static Future<BitmapDescriptor>? _dotFuture;

  /// A small blue dot under the vehicle icon, the way a live-location marker
  /// usually reads — drawn once on a canvas rather than shipped as an asset.
  Future<BitmapDescriptor> _dot() => _dotFuture ??= () async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const size = 22.0;
        canvas.drawCircle(const Offset(size / 2, size / 2), size / 2,
            Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 3.4,
            Paint()..color = const Color(0xFF0454A3));
        final image =
            await recorder.endRecording().toImage(size.toInt(), size.toInt());
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) return BitmapDescriptor.defaultMarker;
        return BitmapDescriptor.bytes(bytes.buffer.asUint8List(),
            imagePixelRatio: 2.5);
      }();

  @override
  void didUpdateWidget(covariant DriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final point = widget.data.driver;
    if (point != null && point != oldWidget.data.driver) {
      _glide.moveTo(point, animate: !MediaQuery.disableAnimationsOf(context));
      if (_following) unawaited(_moveTo(point));
    }
  }

  /// The camera's zoom as last seen (for [DriverGlide.aimAbove] on the web).
  double _zoom = 15.5;

  Future<void> _moveTo(LatLng target, {double? zoom}) async {
    final controller = _controller;
    if (controller == null) return;
    _programmaticMove = true;
    if (kIsWeb) {
      // The web map ignores `padding`: aim below the driver so they land in
      // the middle of the part of the map the bottom panel leaves visible.
      target =
          DriverGlide.aimAbove(target, widget.bottomPadding / 2, zoom ?? _zoom);
    }
    await controller.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(target)
          : CameraUpdate.newLatLngZoom(target, zoom),
    );
  }

  Future<void> _recenter() async {
    setState(() => _following = true);
    final point = widget.data.driver;
    if (point != null) await _moveTo(point, zoom: 16.5);
  }

  Set<Marker> _markers() {
    final point = _glide.position ?? widget.data.driver;
    if (point == null) return const {};
    return {
      Marker(
        markerId: const MarkerId('driver_dot'),
        position: point,
        icon: _dotIcon ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(.5, .5),
        zIndexInt: 1,
        flat: true,
        consumeTapEvents: false,
      ),
      Marker(
        markerId: const MarkerId('driver_vehicle'),
        position: point,
        // Flat + rotated: the vehicle lies on the road and faces where it's
        // going, turning with the map if the driver rotates it.
        rotation: kIsWeb ? 0 : _glide.bearing,
        icon: (kIsWeb ? _webIcons.forBearing(_glide.bearing) : null) ??
            _vehicleIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(.5, .5),
        zIndexInt: 2,
        flat: true,
        consumeTapEvents: false,
      ),
      if (widget.data.pickup case final pickup?)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(.5, 1),
        ),
      if (widget.data.drop case final drop?)
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(.5, 1),
        ),
    };
  }

  Set<Polyline> _polylines() {
    final route = widget.data.route;
    if (route.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: route,
        color: const Color(0xFF0454A3),
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  /// Whether the native map exists. It's let go while a full-screen page
  /// (the trip, with its own map) covers this one: a Google map holds tens of
  /// megabytes of tiles and GPU memory, and two at once is what gets the app
  /// killed on a low-memory phone — often while the camera is open on top.
  bool _hosted = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // False for a route hidden under an opaque one (not under a sheet or a
    // dialog, where the map still shows).
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _hosted) return;
    _hosted = visible;
    if (!visible) {
      _controller = null;
      _created = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = _glide.position ?? widget.data.driver ?? _fallbackCenter;
    return Stack(children: [
      if (!_hosted)
        const Positioned.fill(child: ColoredBox(color: Color(0xFFE8EDF2)))
      else
        GoogleMap(
          style: kMobMapStyle,
          initialCameraPosition: CameraPosition(target: start, zoom: 15.5),
          markers: _markers(),
          polylines: _polylines(),
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          myLocationButtonEnabled: false,
          onCameraMoveStarted: () {
            if (_programmaticMove) return;
            if (_following) setState(() => _following = false);
          },
          onCameraMove: (position) => _zoom = position.zoom,
          onCameraIdle: () => _programmaticMove = false,
          onMapCreated: (controller) {
            _controller = controller;
            if (mounted) setState(() => _created = true);
            // Opened centred on the driver — which on the web (no `padding`)
            // is behind the bottom panel. Aim above it straight away.
            final driver = widget.data.driver;
            if (kIsWeb && driver != null) unawaited(_moveTo(driver));
          },
        ),
      // Fades away once the map exists, so there's no white flash while
      // tiles load (mirrors TripMap's own reveal).
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
        right: 16,
        bottom: widget.bottomPadding + 84,
        child: _MapFab(
          key: const Key('recenter_button'),
          assetPath: 'assets/icons/recenter_location.svg',
          onTap: _recenter,
        ),
      ),
      Positioned(
        right: 16,
        bottom: widget.bottomPadding + 24,
        child: _MapFab(
          key: const Key('sos_button'),
          assetPath: 'assets/icons/sos_icon.svg',
          iconSize: 26,
          onTap: widget.onSos,
        ),
      ),
    ]);
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.iconSize = 22,
  });

  final String assetPath;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child:
                SvgPicture.asset(assetPath, width: iconSize, height: iconSize),
          ),
        ),
      );
}
