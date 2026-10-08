import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/app_card.dart';
import 'package:mob_driver/core/widgets/centered_message.dart';
import 'package:mob_driver/core/widgets/list_skeleton.dart';
import 'package:mob_driver/core/widgets/status_pill.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';

enum _Filter {
  all('All', <TripStatus>[]),
  completed('Completed', [TripStatus.completed]),
  cancelled('Cancelled', [TripStatus.cancelled]);

  const _Filter(this.label, this.statuses);
  final String label;
  final List<TripStatus> statuses;
}

/// The driver's trip history, newest first, with infinite scroll.
class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final _scroll = ScrollController();
  final List<Trip> _trips = [];

  _Filter _filter = _Filter.all;
  int _page = 0;
  bool _hasNext = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _refresh() {
    _trips.clear();
    _page = 0;
    _hasNext = true;
    _error = null;
    return _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasNext) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final filter = _filter;
    final (result, failure) = await context
        .read<DriverSessionCubit>()
        .loadTrips(page: _page + 1, statuses: filter.statuses);
    if (!mounted || filter != _filter) return; // the filter changed mid-flight
    setState(() {
      _loading = false;
      if (result == null) {
        _error = failure?.message ?? tr('Could not load your trips.');
        return;
      }
      _page += 1;
      _hasNext = result.hasNext;
      _trips.addAll(result.items);
    });
  }

  void _select(_Filter filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _trips.clear();
      _page = 0;
      _hasNext = true;
      _loading = false;
      _error = null;
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          foregroundColor: AppColors.ink,
          automaticallyImplyLeading: false,
          leading: BackButton(
              key: const Key('trips_back'),
              onPressed: () => context.go(AppRoutes.profile)),
          title: Text(tr('My trips'),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: Column(children: [
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              for (final filter in _Filter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('filter_${filter.name}'),
                    label: Text(tr(filter.label)),
                    selected: filter == _filter,
                    onSelected: (_) => _select(filter),
                    selectedColor: AppColors.blueSoft,
                    labelStyle: TextStyle(
                        color: filter == _filter
                            ? AppColors.blue
                            : AppColors.muted,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ]),
          ),
          Expanded(child: _body()),
        ]),
      );

  Widget _body() {
    if (_trips.isEmpty) {
      if (_loading) {
        return const ListSkeleton(itemCount: 5, itemHeight: 124);
      }
      if (_error != null) {
        return CenteredMessage(
          icon: Icons.cloud_off_rounded,
          title: tr('Couldn’t load trips'),
          message: _error,
          actionLabel: tr('Retry'),
          onAction: _refresh,
        );
      }
      return CenteredMessage(
        icon: Icons.local_shipping_outlined,
        title: tr('No trips yet'),
        message: tr('Trips you complete or cancel will show up here.'),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        itemCount: _trips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _trips.length) {
            if (_loading) {
              return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5)));
            }
            if (_error != null) {
              return TextButton(
                  onPressed: _loadMore,
                  child: Text(tr('{error} — tap to retry', {'error': _error})));
            }
            return const SizedBox.shrink();
          }
          return _TripTile(trip: _trips[i]);
        },
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (trip.status) {
      TripStatus.completed => (AppColors.green, tr('COMPLETED')),
      TripStatus.cancelled => (AppColors.red, tr('CANCELLED')),
      _ => (AppColors.blue, trip.status.label.toUpperCase()),
    };
    final when = trip.completedAt ?? trip.cancelledAt ?? trip.createdAt;
    return AppCard(
      onTap: () => context.push(AppRoutes.trip(trip.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StatusPill(label, color: color),
          const SizedBox(width: 8),
          Text(formatDateTime(when),
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const Spacer(),
          Text(formatMoney(trip.totalFare, currency: trip.currency),
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        _line(AppColors.green, trip.pickup.address),
        const SizedBox(height: 6),
        _line(AppColors.red, trip.drop.address),
        const SizedBox(height: 10),
        Row(children: [
          Text(trip.isCod ? tr('Cash on delivery') : tr('Prepaid'),
              style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
          const Spacer(),
          if (trip.driverEarning != null) ...[
            Text(
                tr('You earned {p0}', {
                  'p0': formatMoney(trip.driverEarning, currency: trip.currency)
                }),
                key: Key('trip_earning_${trip.id}'),
                style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
          ],
          Text(formatDistance(trip.distanceMeters),
              style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
        ]),
      ]),
    );
  }

  Widget _line(Color color, String text) => Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]);
}
