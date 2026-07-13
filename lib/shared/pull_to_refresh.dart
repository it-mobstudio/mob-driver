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
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> {
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
    _preloadSound();
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
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  void dispose() {
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
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: _RefreshSpinner(),
          ),
      ],
    );
  }
}

/// Team-provided Lottie loader shown while a pull-to-refresh is in flight.
class _RefreshSpinner extends StatelessWidget {
  const _RefreshSpinner();

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottiejson/Spinner_pull.json',
      repeat: true,
      animate: true,
    );
  }
}
