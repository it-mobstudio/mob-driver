import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

enum TopSnackBarType { success, info, error }

class TopSnackBar {
  TopSnackBar._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    TopSnackBarType type = TopSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) return;

    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopSnackBarOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          entry.remove();
          if (identical(_currentEntry, entry)) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _TopSnackBarOverlay extends StatefulWidget {
  const _TopSnackBarOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final TopSnackBarType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopSnackBarOverlay> createState() => _TopSnackBarOverlayState();
}

class _TopSnackBarOverlayState extends State<_TopSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 180),
    )..forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = switch (widget.type) {
      TopSnackBarType.success => const Color(0xFF329537),
      TopSnackBarType.info => const Color(0xFF329537),
      TopSnackBarType.error => const Color(0xFFF0483E),
    };
    final topInset = MediaQuery.paddingOf(context).top;
    final toast = ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(14),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(22, topInset + 7, 16, 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 17 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: 0),
                    duration: widget.duration,
                    curve: Curves.linear,
                    builder: (context, value, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: child,
                        ),
                      );
                    },
                    child: ColoredBox(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            child: toast,
            builder: (context, child) {
              final value = Curves.easeOutCubic.transform(
                _controller.value,
              );
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -10 * (1 - value)),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
