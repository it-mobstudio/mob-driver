import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

enum _Filter {
  all('All', <TripStatus>[]),
  completed('Completed', [TripStatus.completed]),
  cancelled('Cancelled', [TripStatus.cancelled]);

  const _Filter(this.label, this.statuses);
  final String label;
  final List<TripStatus> statuses;
}

/// The driver's trip history, newest first, with infinite scroll.
class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});

  static const routeName = 'DriverTrips';
  static const routePath = DriverRoutes.trips;

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
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
        _error = failure?.message ?? 'Could not load your trips.';
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
        backgroundColor: DriverColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: DriverColors.ink,
          automaticallyImplyLeading: false,
          title: const Text('My trips',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              for (final filter in _Filter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('filter_${filter.name}'),
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
          ),
          Expanded(child: _body()),
        ]),
      );

  Widget _body() {
    if (_trips.isEmpty) {
      if (_loading) {
        return const DriverListSkeleton(itemCount: 5, itemHeight: 124);
      }
      if (_error != null) {
        return CenteredMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load trips',
          message: _error,
          actionLabel: 'Retry',
          onAction: _refresh,
        );
      }
      return const CenteredMessage(
        icon: Icons.local_shipping_outlined,
        title: 'No trips yet',
        message: 'Trips you complete or cancel will show up here.',
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
                  onPressed: _loadMore, child: Text('$_error — tap to retry'));
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
      TripStatus.completed => (DriverColors.green, 'COMPLETED'),
      TripStatus.cancelled => (DriverColors.red, 'CANCELLED'),
      _ => (DriverColors.blue, trip.status.label.toUpperCase()),
    };
    final when = trip.completedAt ?? trip.cancelledAt ?? trip.createdAt;
    return DriverCard(
      onTap: () => context.push(DriverRoutes.trip(trip.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          StatusPill(label, color: color),
          const SizedBox(width: 8),
          Text(formatDateTime(when),
              style: const TextStyle(color: DriverColors.muted, fontSize: 12)),
          const Spacer(),
          Text(formatMoney(trip.totalFare, currency: trip.currency),
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        _line(DriverColors.green, trip.pickup.address),
        const SizedBox(height: 6),
        _line(DriverColors.red, trip.drop.address),
        const SizedBox(height: 10),
        Row(children: [
          Text(trip.isCod ? 'Cash on delivery' : 'Prepaid',
              style:
                  const TextStyle(color: DriverColors.muted, fontSize: 11.5)),
          const Spacer(),
          if (trip.driverEarning != null) ...[
            Text(
                'You earned ${formatMoney(trip.driverEarning, currency: trip.currency)}',
                key: Key('trip_earning_${trip.id}'),
                style: const TextStyle(
                    color: DriverColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
          ],
          Text(formatDistance(trip.distanceMeters),
              style:
                  const TextStyle(color: DriverColors.muted, fontSize: 11.5)),
        ]),
      ]),
    );
  }

  Widget _line(Color color, String text) => Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]);
}
