import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class MobstarPointsPage extends StatelessWidget {
  const MobstarPointsPage({super.key});

  static const routeName = 'MobstarPoints';
  static const routePath = '/mobstar-points';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(MobstarLoadRequested()),
      child: const _MobstarPointsView(),
    );
  }
}

class _MobstarPointsView extends StatelessWidget {
  const _MobstarPointsView();

  static const _primary = Color(0xFF0A243F);
  static const _muted = Color(0xFF596378);

  @override
  Widget build(BuildContext context) {
    final mobstar = context.select<ProfileBloc, MobstarEntity>((bloc) {
      final state = bloc.state;
      return state is MobstarLoaded ? state.mobstar : MobstarEntity.empty;
    });
    final points = mobstar.points;
    final valueText = mobstar.actualMoney % 1 == 0
        ? mobstar.actualMoney.toStringAsFixed(0)
        : mobstar.actualMoney.toStringAsFixed(2);
    final transactions = mobstar.transactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Stack(
        children: [
          Container(
            height: 186,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF000000), Color(0xFF505AB1)],
                stops: [.09, .98],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const _MobstarPointsHeader(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PointsSummaryCard(
                          points: points,
                          valueText: valueText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _PointsInfoNote(),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Transactions',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              height: 22 / 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: transactions.isEmpty
                          ? const _EmptyTransactions()
                          : Column(
                              children: [
                                for (var i = 0;
                                    i < transactions.length;
                                    i++) ...[
                                  _TransactionRow(transaction: transactions[i]),
                                  if (i != transactions.length - 1)
                                    const _TransactionDivider(),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobstarPointsHeader extends StatelessWidget {
  const _MobstarPointsHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 16,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const AppBackIcon(color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            ),
          ),
          Text(
            'mobSTAR',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 22 / 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsSummaryCard extends StatelessWidget {
  const _PointsSummaryCard({
    required this.points,
    required this.valueText,
  });

  final int points;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'mobSTAR points',
            style: GoogleFonts.inter(
              color: _MobstarPointsView._muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/mobstarcoin.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$points',
                style: GoogleFonts.inter(
                  color: _MobstarPointsView._primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 42 / 28,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '₹$valueText',
              style: GoogleFonts.inter(
                color: _MobstarPointsView._primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 20 / 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsInfoNote extends StatelessWidget {
  const _PointsInfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'mobSTAR points are valid for 1 year from the month earned and are non-transferable.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: _MobstarPointsView._muted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 18 / 12,
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final MobstarTransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final credited = transaction.credited;
    final sign = credited ? '+' : '-';
    final absolutePoints = transaction.points.abs();
    final amount = transaction.amount == 0
        ? '₹0'
        : '₹${transaction.amount.toStringAsFixed(2)}';
    final details = _detailsText(transaction);
    final pointsColor =
        credited ? const Color(0xFF07AD61) : _MobstarPointsView._primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      color: _MobstarPointsView._primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                    ),
                    children: [
                      const TextSpan(text: 'Order ID: '),
                      TextSpan(
                        text: transaction.orderId.isEmpty
                            ? transaction.notes
                            : transaction.orderId,
                        style: const TextStyle(color: Color(0xFF0360E5)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$sign${absolutePoints}P',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: pointsColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _MobstarPointsView._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$sign$amount',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: _MobstarPointsView._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 16 / 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _detailsText(MobstarTransactionEntity transaction) {
    final action = transaction.credited ? 'Credited' : 'Debited';
    final date = _formatDate(transaction.createdAt);
    final validTill = transaction.validTill.trim();
    if (validTill.isEmpty) return '$action on $date';
    return '$action on $date | Valid till $validTill';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _TransactionDivider extends StatelessWidget {
  const _TransactionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E2E2)),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Text(
        'No mobSTAR transactions yet',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: _MobstarPointsView._muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 20 / 13,
        ),
      ),
    );
  }
}
