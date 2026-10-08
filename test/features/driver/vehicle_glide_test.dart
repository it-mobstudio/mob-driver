import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mob_driver/features/driver/presentation/widgets/map/vehicle_glide.dart';

void main() {
  // ~111 m per 0.001° of latitude.
  const start = LatLng(26.8500, 80.9400);
  const north = LatLng(26.8510, 80.9400);
  const east = LatLng(26.8510, 80.9411);

  group('geometry', () {
    test('bearings are compass degrees, clockwise from north', () {
      expect(VehicleGlide.bearingBetween(start, north), closeTo(0, .5));
      expect(VehicleGlide.bearingBetween(north, start), closeTo(180, .5));
      expect(VehicleGlide.bearingBetween(north, east), closeTo(90, .5));
      expect(VehicleGlide.distanceMeters(start, north), closeTo(111, 1));
    });
  });

  group('driving', () {
    testWidgets('the first fix places the vehicle, facing north',
        (tester) async {
      final glide = VehicleGlide(vsync: const TestVSync(), onTick: () {});
      expect(glide.position, isNull);
      glide.moveTo(start);
      expect(glide.position, start);
      expect(glide.bearing, 0);
      glide.dispose();
    });

    testWidgets('it glides to the next fix and turns to face it',
        (tester) async {
      var ticks = 0;
      final glide = VehicleGlide(vsync: tester, onTick: () => ticks++);
      glide.moveTo(start);
      glide.moveTo(north, animate: false); // driving north
      glide.moveTo(east); // then a right turn

      await tester.pump(); // the first frame starts the clock
      await tester.pump(const Duration(milliseconds: 550)); // half way
      final mid = glide.position!;
      expect(mid.longitude, greaterThan(north.longitude));
      expect(mid.longitude, lessThan(east.longitude),
          reason: 'still on its way, not jumped');
      expect(glide.bearing, inInclusiveRange(1, 89), reason: 'mid-turn');

      await tester.pump(const Duration(seconds: 1));
      expect(glide.position, east);
      expect(glide.bearing, closeTo(90, .5));
      expect(ticks, greaterThan(2),
          reason: 'the map is told to redraw as it moves');
      glide.dispose();
    });

    testWidgets(
        'it turns the short way round: 350° to 10° is a small right turn',
        (tester) async {
      final glide = VehicleGlide(vsync: tester, onTick: () {});
      const a = LatLng(26.85, 80.94);
      // Head ~350° (north, a touch west)...
      final b = LatLng(a.latitude + .001, a.longitude - .00019);
      glide.moveTo(a);
      glide.moveTo(b, animate: false);
      expect(glide.bearing, closeTo(350, 1.5));
      // ...then ~10° (north, a touch east).
      glide.moveTo(LatLng(b.latitude + .001, b.longitude + .00019));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 550));
      final mid = glide.bearing;
      expect(mid > 340 || mid < 20, isTrue,
          reason: 'never swings through south (got $mid)');
      await tester.pump(const Duration(seconds: 1));
      expect(glide.bearing, closeTo(10, 1.5));
      glide.dispose();
    });

    testWidgets('GPS wobble of a metre or two does not spin a parked vehicle',
        (tester) async {
      final glide = VehicleGlide(vsync: tester, onTick: () {});
      glide.moveTo(start);
      glide.moveTo(north, animate: false); // facing north
      glide.moveTo(const LatLng(26.85099, 80.94001)); // ~1 m south-east
      await tester.pump(const Duration(seconds: 2));
      expect(glide.bearing, closeTo(0, .5));
      glide.dispose();
    });

    testWidgets('a big relocation jumps instead of racing across the city',
        (tester) async {
      final glide = VehicleGlide(vsync: tester, onTick: () {});
      glide.moveTo(start);
      const far = LatLng(26.90, 81.10); // ~17 km
      glide.moveTo(far);
      expect(glide.position, far, reason: 'there at once');
      glide.dispose();
    });
  });
}
