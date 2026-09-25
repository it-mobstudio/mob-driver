import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

/// The "searching for orders" radar: a pin with rings pulsing out from it.
/// A tiny vector Lottie (~5 KB, drawn in code, no video decoder), looped for
/// as long as the driver waits — the search never "finishes" until an order
/// lands. Holds still under the OS "reduce motion" setting.
class FinderAnimation extends StatelessWidget {
  const FinderAnimation({super.key, this.size = 132});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Lottie.asset(
          'assets/lottiejson/finding_orders.json',
          animate: !MediaQuery.disableAnimationsOf(context),
          repeat: true,
          frameRate: FrameRate.composition,
          // No animation beats a broken one: the words below still carry it.
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
}

/// A status line that cross-fades through [messages] every [every], so a
/// driver waiting a while can see the app is still at work — "Finding orders
/// near you", then "Trying hard to find you an order", and so on.
class RotatingStatusText extends StatefulWidget {
  const RotatingStatusText({
    super.key,
    required this.messages,
    this.every = const Duration(milliseconds: 3200),
    this.style,
  });

  final List<String> messages;
  final Duration every;
  final TextStyle? style;

  @override
  State<RotatingStatusText> createState() => _RotatingStatusTextState();
}

class _RotatingStatusTextState extends State<RotatingStatusText> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % widget.messages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .25), end: Offset.zero)
                .animate(animation),
            child: child,
          ),
        ),
        child: Text(
          widget.messages[_index],
          key: ValueKey(_index),
          textAlign: TextAlign.center,
          style: widget.style ??
              const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
        ),
      );
}
