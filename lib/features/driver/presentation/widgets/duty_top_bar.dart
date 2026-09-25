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
class DutyStatusRow extends StatelessWidget {
  const DutyStatusRow({
    super.key,
    required this.online,
    this.busy = false,
    this.onToggle,
    this.onProfileTap,
  });

  final bool online;
  final bool busy;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Center(
              child:
                  _DutyPill(online: online, busy: busy, onToggle: onToggle)),
        ),
        const SizedBox(width: 12),
        Material(
          color: DriverColors.surface,
          shape: const CircleBorder(
              side: BorderSide(color: DriverColors.line)),
          child: InkWell(
            key: const Key('profile_button'),
            customBorder: const CircleBorder(),
            onTap: onProfileTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.person_rounded,
                  color: DriverColors.ink, size: 24),
            ),
          ),
        ),
      ]);
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
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: online ? const Color(0xFFE7F7EF) : Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
              color: online ? const Color(0xFFBDE8D2) : DriverColors.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // A live dot: green and breathing while on duty.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online ? DriverColors.green : const Color(0xFFB8C2CC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(online ? 'On Duty' : 'Off Duty',
                key: const Key('duty_status'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: online ? const Color(0xFF0E7A4E) : DriverColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5)),
          ),
          const SizedBox(width: 6),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2)),
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
                  activeTrackColor: DriverColors.green,
                  onChanged: onToggle ?? (_) {},
                ),
              ),
            ),
        ]),
      );
}

/// Working time while online, or today's earnings while not — full width,
/// flush with both edges (unlike the cards that float above it). A null
/// [onTap] makes it decorative.
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
    const label = TextStyle(
        color: DriverColors.muted, fontSize: 12, fontWeight: FontWeight.w500);
    return Material(
      color: DriverColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const Key('summary_banner'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  online ? Icons.timer_outlined : Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: DriverColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(online ? 'Working time' : 'Today’s earnings',
                        style: label),
                    const SizedBox(height: 2),
                    online
                        ? ValueListenableBuilder<DateTime?>(
                            valueListenable: dutyStartedAt,
                            builder: (_, since, __) =>
                                _ElapsedLabel(since: since),
                          )
                        : Text(formatMoneyShort(todayEarnings),
                            key: const Key('stat_earnings_teaser'),
                            style: const TextStyle(
                                color: DriverColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                  ]),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: DriverColors.muted, size: 22),
          ]),
        ),
      ),
    );
  }
}

class _ElapsedLabel extends StatefulWidget {
  const _ElapsedLabel({required this.since});
  final DateTime? since;

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
    return Text(text,
        key: const Key('working_time'),
        style: const TextStyle(
            color: DriverColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 15));
  }
}
