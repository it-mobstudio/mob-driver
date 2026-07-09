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
      latestVersion: (map['latestVersion'] ?? '').toString(),
      minimumVersion: (map['minimumVersion'] ?? '').toString(),
      forceUpdate: map['forceUpdate'] == true,
      message: (map['message'] ?? '').toString(),
    );
  }
}

/// Fetches the backend's published app-version info. Returns null on any
/// failure (missing/unreachable endpoint, malformed body) — an update check
/// must never block or break the account page.
Future<AppVersionInfo?> fetchAppVersionInfo() async {
  try {
    final response =
        await DioClient.instance.dio.get<dynamic>('/utility/app-version/');
    final body = response.data;
    if (body is! Map || body['success'] != true) return null;
    final data = body['data'];
    if (data is! Map) return null;
    return AppVersionInfo.fromMap(Map<String, dynamic>.from(data));
  } catch (_) {
    return null;
  }
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
