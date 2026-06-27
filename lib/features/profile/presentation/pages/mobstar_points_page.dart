import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';

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
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                        children: [
                          _TransactionRow(
                            credited: true,
                            points: '2000P',
                            amount: '₹500.00',
                            details:
                                'Credited on 22 Jan 2024 | Valid till 31 Jan 2025',
                          ),
                          _TransactionDivider(),
                          _TransactionRow(
                            credited: false,
                            points: '2000P',
                            amount: '₹500.00',
                            details: 'Debited on 18 Nov',
                          ),
                          _TransactionDivider(),
                          _TransactionRow(
                            credited: true,
                            points: '2000P',
                            amount: '₹500.00',
                            details:
                                'Credited on 22 Jan 2024 | Valid till 31 Jan 2025',
                          ),
                          _TransactionDivider(),
                          _TransactionRow(
                            credited: true,
                            points: '2000P',
                            amount: '₹500.00',
                            details:
                                'Credited on 22 Jan 2024 | Valid till 31 Jan 2025',
                          ),
                          _TransactionDivider(),
                          _TransactionRow(
                            credited: true,
                            points: '2000P',
                            amount: '₹500.00',
                            details:
                                'Credited on 22 Jan 2024 | Valid till 31 Jan 2025',
                          ),
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
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
  const _TransactionRow({
    required this.credited,
    required this.points,
    required this.amount,
    required this.details,
  });

  final bool credited;
  final String points;
  final String amount;
  final String details;

  @override
  Widget build(BuildContext context) {
    final sign = credited ? '+' : '-';
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
                    children: const [
                      TextSpan(text: 'Order ID: '),
                      TextSpan(
                        text: 'OD20250910004507',
                        style: TextStyle(color: Color(0xFF0360E5)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$sign$points',
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
