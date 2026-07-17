import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/frosted_nav_bar.dart';

class ReferralHistoryPage extends StatelessWidget {
  const ReferralHistoryPage({super.key});

  static const String routeName = 'ReferralHistoryPage';
  static const String routePath = '/referral-history';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ReferralSummaryLoadRequested()),
      child: const _ReferralHistoryView(),
    );
  }
}

class _ReferralHistoryView extends StatefulWidget {
  const _ReferralHistoryView();

  @override
  State<_ReferralHistoryView> createState() => _ReferralHistoryViewState();
}

class _ReferralHistoryViewState extends State<_ReferralHistoryView> {
  final _scrollController = ScrollController();

  static const _navy = Color(0xFF0A243F);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        body: Stack(
          children: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final isLoading =
                    state is ProfileLoading || state is ProfileInitial;
                final summary =
                    state is ReferralSummaryLoaded ? state.summary : null;

                return Column(
                  children: [
                    _HistoryHero(
                      amount: summary?.walletCreditedAmount ?? 0,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _WalletNotice(),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Referrals',
                          style: GoogleFonts.inter(
                            color: _navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 22 / 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _ReferralList(
                              invites: summary?.invites ?? const [],
                              isLoading: isLoading,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            FrostedNavBar(),
          ],
        ),
      ),
    );
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({
    required this.amount,
    required this.isLoading,
  });

  final double amount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final amountText = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final safeTop = MediaQuery.paddingOf(context).top;
    const cardTopAfterSafeArea = 74.0;
    const cardHeight = 102.0;
    final gradientHeight = safeTop + cardTopAfterSafeArea + cardHeight / 2;
    final heroHeight = safeTop + cardTopAfterSafeArea + cardHeight;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: gradientHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.25, -1.1),
                  radius: 1.35,
                  colors: [
                    Color(0xFF8A4E00),
                    Color(0xFF17110A),
                    Color(0xFF050505),
                  ],
                  stops: [0, .46, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              height: cardTopAfterSafeArea + cardHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 47,
                    right: 47,
                    top: 15,
                    child: Text(
                      'Your referrals',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 22 / 15,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: cardTopAfterSafeArea,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Amount earned',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF596378),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 20 / 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isLoading)
                              const _Skeleton(width: 92, height: 32)
                            else
                              Text(
                                '₹$amountText',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF0A243F),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 42 / 28,
                                ),
                              ),
                          ],
                        ),
                      ),
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

class _WalletNotice extends StatelessWidget {
  const _WalletNotice();

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
        'Amount will be added to mobWallet. Valid for 30 days.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFF596378),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 18 / 12,
        ),
      ),
    );
  }
}

class _ReferralList extends StatelessWidget {
  const _ReferralList({required this.invites, required this.isLoading});

  final List<ReferralInviteEntity> invites;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Column(
          children: [_SkeletonInvite(), _SkeletonInvite(), _SkeletonInvite()]);
    }
    if (invites.isEmpty) {
      return const _EmptyReferrals();
    }
    return Column(
      children: [
        for (var i = 0; i < invites.length; i++) ...[
          _InviteRow(invite: invites[i]),
          if (i != invites.length - 1)
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
        ],
      ],
    );
  }
}

class _EmptyReferrals extends StatelessWidget {
  const _EmptyReferrals();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Image.asset(
            'assets/images/norefferals.webp',
            width: 136,
            height: 136,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'No referrals yet',
            textAlign: TextAlign.center,
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

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite});

  final ReferralInviteEntity invite;

  bool get _successful => invite.ordered || invite.rewarded;
  String get _status => _successful ? 'Order placed' : 'Order pending';

  @override
  Widget build(BuildContext context) {
    final name = invite.inviteeName.trim().isEmpty
        ? invite.inviteePhone
        : invite.inviteeName.trim();
    final amount = invite.inviterRewardAmount;

    return SizedBox(
      height: 75,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        invite.inviteePhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF596378),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 16 / 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _successful
                              ? const [Color(0xFFB5E6C5), Color(0x00B5E6C6)]
                              : const [Color(0xFFFFE0D1), Color(0x00FFE1D2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _status,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 16 / 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount > 0 ? '+₹${amount.toStringAsFixed(2)}' : '--',
            style: GoogleFonts.inter(
              color: amount > 0
                  ? const Color(0xFF07AD61)
                  : const Color(0xFF596378),
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

class _SkeletonInvite extends StatelessWidget {
  const _SkeletonInvite();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: Row(
        children: [
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _Skeleton(width: 110, height: 14),
                SizedBox(height: 8),
                _Skeleton(width: 170, height: 12),
              ])),
          _Skeleton(width: 64, height: 14),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
