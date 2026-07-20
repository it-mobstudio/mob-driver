import 'package:m_o_b_demand_side/core/network/dio_client.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.message,
  });

  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final String message;

  factory AppVersionInfo.fromMap(Map<String, dynamic> map) {
    return AppVersionInfo(
      latestVersion: _stringValue(
        map,
        const ['latest_version', 'latestVersion', 'latest'],
      ),
      minimumVersion: _stringValue(
        map,
        const ['minimum_version', 'minimumVersion', 'min_version'],
      ),
      forceUpdate:
          _boolValue(map, const ['force_update', 'forceUpdate', 'force']),
      message: (map['message'] ?? '').toString(),
    );
  }
}

class AppUpdateDecision {
  const AppUpdateDecision({
    required this.info,
    required this.currentVersion,
    required this.updateAvailable,
    required this.forceUpdate,
  });

  final AppVersionInfo info;
  final String currentVersion;
  final bool updateAvailable;
  final bool forceUpdate;
}

/// Fetches the backend's published app-version info. Returns null on any
/// failure (missing/unreachable endpoint, malformed body) — an update check
/// must never block or break the account page.
Future<AppVersionInfo?> fetchAppVersionInfo() async {
  try {
    final response =
        await DioClient.instance.dio.get<dynamic>('/utility/app-version/');
    final body = response.data;
    final data = _versionPayload(body);
    if (data == null) return null;
    return AppVersionInfo.fromMap(data);
  } catch (_) {
    return null;
  }
}

AppUpdateDecision? evaluateAppUpdate({
  required AppVersionInfo info,
  required String currentVersion,
}) {
  final latestVersion = info.latestVersion.trim();
  final minimumVersion = info.minimumVersion.trim();
  if (latestVersion.isEmpty && minimumVersion.isEmpty) return null;

  final belowLatest =
      latestVersion.isNotEmpty && isVersionOlder(currentVersion, latestVersion);
  final belowMinimum = minimumVersion.isNotEmpty &&
      isVersionOlder(currentVersion, minimumVersion);
  final updateAvailable = belowLatest || belowMinimum;
  if (!updateAvailable) {
    return AppUpdateDecision(
      info: info,
      currentVersion: currentVersion,
      updateAvailable: false,
      forceUpdate: false,
    );
  }

  return AppUpdateDecision(
    info: info,
    currentVersion: currentVersion,
    updateAvailable: true,
    forceUpdate: belowMinimum || info.forceUpdate,
  );
}

/// True if [current] is an older dotted version than [latest] (e.g. "1.0.1"
/// vs "1.0.2"). Missing/non-numeric segments count as 0, and the shorter of
/// the two is zero-padded, so "1.0" vs "1.0.1" correctly reports outdated.
bool isVersionOlder(String current, String latest) {
  final currentParts =
      current.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  final latestParts =
      latest.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  final length = currentParts.length > latestParts.length
      ? currentParts.length
      : latestParts.length;
  for (var i = 0; i < length; i++) {
    final c = i < currentParts.length ? currentParts[i] : 0;
    final l = i < latestParts.length ? latestParts[i] : 0;
    if (c != l) return c < l;
  }
  return false;
}

Map<String, dynamic>? _versionPayload(dynamic body) {
  if (body is! Map) return null;
  final map = Map<String, dynamic>.from(body);
  if (map['success'] == false) return null;
  final data = map['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List) {
    for (final item in data) {
      if (item is Map) return Map<String, dynamic>.from(item);
    }
  }
  if (map['latest_version'] != null ||
      map['latestVersion'] != null ||
      map['minimum_version'] != null ||
      map['minimumVersion'] != null) {
    return map;
  }
  return null;
}

String _stringValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

bool _boolValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
  }
  return false;
}
