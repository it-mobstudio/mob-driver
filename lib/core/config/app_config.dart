class AppConfig {
  const AppConfig._();

  // Use --dart-define=API_BASE_URL=... to override per environment.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://uat.madoverbuilding.com/api',
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
}
