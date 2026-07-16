import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_projects_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class MobCreditProfilePage extends StatelessWidget {
  const MobCreditProfilePage({super.key});

  static const String routeName = 'ProfileMobCredit';
  static const String routePath = '/profile/mob-credit';

  static const _primary = Color(0xFF0A243F);
  static const _muted = Color(0xFF767C8F);
  static const _pale = Color(0xFFF8FAF7);
  static const _background = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _background,
      body: _MobCreditProfileBody(),
    );
  }
}

class _MobCreditProfileBody extends StatelessWidget {
  const _MobCreditProfileBody();

  @override
  Widget build(BuildContext context) {
    final profile = _CreditProfileData.fromSession();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _CreditProfileHeader(profile: profile)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
          sliver: SliverList.list(
            children: [
              _DesignWidth(
                child: Row(
                  children: [
                    Expanded(
                      child: _ProfileSummaryCard(
                        iconAsset: 'assets/images/ordersprofile.svg',
                        title: 'Orders',
                        subtitle: 'View all orders',
                        onTap: () => context.push(OrdersPage.routePath),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ProfileSummaryCard(
                        iconAsset: 'assets/images/walletprofile.svg',
                        title: 'Wallet',
                        subtitle: _currency(profile.walletBalance),
                        onTap: () => context.push(WalletPointsPage.routePath),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DesignWidth(
                child: _ProfileReferralCard(
                  onTap: () => context.push(ReferralPage.routePath),
                ),
              ),
              const SizedBox(height: 16),
              _DesignWidth(
                child: _ProfileMenuCard(
                  items: [
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/quotationreq.svg',
                      label: 'Quotation request',
                      onTap: () => context.push(RfqPage.routePath),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/addresses.svg',
                      label: 'Address',
                      onTap: () =>
                          context.push(AddressSelectionWidget.routePath),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/mobcreditprofile.svg',
                      label: 'mob Credit',
                      onTap: () => _comingSoon(context, 'mob Credit'),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/myprojects.svg',
                      label: 'My projects',
                      onTap: () => context.push(MyProjectsPage.routePath),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/mobsupport.svg',
                      label: 'mob support',
                      onTap: () => _comingSoon(context, 'mob support'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _DesignWidth(
                child: Text(
                  'OTHER INFORMATION',
                  style: _inter(
                    color: const Color(0xFF67696D),
                    size: 13,
                    weight: FontWeight.w400,
                    height: 20 / 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DesignWidth(
                child: _ProfileMenuCard(
                  items: [
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/notifications.svg',
                      label: 'Notification preferences',
                      onTap: () =>
                          _comingSoon(context, 'Notification preferences'),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/aboutus.svg',
                      label: 'About us',
                      onTap: () => _comingSoon(context, 'About us'),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/faqs.svg',
                      label: 'FAQs',
                      onTap: () => _comingSoon(context, 'FAQs'),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/becomepartner.svg',
                      label: 'Become a partner',
                      onTap: () => _comingSoon(context, 'Become a partner'),
                    ),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/logout.svg',
                      label: 'Logout',
                      onTap: () => AuthSession.instance.signOut(),
                    ),
                  ],
                ),
              ),
              const _CreditProfileFooter(),
            ],
          ),
        ),
      ],
    );
  }

  static void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }
}

class _CreditProfileHeader extends StatelessWidget {
  const _CreditProfileHeader({required this.profile});

  final _CreditProfileData profile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: MobCreditProfilePage._primary),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
          child: Column(
            children: [
              _DesignWidth(
                child: _CreditTopBar(
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/homepage');
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              _DesignWidth(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: SvgPicture.asset(
                        'assets/images/profile.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _inter(
                              color: Colors.white,
                              size: 21,
                              weight: FontWeight.w700,
                              height: 31 / 21,
                            ),
                          ),
                          Text(
                            profile.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _inter(
                              color: Colors.white.withValues(alpha: .6),
                              size: 13,
                              weight: FontWeight.w500,
                              height: 20 / 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DesignWidth(
                child: _ProfileMembershipBar(
                  points: profile.rewardPoints,
                  onTap: () => context.push(MobstarPage.routePath),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditTopBar extends StatelessWidget {
  const _CreditTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 6,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1,
                  color: Color(0xFFD0D4DC),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onBack,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/Arrow.svg',
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMembershipBar extends StatelessWidget {
  const _ProfileMembershipBar({
    required this.points,
    required this.onTap,
  });

  final int points;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/bronze.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/images/mobstar logo.svg',
                        width: 57,
                        height: 10,
                      ),
                      Text(
                        'Bronze member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _profileMedium(Colors.white, 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$points Points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _profileMedium(Colors.white, 14),
                ),
                const SizedBox(width: 7),
                const _ProfileChevron(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 112,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(iconAsset, width: 24, height: 24),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _profileLabel,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _profileSubtle,
                      ),
                    ),
                    const _ProfileChevron(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileReferralCard extends StatelessWidget {
  const _ProfileReferralCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/referandearn.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'Refer and earn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _profileLabel,
                  ),
                ),
                const SizedBox(width: 12),
                SvgPicture.asset(
                  'assets/images/rs1000.svg',
                  width: 61,
                  height: 24,
                ),
                const Spacer(),
                const _ProfileChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _ProfileMenuRow(item: items[index]),
              if (index != items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 0,
                    thickness: 1,
                    color: Color(0xFFE7EAEE),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.item});

  final _ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  item.iconAsset,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _profileLabel,
                  ),
                ),
                const _ProfileChevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditProfileFooter extends StatelessWidget {
  const _CreditProfileFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 26, 0, 16),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/images/moblogo.svg',
            width: 88,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFFD2D4D8),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'APP VERSION 0.2.456',
            style: _inter(
              color: const Color(0xFF67696D),
              size: 11,
              weight: FontWeight.w400,
              height: 16 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChevron extends StatelessWidget {
  const _ProfileChevron({this.color = const Color(0xFF78838F)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/Arrow.svg',
      width: 12,
      height: 12,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _DesignWidth extends StatelessWidget {
  const _DesignWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth <= 375
            ? 16.0
            : (constraints.maxWidth - 343) / 2;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding.clamp(16.0, double.infinity),
          ),
          child: child,
        );
      },
    );
  }
}

class _CreditProfileData {
  const _CreditProfileData({
    required this.name,
    required this.phone,
    required this.rewardPoints,
    required this.walletBalance,
  });

  final String name;
  final String phone;
  final int rewardPoints;
  final double walletBalance;

  factory _CreditProfileData.fromSession() {
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    final name = _firstString(user, const [
      'full_name',
      'fullName',
      'name',
      'first_name',
      'username',
    ]);
    final phone = _firstString(user, const [
      'phone',
      'phone_number',
      'mobile',
      'business_mobile',
      'email_or_phone',
    ]);
    final wallet = _numValue(
        user,
        const [
          'wallet_balance',
          'mob_wallet_balance',
          'wallet',
          'mob_wallet',
        ],
        fallback: 0);
    final points = _numValue(
        user,
        const [
          'reward_points',
          'mobstar_points',
          'points',
          'total_points',
        ],
        fallback: 0);

    return _CreditProfileData(
      name: name,
      phone: _formatPhone(phone),
      rewardPoints: points.round(),
      walletBalance: wallet,
    );
  }
}

TextStyle get _profileLabel => _inter(
      color: MobCreditProfilePage._primary,
      size: 15,
      weight: FontWeight.w600,
      height: 22 / 15,
    );

TextStyle get _profileSubtle => _inter(
      color: const Color(0xFF67696D),
      size: 13,
      weight: FontWeight.w400,
      height: 20 / 13,
    );

TextStyle _profileMedium(Color color, double size) => _inter(
      color: color,
      size: size,
      weight: FontWeight.w500,
      height: 20 / size,
    );

String _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    if (value is Map) {
      final nested = _firstString(Map<String, dynamic>.from(value), const [
        'balance',
        'wallet_balance',
        'name',
        'phone',
        'value',
      ]);
      if (nested.isNotEmpty) return nested;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10) return '+91 ${digits.substring(digits.length - 10)}';
  return phone.isEmpty ? '+91 8976645323' : phone;
}

class MobCreditHero extends StatelessWidget {
  const MobCreditHero({
    super.key,
    this.onBack,
    this.showBackButton = true,
  });

  final VoidCallback? onBack;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final logoTop = top + (showBackButton ? 44.0 : 23.0);
    final titleTop = top + (showBackButton ? 96.0 : 83.0);
    const titleWidth = 179.0;
    const titleHeight = 80.0;
    final firstFeatureTop = titleTop + titleHeight + 28;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final heroHeight = top + 424;
        final architectWidth = (width * .43).clamp(142.0, 176.0);
        final architectHeight = (heroHeight * .56).clamp(238.0, 268.0);

        return SizedBox(
          height: heroHeight,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/mobcreditbg.svg',
                    fit: BoxFit.fill,
                  ),
                ),
                if (showBackButton)
                  Positioned(
                    left: 16,
                    top: top + 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: .12),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack,
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: AppBackIcon(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 25,
                  top: logoTop,
                  child: SvgPicture.asset(
                    'assets/images/mobcredwithtick.svg',
                    width: 146,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 16,
                  top: titleTop,
                  child: SizedBox(
                    width: titleWidth,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Build now, ',
                            style: _inter(
                              color: Colors.white,
                              size: 32,
                              weight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          TextSpan(
                            text: 'pay later',
                            style: _inter(
                              color: const Color(0xFF0DE09F),
                              size: 32,
                              weight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: firstFeatureTop,
                  child: const _HeroFeature(
                    icon: 'assets/images/uptoo25lakh.svg',
                    label: 'Upto 25 lakhs',
                  ),
                ),
                Positioned(
                  left: 16,
                  top: firstFeatureTop + 40,
                  child: const _HeroFeature(
                    icon: 'assets/images/collateral.svg',
                    label: 'No collateral',
                  ),
                ),
                Positioned(
                  left: 16,
                  top: firstFeatureTop + 80,
                  child: const _HeroFeature(
                    icon: 'assets/images/replayment.svg',
                    label: 'Upto 90 days repayment',
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/mobcreditarchitect.webp',
                    width: architectWidth,
                    height: architectHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 26,
                  child: Row(
                    children: [
                      Text(
                        'Powered by',
                        style: _inter(
                          color: Colors.white.withValues(alpha: .6),
                          size: 12,
                          weight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/images/muthoot.svg',
                        width: 65,
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: 22, height: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: _inter(
            color: Colors.white,
            size: 14,
            weight: FontWeight.w500,
            height: 1.43,
          ),
        ),
      ],
    );
  }
}

class MobCreditSectionTitle extends StatelessWidget {
  MobCreditSectionTitle(String text, {super.key}) : span = TextSpan(text: text);
  const MobCreditSectionTitle.rich(this.span, {super.key});

  final TextSpan span;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      span,
      style: _inter(
        color: MobCreditProfilePage._primary,
        size: 16,
        weight: FontWeight.w700,
        height: 24 / 16,
      ),
    );
  }
}

class MobCreditAudiencePills extends StatelessWidget {
  const MobCreditAudiencePills({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: ShapeDecoration(
        color: const Color(0xFFF8FAF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _pillText('Architects'),
          const SizedBox(width: 16),
          _divider(),
          const SizedBox(width: 16),
          _pillText('Contractors'),
          const SizedBox(width: 16),
          _divider(),
          const SizedBox(width: 16),
          _pillText('Builders'),
        ],
      ),
    );
  }

  Widget _pillText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: _inter(
        color: MobCreditProfilePage._primary,
        size: 14,
        weight: FontWeight.w500,
        height: 1.43,
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 2,
      height: 18,
      decoration: ShapeDecoration(
        color: const Color(0xFFD9D9D9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class MobCreditTermCard extends StatelessWidget {
  const MobCreditTermCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: ShapeDecoration(
        color: const Color(0xFFF8FAF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            icon,
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0A243F),
                    fontSize: 17,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.41,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF0A243F),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
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

class MobCreditHowItWorksCard extends StatefulWidget {
  const MobCreditHowItWorksCard({super.key});

  @override
  State<MobCreditHowItWorksCard> createState() =>
      _MobCreditHowItWorksCardState();
}

class _MobCreditHowItWorksCardState extends State<MobCreditHowItWorksCard> {
  static const _steps = [
    _MobCreditHowStep(
      title: 'Apply online',
      image: 'assets/images/Step1.webp',
    ),
    _MobCreditHowStep(
      title: 'Get approved',
      image: 'assets/images/Step2.webp',
    ),
    _MobCreditHowStep(
      title: 'Use mobCREDIT anywhere',
      image: 'assets/images/mobileimg.webp',
    ),
  ];

  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 456,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.50, -0.00),
          end: Alignment(0.50, 1.00),
          colors: [Color(0xFFF1F1F2), Color(0xFFBDE6E3)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _steps.length,
            onPageChanged: (index) => setState(() => _currentStep = index),
            itemBuilder: (context, index) {
              final step = _steps[index];
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 72,
                    left: 16,
                    right: 16,
                    child: Text(
                      step.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0A243F),
                        fontSize: 17,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        height: 1.41,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.asset(
                      step.image,
                      width: 248,
                      height: 320,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 16,
            child: _StepDots(
              activeIndex: _currentStep,
              onStepTap: _goToStep,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobCreditHowStep {
  const _MobCreditHowStep({
    required this.title,
    required this.image,
  });

  final String title;
  final String image;
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.activeIndex,
    required this.onStepTap,
  });

  final int activeIndex;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _dot('1', 0),
          const SizedBox(width: 4),
          _line(),
          const SizedBox(width: 4),
          _dot('2', 1),
          const SizedBox(width: 4),
          _line(),
          const SizedBox(width: 4),
          _dot('3', 2),
        ],
      ),
    );
  }

  Widget _dot(String text, int index) {
    final active = index == activeIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onStepTap(index),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: active ? const Color(0xFF0A243F) : const Color(0xFFEAEAEA),
          shape: const OvalBorder(),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: _inter(
            color: active ? Colors.white : const Color(0xFF767C8F),
            size: 12,
            weight: FontWeight.w700,
            height: 1.50,
          ),
        ),
      ),
    );
  }

  Widget _line() {
    return Container(
      width: 16,
      height: 2,
      decoration: ShapeDecoration(
        color: const Color(0xFFEAEAEA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class MobCreditDocumentsCard extends StatelessWidget {
  const MobCreditDocumentsCard({
    super.key,
    required this.onViewDocuments,
  });

  final VoidCallback onViewDocuments;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep these\ndocuments ready',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 17,
                    weight: FontWeight.w700,
                    height: 24 / 17,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onViewDocuments,
                    borderRadius: BorderRadius.circular(8),
                    child: Ink(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'View documents',
                            style: _inter(
                              color: const Color(0xFF053961),
                              size: 12,
                              weight: FontWeight.w600,
                              height: 1.50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            right: -16,
            bottom: -8,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/Documentsrequired.webp',
                width: 133,
                height: 113,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobCreditIndiaCard extends StatelessWidget {
  const MobCreditIndiaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            top: 10,
            child: SvgPicture.asset(
              'assets/images/indiamap.svg',
              // width: 112,
              // height: 122,
            ),
          ),
          const SizedBox(
            height: 128,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use mobCREDIT\nacross India',
                    style: TextStyle(
                      color: Color(0xFF0A243F),
                      fontSize: 17,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.41,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'With any registered sellers',
                    style: TextStyle(
                      color: Color(0xFF053961),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.50,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 152,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment(1.00, 0.46),
          end: Alignment(-0.00, 0.47),
          colors: [Color(0xFFF8FAF7), Color(0xFFD5ECEA)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: child,
    );
  }
}

class MobCreditTestimonialsCarousel extends StatefulWidget {
  const MobCreditTestimonialsCarousel({super.key});

  @override
  State<MobCreditTestimonialsCarousel> createState() =>
      _MobCreditTestimonialsCarouselState();
}

class _MobCreditTestimonialsCarouselState
    extends State<MobCreditTestimonialsCarousel> {
  static const _testimonials = [
    _MobCreditTestimonial(
      quote:
          'mobCREDIT has simplified the process, eliminating the hassle of constantly requesting credit from suppliers. Now, we focus on what matters most—building! Highly recommend it!',
      name: 'Sankalp Solanki',
      role: 'Architect',
    ),
    _MobCreditTestimonial(
      quote:
          'Getting credit for materials became smoother and faster. The repayment window helps us manage project purchases with much better flexibility.',
      name: 'Rohit Mehta',
      role: 'Contractor',
    ),
    _MobCreditTestimonial(
      quote:
          'mobCREDIT lets us keep work moving without waiting on supplier credit approvals every time. It has been genuinely useful on active sites.',
      name: 'Aarav Shah',
      role: 'Builder',
    ),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients || _testimonials.isEmpty) return;
      final nextIndex = (_activeIndex + 1) % _testimonials.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 208,
          child: PageView.builder(
            controller: _controller,
            itemCount: _testimonials.length,
            onPageChanged: (index) {
              setState(() => _activeIndex = index);
              _startTimer();
            },
            itemBuilder: (context, index) {
              final testimonial = _testimonials[index];
              return MobCreditTestimonialCard(
                quote: testimonial.quote,
                name: testimonial.name,
                role: testimonial.role,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        MobCreditCarouselDots(
          itemCount: _testimonials.length,
          activeIndex: _activeIndex,
        ),
      ],
    );
  }
}

class MobCreditTestimonialCard extends StatelessWidget {
  const MobCreditTestimonialCard({
    super.key,
    required this.quote,
    required this.name,
    required this.role,
  });

  final String quote;
  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: MobCreditProfilePage._pale,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote,
            color: Color(0xFFD9D9D9),
            size: 30,
          ),
          const SizedBox(height: 14),
          Text(
            quote,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF767C8F),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          const Spacer(),
          Text(
            name,
            style: _inter(
              color: MobCreditProfilePage._primary,
              size: 12,
              weight: FontWeight.w600,
              height: 18 / 12,
            ),
          ),
          Text(
            role,
            style: _inter(
              color: MobCreditProfilePage._muted,
              size: 12,
              weight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobCreditTestimonial {
  const _MobCreditTestimonial({
    required this.quote,
    required this.name,
    required this.role,
  });

  final String quote;
  final String name;
  final String role;
}

class MobCreditCarouselDots extends StatelessWidget {
  const MobCreditCarouselDots({
    super.key,
    required this.itemCount,
    required this.activeIndex,
  });

  final int itemCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final safeCount = itemCount < 0 ? 0 : itemCount;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(safeCount, (index) {
          final isActive = index == activeIndex.clamp(0, safeCount - 1);
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
            child: Container(
              width: 10,
              height: 10,
              decoration: ShapeDecoration(
                color: isActive
                    ? const Color(0xFF0A243F)
                    : const Color(0xFFD9D9D9),
                shape: const OvalBorder(),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class MobCreditSupportCard extends StatelessWidget {
  const MobCreditSupportCard({
    super.key,
    required this.onChatTap,
  });

  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [MobCreditProfilePage._pale, Color(0xFFD7F2E1)],
        ),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: 185,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get more clarity about mobCREDIT',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 16,
                    weight: FontWeight.w700,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chat with us about limit, how to apply, documents required etc',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 12,
                    weight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: onChatTap,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF37BD68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: SvgPicture.asset(
                      'assets/images/whatsapp.svg',
                      width: 18,
                      height: 18,
                    ),
                    label: Text(
                      'Chat with us',
                      style: _inter(
                        color: Colors.white,
                        size: 12,
                        weight: FontWeight.w600,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/Chat with us.webp',
                width: 126,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobCreditFaqRow extends StatelessWidget {
  const MobCreditFaqRow({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: Colors.white.withValues(alpha: .1),
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFDEDEDE),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Frequently asked questions',
                  style: TextStyle(
                    color: Color(0xFF0A243F),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.54,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/images/Arrow.svg',
                width: 12,
                height: 12,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0A243F),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _numValue(
  Map<String, dynamic> map,
  List<String> keys, {
  required double fallback,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '').trim());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

String _currency(double value) {
  final formatter = NumberFormat('#,##0.##', 'en_IN');
  return '₹${formatter.format(value)}';
}

TextStyle _inter({
  required Color color,
  required double size,
  required FontWeight weight,
  double? height,
}) {
  return GoogleFonts.inter(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
  );
}
