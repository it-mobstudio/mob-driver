import 'package:flutter/material.dart';

/// Lightweight pulsing placeholder used while network images load.
/// Drop-in for CachedNetworkImage's `placeholder` parameter.
class ImageShimmer extends StatefulWidget {
  const ImageShimmer({super.key});

  @override
  State<ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<ImageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<Color?> _color = ColorTween(
    begin: const Color(0xFFE8EEF5),
    end: const Color(0xFFF7F9FC),
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (_, __) => ColoredBox(color: _color.value!),
    );
  }
}
