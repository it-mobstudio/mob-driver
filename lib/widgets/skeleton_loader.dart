import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 10,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final width = rect.width <= 0 ? 1.0 : rect.width;
            final dx = (2 * width * _controller.value) - width;
            return LinearGradient(
              colors: const <Color>[
                Color(0xFFE9E9E9),
                Color(0xFFF5F5F5),
                Color(0xFFE9E9E9),
              ],
              stops: const <double>[0.1, 0.5, 0.9],
              begin: Alignment(-1 + (dx / width), 0),
              end: Alignment(1 + (dx / width), 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: (itemCount / 2).ceil(),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Row(
            children: <Widget>[
              Expanded(child: _ProductCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: _ProductCardSkeleton()),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SkeletonBox(height: 120, borderRadius: 12),
        SizedBox(height: 8),
        SkeletonBox(height: 14, borderRadius: 6),
        SizedBox(height: 8),
        SkeletonBox(width: 110, height: 14, borderRadius: 6),
      ],
    );
  }
}

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        SkeletonBox(height: 220, borderRadius: 14),
        SizedBox(height: 16),
        SkeletonBox(height: 20, borderRadius: 8),
        SizedBox(height: 10),
        SkeletonBox(width: 180, height: 18, borderRadius: 8),
        SizedBox(height: 18),
        SkeletonBox(height: 90, borderRadius: 12),
        SizedBox(height: 18),
        SkeletonBox(height: 16, borderRadius: 8),
        SizedBox(height: 10),
        SkeletonBox(height: 16, borderRadius: 8),
        SizedBox(height: 10),
        SkeletonBox(width: 200, height: 16, borderRadius: 8),
      ],
    );
  }
}
