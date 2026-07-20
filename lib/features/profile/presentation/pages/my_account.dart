import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:m_o_b_demand_side/core/app_runtime/app_version_checker.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_dashboard_page.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_profile_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/dev_info_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/account_privacy_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mob_support_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_projects_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/personal_info_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/upgrade_to_pro_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';
import 'package:m_o_b_demand_side/shared/widgets/frosted_nav_bar.dart';
import 'package:m_o_b_demand_side/shared/mob_credit.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/scaffold_with_nav_bar.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';

class MyAccountWidget extends StatefulWidget {
  const MyAccountWidget({super.key});

  static const String routeName = 'MyAccount';
  static const String routePath = '/myaccount';

  @override
  State<MyAccountWidget> createState() => _MyAccountWidgetState();
}

class _MyAccountWidgetState extends State<MyAccountWidget> {
  late final ProfileBloc _profileBloc;
  final _scrollController = ScrollController();
  bool _frosted = false;
  AppVersionInfo? _versionInfo;
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _profileBloc = sl<ProfileBloc>()..add(ProfileLoadRequested());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartBloc>().add(CartLoadRequested());
    });
    _scrollController.addListener(_onScroll);
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    final info = await fetchAppVersionInfo();
    if (!mounted || info == null) return;
    final packageInfo = await PackageInfo.fromPlatform();
    final decision = evaluateAppUpdate(
      info: info,
      currentVersion: packageInfo.version,
    );
    if (!mounted || decision == null || !decision.updateAvailable) return;
    setState(() {
      _versionInfo = info;
      _updateAvailable = true;
    });
  }

  void _onScroll() {
    final shouldFrost = _scrollController.offset > 8;
    if (shouldFrost != _frosted) setState(() => _frosted = shouldFrost);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileBloc,
      child: Scaffold(
        backgroundColor: _ProfileColors.background,
        body: Stack(
          children: [
            _ProfileBody(
              scrollController: _scrollController,
              updateAvailable: _updateAvailable,
              versionInfo: _versionInfo,
            ),
            FrostedNavBar(
              frosted: _frosted,
              onBack: () => context.go('/homepage'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.scrollController,
    required this.updateAvailable,
    required this.versionInfo,
  });

  final ScrollController scrollController;
  final bool updateAvailable;
  final AppVersionInfo? versionInfo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            // Show a skeleton until both blocs have reached a terminal
            // state at least once — rendering real widgets against empty
            // placeholder entities in the meantime caused a visible flash
            // (default "Welcome back" name, zeroed balances, Apply-now
            // mobCREDIT card) the instant real data arrived.
            final isProfileReady = profileState is ProfileLoaded ||
                profileState is ProfileUpdated ||
                profileState is ProfileError;
            final isCartReady = cartState is CartLoaded ||
                cartState is CartError ||
                cartState is CartRequiresLogin;
            if (!isProfileReady || !isCartReady) {
              return _MyAccountSkeleton(scrollController: scrollController);
            }

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
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(profile: profile, account: account),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      if (resolveMobCreditStatus(account) ==
                          MobCreditStatus.active) ...[
                        MobCreditCard(
                          account: account,
                          onManage: () =>
                              context.push(MobCreditDashboardPage.routePath),
                          onApply: () =>
                              context.push(MobCreditProfilePage.routePath),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                              subtitle: formatRupees(account.wallet),
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
                      // Only shown when an update is actually available —
                      // hidden once the app is up to date.
                      if (updateAvailable) ...[
                        _AppUpdateCard(
                          updateAvailable: updateAvailable,
                          onTap: () =>
                              _showUpdateAvailable(context, versionInfo),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                            onTap: () => context.push(
                              AddressSelectionWidget.routePath,
                              extra: {'showSearch': false, 'selectable': false},
                            ),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/personalinfo.svg',
                            label: 'Personal info',
                            onTap: () =>
                                context.push(PersonalInfoPage.routePath),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/mobcreditprofile.svg',
                            label: 'mob Credit',
                            onTap: () => context.push(
                              MobCreditProfilePage.routePath,
                              extra: {'showBackButton': true},
                            ),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/myprojects.svg',
                            label: 'My projects',
                            onTap: () => context.push(MyProjectsPage.routePath),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/mobsupport.svg',
                            label: 'mob support',
                            onTap: () => context.push(MobSupportPage.routePath),
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
                            iconAsset: 'assets/images/upgradeicon.svg',
                            label:
                                account.isProfessional ? 'mob' : 'Upgrade to',
                            badgeAsset: 'assets/images/proicon.svg',
                            onTap: () =>
                                context.push(UpgradeToProPage.routePath),
                          ),
                          // Notification preferences: hidden for now (not
                          // ready), keeping the entry here so it's a one-line
                          // uncomment to bring back rather than a rebuild.r
                          // _MenuItem(
                          //   iconAsset: 'assets/images/notifications.svg',
                          //   label: 'Notification preferences',
                          //   onTap: () => _comingSoon(
                          //       context, 'Notification preferences'),
                          // ),
                          _MenuItem(
                            iconAsset: 'assets/images/accountprivacy.svg',
                            label: 'Account privacy',
                            onTap: () =>
                                context.push(AccountPrivacyPage.routePath),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/aboutus.svg',
                            label: 'About us',
                            onTap: () => _openExternal(
                              context,
                              'https://madoverbuildings.com/home/aboutus',
                            ),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/faqs.svg',
                            label: 'FAQs',
                            onTap: () => _openExternal(
                              context,
                              'https://madoverbuildings.com/home/faq?key=faq',
                            ),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/becomepartner.svg',
                            label: 'Become a partner',
                            onTap: () => _openExternal(
                              context,
                              'https://www.partner.madoverbuildings.com/',
                            ),
                          ),
                          _MenuItem(
                            iconAsset: 'assets/images/logout.svg',
                            label: 'Logout',
                            showChevron: false,
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                      const _VersionFooter(),
                      // This page's bottom nav bar never auto-hides while
                      // scrolling (unlike the home feed, this page doesn't
                      // drive navBarVisible), so it stays permanently
                      // docked over the Scaffold's extendBody content —
                      // without this the version footer renders half
                      // hidden underneath it. But this page is also reached
                      // via a standalone push (e.g. the Home avatar tap),
                      // outside ScaffoldWithNavBar entirely — reserving the
                      // nav bar's height there just leaves a blank gap, so
                      // only add it when that ancestor is actually present.
                      SizedBox(
                        height: (context.findAncestorWidgetOfExactType<
                                        ScaffoldWithNavBar>() !=
                                    null
                                ? kBottomNavBarHeight
                                : 0) +
                            MediaQuery.paddingOf(context).bottom,
                      ),
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

  static Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      TopSnackBar.show(
        context,
        message: 'Unable to open link.',
        type: TopSnackBarType.error,
      );
    }
  }

  static Future<void> _openWhatsapp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/918970415365');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      TopSnackBar.show(
        context,
        message: 'Unable to open WhatsApp.',
        type: TopSnackBarType.error,
      );
    }
  }

  static const _androidPackageId = 'com.madoverbuildings.mobileapp';

  static Future<void> _openAppStore() async {
    final Uri uri;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // The app isn't published on the App Store yet — it's only
      // distributed via TestFlight, so the App Store search page above
      // never actually shows an update (there's nothing there to show).
      // `itms-beta://` opens the TestFlight app itself, where an installed
      // build's pending update actually lives.
      // TODO: swap to the real numeric App Store id once this app is
      // published there, since TestFlight builds get replaced by the
      // public listing at that point.
      uri = Uri.parse('itms-beta://');
    } else {
      uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$_androidPackageId',
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void _showUpdateAvailable(
    BuildContext context,
    AppVersionInfo? info,
  ) {
    final forceUpdate = info?.forceUpdate ?? false;
    final message = info?.message.trim().isNotEmpty ?? false
        ? info!.message.trim()
        : 'A new version of the app is available.';
    showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          title: const Text('Update available'),
          content: Text(message),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Later'),
              ),
            TextButton(
              onPressed: () {
                if (!forceUpdate) Navigator.of(dialogContext).pop();
                _openAppStore();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthSession.instance.signOut();
    }
  }
}

/// Mirrors the real page's section heights so there's no layout jump when
/// the skeleton is swapped for actual content.
class _MyAccountSkeleton extends StatelessWidget {
  const _MyAccountSkeleton({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _headerSkeleton()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.list(
            children: [
              const SkeletonBox(height: 96, borderRadius: 16),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 112, borderRadius: 16)),
                  SizedBox(width: 15),
                  Expanded(child: SkeletonBox(height: 112, borderRadius: 16)),
                ],
              ),
              const SizedBox(height: 16),
              const SkeletonBox(height: 58, borderRadius: 16),
              const SizedBox(height: 16),
              const SkeletonBox(height: 58, borderRadius: 16),
              const SizedBox(height: 16),
              _menuCardSkeleton(rowCount: 6),
              const SizedBox(height: 24),
              const SkeletonBox(width: 140, height: 10, borderRadius: 4),
              const SizedBox(height: 20),
              _menuCardSkeleton(rowCount: 4),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerSkeleton() {
    return const ColoredBox(
      color: _ProfileColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 56),
              Row(
                children: [
                  SkeletonBox(width: 56, height: 56, borderRadius: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 20, borderRadius: 6),
                        SizedBox(height: 8),
                        SkeletonBox(width: 110, height: 14, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              SkeletonBox(height: 58, borderRadius: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCardSkeleton({required int rowCount}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            for (var i = 0; i < rowCount; i++) ...[
              const SizedBox(
                height: 56,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      SkeletonBox(width: 24, height: 24, borderRadius: 6),
                      SizedBox(width: 16),
                      Expanded(
                        child: SkeletonBox(height: 14, borderRadius: 6),
                      ),
                    ],
                  ),
                ),
              ),
              if (i != rowCount - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                      height: 1, thickness: 1, color: Color(0xFFE7EAEE)),
                ),
            ],
          ],
        ),
      ),
    );
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
              // Back button now lives in the fixed FrostedNavBar overlay
              // (see MyAccountWidget.build) so it stays pinned above this
              // scrolling header instead of scrolling away with it.
              const SizedBox(height: 56),
              // const SizedBox(height: 34),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push(PersonalInfoPage.routePath),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage.isEmpty
                            ? SvgPicture.asset(
                                'assets/images/profile.svg',
                                width: 24,
                                height: 24,
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
                      // const _Chevron(color: Colors.white),
                    ],
                  ),
                ),
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
                            height: 1.43,
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

// Always visible — "App update available" opens the update dialog; once
// there's nothing to update it just shows the current app version instead,
// same as Blinkit's account menu, rather than disappearing entirely.
class _AppUpdateCard extends StatelessWidget {
  const _AppUpdateCard({
    required this.updateAvailable,
    required this.onTap,
  });

  final bool updateAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: updateAvailable ? onTap : null,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/updateavailable.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  updateAvailable ? 'App update available' : 'App update',
                  style: _labelStyle,
                ),
                const Spacer(),
                if (!updateAvailable)
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version;
                      return Text(
                        version == null ? '' : 'v$version',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9FA4AA),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  )
                else
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
    this.badgeAsset,
    this.showChevron = true,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final String? badgeAsset;
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
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _labelStyle,
                        ),
                      ),
                      if (item.badgeAsset != null) ...[
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          item.badgeAsset!,
                          width: 41,
                          height: 24,
                        ),
                      ],
                    ],
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

class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter> {
  static const _tapsToUnlock = 6;
  static const _tapWindow = Duration(seconds: 3);

  int _tapCount = 0;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  // Secret dev-info screen — tap the version footer several times in a row.
  // Hidden from normal users, but gives QA/support exact build + environment
  // info without needing a separate debug build.
  void _onSecretTap() {
    _resetTimer?.cancel();
    _tapCount++;
    if (_tapCount >= _tapsToUnlock) {
      _tapCount = 0;
      context.push(DevInfoPage.routePath);
      return;
    }
    _resetTimer = Timer(_tapWindow, () => _tapCount = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 26, 0, 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onSecretTap,
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
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final versionText = info == null
                    ? ''
                    : 'v${info.version} (${info.buildNumber})';
                return Text(
                  versionText.isEmpty ? 'APP VERSION' : versionText,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9FA4AA),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                );
              },
            ),
          ],
        ),
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
      'assets/images/Arrow.svg',
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
  height: 20 / 13,
);

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
