import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'dart:typed_data';

import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';

import '../../support/fakes.dart';

void main() {
  late FakeDriverRepository repo;
  late FakeLocationService location;
  late DriverSessionCubit cubit;
  late List<DriverEvent> events;

  DriverSessionCubit build() => DriverSessionCubit(
        repository: repo,
        location: location,
        // Fast timers so polling tests don't wait real seconds.
        pingInterval: const Duration(milliseconds: 30),
        pollInterval: const Duration(milliseconds: 30),
      );

  Future<void> settle([int ms = 100]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    repo = FakeDriverRepository();
    location = FakeLocationService();
    cubit = build();
    events = [];
    cubit.events.listen(events.add);
  });

  tearDown(() async {
    await cubit.close();
    await location.stream.close();
  });

  group('load', () {
    test('populates profile, stats and no active trip; stays idle while offline', () async {
      await cubit.load();

      expect(cubit.state.load, SessionLoad.ready);
      expect(cubit.state.profile?.fullName, 'Seed Driver 1');
      expect(cubit.state.activeTrip, isNull);
      expect(cubit.state.isOnline, isFalse);
      await settle();
      expect(repo.pings, isEmpty, reason: 'an offline driver must not be pinging');
    });

    test('a profile failure on first load is surfaced', () async {
      repo.profileFailure = const NetworkFailure();
      await cubit.load();
      expect(cubit.state.load, SessionLoad.failed);
      expect(cubit.state.loadError, contains('internet'));
    });

    test('a failed silent refresh keeps what was already showing', () async {
      await cubit.load();
      repo.profileFailure = const NetworkFailure();
      await cubit.load(silent: true);
      expect(cubit.state.load, SessionLoad.ready);
      expect(cubit.state.profile, isNotNull);
    });

    test('resumes tracking when the server says the driver is already online', () async {
      repo.profileValue = fakeProfile(online: true);
      await cubit.load();
      await settle();
      expect(repo.pings, isNotEmpty);
    });

    test('an existing trip at startup is shown without a "new trip" alert', () async {
      repo.profileValue = fakeProfile(online: true);
      repo.activeTripValue = fakeTrip();
      await cubit.load();
      await settle();
      expect(cubit.state.activeTrip?.status, TripStatus.assigned);
      expect(events, isEmpty);
    });
  });

  group('cache-first first paint', () {
    test('paints the cached profile and stats while the network is still answering', () async {
      repo.cachedProfile = fakeProfile();
      repo.cachedStats = const DriverStats(today: PeriodStats(tripsCompleted: 5));
      repo.profileGate = Completer<void>(); // a slow network

      final loading = cubit.load();
      await settle(20);

      // On screen already — no spinner, no waiting.
      expect(cubit.state.load, SessionLoad.ready);
      expect(cubit.state.profile?.fullName, 'Seed Driver 1');
      expect(cubit.state.stats.today.tripsCompleted, 5);
      // ...but a trip is never guessed at from the cache.
      expect(cubit.state.tripKnown, isFalse);
      expect(cubit.state.activeTrip, isNull);

      repo.profileGate!.complete();
      await loading;
      expect(cubit.state.tripKnown, isTrue);
    });

    test('the network answer replaces the cached one', () async {
      repo.cachedProfile = fakeProfile(); // remembered as offline
      repo.profileValue = fakeProfile(online: true); // actually online now
      await cubit.load();
      expect(cubit.state.profile?.isOnline, isTrue);
    });

    test('a cached "online" does NOT start GPS pings — only the backend\'s answer does', () async {
      repo.cachedProfile = fakeProfile(online: true);
      repo.profileGate = Completer<void>();

      final loading = cubit.load();
      await settle(120);
      expect(repo.pings, isEmpty, reason: 'nothing has been confirmed with the server yet');

      repo.profileValue = fakeProfile(); // server says: actually offline
      repo.profileGate!.complete();
      await loading;
      await settle(120);
      expect(repo.pings, isEmpty);
    });

    test('with no network AND a cache, the driver still sees their dashboard', () async {
      repo.cachedProfile = fakeProfile();
      repo.profileFailure = const NetworkFailure();

      await cubit.load();

      expect(cubit.state.load, SessionLoad.ready);
      expect(cubit.state.profile?.fullName, 'Seed Driver 1');
    });

    test('with no network and NO cache it is a proper error', () async {
      repo.profileFailure = const NetworkFailure();
      await cubit.load();
      expect(cubit.state.load, SessionLoad.failed);
    });

    test('reset() wipes the on-device cache', () async {
      await cubit.load();
      cubit.reset();
      await settle(10);
      expect(repo.clearCacheCalls, 1);
    });

    test('a trip call that FAILS still ends the placeholder (best knowledge, not forever)', () async {
      repo.activeTripFailure = const NetworkFailure();
      await cubit.load();
      expect(cubit.state.tripKnown, isTrue);
    });
  });

  group('duty', () {
    test('goOnline sends the first GPS fix with the vehicle and starts pinging', () async {
      await cubit.load();

      final failure = await cubit.goOnline('v-1');

      expect(failure, isNull);
      expect(repo.calls, contains('startDuty:v-1:12.9716,77.5946'));
      expect(cubit.state.isOnline, isTrue);
      expect(cubit.state.dutyBusy, isFalse);
      await settle();
      expect(repo.pings, isNotEmpty);
      expect(repo.pings.first.lat, closeTo(12.9716, 1e-9));
    });

    test('goOnline refuses (without calling the backend) when there is no GPS fix', () async {
      await cubit.load();
      location.fix = null;

      final failure = await cubit.goOnline('v-1');

      expect(failure?.message, contains('location'));
      expect(repo.calls.where((c) => c.startsWith('startDuty')), isEmpty);
      expect(cubit.state.isOnline, isFalse);
      expect(cubit.state.dutyBusy, isFalse);
    });

    test('a backend rejection is returned and leaves the driver offline', () async {
      await cubit.load();
      repo.startDutyFailure =
          const BusinessFailure('This vehicle is being used by another driver.', code: 'VEHICLE_IN_USE');

      final failure = await cubit.goOnline('v-1');

      expect(failure?.code, 'VEHICLE_IN_USE');
      expect(cubit.state.isOnline, isFalse);
      await settle();
      expect(repo.pings, isEmpty);
    });

    test('goOffline stops the pings', () async {
      await cubit.load();
      await cubit.goOnline('v-1');
      await settle();

      expect(await cubit.goOffline(), isNull);
      await settle(60);
      final pingsAfterStop = repo.pings.length;
      await settle(120);

      expect(cubit.state.isOnline, isFalse);
      expect(repo.pings.length, pingsAfterStop);
    });

    test('goOffline is refused while a trip is active and keeps tracking', () async {
      repo.profileValue = fakeProfile(online: true);
      repo.activeTripValue = fakeTrip();
      await cubit.load();
      repo.endDutyFailure = const BusinessFailure(
          'This driver has an active trip and cannot go offline.',
          code: 'DRIVER_HAS_ACTIVE_TRIP');

      final failure = await cubit.goOffline();

      expect(failure?.code, 'DRIVER_HAS_ACTIVE_TRIP');
      expect(cubit.state.isOnline, isTrue);
    });

    test('the live position stream feeds the pings', () async {
      await cubit.load();
      await cubit.goOnline('v-1');
      location.stream.add(const GeoPoint(12.99, 77.61));
      await settle();
      expect(repo.pings.last.lat, closeTo(12.99, 1e-9));
    });

    test('a failing GPS stream flags the location as unavailable, and recovers', () async {
      await cubit.load();
      await cubit.goOnline('v-1');

      location.stream.addError(Exception('GPS off'));
      await settle(20);
      expect(cubit.state.locationUnavailable, isTrue);

      location.stream.add(const GeoPoint(12.97, 77.59));
      await settle(20);
      expect(cubit.state.locationUnavailable, isFalse);
    });
  });

  test('a driver resumed as online with no location permission is flagged, then recovers once a fix is possible', () async {
    location.fix = null; // permission not granted yet
    repo.profileValue = fakeProfile(online: true);
    await cubit.load();
    await settle(80);
    expect(cubit.state.locationUnavailable, isTrue);
    expect(repo.pings, isEmpty);

    location.fix = const GeoPoint(12.97, 77.59); // they tapped Fix and allowed it
    await settle(120);

    expect(cubit.state.locationUnavailable, isFalse);
    expect(repo.pings, isNotEmpty);
  });

  group('trip polling', () {
    setUp(() async {
      repo.profileValue = fakeProfile(online: true);
      await cubit.load();
    });

    test('a trip assigned while online raises exactly one NewTripAssigned', () async {
      repo.activeTripValue = fakeTrip();
      await settle(150); // several polls

      expect(cubit.state.activeTrip?.id, '604807b6-7053-4f5f-bf99-163eb9620dc3');
      expect(events.whereType<NewTripAssigned>(), hasLength(1));
    });

    test('a network error during a poll is not mistaken for the trip vanishing', () async {
      repo.activeTripValue = fakeTrip();
      await settle(80);
      events.clear();

      repo.activeTripFailure = const NetworkFailure();
      repo.activeTripValue = null;
      await settle(150);

      expect(cubit.state.activeTrip, isNotNull);
      expect(events, isEmpty);
    });

    test('progress made elsewhere is reflected (status change, no new alert)', () async {
      repo.activeTripValue = fakeTrip();
      await settle(80);
      events.clear();

      repo.activeTripValue = fakeTrip(status: 'arrived_at_pickup');
      await settle(100);

      expect(cubit.state.activeTrip?.status, TripStatus.arrivedAtPickup);
      expect(events, isEmpty);
    });

    test('the company cancelling the trip raises TripEndedExternally with its final state', () async {
      repo.activeTripValue = fakeTrip();
      await settle(80);
      events.clear();

      repo.tripsById['604807b6-7053-4f5f-bf99-163eb9620dc3'] =
          Trip.fromJson(tripJson(status: 'cancelled', cancelledBy: 'company', cancellationReason: 'Order cancelled'));
      repo.activeTripValue = null;
      await settle(120);

      expect(cubit.state.activeTrip, isNull);
      final ended = events.whereType<TripEndedExternally>().single;
      expect(ended.trip.status, TripStatus.cancelled);
      expect(ended.trip.cancelledByCompany, isTrue);
      expect(ended.trip.cancellationReason, 'Order cancelled');
    });
  });

  group('trip actions', () {
    const id = '604807b6-7053-4f5f-bf99-163eb9620dc3';

    setUp(() async {
      repo.profileValue = fakeProfile(online: true);
      repo.activeTripValue = fakeTrip();
      await cubit.load();
    });

    test('arrive adopts the server\'s updated trip', () async {
      repo.actionResult = (fakeTrip(status: 'arrived_at_pickup'), null);

      final (trip, failure) = await cubit.arrive(id);

      expect(failure, isNull);
      expect(trip?.status, TripStatus.arrivedAtPickup);
      expect(cubit.state.activeTrip?.status, TripStatus.arrivedAtPickup);
      expect(cubit.state.tripBusy, isFalse);
    });

    test('a rejected action returns the failure and leaves the trip untouched', () async {
      repo.actionResult = (
        null,
        const BusinessFailure('Trip must be arrived.', code: 'INVALID_TRIP_STATUS_TRANSITION')
      );

      final (trip, failure) = await cubit.startTrip(id);

      expect(trip, isNull);
      expect(failure?.code, 'INVALID_TRIP_STATUS_TRANSITION');
      expect(cubit.state.activeTrip?.status, TripStatus.assigned);
      expect(cubit.state.tripBusy, isFalse);
    });

    test('completing clears the active trip, refreshes stats, and passes the OTP through', () async {
      repo.actionResult = (fakeTrip(status: 'completed', paymentStatus: 'paid'), null);

      final (trip, _) = await cubit.complete(id, otp: '123456');

      expect(trip?.status, TripStatus.completed);
      expect(repo.calls, contains('complete[123456]:$id'));
      expect(cubit.state.activeTrip, isNull);
    });

    test('a poll that was already in flight cannot resurrect a just-completed trip', () async {
      repo.activeTripValue = fakeTrip(status: 'in_progress');
      await settle(80);

      // A poll goes out while the trip is still in progress, and its (slow)
      // response is held back...
      repo.activeTripGate = Completer<void>();
      await settle(60);
      // ...meanwhile the driver completes the trip.
      repo.actionResult = (fakeTrip(status: 'completed', paymentStatus: 'paid'), null);
      await cubit.complete(id, otp: '123456');
      expect(cubit.state.activeTrip, isNull);

      // The stale "still in progress" answer now arrives.
      repo.activeTripValue = null;
      repo.activeTripGate!.complete();
      repo.activeTripGate = null;
      await settle(150);

      expect(cubit.state.activeTrip, isNull);
      expect(events.whereType<NewTripAssigned>(), isEmpty,
          reason: 'the finished trip must not be re-announced as a new assignment');
      expect(events.whereType<TripEndedExternally>(), isEmpty,
          reason: 'the driver ended it themself — not an external cancellation');
    });

    test('a second action while one is in flight is refused, not queued', () async {
      repo.actionGate = Completer<void>();
      repo.actionResult = (fakeTrip(status: 'arrived_at_pickup'), null);

      final first = cubit.arrive(id);
      await Future<void>.delayed(Duration.zero);
      final (second, failure) = await cubit.arrive(id);

      expect(second, isNull);
      expect(failure, isNotNull);
      repo.actionGate!.complete();
      await first;
      expect(repo.calls.where((c) => c.startsWith('arrive')), hasLength(1));
    });

    test('collecting COD payment refreshes the trip so the OTP step appears', () async {
      repo.tripsById[id] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');

      final (sent, failure) = await cubit.collectPayment(id);

      expect(failure, isNull);
      expect(sent?.debugOtp, '123456');
      expect(cubit.state.activeTrip?.needsDeliveryOtp, isTrue);
    });

    test('ALREADY_PAID still refreshes the (stale) local trip', () async {
      repo.collectResult = (null, const BusinessFailure('already paid', code: 'ALREADY_PAID'));
      repo.tripsById[id] = fakeTrip(status: 'in_progress', paymentStatus: 'paid');

      final (_, failure) = await cubit.collectPayment(id);

      expect(failure?.code, 'ALREADY_PAID');
      expect(cubit.state.activeTrip?.isPaid, isTrue);
    });
  });

  test('reset stops tracking and forgets the previous driver', () async {
    repo.profileValue = fakeProfile(online: true);
    await cubit.load();
    await settle(80);

    cubit.reset();
    final before = repo.pings.length;
    await settle(120);

    expect(cubit.state.profile, isNull);
    expect(cubit.state.load, SessionLoad.initial);
    expect(repo.pings.length, before);
  });

  group('onboarding', () {
    DriverProfile signedUp({String status = 'profile_incomplete'}) => DriverProfile.fromJson(profileJson(
          eligible: false,
          onboarding: status,
          fullName: status == 'profile_incomplete' ? '' : 'Ravi Kumar',
          profileComplete: status != 'profile_incomplete',
        ));

    CapturedPhoto photo() => CapturedPhoto(bytes: Uint8List(2), filename: 'a.jpg');

    test('a new driver needs onboarding; one who is waiting on the company does not', () async {
      repo.profileValue = signedUp();
      await cubit.load();
      expect(cubit.state.needsOnboarding, isTrue);

      repo.profileChangeResult = signedUp(status: 'documents_required');
      await cubit.updateProfile(const ProfileUpdate(fullName: 'Ravi Kumar'));
      expect(cubit.state.needsOnboarding, isTrue, reason: 'documents are still to come');

      repo.profileChangeResult = signedUp(status: 'under_review');
      await cubit.submitAadhar(number: '234567890123', front: photo(), back: photo());
      expect(cubit.state.needsOnboarding, isFalse, reason: 'their turn is over — now it is the company\'s');
    });

    test('nothing is forced on the driver before their profile is known', () {
      expect(cubit.state.profile, isNull);
      expect(cubit.state.needsOnboarding, isFalse);
    });

    test('every profile-changing call adopts the profile the backend answered with', () async {
      repo.profileValue = signedUp();
      await cubit.load();

      repo.profileChangeResult = signedUp(status: 'documents_required');
      expect(await cubit.updateProfile(const ProfileUpdate(fullName: 'Ravi Kumar')), isNull);
      expect(cubit.state.profile?.fullName, 'Ravi Kumar');
      expect(repo.profileUpdates.single.fullName, 'Ravi Kumar');

      await cubit.uploadPhoto(photo());
      await cubit.submitLicence(number: 'KA01 20110012345', expiry: DateTime(2027, 3, 1), front: photo());
      await cubit.submitPolice(photo());
      expect(repo.calls, containsAll(['updateProfile', 'uploadPhoto', 'submitLicence', 'submitPolice']));
      expect(repo.licenceSubmissions.single.hasBack, isFalse);
    });

    test('a refusal is handed back and the profile stays as it was', () async {
      repo.profileValue = signedUp();
      await cubit.load();
      repo.profileChangeFailure = const BusinessFailure('You must be at least 18 years old.', code: 'VALIDATION_ERROR');

      final failure = await cubit.updateProfile(ProfileUpdate(dateOfBirth: DateTime(2015)));

      expect(failure?.message, 'You must be at least 18 years old.');
      expect(cubit.state.profile?.onboardingStatus, OnboardingStatus.profileIncomplete);
    });

    test('deleting the account forgets everything; a refusal leaves the session intact', () async {
      repo.profileValue = fakeProfile();
      await cubit.load();

      repo.deleteAccountFailure = const BusinessFailure('You still have money in your wallet.', code: 'WALLET_BALANCE_PENDING');
      final refused = await cubit.deleteAccount();
      expect(refused?.code, 'WALLET_BALANCE_PENDING');
      expect(cubit.state.profile, isNotNull);
      expect(repo.clearCacheCalls, 0);

      repo.deleteAccountFailure = null;
      expect(await cubit.deleteAccount(), isNull);
      expect(cubit.state.profile, isNull);
      expect(repo.clearCacheCalls, 1, reason: 'personal data must not outlive the account');
    });
  });

  group('wallet', () {
    test('the summary and statement are read through the session', () async {
      repo.walletValue = const WalletSummary(balance: 260, today: WalletPeriod(earnings: 150, trips: 1));
      repo.walletEntriesValue = [
        const WalletEntry(id: 'a', kind: WalletKind.payout, amount: -40, balanceAfter: 60),
        const WalletEntry(id: 'b', kind: WalletKind.tripEarning, amount: 100, balanceAfter: 100),
      ];

      final (summary, _) = await cubit.loadWallet();
      final (page, _) = await cubit.loadWalletEntries(kinds: [WalletKind.payout]);

      expect(summary?.balance, 260);
      expect(page?.items.map((e) => e.id), ['a']);
      expect(repo.walletEntryCalls, ['1:payout']);
    });
  });

  group('item verification', () {
    setUp(() async {
      repo.startItemTrip([itemJson(id: 'a'), itemJson(id: 'b', name: 'TMT bar')]);
      repo.profileValue = fakeProfile(online: true);
      await cubit.load();
    });

    test('an answer updates the live trip in place', () async {
      expect(cubit.state.activeTrip?.pendingItemCount, 2);

      final (trip, failure) = await cubit.verifyItem(cubit.state.activeTrip!.id, 'a', status: ItemStatus.delivered);

      expect(failure, isNull);
      expect(trip?.resolvedItemCount, 1);
      expect(cubit.state.activeTrip?.items.first.status, ItemStatus.delivered);
      expect(cubit.state.activeTrip?.needsItemVerification, isTrue, reason: 'one item still to go');
    });

    test('the photo and the reason travel with the answer', () async {
      final id = cubit.state.activeTrip!.id;
      await cubit.verifyItem(id, 'b',
          status: ItemStatus.notDelivered, note: 'Damaged', photo: CapturedPhoto(bytes: Uint8List(3)));

      final answer = repo.itemAnswers.single;
      expect((answer.itemId, answer.status, answer.note, answer.hasPhoto), ('b', ItemStatus.notDelivered, 'Damaged', true));
      expect(cubit.state.activeTrip?.items.last.proofImageUrl, isNotNull);
    });

    test('answering everything clears the verification requirement', () async {
      final id = cubit.state.activeTrip!.id;
      await cubit.verifyItem(id, 'a', status: ItemStatus.delivered);
      await cubit.verifyItem(id, 'b', status: ItemStatus.notDelivered, note: 'Out of stock');
      expect(cubit.state.activeTrip?.needsItemVerification, isFalse);
    });

    test('taking an answer back makes the item pending again', () async {
      final id = cubit.state.activeTrip!.id;
      await cubit.verifyItem(id, 'a', status: ItemStatus.delivered, photo: CapturedPhoto(bytes: Uint8List(1)));

      final (trip, _) = await cubit.resetItem(id, 'a');

      expect(trip?.items.first.status, ItemStatus.pending);
      expect(trip?.items.first.proofImageUrl, isNull);
    });

    test('a refusal leaves the trip untouched and reports why', () async {
      repo.verifyItemFailure = const BusinessFailure('Items are verified at the drop.', code: 'TRIP_NOT_IN_PROGRESS');
      final before = cubit.state.activeTrip;

      final (trip, failure) = await cubit.verifyItem(before!.id, 'a', status: ItemStatus.delivered);

      expect(trip, isNull);
      expect(failure?.code, 'TRIP_NOT_IN_PROGRESS');
      expect(cubit.state.activeTrip, before);
      expect(cubit.state.tripBusy, isFalse);
    });

    test('a poll that was already in flight cannot put back an answer the driver just changed', () async {
      final id = cubit.state.activeTrip!.id;
      // The poll asks the server while item "a" is still pending…
      final staleTrip = cubit.state.activeTrip;
      repo.activeTripValue = staleTrip;
      repo.activeTripGate = Completer<void>();
      final poll = cubit.pollNow();

      // …and the driver confirms it before that answer arrives.
      await cubit.verifyItem(id, 'a', status: ItemStatus.delivered);
      repo.activeTripGate!.complete();
      await poll;

      expect(cubit.state.activeTrip?.items.first.status, ItemStatus.delivered);
    });
  });
}
