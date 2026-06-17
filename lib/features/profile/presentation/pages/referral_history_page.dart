import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _ReferralHistoryView extends StatelessWidget {
  const _ReferralHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A243F), size: 22),
        ),
        title: Text(
          'Referrals',
          style: GoogleFonts.inter(
            color: const Color(0xFF0A243F),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search, color: Color(0xFF0A243F), size: 24),
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final isLoading = state is ProfileLoading || state is ProfileInitial;
          final summary = state is ReferralSummaryLoaded ? state.summary : null;
          final referralCode = summary?.referralCode ?? '';
          final referralLink = summary?.referralLink ?? '';
          final invites = summary?.invites ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                _HeroCard(
                  referralCode: referralCode,
                  referralLink: referralLink,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 12),
                _ReferralsTable(invites: invites, isLoading: isLoading),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Hero card (horizontal layout matching MobReferral.jsx) ────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.referralCode,
    required this.referralLink,
    required this.isLoading,
  });

  final String referralCode;
  final String referralLink;
  final bool isLoading;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final link = referralLink.isNotEmpty
        ? referralLink
        : '${AppConfig.webAppBaseUrl}/?ref=$referralCode';
    final message =
        'Hey! Need construction or interior materials in a flash? '
        "I've been using Mad over Buildings, and their QWIK 1-4 hour delivery is an absolute lifesaver. "
        'No more waiting around for supplies! Try it out for yourself: '
        'sign up with my code $referralCode to get ₹1,000 off your first order. $link';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: message));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral link copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: text left, image right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refer a friend to',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                      ),
                    ),
                    Text(
                      'Get ₹1000',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF00C48B),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 36 / 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Code + Share row
                    Row(
                      children: [
                        InkWell(
                          onTap: isLoading ? null : () => _copyCode(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLoading ? '...' : referralCode,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0A243F),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.copy_outlined,
                                  size: 14,
                                  color: Color(0xFF0A243F),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: isLoading
                              ? null
                              : () => _shareWhatsApp(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A243F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Share',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/images/referral_hero.png',
                width: 120,
                height: 100,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Reward cards row
          const Row(
            children: [
              Expanded(
                child: _SmallRewardCard(
                  iconAsset: 'assets/images/yourfrndget.svg',
                  heading: 'Your friend gets',
                  amount: '₹1000',
                  caption: 'upon sign up',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SmallRewardCard(
                  iconAsset: 'assets/images/youget.svg',
                  heading: 'You get',
                  amount: '₹1000',
                  caption: 'after their 1st order',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Amount will be added to mobWallet. Valid for 90 days.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF767C8F),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SmallRewardCard extends StatelessWidget {
  const _SmallRewardCard({
    required this.iconAsset,
    required this.heading,
    required this.amount,
    required this.caption,
  });

  final String iconAsset;
  final String heading;
  final String amount;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconAsset, width: 32, height: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 11,
                    height: 16 / 11,
                  ),
                ),
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 22 / 15,
                  ),
                ),
                Text(
                  caption,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 11,
                    height: 16 / 11,
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

// ── Referrals table ───────────────────────────────────────────────────────────

class _ReferralsTable extends StatelessWidget {
  const _ReferralsTable({
    required this.invites,
    required this.isLoading,
  });

  final List<ReferralInviteEntity> invites;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your Referrals',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'DETAILS',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF767C8F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    '1ST ORDER STATUS',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF767C8F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    'AMOUNT',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF767C8F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          if (isLoading)
            ...[1, 2, 3].map((_) => const _SkeletonRow())
          else if (invites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No referrals yet.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...invites.map((invite) => _InviteRow(invite: invite)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite});

  final ReferralInviteEntity invite;

  String get _statusLabel {
    if (invite.rewarded) return 'Reward posted';
    if (invite.ordered) return 'Order placed';
    return 'Order pending';
  }

  Color get _statusColor {
    if (invite.rewarded) return const Color(0xFF00C48B);
    if (invite.ordered) return const Color(0xFF2F80ED);
    return const Color(0xFF767C8F);
  }

  String get _amountLabel {
    final amt = invite.inviterRewardAmount;
    return amt > 0 ? '+₹${amt.toStringAsFixed(0)}' : '-';
  }

  @override
  Widget build(BuildContext context) {
    final name = invite.inviteeName.isNotEmpty
        ? invite.inviteeName
        : invite.inviteePhone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Details
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (invite.inviteeName.isNotEmpty &&
                    invite.inviteePhone.isNotEmpty)
                  Text(
                    invite.inviteePhone,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF767C8F),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Amount
          SizedBox(
            width: 56,
            child: Text(
              _amountLabel,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                color: invite.inviterRewardAmount > 0
                    ? const Color(0xFF00C48B)
                    : const Color(0xFF767C8F),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: 100, height: 12),
                SizedBox(height: 6),
                _Shimmer(width: 80, height: 10),
              ],
            ),
          ),
          Expanded(flex: 5, child: _Shimmer(width: 80, height: 24)),
          SizedBox(width: 56, child: _Shimmer(width: 40, height: 12)),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.width, required this.height});

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
