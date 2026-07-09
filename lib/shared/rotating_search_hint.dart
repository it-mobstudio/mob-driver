import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

/// Cycles through a few product search terms (`Search "Fevicol"` →
/// `Search "cements"` → ...), sliding/fading between them. Used as a ghost
/// hint in tap-to-navigate search boxes and empty product-search fields —
/// anywhere a real `TextField.hintText` (plain String) can't do the
/// animation itself.
class RotatingSearchHint extends StatefulWidget {
  const RotatingSearchHint({super.key, this.style});

  final TextStyle? style;

  @override
  State<RotatingSearchHint> createState() => _RotatingSearchHintState();
}

class _RotatingSearchHintState extends State<RotatingSearchHint>
    with SingleTickerProviderStateMixin {
  static const _terms = [
    'Fevicol',
    'cements',
    'TMT bars',
    'wall putty',
    'tiles',
    'electrical wires',
  ];

  int _current = 0;
  int _next = 1;
  Timer? _timer;
  late AnimationController _ctrl;

  // Current text exits upward + fades out
  late Animation<Offset> _slideOut;
  late Animation<double> _fadeOut;
  // Next text enters from below + fades in
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _fadeOut = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _slideIn = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeIn = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1)));

    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _rotate());
  }

  Future<void> _rotate() async {
    if (!mounted || _ctrl.isAnimating) return;
    _next = (_current + 1) % _terms.length;
    await _ctrl.forward();
    if (!mounted) return;
    setState(() => _current = _next);
    _ctrl.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  TextStyle get _style =>
      widget.style ??
      GoogleFonts.inter(
        color: const Color(0xFF767C8F),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(
          children: [
            SlideTransition(
              position: _slideOut,
              child: FadeTransition(
                opacity: _fadeOut,
                child: Text('Search "${_terms[_current]}"', style: _style),
              ),
            ),
            SlideTransition(
              position: _slideIn,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Text('Search "${_terms[_next]}"', style: _style),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
