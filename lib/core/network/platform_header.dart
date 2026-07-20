import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

String? appPlatformHeaderValue() {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'IOS_APP',
    TargetPlatform.android => 'ANDROID_APP',
    _ => null,
  };
}

void addPlatformHeader(Map<String, dynamic> headers) {
  final platform = appPlatformHeaderValue();
  if (platform == null || platform.isEmpty) return;
  headers['platform'] = platform;
}

Map<String, String> jsonHeadersWithPlatform() {
  final headers = <String, dynamic>{'Content-Type': 'application/json'};
  addPlatformHeader(headers);
  return headers.map((key, value) => MapEntry(key, value.toString()));
}
