import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_version_checker.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _androidPackageId = 'com.madoverbuildings.app';
const _iosAppId = '6784914110';

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
  showDialog<void>(
    context: context,
    barrierDismissible: !decision.forceUpdate,
    barrierColor: Colors.black.withValues(alpha: .6),
    builder: (dialogContext) => _UpdateAvailableDialog(decision: decision),
  );
}

class _UpdateAvailableDialog extends StatelessWidget {
  const _UpdateAvailableDialog({required this.decision});

  final AppUpdateDecision decision;

  static const _navy = Color(0xFF0A243F);
  static const _blue = Color(0xFF0360E5);

  @override
  Widget build(BuildContext context) {
    final forceUpdate = decision.forceUpdate;
    final message = decision.info.message.trim().isNotEmpty
        ? decision.info.message.trim()
        : 'A new version of the app is available.';

    return PopScope(
      canPop: !forceUpdate,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/updateavailable.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Update available',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 26 / 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF596378),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (!forceUpdate) ...[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _navy,
                            side: const BorderSide(color: Color(0xFFDEDEDE)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Later',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 21 / 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!forceUpdate) Navigator.of(context).pop();
                          openAppUpdateStore();
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Update now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 21 / 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openAppUpdateStore() async {
  final Uri uri;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    uri = Uri.parse('https://apps.apple.com/app/id$_iosAppId');
  } else {
    uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$_androidPackageId',
    );
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
