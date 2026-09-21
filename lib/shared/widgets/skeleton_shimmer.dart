import 'package:flutter/material.dart';

const Color _base = Color(0xFFE6ECF2);
const Color _highlight = Color(0xFFF4F7FA);

/// Shimmers everything beneath it with ONE animation and ONE shader.
///
/// Compose a placeholder screen from plain [SkeletonBlock]s and wrap the whole
/// thing once. (A shimmer per box means a controller and a shader per box — on
/// a full screen of placeholders that's the difference between smooth and
/// stuttering on a mid-range phone.) With the OS "reduce motion" setting on, it
/// holds still instead of animating.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            // A soft band that travels left → right across the whole area.
            final shift = _controller.value * 2 - 1; // -1 … 1
            return LinearGradient(
              colors: const [_base, _highlight, _base],
              stops: const [0.25, 0.5, 0.75],
              begin: Alignment(-1.6 + shift * 1.6, 0),
              end: Alignment(0 + shift * 1.6, 0),
            ).createShader(rect);
          },
          child: child,
        ),
      );
}

/// A rounded grey placeholder. Give it a [SkeletonShimmer] ancestor.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  const SkeletonBlock.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = size / 2;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
