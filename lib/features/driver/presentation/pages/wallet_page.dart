import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

enum _Filter {
  all('All', <WalletKind>[]),
  earnings('Earnings', [WalletKind.tripEarning, WalletKind.bonus]),
  payouts('Payouts', [WalletKind.payout]);

  const _Filter(this.label, this.kinds);
  final String label;
  final List<WalletKind> kinds;
}

/// Earnings at a glance and the statement behind them: the balance the company
/// owes the driver, today / week / month / lifetime, the last seven days as a
/// chart, and every credit and payout newest-first.
class DriverWalletPage extends StatefulWidget {
  const DriverWalletPage({super.key});

  static const routeName = 'DriverWallet';
  static const routePath = DriverRoutes.wallet;

  @override
  State<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends State<DriverWalletPage> {
  final _scroll = ScrollController();
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();

  WalletSummary? _summary;
  String? _summaryError;

  final List<WalletEntry> _entries = [];
  _Filter _filter = _Filter.all;
  int _page = 0;
  bool _hasNext = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 400) {
        _loadMore();
      }
    });
    _loadSummary();
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final (summary, failure) = await _cubit.loadWallet();
    if (!mounted) return;
    setState(() {
      if (summary != null) {
        _summary = summary;
        _summaryError = null;
      } else if (_summary == null) {
        _summaryError = failure?.message ?? 'Could not load your wallet.';
      }
    });
  }

  Future<void> _refresh() async {
    _entries.clear();
    _page = 0;
    _hasNext = true;
    _error = null;
    await Future.wait([_loadSummary(), _loadMore()]);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasNext) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final filter = _filter;
    final (result, failure) = await _cubit.loadWalletEntries(
      page: _page + 1,
      kinds: filter.kinds,
    );
    if (!mounted || filter != _filter) return; // the filter changed mid-flight
    setState(() {
      _loading = false;
      if (result == null) {
        _error = failure?.message ?? 'Could not load your transactions.';
        return;
      }
      _page += 1;
      _hasNext = result.hasNext;
      _entries.addAll(result.items);
    });
  }

  void _select(_Filter filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _entries.clear();
      _page = 0;
      _hasNext = true;
      _loading = false;
      _error = null;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<DriverSessionCubit, DriverSessionState>(
        // A trip finishing changes what's owed: the session refreshes its
        // stats when that happens, and that's the cue to re-read the wallet.
        listenWhen: (a, b) =>
            a.stats.allTime.tripsCompleted != b.stats.allTime.tripsCompleted,
        listener: (_, __) => _refresh(),
        child: Scaffold(
          backgroundColor: DriverColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: DriverColors.ink,
            automaticallyImplyLeading: false,
            title: const Text('Wallet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          ),
          body: _body(),
        ),
      );

  Widget _body() {
    final summary = _summary;
    if (summary == null) {
      if (_summaryError != null) {
        return CenteredMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load your wallet',
          message: _summaryError,
          actionLabel: 'Retry',
          onAction: () {
            setState(() => _summaryError = null);
            _loadSummary();
          },
        );
      }
      return const DriverListSkeleton(itemCount: 4, itemHeight: 120);
    }

    final rows = _rows();
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: rows.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _Overview(summary: summary);
          return rows[i - 1](context);
        },
      ),
    );
  }

  /// The statement below the overview: filter chips, then day headings and
  /// entries, then a footer for loading / errors / empty.
  List<WidgetBuilder> _rows() {
    final rows = <WidgetBuilder>[
      (_) => Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('History'),
              const SizedBox(height: 10),
              Row(children: [
                for (final filter in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: Key('wallet_filter_${filter.name}'),
                      label: Text(filter.label),
                      selected: filter == _filter,
                      onSelected: (_) => _select(filter),
                      selectedColor: const Color(0xFFEAF2FF),
                      labelStyle: TextStyle(
                          color: filter == _filter
                              ? DriverColors.blue
                              : DriverColors.muted,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ]),
            ]),
          ),
    ];

    DateTime? lastDay;
    for (final entry in _entries) {
      final at = entry.createdAt;
      final day = at == null ? null : DateTime(at.year, at.month, at.day);
      if (day != null && day != lastDay) {
        lastDay = day;
        rows.add((_) => Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(formatDayHeading(day).toUpperCase(),
                  style: const TextStyle(
                      color: DriverColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8)),
            ));
      }
      rows.add((_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EntryTile(entry: entry),
          ));
    }

    rows.add((_) {
      if (_loading) {
        return _entries.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 6),
                child: DriverListSkeletonInline(itemCount: 3, itemHeight: 64))
            : const Padding(
                padding: EdgeInsets.all(14),
                child:
                    Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
      }
      if (_error != null) {
        return TextButton(
            onPressed: _loadMore, child: Text('$_error — tap to retry'));
      }
      if (_entries.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CenteredMessage(
            icon: Icons.receipt_long_outlined,
            title: 'Nothing here yet',
            message:
                'Your earnings appear here after each delivery, and payouts show up when the company sends them.',
          ),
        );
      }
      return const SizedBox.shrink();
    });
    return rows;
  }
}

// -----------------------------------------------------------------------------

class _Overview extends StatelessWidget {
  const _Overview({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = summary.currency;
    String money(double v) => formatMoney(v, currency: currency);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FadeSlideIn(child: _BalanceCard(summary: summary)),
      const SizedBox(height: 14),
      FadeSlideIn(
        delay: const Duration(milliseconds: 60),
        child: Row(children: [
          Expanded(
              child: _PeriodTile(
                  keyName: 'wallet_week',
                  label: 'This week',
                  value: money(summary.week.earnings),
                  trips: summary.week.trips)),
          const SizedBox(width: 12),
          Expanded(
              child: _PeriodTile(
                  keyName: 'wallet_month',
                  label: 'This month',
                  value: money(summary.month.earnings),
                  trips: summary.month.trips)),
        ]),
      ),
      const SizedBox(height: 12),
      FadeSlideIn(
        delay: const Duration(milliseconds: 110),
        child: _PeriodTile(
            keyName: 'wallet_lifetime',
            label: 'All time',
            value: money(summary.lifetime.earnings),
            trips: summary.lifetime.trips,
            wide: true),
      ),
      const SizedBox(height: 18),
      FadeSlideIn(
        delay: const Duration(milliseconds: 160),
        child: _WeekChart(days: summary.last7Days),
      ),
      const SizedBox(height: 14),
      const _PayoutPrompt(),
    ]);
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DriverColors.ink,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33102A43),
                blurRadius: 22,
                offset: Offset(0, 10)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Wallet balance',
              style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(formatMoney(summary.balance, currency: summary.currency),
              key: const Key('wallet_balance'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.trending_up_rounded,
                  color: Color(0xFF6EE7B7), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Earned today',
                          style: TextStyle(
                              color: Color(0xB3FFFFFF), fontSize: 11.5)),
                      Text(
                          formatMoney(summary.today.earnings,
                              currency: summary.currency),
                          key: const Key('wallet_today'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ]),
              ),
              Text(
                  '${summary.today.trips} trip${summary.today.trips == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Color(0xB3FFFFFF), fontSize: 12.5)),
            ]),
          ),
          if (summary.lifetimePayouts > 0) ...[
            const SizedBox(height: 12),
            Text(
                'Paid out so far: ${formatMoney(summary.lifetimePayouts, currency: summary.currency)}',
                key: const Key('wallet_payouts'),
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
          ],
        ]),
      );
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.keyName,
    required this.label,
    required this.value,
    required this.trips,
    this.wide = false,
  });

  final String keyName;
  final String label;
  final String value;
  final int trips;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tripsText = '$trips trip${trips == 1 ? '' : 's'}';
    return DriverCard(
      padding: const EdgeInsets.all(14),
      child: wide
          ? Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: DriverColors.muted, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(value,
                          key: Key(keyName),
                          style: const TextStyle(
                              color: DriverColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                    ]),
              ),
              Text(tripsText,
                  style: const TextStyle(
                      color: DriverColors.muted, fontSize: 12.5)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style:
                      const TextStyle(color: DriverColors.muted, fontSize: 12)),
              const SizedBox(height: 3),
              Text(value,
                  key: Key(keyName),
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(tripsText,
                  style: const TextStyle(
                      color: DriverColors.muted, fontSize: 11.5)),
            ]),
    );
  }
}

/// The last seven days as bars. Heights animate in from zero once; today's bar
/// is the strong colour, and each day with earnings carries its amount.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});
  final List<DayEarning> days;

  static const _plotHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final peak =
        days.map((d) => d.earnings).fold<double>(0, (a, b) => a > b ? a : b);
    final total = days.fold<double>(0, (sum, d) => sum + d.earnings);
    return DriverCard(
      key: const Key('wallet_chart'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: SectionTitle('Last 7 days')),
          Text(formatMoney(total),
              style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: _plotHeight + 42,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _Bar(
                    day: days[i],
                    ratio: peak <= 0 ? 0 : days[i].earnings / peak,
                    isToday: i == days.length - 1,
                    delay: Duration(milliseconds: 40 * i),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.ratio,
    required this.isToday,
    required this.delay,
  });

  final DayEarning day;
  final double ratio;
  final bool isToday;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final barHeight =
        ratio <= 0 ? 4.0 : 8 + (_WeekChart._plotHeight - 8) * ratio;
    final color = day.earnings <= 0
        ? DriverColors.line
        : isToday
            ? DriverColors.blue
            : const Color(0xFFBFD4FF);
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      SizedBox(
        height: 16,
        child: day.earnings > 0
            ? FittedBox(
                child: Text(formatCompactMoney(day.earnings),
                    style: TextStyle(
                        color: isToday ? DriverColors.blue : DriverColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)))
            : null,
      ),
      const SizedBox(height: 4),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: barHeight),
        duration: Duration(milliseconds: 420 + delay.inMilliseconds),
        curve: Curves.easeOutCubic,
        builder: (_, height, __) => Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(7)),
        ),
      ),
      const SizedBox(height: 6),
      Text(DateFormat('E').format(day.date).substring(0, 1),
          style: TextStyle(
              color: isToday ? DriverColors.ink : DriverColors.muted,
              fontSize: 11.5,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600)),
    ]);
  }
}

class _PayoutPrompt extends StatelessWidget {
  const _PayoutPrompt();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
        buildWhen: (a, b) => a.profile?.payout != b.profile?.payout,
        builder: (context, state) {
          final payout = state.profile?.payout;
          if (payout == null) return const SizedBox.shrink();
          if (!payout.isSet) {
            return InfoBanner(
              key: const Key('wallet_payout_prompt'),
              text:
                  'Add a UPI id or bank account so your company knows where to send your earnings.',
              icon: Icons.account_balance_outlined,
              action: TextButton(
                key: const Key('wallet_add_payout'),
                onPressed: () => context.push(DriverRoutes.payout),
                child: const Text('Add'),
              ),
            );
          }
          return DriverCard(
            key: const Key('wallet_payout_set'),
            onTap: () => context.push(DriverRoutes.payout),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              const Icon(Icons.account_balance_outlined,
                  color: DriverColors.muted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Payouts go to ${payout.summary ?? 'your account'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: DriverColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              const Text('Change',
                  style: TextStyle(
                      color: DriverColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ]),
          );
        },
      );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.kind) {
      WalletKind.tripEarning => (
          Icons.local_shipping_outlined,
          DriverColors.green
        ),
      WalletKind.bonus => (Icons.card_giftcard_rounded, DriverColors.green),
      WalletKind.penalty => (
          Icons.remove_circle_outline_rounded,
          DriverColors.red
        ),
      WalletKind.payout => (Icons.account_balance_outlined, DriverColors.blue),
      _ => (Icons.tune_rounded, DriverColors.orange),
    };
    final meta = [
      entry.kind.label,
      if (entry.createdAt != null) formatClock(entry.createdAt),
      if ((entry.reference ?? '').isNotEmpty) 'Ref ${entry.reference}',
    ].join(' · ');
    return DriverCard(
      key: Key('wallet_entry_${entry.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.description ?? entry.kind.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: DriverColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: DriverColors.muted, fontSize: 11.5)),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatSignedMoney(entry.amount),
              key: Key('wallet_amount_${entry.id}'),
              style: TextStyle(
                  color: entry.isCredit ? DriverColors.green : DriverColors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Bal ${formatMoney(entry.balanceAfter)}',
              style: const TextStyle(color: DriverColors.muted, fontSize: 11)),
        ]),
      ]),
    );
  }
}
