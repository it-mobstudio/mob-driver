import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
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
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        body: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
                position: _slide, child: widget.navigationShell)),
        bottomNavigationBar: _DriverBottomBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: (index) {
            widget.navigationShell.goBranch(index,
                initialLocation: index == widget.navigationShell.currentIndex);
            if (index == 0) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => refreshDriverDashboard?.call());
            }
          },
        ),
      );
}

class _DriverBottomBar extends StatelessWidget {
  const _DriverBottomBar({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const items = [
    ('Today', 'assets/images/Homemenu.svg', 'assets/images/Homeselect.svg'),
    ('Trips', 'assets/images/Orders.svg', 'assets/images/Ordersselect.svg'),
    (
      'Vehicle',
      'assets/images/vehicletracking.svg',
      'assets/images/vehicletracking.svg'
    ),
    ('Profile', 'assets/icons/profile.svg', 'assets/icons/profile.svg'),
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
                      SvgPicture.asset(selected ? item.$3 : item.$2,
                          width: 20,
                          height: 20,
                          colorFilter: entry.key > 1
                              ? ColorFilter.mode(
                                  selected
                                      ? const Color(0xFF2973F0)
                                      : const Color(0xFF8D8F91),
                                  BlendMode.srcIn)
                              : null),
                      const SizedBox(height: 4),
                      Text(item.$1,
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
