class AppConfig {
  const AppConfig._();

  // Use --dart-define=API_BASE_URL=https://host/api/v1/ to override per
  // environment.
  /// The dev backend's public ngrok tunnel (to `runserver` on :8000), used by
  /// iOS — a real iPhone reaches it from any network, not just the Mac's
  /// Wi-Fi. Free ngrok URLs change when the tunnel restarts: update it here.
  static const String _devTunnelUrl =
      'https://earring-barbed-willing.ngrok-free.dev/';

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Always ends in a single `/`, so it composes with either `path` or
  /// `/path` (see [apiUri]).
  static String get apiBaseUrl {
    final configured = _apiBaseUrlOverride.trim();
    if (configured.isNotEmpty) {
      return configured.endsWith('/') ? configured : '$configured/';
    }
    // Local Django dev server. Inside an Android emulator 127.0.0.1 is the
    // emulator itself; the host machine is reachable at 10.0.2.2. iOS (a real
    // iPhone or the simulator) goes through the ngrok tunnel.
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1/';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1/';
    }
    return '${_devTunnelUrl}api/v1/';
  }

  static const String _realtimeUrlOverride = String.fromEnvironment(
    'REALTIME_URL',
  );

  /// The driver's live connection (`/ws/driver/`) on the same server as
  /// [apiBaseUrl]: `http://host:8000/api/v1/` → `ws://host:8000/ws/driver/`,
  /// `https://…` → `wss://…`. Override with `--dart-define=REALTIME_URL=…`
  /// when the socket is served from elsewhere.
  static Uri get realtimeUrl {
    final configured = _realtimeUrlOverride.trim();
    if (configured.isNotEmpty) return Uri.parse(configured);
    final api = Uri.parse(apiBaseUrl);
    // Whatever prefix the API sits under (a proxy path), minus `api/v1/`.
    final prefix = api.path.replaceFirst(RegExp(r'api/v\d+/?$'), '');
    final base = prefix.endsWith('/') ? prefix : '$prefix/';
    return api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      path: '${base}ws/driver/',
    );
  }

  /// The in-app "update available" prompt asks the backend for the published
  /// app version (`GET utility/app-version/`). This backend doesn't have that
  /// endpoint, so the check is off unless a build opts in with
  /// `--dart-define=APP_UPDATE_CHECK=true` — otherwise every cold start would
  /// spend a request (and a Sentry breadcrumb) on a guaranteed 404.
  static const bool appUpdateCheckEnabled =
      bool.fromEnvironment('APP_UPDATE_CHECK');

  static const String webAppBaseUrl = String.fromEnvironment(
    'WEB_APP_BASE_URL',
    defaultValue: 'https://mob-demand-side.netlify.app',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyC_dvw8b7g1e1RB9dQj4rAnFyxGD1S2s7Y',
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://e6f444c8d09b089d88b8a9b572c55c27@o4510619510505472.ingest.de.sentry.io/4511732953841744',
  );

  static Uri apiUri(String path, {Map<String, dynamic>? queryParameters}) {
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$apiBaseUrl$relativePath')
        .replace(queryParameters: _stringQuery(queryParameters));
  }

  static Map<String, String>? _stringQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) {
      return null;
    }
    return query.map((key, value) => MapEntry(key, value.toString()));
  }

  /// A file our own server hosts (`…/media/…`), re-pointed at the server the
  /// app is talking to *now*. Media links are absolute and get cached with
  /// the trip, so one saved while on the emulator (10.0.2.2), a LAN IP or an
  /// old tunnel would otherwise point at a host this phone can't reach.
  /// Links elsewhere (cloud storage, other sites) are left alone.
  static String ourMediaUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url;
    if (!uri.hasScheme) return resolveMediaUrl(url);
    if (!uri.path.startsWith('/media/')) return url;
    final api = Uri.parse(apiBaseUrl);
    return uri
        .replace(scheme: api.scheme, host: api.host, port: api.port)
        .toString();
  }

  static String resolveMediaUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == 'null') return '';

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) return trimmed;
    if (trimmed.startsWith('//')) {
      final scheme = Uri.parse(apiBaseUrl).scheme;
      return '$scheme:$trimmed';
    }
    if (trimmed.startsWith('/')) {
      final apiUri = Uri.parse(apiBaseUrl);
      return '${apiUri.scheme}://${apiUri.authority}$trimmed';
    }
    return Uri.parse(apiBaseUrl).resolve(trimmed).toString();
  }
}
