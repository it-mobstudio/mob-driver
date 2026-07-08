// lib/shared/pull_to_refresh.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';

class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  final AudioPlayer _soundPlayer = AudioPlayer();
  bool _soundReady = false;

  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _preloadSound();
  }

  // Preload so playback is instant once a refresh actually triggers, instead
  // of buffering audibly on the first pull. A missing/unsupported asset must
  // never break pull-to-refresh itself, hence the swallow.
  Future<void> _preloadSound() async {
    try {
      await _soundPlayer.setAsset('assets/audios/pull_to_refresh.mp3');
      _soundReady = true;
    } catch (_) {
      _soundReady = false;
    }
  }

  Future<void> _handleRefresh() async {
    AppHaptics.lightTap();
    if (_soundReady) {
      unawaited(_soundPlayer.seek(Duration.zero));
      unawaited(_soundPlayer.play());
    }
    setState(() => _refreshing = true);
    _spinController.repeat();
    try {
      await widget.onRefresh();
    } finally {
      _spinController.stop();
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          strokeWidth: 0.01,
          child: AnimatedOpacity(
            opacity: _refreshing ? 0.5 : 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
        if (_refreshing)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _BouncingDots(animation: _spinController),
          ),
      ],
    );
  }
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.animation});

  final Animation<double> animation;

  static const _dotColor = Color(0xFF0A243F);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: Colors.white,
      child: SizedBox(
        width: 44,
        height: 44,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t = (animation.value + (i * 0.2)) % 1.0;
                final scale =
                    0.5 + 0.5 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
