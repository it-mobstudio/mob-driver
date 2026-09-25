import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rasterises an SVG asset into a [BitmapDescriptor], the way [MapPins]
/// draws its canvas pins — needed because a `Marker` can only take an image,
/// never a widget. Cached per (asset, width): building one means an offscreen
/// render, and a map marker asks for its icon on every rebuild.
abstract final class SvgMarkers {
  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  static Future<BitmapDescriptor> get(String assetPath, {double width = 40}) =>
      _cache.putIfAbsent('$assetPath@$width', () => _build(assetPath, width));

  static Future<BitmapDescriptor> _build(String assetPath, double width) async {
    final pictureInfo = await vg.loadPicture(SvgAssetLoader(assetPath), null);
    final scale = width / pictureInfo.size.width;
    final height = pictureInfo.size.height * scale;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    pictureInfo.picture.dispose();

    final image =
        await recorder.endRecording().toImage(width.round(), height.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List(),
        imagePixelRatio: 2.5);
  }
}
