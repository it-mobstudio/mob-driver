import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_profile_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_projects_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class MyAccountWidget extends StatefulWidget {
  const MyAccountWidget({super.key});

  static const String routeName = 'MyAccount';
  static const String routePath = '/myaccount';

  @override
  State<MyAccountWidget> createState() => _MyAccountWidgetState();
}

class _MyAccountWidgetState extends State<MyAccountWidget> {
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>()..add(ProfileLoadRequested());
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: const Scaffold(
        backgroundColor: _ProfileColors.background,
        body: _ProfileBody(),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = switch (state) {
          ProfileLoaded(:final profile) => profile,
          ProfileUpdated(:final profile) => profile,
          _ => ProfileEntity.empty,
        };

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ProfileHeader(profile: profile)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          iconAsset: 'assets/images/ordersprofile.svg',
                          title: 'Orders',
                          subtitle: 'View all orders',
                          onTap: () => context.push(OrdersPage.routePath),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _SummaryCard(
                          iconAsset: 'assets/images/walletprofile.svg',
                          title: 'Wallet',
                          subtitle: '₹1500',
                          onTap: () => context.push(WalletPointsPage.routePath),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ReferralCard(
                    onTap: () => context.push(ReferralPage.routePath),
                  ),
                  const SizedBox(height: 16),
                  _MenuCard(
                    items: [
                      _MenuItem(
                        iconAsset: 'assets/images/quotationreq.svg',
                        label: 'Quotation request',
                        onTap: () => context.push(RfqPage.routePath),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/addresses.svg',
                        label: 'Address',
                        onTap: () =>
                            context.push(AddressSelectionWidget.routePath),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/mobcreditprofile.svg',
                        label: 'mob Credit',
                        onTap: () =>
                            context.push(MobCreditProfilePage.routePath),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/myprojects.svg',
                        label: 'My projects',
                        onTap: () => context.push(MyProjectsPage.routePath),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/mobsupport.svg',
                        label: 'mob support',
                        onTap: () => _comingSoon(context, 'mob support'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'OTHER INFORMATION',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF67696D),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 20 / 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    items: [
                      _MenuItem(
                        iconAsset: 'assets/images/notifications.svg',
                        label: 'Notification preferences',
                        onTap: () =>
                            _comingSoon(context, 'Notification preferences'),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/aboutus.svg',
                        label: 'About us',
                        onTap: () => _comingSoon(context, 'About us'),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/faqs.svg',
                        label: 'FAQs',
                        onTap: () => _comingSoon(context, 'FAQs'),
                      ),
                      _MenuItem(
                        iconAsset: 'assets/images/becomepartner.svg',
                        label: 'Become a partner',
                        onTap: () => _comingSoon(context, 'Become a partner'),
                      ),
                      const _MenuItem(
                        iconAsset: 'assets/images/logout.svg',
                        label: 'Logout',
                        showChevron: false,
                        onTap: _logout,
                      ),
                    ],
                  ),
                  const _VersionFooter(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }

  static Future<void> _logout() async {
    await AuthSession.instance.signOut();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name.trim().isEmpty ? 'Welcome back' : profile.name;
    final phone = profile.phone.trim().isEmpty ? 'Your profile' : profile.phone;

    return ColoredBox(
      color: _ProfileColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xFFD0D4DC)),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.pushReplacement('/homepage'),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(child: AppBackIcon()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Row(
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            height: 1.48,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: .60),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MembershipBar(
                points: profile.rewardPoints,
                onTap: () => context.push(MobstarPage.routePath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipBar extends StatelessWidget {
  const _MembershipBar({
    required this.points,
    required this.onTap,
  });

  final int points;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: ShapeDecoration(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/bronze.svg',
                    width: 24,
                    height: 23,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/images/mobstar logo.svg',
                          width: 64,
                          height: 11,
                        ),
                        Text(
                          'Bronze member',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.43,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$points Points',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const _Chevron(color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(iconAsset, width: 24, height: 24),
              const SizedBox(height: 12),
              Text(title, style: _labelStyle),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _subtleStyle,
                    ),
                  ),
                  const _Chevron(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.onTap});

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
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/referandearn.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 16),
                Text('Refer and earn', style: _labelStyle),
                const SizedBox(width: 16),
                SvgPicture.asset(
                  'assets/images/rs1000.svg',
                  width: 61,
                  height: 24,
                ),
                const Spacer(),
                const _Chevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _MenuRow(item: items[index]),
              if (index != items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _DottedDivider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 4.0;
          const dashGap = 4.0;
          final dashCount =
              (constraints.maxWidth / (dashWidth + dashGap)).floor();

          return Row(
            children: List.generate(dashCount, (index) {
              return Padding(
                padding: EdgeInsets.only(
                    right: index == dashCount - 1 ? 0 : dashGap),
                child: const SizedBox(
                  width: dashWidth,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFE7EAEE)),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

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
                    style: _labelStyle,
                  ),
                ),
                if (item.showChevron) const _Chevron(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

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
            style: GoogleFonts.inter(
              color: const Color(0xFF9FA4AA),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 16 / 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({this.color = const Color(0xFF78838F)});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/arrow.svg',
      width: 12,
      height: 12,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

final TextStyle _labelStyle = GoogleFonts.inter(
  color: _ProfileColors.navy,
  fontSize: 15,
  fontWeight: FontWeight.w600,
  height: 22 / 15,
);

final TextStyle _subtleStyle = GoogleFonts.inter(
  color: const Color(0xFF67696D),
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.54,
);

abstract final class _ProfileColors {
  static const navy = Color(0xFF0A243F);
  static const background = Color(0xFFF0F0F0);
}
