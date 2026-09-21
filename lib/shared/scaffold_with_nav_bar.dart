import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/onboarding_page.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(.035, 0), end: Offset.zero)
          .animate(_fade);
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.navigationShell.currentIndex;
    if (next != _previousIndex) {
      final direction = next > _previousIndex ? 1.0 : -1.0;
      _previousIndex = next;
      _slide =
          Tween<Offset>(begin: Offset(.035 * direction, 0), end: Offset.zero)
              .animate(_fade);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Scaffold(
          extendBody: true,
          body: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                  position: _slide, child: widget.navigationShell)),
          bottomNavigationBar: _DriverBottomBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) {
              if (index != widget.navigationShell.currentIndex) {
                AppHaptics.tabSelection();
              }
              widget.navigationShell.goBranch(index,
                  initialLocation:
                      index == widget.navigationShell.currentIndex);
              if (index == 0) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => refreshDriverDashboard?.call());
              }
            },
          ),
        ),
        // A driver who signed themselves up has nothing to do in the app until
        // they've given their details and documents, so set-up covers it — and
        // lifts the moment the backend says that part is done. It sits here (not
        // behind a route) so the session that loads the profile keeps running.
        Positioned.fill(
          child: BlocBuilder<DriverSessionCubit, DriverSessionState>(
            buildWhen: (a, b) => a.needsOnboarding != b.needsOnboarding,
            builder: (context, state) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: state.needsOnboarding
                  ? const OnboardingPage(key: ValueKey('onboarding-layer'))
                  : const SizedBox.shrink(key: ValueKey('no-onboarding')),
            ),
          ),
        ),
      ]);
}

class _DriverBottomBar extends StatelessWidget {
  const _DriverBottomBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = [
    _NavItem('Today',
        svg: 'assets/images/Homemenu.svg',
        svgSelected: 'assets/images/Homeselect.svg'),
    _NavItem('Trips',
        svg: 'assets/images/Orders.svg',
        svgSelected: 'assets/images/Ordersselect.svg'),
    _NavItem('Wallet',
        icon: Icons.account_balance_wallet_outlined,
        iconSelected: Icons.account_balance_wallet_rounded),
    _NavItem('Vehicle',
        svg: 'assets/images/vehicletracking.svg', tint: true),
    _NavItem('Profile', svg: 'assets/icons/profile.svg', tint: true),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 5))
        ]),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: items.asMap().entries.map((entry) {
                final selected = entry.key == currentIndex;
                final item = entry.value;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(entry.key),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2973F0)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      item.build(selected),
                      const SizedBox(height: 4),
                      Text(item.label,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: selected
                                  ? Colors.black
                                  : const Color(0xFF8D8F91),
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
}

/// One tab of the bottom bar: an SVG (the first two tabs ship their own
/// coloured artwork) or a Material icon, tinted blue when selected.
class _NavItem {
  const _NavItem(
    this.label, {
    this.svg,
    this.svgSelected,
    this.icon,
    this.iconSelected,
    this.tint = false,
  });

  final String label;
  final String? svg;
  final String? svgSelected;
  final IconData? icon;
  final IconData? iconSelected;

  /// Recolour the SVG with the selected / unselected colour (the first two
  /// tabs' artwork already has both states drawn in).
  final bool tint;

  static const _selected = Color(0xFF2973F0);
  static const _idle = Color(0xFF8D8F91);

  Widget build(bool selected) {
    final color = selected ? _selected : _idle;
    if (icon != null) {
      return Icon(selected ? (iconSelected ?? icon) : icon,
          size: 22, color: color);
    }
    return SvgPicture.asset(selected ? (svgSelected ?? svg!) : svg!,
        width: 20,
        height: 20,
        colorFilter: tint ? ColorFilter.mode(color, BlendMode.srcIn) : null);
  }
}
