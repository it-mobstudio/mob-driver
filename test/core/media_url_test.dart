import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/core/config/app_config.dart';

void main() {
  final api = Uri.parse(AppConfig.apiBaseUrl);

  test('our media links follow the server the app talks to now', () {
    // Cached while the phone used another address for the same server.
    final fixed = Uri.parse(AppConfig.ourMediaUrl(
        'http://10.9.8.7:8000/media/co/voice-notes/a.m4a'));
    expect((fixed.scheme, fixed.host, fixed.path),
        (api.scheme, api.host, '/media/co/voice-notes/a.m4a'));
  });

  test('relative media paths get the server added', () {
    expect(Uri.parse(AppConfig.ourMediaUrl('/media/x.m4a')).host, api.host);
  });

  test('localhost media uses the current API host and port', () {
    final fixed = Uri.parse(AppConfig.ourMediaUrl(
        'http://localhost:9999/media/co/voice-notes/a.m4a?token=test'));
    expect(fixed.origin, api.origin);
    expect(fixed.path, '/media/co/voice-notes/a.m4a');
    expect(fixed.query, 'token=test');
  });

  test('links to anywhere else are left alone', () {
    const blob =
        'https://mob.blob.core.windows.net/uploads/co/voice-notes/a.m4a';
    expect(AppConfig.ourMediaUrl(blob), blob);
  });
}
