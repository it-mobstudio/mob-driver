import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';

/// The white header shared by the dashboard and incoming-order map: opaque,
/// so the map starts below it rather than showing through behind the pill.
class DutyHeaderSurface extends StatelessWidget {
  const DutyHeaderSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        // Status-bar icons that contrast with the header.
        value: AppColors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14001533),
                  blurRadius: 12,
                  offset: Offset(0, 2)),
            ],
          ),
          child: SafeArea(bottom: false, child: child),
        ),
      );
}

/// SOS and the duty pill on the left, the profile button on the right — shared by
/// the map home screen and the incoming-order screen, so the two always look
/// the same. A null [onToggle]/[onProfileTap] makes that part decorative
/// (shown, not interactive) rather than disabled-looking: the incoming-order
/// screen's job is Accept/Reject, not going off duty or browsing the menu.
class DutyStatusRow extends StatelessWidget {
  const DutyStatusRow({
    super.key,
    required this.online,
    this.busy = false,
    this.onToggle,
    this.onProfileTap,
    this.onSos,
    this.avatar,
  });

  final bool online;
  final bool busy;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onProfileTap;

  final VoidCallback? onSos;

  /// The driver's picture or initial for the profile button (an icon if null).
  final Widget? avatar;

  /// Both sides get the same width, so the duty pill sits exactly in the
  /// middle of the screen.
  static const _side = 44.0;
  static const _sideSlot = 68.0;

  @override
  Widget build(BuildContext context) {
    final pill = _DutyPill(online: online, busy: busy, onToggle: onToggle);
    // With SOS: SOS and the duty pill together on the left, profile on the
    // right. Without it (the incoming-order screen) the pill stays centred.
    if (onSos != null) {
      return Row(children: [
        _sosButton(),
        const SizedBox(width: 10),
        Flexible(child: pill),
        const Spacer(),
        const SizedBox(width: 10),
        _profileButton(),
      ]);
    }
    return Row(children: [
      const SizedBox(width: _sideSlot),
      Expanded(child: Center(child: pill)),
      SizedBox(
        width: _sideSlot,
        child: Align(alignment: Alignment.centerRight, child: _profileButton()),
      ),
    ]);
  }

  Widget _sosButton() => Material(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const Key('sos_button'),
          borderRadius: BorderRadius.circular(12),
          onTap: onSos,
          child: SizedBox(
            width: 64,
            height: 40,
            child: Center(
              child: Text(tr('SOS'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: .4)),
            ),
          ),
        ),
      );

  Widget _profileButton() => Material(
        color: AppColors.navy,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('profile_button'),
          customBorder: const CircleBorder(),
          onTap: onProfileTap,
          child: SizedBox(
            width: _side,
            height: _side,
            child: avatar ??
                const Icon(Icons.person_rounded, color: Colors.white, size: 26),
          ),
        ),
      );
}

class _DutyPill extends StatelessWidget {
  const _DutyPill(
      {required this.online, required this.busy, required this.onToggle});
  final bool online;
  final bool busy;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: 46,
        padding: const EdgeInsets.only(left: 18, right: 4),
        decoration: BoxDecoration(
          color: online ? AppColors.greenSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(online ? tr('On Duty') : tr('Off Duty'),
                key: const Key('duty_status'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: online ? AppColors.ink : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          const SizedBox(width: 6),
          if (busy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(AppColors.blue))),
            )
          else
            // IgnorePointer (not a null onChanged) so a decorative switch
            // still reads as vividly "on" instead of greyed-out/disabled.
            IgnorePointer(
              ignoring: onToggle == null,
              child: Transform.scale(
                scale: .9,
                child: Switch.adaptive(
                  key: const Key('duty_switch'),
                  value: online,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF22B455),
                  onChanged: onToggle ?? (_) {},
                ),
              ),
            ),
        ]),
      );
}

/// Today's earnings, as a slim bar under the duty row. A null [onTap] makes
/// it decorative.
class TodayEarningsBanner extends StatelessWidget {
  const TodayEarningsBanner({
    super.key,
    required this.todayEarnings,
    this.onTap,
  });

  final double todayEarnings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('summary_banner'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(children: [
              Expanded(
                child: Text(tr('Today’s earnings'),
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
              Text(formatMoneyShort(todayEarnings),
                  key: const Key('stat_earnings_teaser'),
                  style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -.2)),
              if (onTap != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: AppColors.card, shape: BoxShape.circle),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppColors.ink, size: 18),
                ),
              ],
            ]),
          ),
        ),
      );
}
