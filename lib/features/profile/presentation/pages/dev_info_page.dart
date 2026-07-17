import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:m_o_b_demand_side/core/app_runtime/fcm_token_sync.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Hidden diagnostics screen — reached by tapping the version footer on My
/// Account several times. Gives QA/support the exact build + environment
/// info without needing a separate debug build.
class DevInfoPage extends StatefulWidget {
  const DevInfoPage({super.key});

  static const routeName = 'DevInfo';
  static const routePath = '/dev-info';

  @override
  State<DevInfoPage> createState() => _DevInfoPageState();
}

class _DevInfoPageState extends State<DevInfoPage> {
  PackageInfo? _packageInfo;
  String? _fcmToken;
  // Surfaced in the UI rather than swallowed — this screen exists so
  // QA/support can see *why* a token is missing (e.g. no Play Services on
  // the device) instead of just a blank "Not available".
  String? _fcmTokenError;
  bool _fcmTokenLoaded = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
    if (kIsWeb) {
      _fcmTokenLoaded = true;
    } else {
      resolveFcmToken().then((token) {
        if (!mounted) return;
        setState(() {
          _fcmToken = token;
          _fcmTokenLoaded = true;
        });
      }).catchError((Object error) {
        if (!mounted) return;
        setState(() {
          _fcmTokenError = error.toString();
          _fcmTokenLoaded = true;
        });
      });
    }
  }

  String get _environment {
    final url = AppConfig.apiBaseUrl.toLowerCase();
    if (url.contains('localhost') || url.contains('127.0.0.1')) return 'Dev';
    if (url.contains('uat')) return 'UAT';
    return 'Production';
  }

  String get _platform {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  // This backend's user payload has never actually included a numeric
  // id/pk (nothing else in the app reads one either — accounts are
  // identified by phone/email throughout, e.g. AuthSession.phoneNumber and
  // FcmTokenSync._currentIdentifier). Try the numeric keys first in case a
  // future backend version adds one, then fall back to the identifier the
  // rest of the app already treats as this user's identity, so QA/support
  // always sees which account is signed in instead of a misleading
  // "Not signed in" for an account that has no numeric id.
  String? get _userId {
    final user = AuthSession.instance.userDetails;
    if (user == null) return null;
    for (final key in const [
      'id',
      'user_id',
      'pk',
      'customer_id',
      'account_id',
      'phone_number',
      'phone',
      'mobile',
      'email_or_phone',
      'email',
    ]) {
      final value = user[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    TopSnackBar.show(
      context,
      message: '$label copied',
      type: TopSnackBarType.success,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _packageInfo;
    final userId = _userId;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A243F),
        elevation: 0,
        title: Text(
          'Developer info',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: info == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DevInfoRow(
                  label: 'App Version',
                  value: info.version,
                  onCopy: () => _copy('App version', info.version),
                ),
                _DevInfoRow(
                  label: 'Build Number',
                  value: info.buildNumber,
                  onCopy: () => _copy('Build number', info.buildNumber),
                ),
                _DevInfoRow(label: 'Environment', value: _environment),
                _DevInfoRow(
                  label: 'API URL',
                  value: AppConfig.apiBaseUrl,
                  onCopy: () => _copy('API URL', AppConfig.apiBaseUrl),
                ),
                _DevInfoRow(
                  label: 'Logged-in User ID',
                  value: userId ?? 'Not signed in',
                  onCopy:
                      userId == null ? null : () => _copy('User ID', userId),
                ),
                _DevInfoRow(label: 'Device Platform', value: _platform),
                _DevInfoRow(
                  label: 'FCM Token',
                  value: _fcmTokenValue,
                  onCopy: _fcmToken == null
                      ? null
                      : () => _copy('FCM token', _fcmToken!),
                ),
                const SizedBox(height: 8),
                // Temporary — remove once Sentry's API/perf wiring has been
                // confirmed working against the live dashboard.
                // ElevatedButton(
                //   onPressed: () {
                //     throw StateError('This is test exception');
                //   },
                //   child: const Text('Verify Sentry Setup'),
                // ),
              ],
            ),
    );
  }

  String get _fcmTokenValue {
    if (kIsWeb) {
      return 'Not available on web (no VAPID key configured)';
    }
    if (!_fcmTokenLoaded) return 'Loading…';
    if (_fcmToken != null) return _fcmToken!;
    return _fcmTokenError == null
        ? 'Not available'
        : 'Not available ($_fcmTokenError)';
  }
}

class _DevInfoRow extends StatelessWidget {
  const _DevInfoRow({required this.label, required this.value, this.onCopy});

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF767C8F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: const Color(0xFF767C8F),
                  visualDensity: VisualDensity.compact,
                  onPressed: onCopy,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
