import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/widgets/frosted_nav_bar.dart';

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

class _WalletView extends StatefulWidget {
  const _WalletView();

  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView> {
  final _scrollController = ScrollController();
  bool _frosted = false;
  static const _balanceCardHeight = 102.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldFrost = _scrollController.offset > 8;
    if (shouldFrost != _frosted) setState(() => _frosted = shouldFrost);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.22).clamp(186.0, 260.0);
    final headerContentHeight =
        headerHeight + (_balanceCardHeight / 2) + 34 + 22 + 14;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: Stack(
          children: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is WalletHistoryError) {
                  return Column(
                    children: [
                      _WalletHeader(height: headerHeight),
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

                final wallet =
                    state is WalletHistoryLoaded ? state.wallet : null;

                return RefreshIndicator(
                  color: const Color(0xFF0360E5),
                  onRefresh: () async {
                    context
                        .read<ProfileBloc>()
                        .add(WalletHistoryLoadRequested());
                    await context.read<ProfileBloc>().stream.firstWhere(
                          (next) =>
                              next is WalletHistoryLoaded ||
                              next is WalletHistoryError,
                        );
                  },
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerContentHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _WalletHeader(height: headerHeight),
                            Positioned(
                              left: 16,
                              right: 16,
                              top: headerHeight - (_balanceCardHeight / 2),
                              child: _BalanceCard(
                                balance: wallet?.balance,
                                loading: wallet == null,
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              top: headerHeight + (_balanceCardHeight / 2) + 34,
                              child: Align(
                                alignment: Alignment.centerLeft,
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
                          child: _WalletTransactionsList(
                            controller: _scrollController,
                            wallet: wallet,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            FrostedNavBar(frosted: _frosted),
          ],
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color(0xFF3A4A7F),
            Color(0xFF263149),
            Color(0xFF181818),
          ],
          stops: [0, 0.42, 1],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              right: 16,
              top: 60,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'mobWALLET',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          ],
        ),
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
      height: _WalletViewState._balanceCardHeight,
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

class _WalletTransactionsList extends StatelessWidget {
  const _WalletTransactionsList({
    required this.controller,
    required this.wallet,
  });

  final ScrollController controller;
  final WalletHistoryEntity? wallet;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final listPadding = EdgeInsets.fromLTRB(16, 16, 16, 40 + bottomInset);

    if (wallet == null) {
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: const [_LoadingRows()],
      );
    }

    if (wallet!.transactions.isEmpty) {
      return ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: const [_EmptyWallet()],
      );
    }

    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: listPadding,
      itemCount: wallet!.transactions.length,
      itemBuilder: (context, index) => _TransactionRow(
        transaction: wallet!.transactions[index],
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
    final amount =
        NumberFormat('#,##0.00', 'en_IN').format(transaction.amount.abs());
    final date = transaction.createdAt == null
        ? ''
        : DateFormat('dd MMM hh:mm a').format(transaction.createdAt!.toLocal());
    final order = transaction.orderNumber;
    final remarks = transaction.remarks;

    return InkWell(
      onTap: order.isEmpty
          ? null
          : () => context.push(
                OrderDetailPage.routePath,
                extra: OrderEntity.baseOrderId(order),
              ),
      child: Container(
        height: 74,
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
                  if (order.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Order ID: '),
                          TextSpan(
                            text: order,
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
                    )
                  else if (remarks.isNotEmpty)
                    Text(
                      'Remarks $remarks',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 20 / 14,
                      ),
                    ),
                  if (order.isNotEmpty || remarks.isNotEmpty)
                    const SizedBox(height: 6),
                  Text(
                    '${transaction.transactionType.toUpperCase()}${date.isEmpty ? '' : ' on $date'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color:
                    debit ? const Color(0xFF0A243F) : const Color(0xFF07AD61),
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

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => Container(
          height: 74,
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
              'assets/images/emptywallet.webp',
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
