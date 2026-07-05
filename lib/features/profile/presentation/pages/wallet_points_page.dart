import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class WalletPointsPage extends StatelessWidget {
  const WalletPointsPage({super.key});

  static const routeName = 'WalletPoints';
  static const routePath = '/wallet-points';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(WalletHistoryLoadRequested()),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is WalletHistoryError) {
              return Column(
                children: [
                  const _WalletHeader(),
                  Expanded(
                    child: ErrorStateView(
                      message: state.message,
                      onRetry: () => context
                          .read<ProfileBloc>()
                          .add(WalletHistoryLoadRequested()),
                    ),
                  ),
                ],
              );
            }

            final wallet = state is WalletHistoryLoaded ? state.wallet : null;
            return RefreshIndicator(
              color: const Color(0xFF0360E5),
              onRefresh: () async {
                context.read<ProfileBloc>().add(WalletHistoryLoadRequested());
                await context.read<ProfileBloc>().stream.firstWhere(
                      (next) =>
                          next is WalletHistoryLoaded ||
                          next is WalletHistoryError,
                    );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          const _WalletHeader(),
                          Positioned(
                            left: 16,
                            right: 16,
                            top: 132,
                            child: _BalanceCard(
                              balance: wallet?.balance,
                              loading: wallet == null,
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 13,
                            child: Text(
                              'Transactions',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0A243F),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 22 / 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 512),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: wallet == null
                          ? const _LoadingRows()
                          : wallet.transactions.isEmpty
                              ? const _EmptyWallet()
                              : Column(
                                  children: wallet.transactions
                                      .map((item) =>
                                          _TransactionRow(transaction: item))
                                      .toList(),
                                ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 186,
      color: const Color(0xFF0A243F),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wallet_header.png',
            width: double.infinity,
            height: 186,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 3,
                    child: IconButton(
                      onPressed: () => context.canPop() ? context.pop() : null,
                      icon: const AppBackIcon(color: Colors.white),
                    ),
                  ),
                  Text(
                    'mobWALLET',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 22 / 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.loading});

  final double? balance;
  final bool loading;

  String get _balanceText {
    if (balance == null) return '—';
    return NumberFormat('#,##0.##', 'en_IN').format(balance);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'mobWALLET balance',
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            opacity: loading ? .3 : 1,
            duration: const Duration(milliseconds: 180),
            child: Text(
              '₹$_balanceText',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 42 / 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final debit = transaction.isDebit;
    final amount = NumberFormat('#,##0.00', 'en_IN').format(transaction.amount);
    final date = transaction.createdAt == null
        ? ''
        : DateFormat('dd MMM hh:mm a').format(transaction.createdAt!.toLocal());
    final order = transaction.orderNumber;

    return Container(
      height: 74,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E2E2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    color: const Color(0xFF0A243F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${transaction.transactionType.toUpperCase()}${date.isEmpty ? '' : ' on $date'}',
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF596378),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${debit ? '-' : '+'}₹$amount',
            style: GoogleFonts.inter(
              color: debit ? const Color(0xFF0A243F) : const Color(0xFF07AD61),
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

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => Container(
          height: 74,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E2E2))),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 210,
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

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          SizedBox(
            width: 136,
            height: 136,
            child: Image.asset(
              'assets/images/wallet_empty.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
