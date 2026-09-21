import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last profile and stats the backend sent, kept on the device so the
/// dashboard can paint instantly on the next launch while fresh data loads
/// (show what we knew, then correct it), instead of opening on a spinner.
///
/// Stores the raw JSON rather than entities, so the cache can never drift from
/// what the parsers accept. Two independent keys — the profile and stats calls
/// run in parallel, and a shared blob would let one overwrite the other.
///
/// It is personal data (name, phone, KYC status), so it is tied to the signed-in
/// driver and wiped on sign-out.
class DriverSnapshotCache {
  DriverSnapshotCache({
    Future<SharedPreferences> Function()? prefs,
    this.currentDriverId,
  }) : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  /// The id of whoever is signed in now. A cached profile for anyone else is
  /// ignored — e.g. a session that ended without a clean sign-out.
  final String? Function()? currentDriverId;

  static const _meKey = 'driver_snapshot_me_v1';
  static const _statsKey = 'driver_snapshot_stats_v1';

  Future<void> saveProfile(Map<String, dynamic> me) => _write(_meKey, me);

  Future<void> saveStats(Map<String, dynamic> stats) =>
      _write(_statsKey, stats);

  Future<({Map<String, dynamic>? me, Map<String, dynamic>? stats})>
      read() async {
    final me = await _read(_meKey);
    final signedIn = currentDriverId?.call();
    if (me != null && signedIn != null && me['id']?.toString() != signedIn) {
      await clear();
      return (me: null, stats: null);
    }
    // Stats carry no owner of their own; they're only trusted alongside a
    // profile that passed the check above.
    return (me: me, stats: me == null ? null : await _read(_statsKey));
  }

  Future<void> clear() async {
    try {
      final prefs = await _prefs();
      await prefs.remove(_meKey);
      await prefs.remove(_statsKey);
    } catch (_) {}
  }

  Future<void> _write(String key, Map<String, dynamic> value) async {
    try {
      await (await _prefs()).setString(key, jsonEncode(value));
    } catch (_) {
      // A cache that can't be written just means a slower next launch.
    }
  }

  Future<Map<String, dynamic>?> _read(String key) async {
    try {
      final raw = (await _prefs()).getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}
