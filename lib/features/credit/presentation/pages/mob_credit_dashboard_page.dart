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
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';
import 'package:m_o_b_demand_side/shared/mob_credit.dart';
import 'package:m_o_b_demand_side/shared/widgets/frosted_nav_bar.dart';

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
  static const _balanceCardHeight = 152.0;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeHeaderMinimum = mediaQuery.padding.top + 190;
    final headerHeight =
        (screenHeight * 0.286).clamp(safeHeaderMinimum, 262.0).toDouble();
    final transactionsTop = headerHeight + 108;
    final contentTop = transactionsTop + 34;

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: contentTop,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: headerHeight,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.0,
                        colors: [
                          Color(0xFF4A8F67),
                          Color(0xFF2B4939),
                          Color(0xFF181818),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: mediaQuery.padding.top + 70,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/myaccounts-mobcredit.svg',
                        width: 180,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: headerHeight - (_balanceCardHeight / 2),
                    child: _CreditBalanceCard(account: account),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: transactionsTop,
                    child: Text(
                      'Transactions',
                      style: GoogleFonts.inter(
                        color: MobCreditDashboardPage._primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 22 / 15,
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
                child: const _CreditTransactionsList(),
              ),
            ),
          ],
        ),
        FrostedNavBar(
          iconColor: MobCreditDashboardPage._primary,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/homepage');
            }
          },
        ),
      ],
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
      height: _DashboardBody._balanceCardHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Available balance',
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatRupees(available),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: MobCreditDashboardPage._primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 42 / 28,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: constraints.maxWidth * progress,
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFBAECB5), Color(0xFF05CA8F)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Credit limit: ${formatRupees(creditLimit)}',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final listPadding = EdgeInsets.fromLTRB(16, 16, 16, 40 + bottomInset);

    return BlocBuilder<CreditBloc, CreditState>(
      builder: (context, state) {
        if (state is CreditHistoryError) {
          return _CreditHistoryMessageScrollView(
            padding: listPadding,
            text: state.message,
            onRetry: () =>
                context.read<CreditBloc>().add(CreditHistoryRequested()),
          );
        }
        if (state is CreditHistoryLoaded) {
          if (state.transactions.isEmpty) {
            return _CreditHistoryMessageScrollView(
              padding: listPadding,
              text: 'No transactions yet',
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: listPadding,
            itemCount: state.transactions.length,
            itemBuilder: (context, index) => _CreditTransactionRow(
              transaction: state.transactions[index],
            ),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: listPadding,
          itemCount: 4,
          itemBuilder: (context, index) => const _CreditHistoryLoadingRow(),
        );
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

    return InkWell(
      onTap: order.isEmpty
          ? null
          : () => context.push(
                OrderDetailPage.routePath,
                extra: OrderEntity.baseOrderId(order),
              ),
      child: Container(
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
      ),
    );
  }
}

class _CreditHistoryLoadingRow extends StatelessWidget {
  const _CreditHistoryLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _CreditHistoryMessageScrollView extends StatelessWidget {
  const _CreditHistoryMessageScrollView({
    required this.padding,
    required this.text,
    this.onRetry,
  });

  final EdgeInsets padding;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: _CreditHistoryMessage(text: text, onRetry: onRetry),
            ),
          ),
        );
      },
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
