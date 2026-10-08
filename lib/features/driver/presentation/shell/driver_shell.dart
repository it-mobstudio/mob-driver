import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/pages/onboarding_page.dart';

/// Hosts the driver's branches (the full-screen map "home", trips, wallet,
/// vehicle, profile) with a cross-fade/slide between them instead of a cut.
/// There's no bottom bar here any more — the map screen is home, and its
/// profile button is how the driver reaches the other branches; each of
/// those has its own way back.
class DriverShell extends StatefulWidget {
  const DriverShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell>
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
  void didUpdateWidget(covariant DriverShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.navigationShell.currentIndex;
    if (next != _previousIndex) {
      final direction = next > _previousIndex ? 1.0 : -1.0;
      _previousIndex = next;
      _slide =
          Tween<Offset>(begin: Offset(.035 * direction, 0), end: Offset.zero)
              .animate(_fade);
      _controller.forward(from: 0);
      // Landing back on the map should show fresh duty/trip state, not
      // whatever it last painted.
      // Back on the dashboard (from the profile menu): bring it up to date.
      if (next == 0) context.read<DriverSessionCubit>().load(silent: true);
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
          body: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                  position: _slide, child: widget.navigationShell)),
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
