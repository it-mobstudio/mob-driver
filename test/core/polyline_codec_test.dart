import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';

void main() {
  test('decodes Google\'s documented precision-5 example', () {
    // https://developers.google.com/maps/documentation/utilities/polylinealgorithm
    final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@', precision: 5);

    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 1e-9));
    expect(points[0].longitude, closeTo(-120.2, 1e-9));
    expect(points[1].latitude, closeTo(40.7, 1e-9));
    expect(points[1].longitude, closeTo(-120.95, 1e-9));
    expect(points[2].latitude, closeTo(43.252, 1e-9));
    expect(points[2].longitude, closeTo(-126.453, 1e-9));
  });

  test('decodes the backend\'s Valhalla shape at precision 6', () {
    // Produced by the backend's encoder (core/testing.py) for
    // (12.975, 77.605) → (12.9765, 77.62) → (12.9783, 77.6408).
    final points = decodePolyline('ox|vWogs_sCw|Aoh\\ooB_sg@', precision: 6);

    expect(points, hasLength(3));
    expect(points.first.latitude, closeTo(12.975, 1e-6));
    expect(points.first.longitude, closeTo(77.605, 1e-6));
    expect(points.last.latitude, closeTo(12.9783, 1e-6));
    expect(points.last.longitude, closeTo(77.6408, 1e-6));
  });

  test('the precision really matters: decoding a precision-6 shape as 5 is 10x off', () {
    const shape = 'ox|vWogs_sCw|Aoh\\ooB_sg@';
    final right = decodePolyline(shape, precision: 6).first;
    final wrong = decodePolyline(shape, precision: 5).first;

    expect(wrong.latitude, closeTo(right.latitude * 10, 1e-4));
    expect(wrong.latitude, greaterThan(90), reason: 'not even a valid latitude');
  });

  test('empty / null give an empty route', () {
    expect(decodePolyline(null), isEmpty);
    expect(decodePolyline(''), isEmpty);
  });

  test('a truncated string yields the points before the break instead of throwing', () {
    const full = 'ox|vWogs_sCw|Aoh\\ooB_sg@';
    final partial = decodePolyline(full.substring(0, full.length - 3));

    expect(partial.length, lessThan(3));
    expect(partial, isNotEmpty);
  });

  test('handles negative coordinates (southern / western hemispheres)', () {
    final points = decodePolyline('_p~iF~ps|U', precision: 5);
    expect(points.single.longitude, lessThan(0));
  });
}
