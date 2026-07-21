import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_version_checker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _androidPackageId = 'com.madoverbuildings.app';

bool _appUpdatePromptShown = false;

Future<void> checkAndShowAppUpdatePrompt(BuildContext context) async {
  if (kIsWeb) return;
  if (_appUpdatePromptShown) return;

  final info = await fetchAppVersionInfo();
  if (!context.mounted || info == null) return;

  final packageInfo = await PackageInfo.fromPlatform();
  if (!context.mounted) return;

  final decision = evaluateAppUpdate(
    info: info,
    currentVersion: packageInfo.version,
  );
  if (decision == null || !decision.updateAvailable) return;

  _appUpdatePromptShown = true;
  showAppUpdatePrompt(context, decision);
}

void showAppUpdatePrompt(
  BuildContext context,
  AppUpdateDecision decision,
) {
  final forceUpdate = decision.forceUpdate;
  final message = decision.info.message.trim().isNotEmpty
      ? decision.info.message.trim()
      : 'A new version of the app is available.';

  showDialog<void>(
    context: context,
    barrierDismissible: !forceUpdate,
    builder: (dialogContext) => PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        title: const Text('Update available'),
        content: Text(message),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
          TextButton(
            onPressed: () {
              if (!forceUpdate) Navigator.of(dialogContext).pop();
              openAppUpdateStore();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    ),
  );
}

Future<void> openAppUpdateStore() async {
  final Uri uri;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    uri = Uri.parse('itms-beta://');
  } else {
    uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_androidPackageId',
    );
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
