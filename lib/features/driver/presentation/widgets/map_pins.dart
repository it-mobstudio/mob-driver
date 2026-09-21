import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

/// Teardrop map pins drawn on a canvas (a coloured disc with a letter), so the
/// pickup/drop/driver markers are distinguishable at a glance without bundling
/// image assets. Cached: building one means an offscreen render.
abstract final class MapPins {
  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  static Future<BitmapDescriptor> get pickup => pin('P', DriverColors.green);
  static Future<BitmapDescriptor> get drop => pin('D', DriverColors.red);
  static Future<BitmapDescriptor> get driver => pin('Me', DriverColors.blue);

  /// Draws all three pins ahead of time (right after app start) so the trip
  /// screen shows its real markers on the first frame instead of default
  /// placeholders that then pop into place.
  static Future<void> warmUp() async {
    try {
      await Future.wait([pickup, drop, driver]);
    } catch (_) {
      // Pins are cosmetic; the map falls back to stock markers.
    }
  }

  static Future<BitmapDescriptor> pin(String label, Color color) =>
      _cache.putIfAbsent(label, () => _build(label, color));

  static Future<BitmapDescriptor> _build(String label, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(88, 104);

    final tip = Path()
      ..moveTo(32, 70)
      ..lineTo(44, 101)
      ..lineTo(56, 70)
      ..close();
    canvas.drawShadow(tip, Colors.black, 5, true);
    canvas.drawPath(tip, Paint()..color = color);
    canvas.drawCircle(const Offset(44, 42), 39, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(44, 42), 35, Paint()..color = color);

    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, Offset(44 - painter.width / 2, 42 - painter.height / 2));

    final image = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(png.buffer.asUint8List(), imagePixelRatio: 2);
  }
}
