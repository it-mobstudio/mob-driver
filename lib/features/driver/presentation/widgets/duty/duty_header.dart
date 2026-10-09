import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
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

/// The duty pill, centred, with the profile button on the right — shared by
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
    this.avatar,
  });

  final bool online;
  final bool busy;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onProfileTap;

  /// The driver's picture or initial for the profile button (an icon if null).
  final Widget? avatar;

  /// Both sides get the same width, so the duty pill sits exactly in the
  /// middle of the screen.
  static const _side = 44.0;

  @override
  Widget build(BuildContext context) => Row(children: [
        const SizedBox(width: _side),
        Expanded(
          child: Center(
              child: _DutyPill(online: online, busy: busy, onToggle: onToggle)),
        ),
        _profileButton(),
      ]);

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

/// Working time while online, or today's earnings while not. A null [onTap]
/// makes it decorative.
class WorkingTimeBanner extends StatelessWidget {
  const WorkingTimeBanner({
    super.key,
    required this.online,
    required this.dutyStartedAt,
    required this.todayEarnings,
    this.onTap,
  });

  final bool online;
  final ValueListenable<DateTime?> dutyStartedAt;
  final double todayEarnings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = TextStyle(
        color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500);
    final value = TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: -.2);
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('summary_banner'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  online
                      ? Icons.timer_outlined
                      : Icons.account_balance_wallet_outlined,
                  size: 19,
                  color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(online ? tr('Working time') : tr('Today’s earnings'),
                        style: label),
                    const SizedBox(height: 2),
                    online
                        ? ValueListenableBuilder<DateTime?>(
                            valueListenable: dutyStartedAt,
                            builder: (_, since, __) =>
                                _ElapsedLabel(since: since, style: value),
                          )
                        : Text(formatMoneyShort(todayEarnings),
                            key: const Key('stat_earnings_teaser'),
                            style: value),
                  ]),
            ),
            if (onTap != null) ...[
              Text(online ? tr('Today') : tr('Stats'),
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ElapsedLabel extends StatefulWidget {
  const _ElapsedLabel({required this.since, required this.style});
  final DateTime? since;
  final TextStyle style;

  @override
  State<_ElapsedLabel> createState() => _ElapsedLabelState();
}

class _ElapsedLabelState extends State<_ElapsedLabel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final since = widget.since;
    final text = since == null
        ? '—'
        : formatDuration(DateTime.now().difference(since).inSeconds);
    return Text(text, key: const Key('working_time'), style: widget.style);
  }
}
