class AppConfig {
  const AppConfig._();

  static final Uri _server =
      Uri.parse('https://earring-barbed-willing.ngrok-free.dev/');

  static const String sentryDsn =
      'https://e6f444c8d09b089d88b8a9b572c55c27@o4510619510505472.ingest.de.sentry.io/4511732953841744';

  static String get apiBaseUrl => _server.resolve('api/v1/').toString();

  /// Prevent ngrok's browser interstitial from replacing API responses.
  static Map<String, String> get apiTunnelHeaders => {
        if (const ['.ngrok-free.dev', '.ngrok-free.app', '.ngrok.app']
            .any(_server.host.endsWith))
          'ngrok-skip-browser-warning': '1',
      };

  static Uri get realtimeUrl => _server
      .resolve('ws/driver/')
      .replace(scheme: _server.scheme == 'https' ? 'wss' : 'ws');

  /// Points links to our own `/media/` files at the current server.
  static String ourMediaUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url;
    if (!uri.hasScheme) return _server.resolve(url.trim()).toString();
    if (!uri.path.startsWith('/media/')) return url;
    return uri
        .replace(scheme: _server.scheme, host: _server.host, port: _server.port)
        .toString();
  }
}
