import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:m_o_b_demand_side/features/driver/data/media/geo_stamp.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';

import '../../support/fonts.dart';

final _stamp = GeoStamp(
  latitude: 12.971598,
  longitude: 77.594566,
  takenAt: DateTime(2026, 5, 16, 10, 25),
  caption: '#MOB9867855HJ · Pickup · Brass shower',
  address: 'Unit 14, Peenya Industrial Area, Bengaluru, 560058',
);

void main() {
  setUpAll(loadAppFonts);

  test('the stamp reads address, coordinates, time and what it shows', () {
    final lines = _stamp.lines;
    expect(lines.first, 'Unit 14, Peenya Industrial Area, Bengaluru, 560058');
    expect(lines[1], 'Lat 12.971598°  Long 77.594566°');
    expect(lines[2], startsWith('16/05/2026 10:25 AM GMT'));
    expect(lines.last, '#MOB9867855HJ · Pickup · Brass shower');
  });

  test('without an address the coordinates lead', () {
    expect(_stamp.withAddress(null).lines.first, startsWith('Lat 12.971598°'));
  });

  testWidgets('the stamp is drawn into the bottom of the picture as a JPEG', (tester) async {
    // A plain white 800x600 "photo".
    final white = img.Image(width: 800, height: 600)
      ..clear(img.ColorRgb8(255, 255, 255));
    final photo = CapturedPhoto(
        bytes: img.encodeJpg(white), filename: 'shot.jpg');

    final stamped = await tester.runAsync(() => renderGeoStamp(photo, _stamp));

    expect(stamped!.filename, endsWith('.jpg'));
    final decoded = img.decodeJpg(stamped.bytes)!;
    expect((decoded.width, decoded.height), (800, 600));
    // Top untouched, bottom darkened by the band.
    expect(decoded.getPixel(400, 20).r, greaterThan(240));
    expect(decoded.getPixel(790, 590).r, lessThan(120));

    final out = Platform.environment['GEO_STAMP_PREVIEW'];
    if (out != null) File(out).writeAsBytesSync(stamped.bytes);
  });
}
