class AppConfig {
  const AppConfig._();

  // Use --dart-define=API_BASE_URL=... to override per environment.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://uat.madoverbuilding.com/api',
  );

  static const String webAppBaseUrl = String.fromEnvironment(
    'WEB_APP_BASE_URL',
    defaultValue: 'https://mob-demand-side.netlify.app',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyC_dvw8b7g1e1RB9dQj4rAnFyxGD1S2s7Y',
  );

  static Uri apiUri(String path, {Map<String, dynamic>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalizedPath')
        .replace(queryParameters: _stringQuery(queryParameters));
  }

  static Map<String, String>? _stringQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) {
      return null;
    }
    return query.map((key, value) => MapEntry(key, value.toString()));
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
