import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/my_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/my_vehicles_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/profile_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/vehicle_form_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/vehicle_page.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/vehicle_picker_sheet.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/harness.dart';
import '../../support/scripted_adapter.dart';

/// What the backend sends for one of the driver's own vehicles.
Map<String, dynamic> vehicleJson(
        {String id = 'v1', String plate = 'KA05MN7788', int photos = 2}) =>
    {
      'id': id,
      'vehicle_type': {
        'id': 'vt-bike',
        'name': 'Bike',
        'category': 'two_wheeler',
        'icon_image_url': null
      },
      'registration_number': plate,
      'capacity_kg': '20.00',
      'photo_url':
          photos == 0 ? null : 'https://api.example.com/media/$id-0.jpg',
      'photos': [
        for (var i = 0; i < photos; i++)
          {'id': '$id-p$i', 'url': 'https://api.example.com/media/$id-$i.jpg'}
      ],
      'status': 'active',
      'is_current': false,
      'created_at': '2026-09-21T09:20:11.482910Z',
    };

MyVehicle mine(
        {String id = 'v1', String plate = 'KA05MN7788', int photos = 2}) =>
    MyVehicle.fromJson(vehicleJson(id: id, plate: plate, photos: photos));

/// The screens, wired the way the app wires them.
Widget hostVehicles(TestRig rig, {Widget? home}) => rig.host(
      home ?? const MyVehiclesPage(),
      routes: [
        GoRoute(
            path: DriverRoutes.newVehicle,
            builder: (_, __) => VehicleFormPage(capture: rig.capture)),
        GoRoute(
          path: DriverRoutes.editVehiclePattern,
          builder: (_, s) => VehicleFormPage(
            vehicleId: s.pathParameters['id'],
            initial: s.extra is MyVehicle ? s.extra as MyVehicle : null,
            capture: rig.capture,
          ),
        ),
        GoRoute(
            path: DriverRoutes.myVehicles,
            builder: (_, __) => const MyVehiclesPage()),
      ],
    );

Future<void> pickPhoto(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('vehicle_photo_add')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('photo_source_camera')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('what the backend sends', () {
    test('a vehicle with pictures: the main one first, every one listed', () {
      final v = mine(photos: 3);
      expect(v.registrationNumber, 'KA05MN7788');
      expect(v.vehicleTypeName, 'Bike');
      expect(v.categoryLabel, '2 wheeler');
      expect(v.capacityKg, 20.0);
      expect(v.photos.map((p) => p.id), ['v1-p0', 'v1-p1', 'v1-p2']);
      expect(v.photoUrls.first, 'https://api.example.com/media/v1-0.jpg');
      expect(v.photoUrls, hasLength(3));
    });

    test('with no pictures there is nothing to show, not a broken link', () {
      final v = mine(photos: 0);
      expect(v.photoUrl, isNull);
      expect(v.photoUrls, isEmpty);
    });

    test('a vehicle type the driver can choose', () {
      final t = VehicleTypeOption.fromJson(const {
        'id': 'vt',
        'name': 'Tempo',
        'category': 'three_wheeler',
        'default_capacity_kg': '500.00',
        'icon_image_url': null
      });
      expect((t.name, t.categoryLabel, t.defaultCapacityKg),
          ('Tempo', '3 wheeler', 500.0));
    });

    test('the picker learns which vehicles are the driver\'s own', () {
      expect(
          DriverVehicle.fromJson(
                  const {'id': 'a', 'registration_number': 'X', 'is_own': true})
              .isOwn,
          isTrue);
      expect(
          DriverVehicle.fromJson(const {'id': 'a', 'registration_number': 'X'})
              .isOwn,
          isFalse,
          reason: 'fleet vehicles say nothing');
    });
  });

  group('the requests it makes', () {
    late ScriptedAdapter http;
    late DriverRepositoryImpl repo;

    setUp(() {
      http = ScriptedAdapter();
      repo = DriverRepositoryImpl(DriverRemoteDatasource(scriptedDio(http)));
    });

    CapturedPhoto photo(String name) =>
        CapturedPhoto(bytes: kTinyPng, filename: name);

    test('vehicle types → GET driver/vehicle-types', () async {
      http.on('GET', '/driver/vehicle-types', {
        'vehicle_types': [
          {
            'id': 'vt-bike',
            'name': 'Bike',
            'category': 'two_wheeler',
            'default_capacity_kg': '20.00',
            'icon_image_url': null
          }
        ]
      });
      final (types, failure) = await repo.vehicleTypes();
      expect(failure, isNull);
      expect(types!.single.name, 'Bike');
    });

    test('my vehicles → GET driver/my-vehicles', () async {
      http.on('GET', '/driver/my-vehicles', {
        'vehicles': [
          vehicleJson(),
          vehicleJson(id: 'v2', plate: 'KA01AA0001', photos: 0)
        ]
      });
      final (vehicles, _) = await repo.myVehicles();
      expect(vehicles!.map((v) => v.registrationNumber),
          ['KA05MN7788', 'KA01AA0001']);
    });

    test(
        'adding one sends the fields and every picture as its own "photos" part',
        () async {
      http.on('POST', '/driver/my-vehicles', vehicleJson(), status: 201);
      final (vehicle, failure) = await repo.addVehicle(
        vehicleTypeId: 'vt-bike',
        registrationNumber: 'KA05MN7788',
        capacityKg: 35.5,
        photos: [photo('front.jpg'), photo('side.jpg')],
      );
      expect(failure, isNull);
      expect(vehicle!.photos, hasLength(2));

      final sent =
          http.lastRequest('POST', '/driver/my-vehicles').data as FormData;
      expect(sent.fields.map((f) => '${f.key}=${f.value}'), [
        'vehicle_type_id=vt-bike',
        'registration_number=KA05MN7788',
        'capacity_kg=35.5'
      ]);
      expect(sent.files.map((f) => f.key), ['photos', 'photos'],
          reason: 'one part per picture, all named photos');
      expect(
          sent.files.map((f) => f.value.filename), ['front.jpg', 'side.jpg']);
    });

    test('the optional parts are left out when there is nothing to send',
        () async {
      http.on('POST', '/driver/my-vehicles', vehicleJson(photos: 0),
          status: 201);
      await repo.addVehicle(
          vehicleTypeId: 'vt-bike', registrationNumber: 'KA05MN7788');
      final sent =
          http.lastRequest('POST', '/driver/my-vehicles').data as FormData;
      expect(sent.fields.map((f) => f.key),
          ['vehicle_type_id', 'registration_number']);
      expect(sent.files, isEmpty);
    });

    test('correcting one → PATCH with only what changed', () async {
      http.on(
          'PATCH', '/driver/my-vehicles/v1', vehicleJson(plate: 'KA05MN9999'));
      final (vehicle, _) =
          await repo.updateVehicle('v1', registrationNumber: 'KA05MN9999');
      expect(vehicle!.registrationNumber, 'KA05MN9999');
      expect(http.lastRequest('PATCH', '/driver/my-vehicles/v1').data,
          {'registration_number': 'KA05MN9999'});
    });

    test('a picture is added as one "photo" part and removed by its id',
        () async {
      http.on('POST', '/driver/my-vehicles/v1/photos', vehicleJson(photos: 3),
          status: 201);
      http.on('DELETE', '/driver/my-vehicles/v1/photos/v1-p0',
          vehicleJson(photos: 1));
      expect((await repo.addVehiclePhoto('v1', photo('back.jpg'))).$1!.photos,
          hasLength(3));
      expect(
          ((http.lastRequest('POST', '/driver/my-vehicles/v1/photos').data)
                  as FormData)
              .files
              .single
              .key,
          'photo');
      expect((await repo.removeVehiclePhoto('v1', 'v1-p0')).$1!.photos,
          hasLength(1));
    });

    test('removing → DELETE, and the server\'s reason comes back as a failure',
        () async {
      http.on('DELETE', '/driver/my-vehicles/v1', '', status: 204);
      expect(await repo.removeVehicle('v1'), isNull);

      http.on(
          'DELETE',
          '/driver/my-vehicles/v2',
          {
            'success': false,
            'error': {
              'code': 'VEHICLE_ON_DUTY',
              'message':
                  'You\'re on duty with this vehicle. Go off duty before removing it.'
            },
          },
          status: 409);
      final failure = await repo.removeVehicle('v2');
      expect(failure, isA<BusinessFailure>());
      expect(failure!.code, 'VEHICLE_ON_DUTY');
      expect(failure.message, contains('Go off duty'));
    });
  });

  group('the list', () {
    rigTest('with none yet it says so and offers to add one',
        (tester, rig) async {
      await tester.pumpWidget(hostVehicles(rig));
      await tester.pumpAndSettle();

      expect(find.text('No vehicles yet'), findsOneWidget);
      expect(find.byKey(const Key('add_vehicle')), findsOneWidget);
      expect(find.text('Add a vehicle'), findsOneWidget);
    });

    rigTest(
        'each vehicle shows its plate, type, capacity and how many pictures it has',
        (tester, rig) async {
      rig.repo.myVehiclesValue.addAll(
          [mine(photos: 3), mine(id: 'v2', plate: 'KA01AA0001', photos: 0)]);
      await tester.pumpWidget(hostVehicles(rig));
      await tester.pumpAndSettle();

      expect(find.text('KA05MN7788'), findsOneWidget);
      expect(find.text('Bike · 2 wheeler · 20 kg'), findsNWidgets(2));
      expect(find.byKey(const Key('vehicle_photo_count_v1')), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('vehicle_photo_count_v1')),
              matching: find.text('3')),
          findsOneWidget);
      expect(find.byKey(const Key('vehicle_no_photos_v2')), findsOneWidget,
          reason: 'invites adding pictures');
      expect(find.byKey(const Key('vehicle_photo_count_v2')), findsNothing);
    });

    rigTest('the add button stops at the limit and says why',
        (tester, rig) async {
      rig.repo.myVehiclesValue.addAll([
        for (var i = 0; i < kMaxOwnVehicles; i++)
          mine(id: 'v$i', plate: 'KA01AA${1000 + i}', photos: 0)
      ]);
      await tester.pumpWidget(hostVehicles(rig));
      await tester.pumpAndSettle();

      expect(find.text('You have $kMaxOwnVehicles vehicles (the limit)'),
          findsOneWidget);
      expect(
          tester
              .widget<ElevatedButton>(find.descendant(
                  of: find.byKey(const Key('add_vehicle')),
                  matching: find.byType(ElevatedButton)))
              .onPressed,
          isNull);
    });

    rigTest('removing asks first, then retires it — and a refusal is explained',
        (tester, rig) async {
      rig.repo.myVehiclesValue
          .addAll([mine(), mine(id: 'v2', plate: 'KA01AA0001', photos: 1)]);
      await tester.pumpWidget(hostVehicles(rig));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('remove_vehicle_v1')));

      await tester.tap(find.byKey(const Key('remove_vehicle_v1')));
      await tester.pumpAndSettle();
      expect(find.text('Remove KA05MN7788?'), findsOneWidget);
      expect(rig.repo.vehicleCalls, isEmpty,
          reason: 'nothing until they confirm');
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(rig.repo.vehicleCalls, isEmpty);

      rig.repo.myVehicleFailure = const BusinessFailure(
          'You\'re on duty with this vehicle. Go off duty before removing it.',
          code: 'VEHICLE_ON_DUTY');
      await tester.tap(find.byKey(const Key('remove_vehicle_v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_remove_vehicle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Go off duty'), findsOneWidget);
      expect(find.text('KA05MN7788'), findsOneWidget, reason: 'still there');

      await tester.pump(const Duration(seconds: 5));
      rig.repo.myVehicleFailure = null;
      await tester.tap(find.byKey(const Key('remove_vehicle_v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_remove_vehicle')));
      await tester.pumpAndSettle();
      expect(rig.repo.vehicleCalls, ['remove:v1', 'remove:v1']);
      expect(find.text('KA05MN7788'), findsNothing);
      expect(find.text('KA01AA0001'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('adding a vehicle', () {
    Future<void> openForm(WidgetTester tester, TestRig rig) async {
      await tester.pumpWidget(hostVehicles(rig));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_vehicle')));
      await tester.pumpAndSettle();
    }

    rigTest(
        'type, plate, capacity and pictures go up together, and the list shows it',
        (tester, rig) async {
      await openForm(tester, rig);
      expect(find.text('Add a vehicle'), findsOneWidget,
          reason: 'the form\'s title');
      expect(find.text('Bike · 2 wheeler'), findsOneWidget);
      expect(find.text('Tempo · 3 wheeler'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicle_type_vt-bike')));
      await tester.pump();
      expect(find.textContaining('Leave empty for 20 kg, the usual for Bike'),
          findsOneWidget,
          reason: 'the type\'s default is explained');
      await tester.enterText(
          find.byKey(const Key('vehicle_plate')), 'ka05 mn-7788');
      await tester.enterText(find.byKey(const Key('vehicle_capacity')), '35.5');
      await pickPhoto(tester);
      await pickPhoto(tester);
      expect(rig.capture.cameraCalls, 2);
      expect(find.text('MAIN'), findsOneWidget,
          reason: 'the first picture is the main one');
      expect(find.text('PICTURES  ·  2 OF 6'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicle_save')));
      await tester.pumpAndSettle();

      expect(rig.repo.vehicleCalls, ['add:KA05MN-7788:2:vt-bike:35.5'],
          reason: 'spaces dropped, upper-cased');
      expect(find.text('KA05MN-7788'), findsOneWidget,
          reason: 'back on the list, with the new vehicle');
      expect(find.byKey(const Key('vehicle_photo_count_v1')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    rigTest('a picture picked by mistake is taken out before saving',
        (tester, rig) async {
      await openForm(tester, rig);
      await pickPhoto(tester);
      await pickPhoto(tester);
      await tester.tap(find.byKey(const Key('vehicle_photo_remove_0')));
      await tester.pump();
      expect(find.text('PICTURES  ·  1 OF 6'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicle_type_vt-bike')));
      await tester.enterText(
          find.byKey(const Key('vehicle_plate')), 'KA01AA0001');
      await tester.tap(find.byKey(const Key('vehicle_save')));
      await tester.pumpAndSettle();
      expect(rig.repo.vehicleCalls.single, startsWith('add:KA01AA0001:1:'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    rigTest('the add-picture slot goes away at the limit', (tester, rig) async {
      await openForm(tester, rig);
      for (var i = 0; i < kMaxVehiclePhotos; i++) {
        await pickPhoto(tester);
      }
      expect(find.text('PICTURES  ·  6 OF 6'), findsOneWidget);
      expect(find.byKey(const Key('vehicle_photo_add')), findsNothing);
    });

    rigTest('what is missing is said in words and nothing is sent',
        (tester, rig) async {
      await openForm(tester, rig);

      await tester.tap(find.byKey(const Key('vehicle_save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Choose the type of vehicle.'), findsWidgets);
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(find.byKey(const Key('vehicle_type_vt-bike')));
      await tester.tap(find.byKey(const Key('vehicle_save')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Enter the registration number.'), findsWidgets);
      expect(rig.repo.vehicleCalls, isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    rigTest('the server\'s refusal stays on the form, with what to fix',
        (tester, rig) async {
      rig.repo.myVehicleFailure = const BusinessFailure(
          'registration_number: A vehicle with this registration number already exists.');
      await openForm(tester, rig);
      await tester.tap(find.byKey(const Key('vehicle_type_vt-bike')));
      await tester.enterText(
          find.byKey(const Key('vehicle_plate')), 'KA09ZZ0001');
      await tester.tap(find.byKey(const Key('vehicle_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vehicle_error')), findsOneWidget);
      expect(find.textContaining('already exists'), findsWidgets);
      expect(find.byKey(const Key('vehicle_save')), findsOneWidget,
          reason: 'still on the form, entries kept');
      expect(find.text('KA09ZZ0001'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('editing a vehicle', () {
    Future<void> openEdit(WidgetTester tester, TestRig rig) async {
      rig.repo.myVehiclesValue.add(mine(photos: 2));
      await tester.pumpWidget(hostVehicles(rig));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('edit_vehicle_v1')));
      await tester.pumpAndSettle();
    }

    rigTest('opens filled in, with its pictures', (tester, rig) async {
      await openEdit(tester, rig);
      expect(find.text('Edit vehicle'), findsOneWidget);
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: find.byKey(const Key('vehicle_plate')),
                  matching: find.byType(TextField)))
              .controller!
              .text,
          'KA05MN7788');
      expect(find.text('PICTURES  ·  2 OF 6'), findsOneWidget);
      expect(find.byKey(const Key('vehicle_photo_0')), findsOneWidget);
      expect(find.byKey(const Key('vehicle_photo_1')), findsOneWidget);
    });

    rigTest(
        'pictures are added and removed straight away, the main one following',
        (tester, rig) async {
      await openEdit(tester, rig);

      await pickPhoto(tester);
      expect(rig.repo.vehicleCalls, ['photo:v1']);
      expect(find.text('PICTURES  ·  3 OF 6'), findsOneWidget);

      await tester.tap(find.byKey(const Key('vehicle_photo_remove_0')));
      await tester.pumpAndSettle();
      expect(rig.repo.vehicleCalls, ['photo:v1', 'unphoto:v1:v1-p0']);
      expect(find.text('PICTURES  ·  2 OF 6'), findsOneWidget);
    });

    rigTest(
        'a corrected plate is saved, and going back tells the list to refresh',
        (tester, rig) async {
      await openEdit(tester, rig);
      await tester.enterText(
          find.byKey(const Key('vehicle_plate')), 'KA05MN9999');
      await tester.tap(find.byKey(const Key('vehicle_save')));
      await tester.pumpAndSettle();

      expect(rig.repo.vehicleCalls.single, startsWith('update:v1:KA05MN9999:'));
      expect(find.text('KA05MN9999'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    rigTest(
        'a failed picture change is explained and the pictures stay as they were',
        (tester, rig) async {
      await openEdit(tester, rig);
      rig.repo.myVehicleFailure = const BusinessFailure(
          'A vehicle can have up to 6 photos. Remove one to add another.',
          code: 'PHOTO_LIMIT_REACHED');
      await pickPhoto(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('up to 6 photos'), findsWidgets);
      expect(find.text('PICTURES  ·  2 OF 6'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('the way in', () {
    rigTest('the vehicle tab and the profile both lead to it',
        (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      await rig.cubit.load();

      await tester
          .pumpWidget(hostVehicles(rig, home: const DriverVehiclePage()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('my_vehicles_entry')));
      await tester.tap(find.byKey(const Key('my_vehicles_entry')));
      await tester.pumpAndSettle();
      expect(find.text('My vehicles'), findsOneWidget);
      expect(find.text('No vehicles yet'), findsOneWidget);
    });

    rigTest('the picker shows a picture and tags the driver\'s own vehicles',
        (tester, rig) async {
      rig.repo.vehiclesValue = const [
        DriverVehicle(
            id: 'a',
            registrationNumber: 'KA01FLEET01',
            vehicleTypeName: 'Bike',
            category: 'two_wheeler'),
        DriverVehicle(
            id: 'b',
            registrationNumber: 'KA05MN7788',
            vehicleTypeName: 'Bike',
            category: 'two_wheeler',
            isOwn: true,
            photoUrl: 'https://x/b.jpg'),
      ];
      await tester.pumpWidget(rig.host(Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showVehiclePicker(context, loader: rig.cubit.loadVehicles),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('YOURS'), findsOneWidget,
          reason: 'only the driver\'s own vehicle is tagged');
      expect(find.text('KA01FLEET01'), findsOneWidget);
      expect(find.text('KA05MN7788'), findsOneWidget);
    });
  });

  group('the driver\'s own photo', () {
    rigTest(
        'tapping the picture on the profile changes it, from the camera or the gallery',
        (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      await rig.cubit.load();
      await tester
          .pumpWidget(rig.host(DriverProfilePage(capture: rig.capture)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_photo')));
      await tester.pumpAndSettle();
      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo_source_gallery')));
      await tester.pumpAndSettle();
      expect(rig.capture.galleryCalls, 1);
      expect(rig.repo.calls, contains('uploadPhoto'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Profile photo updated.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    rigTest('backing out of the picker changes nothing', (tester, rig) async {
      rig.repo.profileValue = fakeProfile(online: true);
      await rig.cubit.load();
      await tester
          .pumpWidget(rig.host(DriverProfilePage(capture: rig.capture)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_photo')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20)); // dismiss the sheet
      await tester.pumpAndSettle();
      expect(rig.repo.calls, isNot(contains('uploadPhoto')));
    });
  });
}
