import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_session.dart';
import '../loginpage/loginpage_widget.dart';
import '../orders/orders_page.dart';
import '../rfq/rfq.dart';
import '../widgets/main_scaffold.dart';

class MyAccountWidget extends StatelessWidget {
  const MyAccountWidget({super.key});
  static const String routeName = 'MyAccount';
  static const String routePath = '/myaccount';

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(
      // title: 'My Account',
      currentIndex: 3, // Profile tab selected
      child: _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const radiusLg = Radius.circular(28);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header with gradient
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFA6E3D1), Color(0xFF9BD9D2)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: radiusLg,
                      bottomRight: radiusLg,
                    ),
                  ),
                  child: _HeaderContent(),
                ),
                // Stats card
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: -48,
                  child: _StatsCard(),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // Menu list
            _MenuSection(
              items: [
                _MenuItemData(
                  icon: CupertinoIcons.cube_box_fill,
                  title: 'Orders',
                  onTap: (ctx) => ctx.push(OrdersPage.routePath),
                ),
                // _MenuItemData(
                //   icon: CupertinoIcons.arrow_2_squarepath,
                //   title: 'Resell order',
                //   onTap: () => _showComingSoon(context, 'Resell order'),
                // ),
                _MenuItemData(
                  icon: CupertinoIcons.doc_on_doc_fill,
                  title: "My RFQ's",
                  onTap: (ctx) => ctx.push(RfqPage.routePath),
                ),
                _MenuItemData(
                  icon: CupertinoIcons.heart_fill,
                  title: 'Wishlist',
                  onTap: (ctx) => _showComingSoon(ctx, 'Wishlist'),
                ),
                _MenuItemData(
                  icon: CupertinoIcons.person_fill,
                  title: 'Personal info',
                  onTap: (ctx) => _showComingSoon(ctx, 'Personal info'),
                ),
                _MenuItemData(
                  icon: CupertinoIcons.location_solid,
                  title: 'Address',
                  onTap: (ctx) => _showComingSoon(ctx, 'Address'),
                ),
                // _MenuItemData(
                //   icon: CupertinoIcons.creditcard_fill,
                //   title: 'My payments',
                //   onTap: (ctx) => _showComingSoon(ctx, 'Payments'),
                // ),
                _MenuItemData(
                  icon: CupertinoIcons.money_dollar_circle_fill,
                  title: 'Wallet & points',
                  onTap: (ctx) => _showComingSoon(ctx, 'Wallet & points'),
                ),
                // _MenuItemData(
                //   icon: CupertinoIcons.gift_fill,
                //   title: 'Refer and earn',
                //   onTap: (ctx) => _showComingSoon(ctx, 'Refer and earn'),
                // ),
                _MenuItemData(
                  icon: CupertinoIcons.arrow_right_square_fill,
                  title: 'Logout',
                  onTap: (ctx) async {
                    await AuthSession.instance.signOut();
                    if (ctx.mounted) {
                      ctx.go(LoginpageWidget.routePath);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: const Color(0xFF0E2545),
          fontWeight: FontWeight.w800,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Johnathan Wick', style: nameStyle),
              const SizedBox(height: 12),
              const _BadgeChip(
                  text: 'Diamond member', icon: Icons.ac_unit_rounded),
              const SizedBox(height: 14),
              const Text(
                '₹50235 saved till now',
                style: TextStyle(
                  color: Color(0xFF0E2545),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 34,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _BadgeChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF3BB6C5), size: 18),
          const SizedBox(width: 8),
          const Text(
            'Diamond member',
            style: TextStyle(
              color: Color(0xFF0E2545),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: const Row(
          children: [
            Expanded(
                child: _StatTile(
                    icon: Icons.stars_rounded, title: 'Points', value: '328')),
            VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE8EDF2)),
            Expanded(
                child: _StatTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Wallet',
                    value: '₹1500')),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Icon(icon, color: const Color(0xFF0E2545), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF37516B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF0E2545),
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final void Function(BuildContext) onTap;
  _MenuItemData({required this.icon, required this.title, required this.onTap});
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F7)),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          onTap: () => item.onTap(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Icon(item.icon, color: const Color(0xFF0E2545), size: 20),
          ),
          title: Text(
            item.title,
            style: const TextStyle(
              color: Color(0xFF0E2545),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right,
              color: Color(0xFF37516B)),
        );
      },
    );
  }
}
