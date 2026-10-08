import 'package:flutter/material.dart';
import 'package:mob_driver/core/widgets/skeleton_shimmer.dart';

/// A screen-sized placeholder: a header-less stack of card-shaped blocks.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 4, this.itemHeight = 96});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => SkeletonBlock(height: itemHeight, radius: 18),
        ),
      );
}

/// Card-shaped placeholders that lay out in place (no scrolling of their own),
/// for the loading state of a list that lives inside a bigger scrolling page.
class ListSkeletonInline extends StatelessWidget {
  const ListSkeletonInline(
      {super.key, this.itemCount = 3, this.itemHeight = 64});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
        child: Column(children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            SkeletonBlock(height: itemHeight, radius: 16),
          ],
        ]),
      );
}
