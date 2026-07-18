// lib/shared/pull_to_refresh.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';

class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.revealedChildBuilder,
    this.playSound = false,
    this.showSpinner = false,
    this.spinnerTopOffset = 16,
    this.spinnerSize = 48,
    this.revealContentOnRefresh = false,
    this.contentRevealExtent = 96,
    this.dimContentOnRefresh = true,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Widget Function(BuildContext context, double revealOffset)?
      revealedChildBuilder;
  final bool playSound;
  final bool showSpinner;
  final double spinnerTopOffset;
  final double spinnerSize;
  final bool revealContentOnRefresh;
  final double contentRevealExtent;
  final bool dimContentOnRefresh;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> {
  final AudioPlayer _soundPlayer = AudioPlayer();
  bool _soundReady = false;

  bool _refreshing = false;
  Future<void>? _refreshFuture;
  Timer? _dragRevealResetTimer;
  double _dragRevealOffset = 0;

  // Tracks whether the in-progress touch gesture is an actual pull-down
  // (top → refresh) versus a normal scroll that merely started at the top
  // edge. null = not yet decided for the current gesture.
  bool? _currentGestureIsPull;

  @override
  void initState() {
    super.initState();
    if (widget.playSound) _preloadSound();
  }

  // Preload so playback is instant once a refresh actually triggers, instead
  // of buffering audibly on the first pull. A missing/unsupported asset must
  // never break pull-to-refresh itself, hence the swallow.
  Future<void> _preloadSound() async {
    try {
      await _soundPlayer.setAsset('assets/audios/pull_to_refresh.mp3');
      await _soundPlayer.setVolume(0.2);
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
      _dragRevealResetTimer?.cancel();
      _currentGestureIsPull = null;
      _setDragRevealOffset(0);
      return true;
    }
    if (notification is ScrollEndNotification) {
      if (!_refreshing) _scheduleDragRevealReset();
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

    if (_currentGestureIsPull == false) {
      _setDragRevealOffset(0);
      return false;
    }

    _updateDragRevealOffset(notification);
    return _currentGestureIsPull ?? true;
  }

  void _updateDragRevealOffset(ScrollNotification notification) {
    if (!widget.revealContentOnRefresh || _refreshing) return;
    if (notification.metrics.pixels > notification.metrics.minScrollExtent) {
      _setDragRevealOffset(0);
      return;
    }

    double nextOffset = _dragRevealOffset;
    if (notification is OverscrollNotification && notification.overscroll < 0) {
      nextOffset -= notification.overscroll;
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.dragDetails?.delta.dy ?? 0;
      if (delta > 0) {
        nextOffset += delta;
      } else if (delta < 0) {
        nextOffset += delta;
      }
    }

    _setDragRevealOffset(
      nextOffset.clamp(0, widget.contentRevealExtent).toDouble(),
    );
  }

  void _setDragRevealOffset(double value) {
    if (_dragRevealOffset == value || !mounted) return;
    setState(() => _dragRevealOffset = value);
  }

  void _scheduleDragRevealReset() {
    _dragRevealResetTimer?.cancel();
    _dragRevealResetTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || _refreshing) return;
      _setDragRevealOffset(0);
    });
  }

  Future<void> _handleRefresh() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;
    _dragRevealResetTimer?.cancel();
    if (mounted) {
      setState(() => _refreshing = true);
    } else {
      _refreshing = true;
    }

    final refreshFuture = _runRefresh();
    _refreshFuture = refreshFuture;
    return refreshFuture;
  }

  Future<void> _runRefresh() async {
    AppHaptics.lightTap();
    if (widget.playSound && _soundReady) {
      unawaited(_soundPlayer.seek(Duration.zero));
      unawaited(_soundPlayer.play());
    }
    try {
      await widget.onRefresh();
    } finally {
      _refreshFuture = null;
      if (mounted) {
        setState(() {
          _refreshing = false;
          _dragRevealOffset = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _dragRevealResetTimer?.cancel();
    _soundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentOffset =
        widget.revealContentOnRefresh && _refreshing
            ? widget.contentRevealExtent
            : _dragRevealOffset;
    final contentOpacity =
        widget.dimContentOnRefresh && _refreshing ? 0.5 : 1.0;
    final showRefreshSpinner = widget.showSpinner &&
        (_refreshing ||
            (widget.revealContentOnRefresh && _dragRevealOffset > 8));
    final revealedChildBuilder = widget.revealedChildBuilder;
    final refreshChild = revealedChildBuilder != null
        ? revealedChildBuilder(context, contentOffset)
        : TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: contentOffset),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: AnimatedOpacity(
              opacity: contentOpacity,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          );

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
          child: refreshChild,
        ),
        if (showRefreshSpinner)
          Positioned(
            top: widget.spinnerTopOffset,
            child: _RefreshSpinner(size: widget.spinnerSize),
          ),
      ],
    );
  }
}

/// Team-provided Lottie loader shown while a pull-to-refresh is in flight.
class _RefreshSpinner extends StatelessWidget {
  const _RefreshSpinner({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Lottie.asset(
        'assets/lottiejson/Spinner_pull.json',
        repeat: true,
        animate: true,
        fit: BoxFit.contain,
      ),
    );
  }
}
