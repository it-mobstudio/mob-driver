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
  static const _summaryCardHeight = 118.0;

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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.22).clamp(186.0, 260.0);
    final headerContentHeight =
        headerHeight + (_summaryCardHeight / 2) + 8 + 52 + 24 + 22 + 14;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: Column(
        children: [
          SizedBox(
            height: headerContentHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: headerHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF000000), Color(0xFF505AB1)],
                      stops: [.09, .98],
                    ),
                  ),
                ),
                const SafeArea(
                  bottom: false,
                  child: _MobstarPointsHeader(),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: headerHeight - (_summaryCardHeight / 2),
                  child: _PointsSummaryCard(
                    points: points,
                    valueText: valueText,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: headerHeight + (_summaryCardHeight / 2) + 8,
                  child: const _PointsInfoNote(),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: headerHeight + (_summaryCardHeight / 2) + 84,
                  child: const Align(
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
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: transactions.isEmpty
                  ? const _EmptyTransactionsScrollView()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        40 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) =>
                          const _TransactionDivider(),
                      itemBuilder: (context, index) => _TransactionRow(
                        transaction: transactions[index],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsScrollView extends StatelessWidget {
  const _EmptyTransactionsScrollView();

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      16,
      16,
      16,
      40 + MediaQuery.paddingOf(context).bottom,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: _EmptyTransactions(),
            ),
          ),
        );
      },
    );
  }
}

class _MobstarPointsHeader extends StatelessWidget {
  const _MobstarPointsHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 16,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const AppBackIcon(color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 40,
                height: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 46),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                'mobSTAR',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 22 / 15, // 1.47
                ),
              ),
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
      width: double.infinity,
      height: _MobstarPointsView._summaryCardHeight,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 7),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'mobSTAR points',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -1),
                  child: SvgPicture.asset(
                    'assets/images/points.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: Center(
                    child: Text(
                      '$points',
                      strutStyle: const StrutStyle(
                        fontSize: 28,
                        height: 1,
                        forceStrutHeight: true,
                      ),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '₹$valueText',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
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
