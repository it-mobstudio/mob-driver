import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_profile_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_projects_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartBloc>().add(CartLoadRequested());
    });
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
      builder: (context, profileState) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            final profile = switch (profileState) {
              ProfileLoaded(:final profile) => profile,
              ProfileUpdated(:final profile) => profile,
              _ => ProfileEntity.empty,
            };
            final cartSummary = cartState is CartLoaded
                ? cartState.summary
                : CartSummaryEntity.empty;
            final account = cartSummary.account;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(profile: profile, account: account),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      _MobCreditCard(
                        account: account,
                        onTap: () =>
                            context.push(MobCreditProfilePage.routePath),
                      ),
                      const SizedBox(height: 16),
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
                              subtitle: _formatRupees(account.wallet),
                              onTap: () =>
                                  context.push(WalletPointsPage.routePath),
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
                            label: 'Addresses',
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
                            onTap: () => _comingSoon(context, 'My projects'),
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
                          color: const Color(0xFF717A84),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _MenuCard(
                        items: [
                          _MenuItem(
                            iconAsset: 'assets/images/notifications.svg',
                            label: 'Notification preferences',
                            onTap: () => _comingSoon(
                                context, 'Notification preferences'),
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
                            onTap: () =>
                                _comingSoon(context, 'Become a partner'),
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
  const _ProfileHeader({required this.profile, required this.account});

  final ProfileEntity profile;
  final CartAccountEntity account;

  @override
  Widget build(BuildContext context) {
    final name = account.fullName.trim().isNotEmpty
        ? account.fullName
        : (profile.name.trim().isEmpty ? 'Welcome back' : profile.name);
    final phone = account.phoneNumber.trim().isNotEmpty
        ? account.phoneNumber
        : (profile.phone.trim().isEmpty ? 'Your profile' : profile.phone);
    final profileImage = account.profileImage.trim();
    final points = account.mobStarPoints != 0
        ? account.mobStarPoints
        : profile.rewardPoints;
    final membership = account.membership;

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
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.pushReplacement('/homepage'),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 19,
                      color: _ProfileColors.navy,
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
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage.isEmpty
                        ? SvgPicture.asset(
                            'assets/icons/profile.svg',
                            width: 31,
                            height: 31,
                          )
                        : null,
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
                            height: 31 / 21,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB8C4D0),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 20 / 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MembershipBar(
                points: points,
                membership: membership,
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
    required this.membership,
    required this.onTap,
  });

  final int points;
  final String membership;
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
                  _mobStarAsset(membership),
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
                        '$membership member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$points Points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(Icons.chevron_right, color: Colors.white, size: 12),
              ],
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
                    const Icon(
                      Icons.chevron_right,
                      size: 12,
                      color: Color(0xFF78838F),
                    ),
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

class _MobCreditCard extends StatelessWidget {
  const _MobCreditCard({required this.account, required this.onTap});

  final CartAccountEntity account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final creditLimit = account.rupifiCurrentLimit != 0
        ? account.rupifiCurrentLimit
        : account.mobCreditSanctioned;
    final available = account.mobCreditAvailable != 0
        ? account.mobCreditAvailable
        : creditLimit - account.rupifiBalance;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF55A77B), Color(0xFF0D889C)],
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/mobcreditlogo.svg',
                        width: 92,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Credit limit: ${_formatRupees(creditLimit)}',
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 20 / 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: .22),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Available balance',
                          softWrap: true,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 20 / 13,
                          ),
                        ),
                      ),
                      Text(
                        _formatRupees(available),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 24 / 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                const Icon(
                  Icons.chevron_right,
                  size: 12,
                  color: Color(0xFF78838F),
                ),
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
                if (item.showChevron)
                  const Icon(
                    Icons.chevron_right,
                    size: 12,
                    color: Color(0xFF78838F),
                  ),
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
          Text(
            'mob∷',
            style: GoogleFonts.inter(
              color: const Color(0xFFC5C8CC),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'APP VERSION 0.2.456',
            style: GoogleFonts.inter(
              color: const Color(0xFF9FA4AA),
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
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
  color: const Color(0xFF747D87),
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 20 / 13,
);

String _formatRupees(double value) {
  final text =
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  return '₹$text';
}

String _mobStarAsset(String level) {
  final lower = level.toLowerCase();
  if (lower.contains('diamond') || lower.contains('dimond')) {
    return 'assets/images/mobStar/dimond.svg';
  }
  if (lower.contains('platinum')) return 'assets/images/mobStar/platinum.svg';
  if (lower.contains('gold')) return 'assets/images/mobStar/gold.svg';
  if (lower.contains('silver')) return 'assets/images/mobStar/silver.svg';
  return 'assets/images/mobStar/bronze.svg';
}

abstract final class _ProfileColors {
  static const navy = Color(0xFF0A243F);
  static const background = Color(0xFFF0F0F0);
}
