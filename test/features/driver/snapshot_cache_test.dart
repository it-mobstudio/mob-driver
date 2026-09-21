import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/features/driver/data/local/driver_snapshot_cache.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes.dart';
import '../../support/scripted_adapter.dart';

void main() {
  late SharedPreferences prefs;
  String? signedInAs = 'd-1';

  DriverSnapshotCache build() => DriverSnapshotCache(
        prefs: () async => prefs,
        currentDriverId: () => signedInAs,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    signedInAs = 'd-1';
  });

  test('round-trips the profile and stats', () async {
    final cache = build();
    await cache.saveProfile(profileJson(online: true));
    await cache.saveStats({'today': {'trips_completed': 3}});

    final stored = await cache.read();

    expect(stored.me?['full_name'], 'Seed Driver 1');
    expect(stored.stats?['today'], {'trips_completed': 3});
  });

  test('starts empty', () async {
    final stored = await build().read();
    expect(stored.me, isNull);
    expect(stored.stats, isNull);
  });

  test('a snapshot belonging to someone else is never shown, and is wiped', () async {
    final cache = build();
    await cache.saveProfile(profileJson()); // id d-1
    await cache.saveStats({'today': {'trips_completed': 9}});

    signedInAs = 'another-driver';
    final stored = await cache.read();

    expect(stored.me, isNull);
    expect(stored.stats, isNull, reason: 'stats have no owner of their own — they follow the profile');
    expect(prefs.getKeys(), isEmpty, reason: 'and the stale data is removed, not just hidden');
  });

  test('stats are ignored when there is no profile to vouch for them', () async {
    final cache = build();
    await cache.saveStats({'today': {'trips_completed': 9}});
    expect((await cache.read()).stats, isNull);
  });

  test('clear() removes everything (sign-out)', () async {
    final cache = build();
    await cache.saveProfile(profileJson());
    await cache.saveStats({'today': <String, dynamic>{}});
    await cache.clear();
    expect(prefs.getKeys(), isEmpty);
  });

  test('corrupt stored JSON is treated as "nothing cached", not a crash', () async {
    await prefs.setString('driver_snapshot_me_v1', '{not json');
    final stored = await build().read();
    expect(stored.me, isNull);
  });

  test('with no signed-in id to check against, the snapshot is still read', () async {
    signedInAs = null;
    final cache = build();
    await cache.saveProfile(profileJson());
    expect((await cache.read()).me, isNotNull);
  });

  group('DriverRepositoryImpl fills and reads the cache', () {
    late ScriptedAdapter adapter;
    late DriverRepositoryImpl repo;

    setUp(() {
      adapter = ScriptedAdapter()
        ..on('GET', '/driver/me', profileJson(online: true))
        ..on('GET', '/driver/stats', {
          'today': {'trips_completed': 2, 'total_fare': '185.00'},
          'all_time': {'trips_completed': 9},
        });
      repo = DriverRepositoryImpl(DriverRemoteDatasource(scriptedDio(adapter)), cache: build());
    });

    test('a successful fetch is what the next launch paints', () async {
      final before = await repo.cachedSnapshot();
      expect(before.profile, isNull);

      await repo.profile();
      await repo.stats();
      await Future<void>.delayed(Duration.zero); // cache writes are fire-and-forget

      final after = await repo.cachedSnapshot();
      expect(after.profile?.fullName, 'Seed Driver 1');
      expect(after.profile?.isOnline, isTrue);
      expect(after.stats?.today.tripsCompleted, 2);
      expect(after.stats?.today.totalFare, 185.0);
    });

    test('a FAILED fetch leaves the previous snapshot alone', () async {
      await repo.profile();
      await Future<void>.delayed(Duration.zero);

      adapter.on('GET', '/driver/me', {'detail': 'boom'}, status: 500);
      final (profile, failure) = await repo.profile();

      expect(profile, isNull);
      expect(failure, isNotNull);
      expect((await repo.cachedSnapshot()).profile?.fullName, 'Seed Driver 1');
    });

    test('clearCache empties it', () async {
      await repo.profile();
      await Future<void>.delayed(Duration.zero);
      await repo.clearCache();
      expect((await repo.cachedSnapshot()).profile, isNull);
    });
  });
}
