import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

/// The duty pill + profile button row — shared by the map home screen and
/// the incoming-order screen, so the two always look the same. A null
/// [onToggle]/[onProfileTap] makes that part decorative (shown, not
/// interactive) rather than disabled-looking: the incoming-order screen's
/// job is Accept/Reject, not going off duty or browsing the menu.
///
/// [onDark] draws it for the navy header (or the dimmed map): frosted glass
/// instead of white. [leading] (the logo) sits on the left when given.
class DutyStatusRow extends StatelessWidget {
  const DutyStatusRow({
    super.key,
    required this.online,
    this.busy = false,
    this.onToggle,
    this.onProfileTap,
    this.onDark = false,
    this.leading,
    this.avatar,
  });

  final bool online;
  final bool busy;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onProfileTap;
  final bool onDark;
  final Widget? leading;

  /// The driver's picture or initial for the profile button (an icon if null).
  final Widget? avatar;

  /// Both sides get the same width, so the duty pill sits exactly in the
  /// middle of the screen whatever the logo and the profile button measure.
  static const _side = 84.0;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
          width: leading == null ? 44 + 12 : _side,
          child: Align(alignment: Alignment.centerLeft, child: leading ?? const SizedBox.shrink()),
        ),
        Expanded(
          child: Center(
              child: _DutyPill(
                  online: online, busy: busy, onToggle: onToggle, onDark: onDark)),
        ),
        SizedBox(
          width: leading == null ? 44 + 12 : _side,
          child: Align(alignment: Alignment.centerRight, child: _profileButton()),
        ),
      ]);

  Widget _profileButton() => Material(
          color: onDark ? Colors.white : DriverColors.surface,
          shape: CircleBorder(
              side: BorderSide(
                  color: onDark ? Colors.white.withValues(alpha: .35) : DriverColors.line, width: onDark ? 2 : 1)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('profile_button'),
            customBorder: const CircleBorder(),
            onTap: onProfileTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: avatar ??
                  const Icon(Icons.person_rounded, color: DriverColors.navy, size: 24),
            ),
          ),
        );
}

class _DutyPill extends StatelessWidget {
  const _DutyPill(
      {required this.online, required this.busy, required this.onToggle, required this.onDark});
  final bool online;
  final bool busy;
  final ValueChanged<bool>? onToggle;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color bg, border, text, dot;
    if (onDark) {
      bg = Colors.white.withValues(alpha: online ? .16 : .08);
      border = online ? DriverColors.mint.withValues(alpha: .55) : Colors.white.withValues(alpha: .18);
      text = online ? Colors.white : Colors.white.withValues(alpha: .75);
      dot = online ? DriverColors.mint : Colors.white.withValues(alpha: .45);
    } else {
      bg = online ? const Color(0xFFE7F7EF) : Colors.white;
      border = online ? const Color(0xFFBDE8D2) : DriverColors.line;
      text = online ? const Color(0xFF0E7A4E) : DriverColors.muted;
      dot = online ? DriverColors.green : const Color(0xFFB8C2CC);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 46,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // A live dot: glowing while on duty.
        _LiveDot(color: dot, on: online),
        const SizedBox(width: 9),
        Flexible(
          child: Text(online ? 'On Duty' : 'Off Duty',
              key: const Key('duty_status'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 14.5)),
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
                    valueColor: AlwaysStoppedAnimation(onDark ? Colors.white : DriverColors.blue))),
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
                activeTrackColor: onDark ? const Color(0xFF00B57F) : DriverColors.green,
                inactiveTrackColor: onDark ? Colors.white.withValues(alpha: .18) : null,
                inactiveThumbColor: onDark ? Colors.white : null,
                trackOutlineColor: onDark ? const WidgetStatePropertyAll(Colors.transparent) : null,
                onChanged: onToggle ?? (_) {},
              ),
            ),
          ),
      ]),
    );
  }
}

/// A status dot with a soft halo while [on]. Deliberately still: an endless
/// pulse here would keep every on-duty screen from ever settling.
class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color, required this.on});
  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: on ? [BoxShadow(color: color.withValues(alpha: .55), blurRadius: 8, spreadRadius: 2)] : const [],
        ),
      );
}

/// Working time while online, or today's earnings while not — full width,
/// flush with both edges (unlike the cards that float above it). A null
/// [onTap] makes it decorative. [onDark] = frosted glass for the navy header.
class WorkingTimeBanner extends StatelessWidget {
  const WorkingTimeBanner({
    super.key,
    required this.online,
    required this.dutyStartedAt,
    required this.todayEarnings,
    this.onTap,
    this.onDark = false,
  });

  final bool online;
  final ValueListenable<DateTime?> dutyStartedAt;
  final double todayEarnings;
  final VoidCallback? onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : DriverColors.ink;
    final sub = onDark ? Colors.white.withValues(alpha: .65) : DriverColors.muted;
    final label = TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w500);
    final value = TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -.2);
    return Material(
      color: onDark ? Colors.white.withValues(alpha: .09) : DriverColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: onDark ? BorderSide(color: Colors.white.withValues(alpha: .12)) : BorderSide.none,
      ),
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
                  color: onDark ? Colors.white.withValues(alpha: .12) : Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(
                  online ? Icons.timer_outlined : Icons.account_balance_wallet_outlined,
                  size: 19,
                  color: onDark ? DriverColors.mint : DriverColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(online ? 'Working time' : 'Today’s earnings', style: label),
                    const SizedBox(height: 2),
                    online
                        ? ValueListenableBuilder<DateTime?>(
                            valueListenable: dutyStartedAt,
                            builder: (_, since, __) => _ElapsedLabel(since: since, style: value),
                          )
                        : Text(formatMoneyShort(todayEarnings),
                            key: const Key('stat_earnings_teaser'), style: value),
                  ]),
            ),
            if (onTap != null) ...[
              Text(online ? 'Today' : 'Stats',
                  style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, color: sub, size: 22),
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
