import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:from_css_color/from_css_color.dart';

import '../lat_lng.dart';
import '../place.dart';
import '../uploaded_file.dart';

String dateTimeRangeToString(DateTimeRange range) {
  final start = range.start.millisecondsSinceEpoch;
  final end = range.end.millisecondsSinceEpoch;
  return '$start|$end';
}

DateTimeRange? dateTimeRangeFromString(String value) {
  final pieces = value.split('|');
  if (pieces.length != 2) {
    return null;
  }
  final start = int.tryParse(pieces.first);
  final end = int.tryParse(pieces.last);
  if (start == null || end == null) {
    return null;
  }
  return DateTimeRange(
    start: DateTime.fromMillisecondsSinceEpoch(start),
    end: DateTime.fromMillisecondsSinceEpoch(end),
  );
}

String placeToString(FFPlace place) => jsonEncode(
      <String, dynamic>{
        'latLng': place.latLng.serialize(),
        'name': place.name,
        'address': place.address,
        'city': place.city,
        'state': place.state,
        'country': place.country,
        'zipCode': place.zipCode,
      },
    );

FFPlace placeFromString(String value) {
  final map = jsonDecode(value);
  if (map is! Map) {
    return const FFPlace();
  }
  final data = Map<String, dynamic>.from(map);
  return FFPlace(
    latLng: latLngFromString(data['latLng']?.toString()) ??
        const LatLng(0.0, 0.0),
    name: data['name']?.toString() ?? '',
    address: data['address']?.toString() ?? '',
    city: data['city']?.toString() ?? '',
    state: data['state']?.toString() ?? '',
    country: data['country']?.toString() ?? '',
    zipCode: data['zipCode']?.toString() ?? '',
  );
}

String uploadedFileToString(FFUploadedFile uploadedFile) =>
    uploadedFile.serialize();

FFUploadedFile uploadedFileFromString(String value) =>
    FFUploadedFile.deserialize(value);

LatLng? latLngFromString(String? value) {
  if (value == null) {
    return null;
  }
  final pieces = value.split(',');
  if (pieces.length != 2) {
    return null;
  }
  final lat = double.tryParse(pieces.first.trim());
  final lng = double.tryParse(pieces.last.trim());
  if (lat == null || lng == null) {
    return null;
  }
  return LatLng(lat, lng);
}

enum ParamType {
  intType,
  doubleType,
  string,
  boolType,
  dateTime,
  dateTimeRange,
  latLng,
  color,
  ffPlace,
  ffUploadedFile,
  json,
}

String? serializeParam(
  dynamic param,
  ParamType type, {
  bool isList = false,
}) {
  if (param == null) {
    return null;
  }

  if (isList) {
    final iterable = param is Iterable ? param : <dynamic>[param];
    final serialized = <String>[];
    for (final item in iterable) {
      final value = serializeParam(item, type);
      if (value != null) {
        serialized.add(value);
      }
    }
    return jsonEncode(serialized);
  }

  switch (type) {
    case ParamType.intType:
    case ParamType.doubleType:
    case ParamType.string:
      return param.toString();
    case ParamType.boolType:
      return param == true ? 'true' : 'false';
    case ParamType.dateTime:
      return (param as DateTime).millisecondsSinceEpoch.toString();
    case ParamType.dateTimeRange:
      return dateTimeRangeToString(param as DateTimeRange);
    case ParamType.latLng:
      return (param as LatLng).serialize();
    case ParamType.color:
      return (param as Color).toCssString();
    case ParamType.ffPlace:
      return placeToString(param as FFPlace);
    case ParamType.ffUploadedFile:
      return uploadedFileToString(param as FFUploadedFile);
    case ParamType.json:
      return jsonEncode(param);
  }
}

T? deserializeParam<T>(
  String? param,
  ParamType type,
  bool isList,
) {
  if (param == null) {
    return null;
  }

  if (isList) {
    final decoded = jsonDecode(param);
    if (decoded is! Iterable) {
      return null;
    }

    final list = <dynamic>[];
    for (final item in decoded.whereType<String>()) {
      final value = deserializeParam<dynamic>(item, type, false);
      if (value != null) {
        list.add(value);
      }
    }
    return list as T;
  }

  switch (type) {
    case ParamType.intType:
      return int.tryParse(param) as T?;
    case ParamType.doubleType:
      return double.tryParse(param) as T?;
    case ParamType.string:
      return param as T;
    case ParamType.boolType:
      return (param == 'true') as T;
    case ParamType.dateTime:
      final ms = int.tryParse(param);
      if (ms == null) {
        return null;
      }
      return DateTime.fromMillisecondsSinceEpoch(ms) as T;
    case ParamType.dateTimeRange:
      return dateTimeRangeFromString(param) as T?;
    case ParamType.latLng:
      return latLngFromString(param) as T?;
    case ParamType.color:
      return fromCssColor(param) as T;
    case ParamType.ffPlace:
      return placeFromString(param) as T;
    case ParamType.ffUploadedFile:
      return uploadedFileFromString(param) as T;
    case ParamType.json:
      return jsonDecode(param) as T;
  }
}
