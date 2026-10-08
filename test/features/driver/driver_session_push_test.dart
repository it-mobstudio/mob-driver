import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/features/driver/data/location/driver_location_service.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';

import '../../support/fake_socket.dart';
import '../../support/fakes.dart';

/// The session with a push socket: trips arrive by push, not by polling.
void main() {
  late FakeDriverRepository repo;
  late FakeLocationService location;
  late RealtimeRig socketRig;
  late DriverSessionCubit cubit;
  late List<DriverEvent> events;

  Future<void> settle([int ms = 20]) => RealtimeRig.settle(ms);
  int activeTripCalls() => repo.calls.where((c) => c == 'activeTrip').length;

  setUp(() {
    repo = FakeDriverRepository();
    location = FakeLocationService();
    socketRig = RealtimeRig();
    cubit = DriverSessionCubit(
      repository: repo,
      location: location,
      realtime: socketRig.realtime,
      pingInterval: const Duration(hours: 1),
      // Fast, so a test would notice if the fallback kept polling while live.
      pollInterval: const Duration(milliseconds: 20),
      minLocationGap: Duration.zero,
    );
    events = [];
    cubit.events.listen(events.add);
  });

  tearDown(() async {
    await cubit.close();
    await socketRig.realtime.dispose();
    await location.stream.close();
  });

  /// Loaded, on duty, with the socket authenticated.
  Future<FakeSocket> onDutyAndLive() async {
    repo.profileValue = fakeProfile(online: true);
    await cubit.load();
    await settle();
    socketRig.socket.serverSends({'type': 'ready'});
    await settle();
    return socketRig.socket;
  }

  test(
      'a signed-in driver connects even off duty (to hear about document review)',
      () async {
    await cubit.load();
    await settle();
    expect(socketRig.sockets, hasLength(1));
  });

  test('while live, it does not poll for trips', () async {
    await onDutyAndLive();
    final before = activeTripCalls();
    await settle(120);
    expect(activeTripCalls(), before);
  });

  test('a trip push fetches the trip once and announces it', () async {
    final socket = await onDutyAndLive();
    final before = activeTripCalls();

    repo.activeTripValue = fakeTrip();
    socket.serverSends({
      'type': 'trip.changed',
      'event': 'trip.assigned',
      'trip_id': repo.activeTripValue!.id
    });
    await settle();

    expect(activeTripCalls(), before + 1);
    expect(cubit.state.activeTrip?.status, TripStatus.assigned);
    expect(events.single, isA<NewTripAssigned>());
  });

  test('pushes for a trip reach screens waiting on it', () async {
    final socket = await onDutyAndLive();
    final changed = <String>[];
    cubit.tripChanges.listen(changed.add);

    socket.serverSends({
      'type': 'trip.changed',
      'event': 'trip.payment_collected',
      'trip_id': 't9'
    });
    await settle();

    expect(changed, ['t9']);
  });

  test('a profile push reloads the profile', () async {
    final socket = await onDutyAndLive();
    final before = repo.calls.where((c) => c == 'profile').length;

    socket.serverSends({'type': 'driver.changed'});
    await settle();

    expect(repo.calls.where((c) => c == 'profile').length, before + 1);
  });

  test(
      'when the socket drops, the fallback poll takes over; when it is back, it catches up',
      () async {
    final socket = await onDutyAndLive();
    await socket.serverCloses(1006);
    final dropped = activeTripCalls();
    // Reconnected but not yet authenticated: still "down", so polling runs.
    await settle(100);
    expect(activeTripCalls(), greaterThan(dropped));

    final beforeLive = activeTripCalls();
    socketRig.socket.serverSends({'type': 'ready'});
    await settle(40);
    final afterCatchUp = activeTripCalls();
    expect(afterCatchUp, greaterThan(beforeLive),
        reason: 'a catch-up sync on reconnect');

    await settle(120);
    expect(activeTripCalls(), afterCatchUp,
        reason: 'live again: polling stops');
  });

  test('locations go over the socket while it is live, not as HTTP requests',
      () async {
    final socket = await onDutyAndLive();
    final httpBefore = repo.pings.length;

    location.stream
        .add(const GeoPoint(12.99, 77.61)); // ~2 km away: worth sending
    await settle();

    expect(socket.sentOfType('location').last,
        {'type': 'location', 'lat': 12.99, 'lng': 77.61});
    expect(repo.pings.length, httpBefore);
  });

  test('GPS wobble of a few metres is not sent', () async {
    final socket = await onDutyAndLive();
    location.stream.add(const GeoPoint(12.99, 77.61));
    await settle();
    final sent = socket.sentOfType('location').length;

    location.stream.add(const GeoPoint(12.99005, 77.61005)); // ~7 m
    await settle();

    expect(socket.sentOfType('location').length, sent);
  });

  test('a demand hint is kept while waiting, and dropped once a trip comes',
      () async {
    final socket = await onDutyAndLive();
    socket.serverSends({'type': 'driver.hint', 'message': 'Busy near MG Road'});
    await settle();
    expect(cubit.demandHint.value?.message, 'Busy near MG Road');

    repo.activeTripValue = fakeTrip();
    socket.serverSends({
      'type': 'trip.changed',
      'event': 'trip.assigned',
      'trip_id': repo.activeTripValue!.id
    });
    await settle();
    expect(cubit.demandHint.value, isNull);
  });

  test('signing out closes the socket', () async {
    final socket = await onDutyAndLive();
    cubit.reset();
    await settle();
    expect(socket.closedByApp, isTrue);
    expect(socketRig.realtime.isLive, isFalse);
  });
}
