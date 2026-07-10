import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps [child] with a soft diagonal light streak that periodically sweeps
/// across it — a decorative "shine" for promo/CTA cards. Not a loading
/// placeholder; see [SkeletonBox]/[ImageShimmer] for those.
class ShimmerSweep extends StatefulWidget {
  const ShimmerSweep({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 8),
    this.sweepDuration = const Duration(milliseconds: 3000),
  });

  final Widget child;
  final Duration interval;
  final Duration sweepDuration;

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.sweepDuration,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sweep();
    _timer = Timer.periodic(widget.interval, (_) => _sweep());
  }

  void _sweep() {
    if (!mounted) return;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Colors.transparent,
              Colors.transparent,
              Color(0x40FFFFFF),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            transform: _SweepTransform(_ctrl.value),
          ).createShader(rect),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Slides the (already wide) transparent/highlight/transparent gradient
/// fully across the shader's rect over the course of the animation, so the
/// highlight band sweeps in from one corner and back out the other.
///
/// The highlight itself only occupies stops 0.35–0.65 (30% of the
/// gradient), so the travel range here is kept just wide enough to carry
/// it from fully-offscreen-left to fully-offscreen-right — not several
/// multiples of that. A wider range spends most of [sweepDuration] with
/// the band invisible off both edges, which makes the brief moment it's
/// actually crossing the card look far faster than the configured
/// duration suggests.
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (1.5 * t - 0.75);
    return Matrix4.translationValues(dx, 0, 0);
  }
}
