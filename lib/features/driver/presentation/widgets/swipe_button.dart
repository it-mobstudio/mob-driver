import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

/// The blue "» Deliver order" bar: drag the white knob to the end to confirm.
/// A deliberate gesture for the steps that can't be undone (pickup, deliver),
/// so a pocket tap never triggers one. A plain tap nudges the knob to show it
/// wants a swipe; screen readers get a normal button.
class SwipeButton extends StatefulWidget {
  const SwipeButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.color = DriverColors.blue,
    this.loading = false,
    this.enabled = true,
    this.trailing,
    this.remaining,
  });

  final String label;

  /// Small text after the label — the offer's `21s`.
  final String? trailing;

  /// 1 → 0 as time runs out: a lighter band across the track that drains
  /// from the right, so the countdown lives on the button itself.
  final double? remaining;

  /// Called once the knob reaches the end. The knob stays there (showing a
  /// spinner if [loading]) until the future completes, then slides back.
  final Future<void> Function() onConfirmed;
  final Color color;
  final bool loading;
  final bool enabled;

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton>
    with SingleTickerProviderStateMixin {
  static const _height = 56.0;
  static const _knob = 44.0;
  static const _inset = 6.0;

  late final AnimationController _position = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  bool _running = false;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  bool get _active => widget.enabled && !widget.loading && !_running;

  Future<void> _confirm() async {
    setState(() => _running = true);
    AppHaptics.success();
    await _position.animateTo(1, curve: Curves.easeOut);
    try {
      await widget.onConfirmed();
    } finally {
      if (mounted) {
        setState(() => _running = false);
        await _position.animateBack(0, curve: Curves.easeOutCubic);
      }
    }
  }

  Future<void> _nudge() async {
    if (!_active) return;
    AppHaptics.lightTap();
    await _position.animateTo(.18, curve: Curves.easeOut);
    if (mounted) await _position.animateBack(0, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final track = constraints.maxWidth - _knob - _inset * 2;

          return Semantics(
            button: true,
            enabled: _active,
            label: widget.label,
            onTap: _active ? _confirm : null,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: _nudge,
              onHorizontalDragUpdate: _active
                  ? (d) => _position.value += d.primaryDelta! / track
                  : null,
              onHorizontalDragEnd: _active
                  ? (_) => _position.value > .8
                      ? _confirm()
                      : _position.animateBack(0, curve: Curves.easeOutCubic)
                  : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: widget.enabled ? 1 : .5,
                child: Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(_height / 2),
                  ),
                  child: AnimatedBuilder(
                    animation: _position,
                    builder: (context, _) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        if (widget.remaining != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(_height / 2),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    end: widget.remaining!.clamp(0.0, 1.0)),
                                duration: const Duration(seconds: 1),
                                builder: (_, value, __) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: value,
                                    heightFactor: 1,
                                    child: ColoredBox(
                                        color: Colors.white
                                            .withValues(alpha: .16)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // The label fades as the knob covers it.
                        Center(
                          child: Opacity(
                            opacity: (1 - _position.value * 1.6).clamp(0, 1),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(widget.label,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  if (widget.trailing != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: .22),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(widget.trailing!,
                                          key: const Key('swipe_trailing'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontFeatures: [
                                                FontFeature.tabularFigures()
                                              ],
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ]),
                          ),
                        ),
                        Positioned(
                          left: _inset + track * _position.value,
                          child: Container(
                            key: ValueKey('swipe_knob_${widget.label}'),
                            width: _knob,
                            height: _knob,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            // Spinner only while the app is actually waiting on the
                            // server; a confirm dialog shows a plain tick.
                            child: widget.loading
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation(
                                            widget.color)),
                                  )
                                : Icon(
                                    _running
                                        ? Icons.check_rounded
                                        : Icons.keyboard_double_arrow_right_rounded,
                                    color: widget.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
