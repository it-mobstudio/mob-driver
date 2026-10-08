import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/driver/data/realtime/driver_realtime.dart';

import '../../support/fake_socket.dart';

void main() {
  late RealtimeRig rig;

  setUp(() => rig = RealtimeRig());
  tearDown(() => rig.realtime.dispose());

  Future<void> settle([int ms = 10]) => RealtimeRig.settle(ms);

  test('authenticates in the first frame, and is live once the server says ready', () async {
    rig.realtime.start();
    await settle();

    expect(rig.socket.sent.first, {'type': 'auth', 'token': 'token-1'});
    expect(rig.realtime.status.value, RealtimeStatus.connecting);

    rig.socket.serverSends({'type': 'ready'});
    await settle();
    expect(rig.realtime.status.value, RealtimeStatus.live);
  });

  test('turns server frames into pushes, ignoring what it does not know', () async {
    final pushes = <RealtimePush>[];
    rig.realtime.pushes.listen(pushes.add);
    final socket = await rig.goLive();

    socket.serverSends({'type': 'trip.changed', 'event': 'trip.assigned', 'trip_id': 't1'});
    socket.serverSends({'type': 'driver.changed'});
    socket.serverSends({'type': 'something.from.the.future'});
    socket.serverSends({'type': 'trip.changed'}); // no trip id: dropped
    await settle();

    expect(pushes, hasLength(2));
    expect((pushes[0] as TripChanged).tripId, 't1');
    expect((pushes[0] as TripChanged).event, 'trip.assigned');
    expect(pushes[1], isA<ProfileChanged>());
  });

  test('sends a location only once live', () async {
    rig.realtime.start();
    await settle();
    expect(rig.realtime.sendLocation(12.9, 77.5), isFalse);

    rig.socket.serverSends({'type': 'ready'});
    await settle();
    expect(rig.realtime.sendLocation(12.9, 77.5), isTrue);
    expect(rig.socket.sentOfType('location').single, {'type': 'location', 'lat': 12.9, 'lng': 77.5});
  });

  test('a dropped connection is re-opened', () async {
    final first = await rig.goLive();
    await first.serverCloses(1006);
    await settle(60);

    expect(rig.sockets, hasLength(2));
    expect(first.closedByApp, isTrue);
    expect(rig.socket.sent.first['type'], 'auth');
  });

  test('a refused token is refreshed once, then the new one is used', () async {
    final first = await rig.goLive();
    await first.serverCloses(DriverRealtime.closeUnauthorized);
    await settle(30);

    expect(rig.refreshes, 1);
    expect(rig.socket.sent.first, {'type': 'auth', 'token': 'token-2'});
  });

  test('no answer to a ping means the connection is dead: it reconnects', () async {
    rig = RealtimeRig(heartbeat: const Duration(milliseconds: 20));
    await rig.goLive();

    await settle(120);

    expect(rig.sockets.length, greaterThan(1));
    expect(rig.sockets.first.sentOfType('ping'), isNotEmpty);
  });

  test('answered pings keep the same connection', () async {
    rig = RealtimeRig(
      heartbeat: const Duration(milliseconds: 20),
      pongTimeout: const Duration(milliseconds: 200),
    );
    final socket = await rig.goLive();
    for (var i = 0; i < 4; i++) {
      await settle(25);
      socket.serverSends({'type': 'pong'});
    }
    await settle();

    expect(rig.sockets, hasLength(1));
    expect(rig.realtime.isLive, isTrue);
  });

  test('stop closes it and keeps it closed', () async {
    final socket = await rig.goLive();
    rig.realtime.stop();
    await settle(60);

    expect(rig.realtime.status.value, RealtimeStatus.off);
    expect(socket.closedByApp, isTrue);
    expect(rig.sockets, hasLength(1));
  });

  test('without a token it waits instead of connecting', () async {
    rig.token = null;
    rig.realtime.start();
    await settle(30);
    expect(rig.sockets, isEmpty);

    rig.token = 'token-1';
    await settle(60);
    expect(rig.sockets, isNotEmpty);
  });

  test('backoff doubles up to the cap, jittered into its upper half', () {
    final realtime = DriverRealtime(
      url: Uri.parse('ws://test/'),
      accessToken: () => null,
      refreshToken: () async => null,
      maxBackoff: const Duration(seconds: 30),
    );
    addTearDown(realtime.dispose);

    for (final (failures, base) in [(0, 1000), (1, 2000), (3, 8000), (10, 30000), (60, 30000)]) {
      for (var i = 0; i < 50; i++) {
        final ms = realtime.nextBackoff(failures).inMilliseconds;
        expect(ms, inInclusiveRange(base ~/ 2, base), reason: 'after $failures failures');
      }
    }
  });
}
