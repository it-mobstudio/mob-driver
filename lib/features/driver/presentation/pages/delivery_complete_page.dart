import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/fare_chips.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

/// Shown once a delivery is completed: a "Delivered" banner with the time,
/// and what the trip added to the driver's earnings — the fare share and the
/// unloading bonus. "Done" (or back) returns to the dashboard.
class DeliveryCompletePage extends StatefulWidget {
  const DeliveryCompletePage({super.key, required this.tripId, this.trip});

  static const routeName = 'DeliveryComplete';

  final String tripId;

  /// The completed trip as the server returned it, when the caller has it.
  final Trip? trip;

  @override
  State<DeliveryCompletePage> createState() => _DeliveryCompletePageState();
}

class _DeliveryCompletePageState extends State<DeliveryCompletePage> {
  Trip? _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    if (_trip == null) unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final (trip, _) =
        await context.read<DriverSessionCubit>().fetchTrip(widget.tripId);
    if (mounted && trip != null) setState(() => _trip = trip);
  }

  void _done() => context.go(DriverRoutes.dashboard);

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        backgroundColor: DriverColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          foregroundColor: DriverColors.ink,
          titleSpacing: 0,
          leading: IconButton(
            key: const Key('delivery_complete_back'),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _done,
          ),
          title: const Text('Delivery complete',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          actions: const [
            Center(child: HelpChip()),
            SizedBox(width: 14),
          ],
        ),
        body: trip == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _DeliveredBanner(completedAt: trip.completedAt),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _EarningsCard(trip: trip),
                  ),
                ],
              ),
        bottomNavigationBar: Material(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: PrimaryButton(
                key: const Key('delivery_complete_done'),
                label: 'Done',
                onPressed: _done,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveredBanner extends StatelessWidget {
  const _DeliveredBanner({required this.completedAt});
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final when = (completedAt ?? DateTime.now()).toLocal();
    return Container(
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B2545), Color(0xFF13315C)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: 8,
          bottom: 0,
          child: Image.asset('assets/images/delivered_driver.png',
              key: const Key('delivered_driver_image'),
              height: 124,
              fit: BoxFit.contain),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 130, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivered',
                  key: Key('delivered_title'),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM yyyy \'at\' hh:mm a').format(when),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: .75), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// The green badge overlapping a white card: what this trip added, split into
/// the fare share and the unloading bonus.
class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final bonus = (trip.bonusFare ?? 0) > 0 ? trip.bonusFare : null;
    // The server credits the driver's share of the fare plus the whole bonus
    // (driver_earning). Before it's known, fall back to the fare itself.
    final earned = trip.driverEarning ?? (trip.totalFare ?? 0) + (bonus ?? 0);
    final fareShare = earned - (bonus ?? 0);

    return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
      Container(
        margin: const EdgeInsets.only(top: 22),
        padding: const EdgeInsets.fromLTRB(14, 38, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Column(children: [
          Text(formatMoneyShort(earned, currency: trip.currency),
              key: const Key('completed_earning'),
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('Added to your earnings',
              style: TextStyle(
                  color: DriverColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          FareChips(
              tripFare: fareShare, bonus: bonus, currency: trip.currency),
        ]),
      ),
      // The badge pops in with a little spring — the moment worth marking.
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        builder: (_, value, child) => Transform.scale(scale: value, child: child),
        child: const _VerifiedBadge(),
      ),
    ]);
  }
}

/// A green scalloped seal with a white tick.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration:
            BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(Icons.verified_rounded,
            key: Key('delivered_badge'), color: DriverColors.green, size: 46),
      );
}
