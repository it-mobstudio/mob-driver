import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

enum TopSnackBarType { success, info, error }

class TopSnackBar {
  TopSnackBar._();

  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;

  static void show(
    BuildContext context, {
    required String message,
    TopSnackBarType type = TopSnackBarType.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) return;

    _currentTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (_) => _TopSnackBarOverlay(
        message: message,
        type: type,
        duration: duration,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _currentTimer = Timer(duration + const Duration(milliseconds: 250), () {
      entry.remove();
      if (identical(_currentEntry, entry)) _currentEntry = null;
    });
  }
}

class _TopSnackBarOverlay extends StatelessWidget {
  const _TopSnackBarOverlay({
    required this.message,
    required this.type,
    required this.duration,
  });

  final String message;
  final TopSnackBarType type;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final accent = switch (type) {
      TopSnackBarType.success => const Color(0xFF329537),
      TopSnackBarType.info => const Color(0xFF329537),
      TopSnackBarType.error => const Color(0xFFF0483E),
    };
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, -10 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message,
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
                      bottom: 7,
                      child: SizedBox(
                        width: 58,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.26),
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1, end: 0),
                              duration: duration,
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
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
