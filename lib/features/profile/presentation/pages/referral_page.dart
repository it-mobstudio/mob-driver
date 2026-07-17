import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_history_page.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  static const String routeName = 'ReferralPage';
  static const String routePath = '/refer-a-friend';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ReferralSummaryLoadRequested()),
      child: const _ReferralView(),
    );
  }
}

class _ReferralView extends StatelessWidget {
  const _ReferralView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final isLoading = state is ProfileLoading || state is ProfileInitial;
          final summary = state is ReferralSummaryLoaded ? state.summary : null;
          final cachedReferral = _cachedReferralData();
          final referralCode =
              (summary?.referralCode.trim().isNotEmpty ?? false)
                  ? summary!.referralCode.trim()
                  : cachedReferral.code;
          final referralLink =
              (summary?.referralLink.trim().isNotEmpty ?? false)
                  ? summary!.referralLink.trim()
                  : cachedReferral.link;
          final canShare = referralCode.isNotEmpty;

          return Column(
            children: [
              _ReferralHeader(
                onBack: () => context.pop(),
                onSearch: () => context.push('/search'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReferralPromoSection(
                        referralCode: referralCode,
                        isLoading: isLoading && !canShare,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _YourReferralsCard(
                          onTap: () =>
                              context.push(ReferralHistoryPage.routePath),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                left: false,
                right: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: canShare
                          ? () => _shareReferral(
                                context,
                                referralCode,
                                referralLink,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF0A243F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Share referral link',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 21 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ({String code, String link}) _cachedReferralData() {
    final details = AuthSession.instance.userDetails;
    if (details == null || details.isEmpty) return (code: '', link: '');
    final flattened = _flattenReferralData(details);
    return (
      code: _firstNonEmpty(flattened, const [
        'referral_code',
        'referralCode',
        'refer_code',
        'referCode',
      ]),
      link: _firstNonEmpty(flattened, const [
        'referral_link',
        'referralLink',
      ]),
    );
  }

  Map<String, dynamic> _flattenReferralData(Map<String, dynamic> source) {
    final flattened = <String, dynamic>{};
    for (final key in const [
      'user_details',
      'user_data',
      'user',
      'profile',
      'account',
    ]) {
      final nested = source[key];
      if (nested is Map) {
        flattened.addAll(Map<String, dynamic>.from(nested));
      }
    }
    flattened.addAll(source);
    return flattened;
  }

  String _firstNonEmpty(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  Future<void> _shareReferral(
    BuildContext context,
    String referralCode,
    String referralLink,
  ) async {
    final link = referralLink.isNotEmpty
        ? referralLink
        : '${AppConfig.webAppBaseUrl}/?ref=$referralCode';

    final message = 'Hey! Need construction or interior materials in a flash? '
        "I've been using Mad over Buildings, and their QWIK 1-4 hour delivery is an absolute lifesaver. "
        'No more waiting around for supplies! Try it out for yourself: '
        'sign up with my code $referralCode to get ₹1,000 off your first order. $link';

    final whatsappUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: message));
      if (!context.mounted) return;
      TopSnackBar.show(
        context,
        message: 'Referral link copied - WhatsApp not available',
        type: TopSnackBarType.info,
      );
    }
  }
}

class _ReferralHeader extends StatelessWidget {
  const _ReferralHeader({required this.onBack, required this.onSearch});

  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 10),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const AppBackIcon(),
              ),
              const Spacer(),
              IconButton(
                onPressed: onSearch,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
                icon: const Icon(
                  Icons.search,
                  size: 24,
                  color: Color(0xFF0A243F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralPromoSection extends StatelessWidget {
  const _ReferralPromoSection({
    required this.referralCode,
    required this.isLoading,
  });

  final String referralCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasReferralCode = referralCode.trim().isNotEmpty;
    return SizedBox(
      height: 606,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 449,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 253,
            height: 196,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00F8E3A8), Color(0xFFE1C370)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            child: Text(
              'Refer a friend to',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 30 / 20,
              ),
            ),
          ),
          Positioned(
            top: 56,
            child: Text(
              'Get ₹1000',
              style: GoogleFonts.inter(
                color: const Color(0xFF00C48B),
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 48 / 36,
              ),
            ),
          ),
          Positioned(
            top: 118,
            child: InkWell(
              borderRadius: BorderRadius.circular(48),
              onTap: !hasReferralCode
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: referralCode),
                      );
                      if (!context.mounted) return;
                      TopSnackBar.show(
                        context,
                        message: 'Referral code copied',
                        type: TopSnackBarType.success,
                      );
                    },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoading ? 'Loading...' : referralCode,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.copy_outlined,
                      size: 17,
                      color: Color(0xFF0A243F),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 161,
            left: 34,
            right: 34,
            height: 205,
            child: Image.asset(
              'assets/images/Referandearnapp.webp',
              fit: BoxFit.contain,
            ),
          ),
          const Positioned(
            top: 370,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 166,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RewardCard(
                      iconAsset: 'assets/images/yourfrndget.svg',
                      heading: 'Your friend gets',
                      amount: '₹1000',
                      caption: 'after sign up',
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _RewardCard(
                      iconAsset: 'assets/images/youget.svg',
                      heading: 'You get',
                      amount: '₹1000',
                      caption: 'after their 1st order',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 556,
            left: 16,
            right: 16,
            child: Text(
              'Amount will be added to your mobWallet. Valid for 90 days. Up to 20% can be used per transaction.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF767C8F),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YourReferralsCard extends StatelessWidget {
  const _YourReferralsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 74,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your referrals',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your referrals and rewards',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8A8A8A),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1F2),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/greaterarrow.svg',
                    width: 6,
                    height: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
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
    return SizedBox(
      height: 166,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            height: 134,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 42, 8, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      heading,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF767C8F),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 30 / 20,
                      ),
                    ),
                    Text(
                      caption,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF767C8F),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SvgPicture.asset(
            iconAsset,
            width: 64,
            height: 64,
          ),
        ],
      ),
    );
  }
}
