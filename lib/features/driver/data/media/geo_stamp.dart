import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter/painting.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';

/// What gets burned into the bottom of a proof photo, GPS-camera style: where
/// and when it was taken, and what it's of. Part of the picture itself (not
/// metadata), so it survives any re-share and can't be quietly edited.
class GeoStamp extends Equatable {
  const GeoStamp({
    required this.latitude,
    required this.longitude,
    required this.takenAt,
    required this.caption,
    this.address,
  });

  final double latitude;
  final double longitude;
  final DateTime takenAt;

  /// What the photo is of: `#MOB9867855HJ · Pickup · Brass shower`.
  final String caption;

  /// The street address at [latitude]/[longitude], when it could be looked up.
  final String? address;

  GeoStamp withAddress(String? value) => GeoStamp(
        latitude: latitude,
        longitude: longitude,
        takenAt: takenAt,
        caption: caption,
        address: value,
      );

  /// The stamp's text, top to bottom.
  List<String> get lines {
    final offset = takenAt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return [
      if ((address ?? '').isNotEmpty) address!,
      'Lat ${latitude.toStringAsFixed(6)}°  Long ${longitude.toStringAsFixed(6)}°',
      '${DateFormat('dd/MM/yyyy hh:mm a').format(takenAt)} GMT$sign$hh:$mm',
      caption,
    ];
  }

  @override
  List<Object?> get props => [latitude, longitude, takenAt, caption, address];
}

/// A short street address for [latitude]/[longitude], or null if it can't be
/// had quickly (no network, web build, no result). A photo never waits long
/// on this — the coordinates alone are the proof.
Future<String?> lookUpAddress(double latitude, double longitude) async {
  if (kIsWeb) return null;
  try {
    final places = await placemarkFromCoordinates(latitude, longitude)
        .timeout(const Duration(seconds: 3));
    if (places.isEmpty) return null;
    final p = places.first;
    final parts = <String>{
      for (final part in [
        p.name,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.postalCode,
      ])
        if ((part ?? '').trim().isNotEmpty) part!.trim(),
    };
    return parts.isEmpty ? null : parts.join(', ');
  } catch (_) {
    return null;
  }
}

/// Draws [stamp] as a dark band across the bottom of [photo] and re-encodes it
/// as a JPEG. The band scales with the picture, so the text reads the same on
/// a 1600 px shot as on a small one.
Future<CapturedPhoto> renderGeoStamp(CapturedPhoto photo, GeoStamp stamp) async {
  final codec = await ui.instantiateImageCodec(photo.bytes);
  final source = (await codec.getNextFrame()).image;
  final pixelsWide = source.width, pixelsHigh = source.height;
  final width = pixelsWide.toDouble();
  final height = pixelsHigh.toDouble();
  final unit = width / 100; // 1% of the width

  final lines = stamp.lines;
  final paragraphs = <ui.Paragraph>[
    for (var i = 0; i < lines.length; i++)
      _paragraph(
        lines[i],
        // The first line (address, or coordinates) leads; the caption is
        // set a touch brighter than the facts above it.
        size: unit * (i == 0 ? 3.3 : 2.8),
        weight: i == 0 ? FontWeight.w700 : FontWeight.w500,
        color: i == lines.length - 1
            ? const Color(0xFFFFD66B)
            : const Color(0xFFFFFFFF),
        maxWidth: width - unit * 12,
      ),
  ];
  final gap = unit * 0.9;
  final pad = unit * 3;
  final textHeight = paragraphs.fold<double>(0, (h, p) => h + p.height) +
      gap * (paragraphs.length - 1);
  final bandHeight = textHeight + pad * 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(source, Offset.zero, Paint());
  canvas.drawRect(
    Rect.fromLTWH(0, height - bandHeight, width, bandHeight),
    Paint()..color = const Color(0xB3000000),
  );

  // A map pin, drawn rather than taken from an icon font so it renders the
  // same everywhere.
  final pinX = pad + unit * 2.2;
  final pinY = height - bandHeight + pad + unit * 2.2;
  final pin = Path()
    ..addOval(Rect.fromCircle(center: Offset(pinX, pinY), radius: unit * 2.1))
    ..moveTo(pinX - unit * 1.6, pinY + unit * 1.3)
    ..lineTo(pinX, pinY + unit * 4)
    ..lineTo(pinX + unit * 1.6, pinY + unit * 1.3)
    ..close();
  canvas.drawPath(pin, Paint()..color = const Color(0xFFE5484D));
  canvas.drawCircle(
      Offset(pinX, pinY), unit * 0.8, Paint()..color = const Color(0xFFFFFFFF));

  var y = height - bandHeight + pad;
  final x = pad + unit * 6.5;
  for (final p in paragraphs) {
    canvas.drawParagraph(p, Offset(x, y));
    y += p.height + gap;
  }

  final stamped = await recorder
      .endRecording()
      .toImage(pixelsWide, pixelsHigh);
  final rgba = await stamped.toByteData(format: ui.ImageByteFormat.rawRgba);
  source.dispose();
  stamped.dispose();
  if (rgba == null) return photo;

  final jpeg = await compute(
    _encodeJpeg,
    (
      bytes: rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
      width: pixelsWide,
      height: pixelsHigh,
    ),
  );
  return CapturedPhoto(
    bytes: jpeg,
    filename: 'geo-${stamp.takenAt.millisecondsSinceEpoch}.jpg',
  );
}

ui.Paragraph _paragraph(
  String text, {
  required double size,
  required FontWeight weight,
  required Color color,
  required double maxWidth,
}) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
    fontSize: size,
    fontWeight: weight,
    maxLines: 2,
    ellipsis: '…',
    height: 1.2,
  ))
    ..pushStyle(ui.TextStyle(
      color: color,
      fontFamily: 'Inter',
      shadows: const [Shadow(color: Color(0x66000000), blurRadius: 2)],
    ))
    ..addText(text);
  return builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
}

// Runs off the UI thread (on mobile): encoding a 1600 px JPEG in Dart takes a
// noticeable moment.
Uint8List _encodeJpeg(({Uint8List bytes, int width, int height}) raw) {
  final image = img.Image.fromBytes(
    width: raw.width,
    height: raw.height,
    bytes: raw.bytes.buffer,
    numChannels: 4,
  );
  return img.encodeJpg(image, quality: 85);
}
