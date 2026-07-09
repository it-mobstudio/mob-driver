// lib/shared/pull_to_refresh.dart
import 'dart:async';
import 'dart:math';

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

  // Tracks whether the in-progress touch gesture is an actual pull-down
  // (top → refresh) versus a normal scroll that merely started at the top
  // edge. null = not yet decided for the current gesture.
  bool? _currentGestureIsPull;

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

  // RefreshIndicator arms as soon as a drag *starts* while the scrollable is
  // already at its top edge — regardless of which direction that drag then
  // moves in. Combined with AlwaysScrollableScrollPhysics (needed so short
  // lists can still be refreshed), that means an ordinary scroll gesture
  // that merely begins at the top — e.g. a short/filtered list, or grabbing
  // a list right as it decelerates to the top — can accidentally arm and
  // fire a refresh even though the user is scrolling down through content,
  // not pulling down. We disambiguate using the direction of the gesture's
  // first real movement and suppress notifications for non-pull gestures so
  // RefreshIndicator never arms for them.
  bool _shouldForwardScrollNotification(ScrollNotification notification) {
    if (!defaultScrollNotificationPredicate(notification)) return false;

    if (notification is ScrollStartNotification) {
      _currentGestureIsPull = null;
      return true;
    }
    if (notification is ScrollEndNotification) {
      return true;
    }

    if (_currentGestureIsPull == null) {
      if (notification is OverscrollNotification) {
        // Negative overscroll = trying to move past the top (a pull).
        _currentGestureIsPull = notification.overscroll < 0;
      } else if (notification is ScrollUpdateNotification &&
          notification.dragDetails != null &&
          notification.scrollDelta != null &&
          notification.scrollDelta != 0) {
        // Negative scrollDelta = content moving toward the top (a pull).
        _currentGestureIsPull = notification.scrollDelta! < 0;
      }
    }

    return _currentGestureIsPull ?? true;
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
          notificationPredicate: _shouldForwardScrollNotification,
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          strokeWidth: 0.01,
          triggerMode: RefreshIndicatorTriggerMode.onEdge,
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
            child: _RefreshSpinner(animation: _spinController),
          ),
      ],
    );
  }
}

/// A rotating gradient-tail arc on a light track — visually matches the
/// brand blue used across buttons/CTAs, and reads as an active loading
/// state at a glance rather than a static dot pattern.
class _RefreshSpinner extends StatelessWidget {
  const _RefreshSpinner({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: Colors.white,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _ArcSpinnerPainter(progress: animation.value),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArcSpinnerPainter extends CustomPainter {
  _ArcSpinnerPainter({required this.progress});

  final double progress;

  static const _track = Color(0xFFE3ECFB);
  static const _brand = Color(0xFF0360E5);
  static const _sweep = 4.6; // ~264°, leaves a visible gap for a tail

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = progress * 2 * pi;

    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = _track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawArc(
      rect,
      startAngle,
      _sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: _sweep,
          colors: const [Color(0x000360E5), _brand],
          transform: GradientRotation(startAngle),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
