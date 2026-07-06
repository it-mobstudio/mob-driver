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

/// Fallback shown in place of a product image when there's no URL to load,
/// or the real image failed to load. Code-drawn rather than a bundled
/// asset — there is no packaged "coming soon" image in this project (the
/// path `assets/images/Image-coming-soon.png` referenced all over the
/// codebase doesn't exist, which is why those spots rendered as broken
/// images). Drop-in for CachedNetworkImage's `errorWidget`/`placeholder`,
/// or directly wherever there's no image URL at all.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1F1F2),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 28,
          color: Color(0xFFB9C0CB),
        ),
      ),
    );
  }
}
