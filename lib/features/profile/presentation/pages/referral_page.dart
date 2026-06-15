import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  static const String routeName = 'ReferralPage';
  static const String routePath = '/refer-a-friend';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ProfileLoadRequested()),
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
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final profile = switch (state) {
              ProfileLoaded(:final profile) => profile,
              ProfileUpdated(:final profile) => profile,
              _ => ProfileEntity.empty,
            };
            final referralCode = _referralCode(profile);

            return Column(
              children: [
                _ReferralHeader(
                  onBack: () => context.pop(),
                  onSearch: () => context.push('/search'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _ReferralContent(
                      referralCode: referralCode,
                      isLoading:
                          state is ProfileLoading || state is ProfileInitial,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _shareReferral(context, referralCode),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF0A243F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Share referral link',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 21 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _referralCode(ProfileEntity profile) {
    if (profile.referralCode.trim().isNotEmpty) {
      return profile.referralCode.trim().toUpperCase();
    }

    final compactName =
        profile.name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final namePart = compactName.isEmpty
        ? 'MOB'
        : compactName.substring(0, compactName.length.clamp(0, 5));
    final digits = profile.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix =
        digits.length >= 2 ? digits.substring(digits.length - 2) : '01';
    return '$namePart$suffix';
  }

  Future<void> _shareReferral(
    BuildContext context,
    String referralCode,
  ) async {
    final referralLink = 'https://madoverbuildings.com/referral/$referralCode';
    await Clipboard.setData(
      ClipboardData(
        text: 'Join MOB with my referral code $referralCode: $referralLink',
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral link copied')),
    );
  }
}

class _ReferralHeader extends StatelessWidget {
  const _ReferralHeader({
    required this.onBack,
    required this.onSearch,
  });

  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              icon: const Icon(
                Icons.arrow_back,
                size: 22,
                color: Color(0xFF0A243F),
              ),
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
    );
  }
}

class _ReferralContent extends StatelessWidget {
  const _ReferralContent({
    required this.referralCode,
    required this.isLoading,
  });

  final String referralCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 556,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 433,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 237,
            height: 196,
            child: DecoratedBox(
              decoration: const BoxDecoration(
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
            top: 0,
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
            top: 40,
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
            top: 102,
            child: InkWell(
              borderRadius: BorderRadius.circular(48),
              onTap: isLoading
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: referralCode),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code copied')),
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
            top: 142,
            child: SvgPicture.asset(
              'assets/images/Vector.svg',
              width: 183,
              height: 180,
            ),
          ),
          Positioned(
            top: 145,
            left: 34,
            right: 34,
            height: 205,
            child: Image.asset(
              'assets/images/referral_hero.png',
              fit: BoxFit.contain,
            ),
          ),
          const Positioned(
            top: 366,
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
            top: 516,
            left: 16,
            right: 16,
            child: Text(
              'Amount will be added to mobWallet.\nValid for 30 days.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF767C8F),
                fontSize: 14,
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
