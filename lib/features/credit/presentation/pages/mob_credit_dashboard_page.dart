import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/credit_transaction_entity.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:m_o_b_demand_side/shared/mob_credit.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

/// Real mobCREDIT dashboard for customers who already have an account with
/// Rupifi — shows the live available balance / credit limit and the debit
/// history from `get_credit_history`, per the design attachment. This is the
/// destination for an "active" mobCREDIT customer; everyone else still lands
/// on [CreditPage]'s apply flow.
class MobCreditDashboardPage extends StatelessWidget {
  const MobCreditDashboardPage({super.key});

  static const String routeName = 'MobCreditDashboard';
  static const String routePath = '/credit/dashboard';

  static const _primary = Color(0xFF0A243F);
  static const _muted = Color(0xFF767C8F);
  static const _background = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreditBloc>()..add(CreditHistoryRequested()),
      child: Scaffold(
        backgroundColor: _background,
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final account = state is CartLoaded
                ? state.summary.account
                : CartAccountEntity.empty;
            return _DashboardBody(account: account);
          },
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.account});

  final CartAccountEntity account;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ColoredBox(
            color: MobCreditDashboardPage._background,
            child: Stack(
              children: [
                const _DashboardHeader(),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 132,
                  child: _CreditBalanceCard(account: account),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList.list(
            children: [
              Text(
                'Transactions',
                style: GoogleFonts.inter(
                  color: MobCreditDashboardPage._primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(height: 8),
              const _CreditTransactionsList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 186,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08131F), Color(0xFF0A243F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 4,
              top: 8,
              child: IconButton(
                icon: const AppBackIcon(color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/homepage');
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SvgPicture.asset(
                'assets/images/mobcredwithtick.svg',
                width: 146,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditBalanceCard extends StatelessWidget {
  const _CreditBalanceCard({required this.account});

  final CartAccountEntity account;

  @override
  Widget build(BuildContext context) {
    final creditLimit = account.rupifiCurrentLimit;
    final available = account.rupifiBalance;
    final progress =
        creditLimit > 0 ? (available / creditLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Available balance',
            style: GoogleFonts.inter(
              color: MobCreditDashboardPage._muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatRupees(available),
            style: GoogleFonts.inter(
              color: MobCreditDashboardPage._primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 36 / 28,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE7E7E7),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF37BD68)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Credit limit: ${formatRupees(creditLimit)}',
            style: GoogleFonts.inter(
              color: MobCreditDashboardPage._muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditTransactionsList extends StatelessWidget {
  const _CreditTransactionsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditBloc, CreditState>(
      builder: (context, state) {
        if (state is CreditHistoryError) {
          return _CreditHistoryMessage(
            text: state.message,
            onRetry: () =>
                context.read<CreditBloc>().add(CreditHistoryRequested()),
          );
        }
        if (state is CreditHistoryLoaded) {
          if (state.transactions.isEmpty) {
            return const _CreditHistoryMessage(text: 'No transactions yet');
          }
          return Column(
            children: state.transactions
                .map((t) => _CreditTransactionRow(transaction: t))
                .toList(),
          );
        }
        return const _CreditHistoryLoadingRows();
      },
    );
  }
}

class _CreditTransactionRow extends StatelessWidget {
  const _CreditTransactionRow({required this.transaction});

  final CreditTransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final debit = transaction.isDebit;
    final amount =
        NumberFormat('#,##0.00', 'en_IN').format(transaction.amount.abs());
    final date = transaction.createdAt == null
        ? ''
        : DateFormat('dd MMM yyyy, hh:mm a')
            .format(transaction.createdAt!.toLocal());
    final order = transaction.orderNumber;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2E2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Order ID: '),
                      TextSpan(
                        text: order.isEmpty ? '—' : order,
                        style: const TextStyle(color: Color(0xFF0360E5)),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MobCreditDashboardPage._primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.isEmpty
                      ? transaction.remarks
                      : '${debit ? 'Debited' : 'Credited'} on $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MobCreditDashboardPage._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${debit ? '-' : '+'}₹$amount',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: debit
                  ? MobCreditDashboardPage._primary
                  : const Color(0xFF07AD61),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditHistoryLoadingRows extends StatelessWidget {
  const _CreditHistoryLoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E2E2))),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 180,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAED),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditHistoryMessage extends StatelessWidget {
  const _CreditHistoryMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: MobCreditDashboardPage._muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
