import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

enum TopSnackBarType { success, info, error, stock }

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
    final topInset = MediaQuery.paddingOf(context).top;
    final toast = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.clamp(0.0, 430.0).toDouble();
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                  color: Colors.white,
                  child: SizedBox(
                    height: 62,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 18, 12),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            _iconAsset,
                            width: 38,
                            height: 38,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0A243F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 16 / 12,
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
          ),
        );
      },
    );

    return Positioned(
      top: topInset + 12,
      left: 20,
      right: 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -250) _dismiss();
        },
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
                  offset: Offset(0, -12 * (1 - value)),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String get _iconAsset {
    return switch (widget.type) {
      TopSnackBarType.success => 'assets/images/toasticons/success.svg',
      TopSnackBarType.error => 'assets/images/toasticons/failure.svg',
      TopSnackBarType.stock => 'assets/images/toasticons/stock.svg',
      TopSnackBarType.info => _infoIconAsset,
    };
  }

  String get _infoIconAsset {
    final text = widget.message.toLowerCase();
    if (text.contains('stock') ||
        text.contains('available') ||
        text.contains('pieces') ||
        text.contains('item')) {
      return 'assets/images/toasticons/stock.svg';
    }
    if (text.contains('copied') || text.contains('copy')) {
      return 'assets/images/toasticons/copied.svg';
    }
    return 'assets/images/toasticons/success.svg';
  }
}
