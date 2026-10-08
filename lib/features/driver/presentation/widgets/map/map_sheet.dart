import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:mob_driver/core/theme/app_colors.dart';

/// The white sheet over a map screen. At rest only [peek] shows, so the map
/// keeps most of the screen; dragging the sheet up reveals [more] and then
/// scrolls it. [footer] — the screen's main action — stays pinned under the
/// sheet whatever its position.
///
/// Fills its parent: put it over the map in a [Stack]. Touches above the
/// sheet fall through to the map.
class MapSheet extends StatefulWidget {
  const MapSheet({
    super.key,
    required this.peek,
    this.more,
    this.footer,
    this.onRestingHeight,
  });

  /// What's always visible.
  final Widget peek;

  /// What scrolling up reveals. Without it the sheet doesn't move.
  final Widget? more;

  /// Pinned at the bottom of the screen, under the sheet.
  final Widget? footer;

  /// How much of the screen's bottom edge the resting sheet (and the footer)
  /// covers — for the map's padding, so its logo, buttons and camera centre
  /// stay in the visible part.
  final ValueChanged<double>? onRestingHeight;

  @override
  State<MapSheet> createState() => _MapSheetState();
}

class _MapSheetState extends State<MapSheet> {
  /// The most of the space above the footer the open sheet takes.
  static const _maxFraction = .86;
  static const _radius = BorderRadius.vertical(top: Radius.circular(26));

  // Guesses until the first layout reports the real sizes.
  double _peekHeight = 200;
  double? _contentHeight;
  double _footerHeight = 0;
  double? _reported;

  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  void _report(double height) {
    if (_reported != null && (height - _reported!).abs() < 1) return;
    _reported = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRestingHeight?.call(height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFooter = widget.footer != null;
    // With no footer the sheet itself reaches the bottom edge of the screen.
    final inset = hasFooter ? 0.0 : MediaQuery.paddingOf(context).bottom;
    if (!hasFooter) _footerHeight = 0;

    return Column(children: [
      Expanded(
        child: LayoutBuilder(builder: (context, constraints) {
          final available = constraints.maxHeight;
          if (!available.isFinite || available <= 0) {
            return const SizedBox.shrink();
          }
          final cap = available * _maxFraction;
          final open = math.min(_contentHeight ?? cap, cap);
          final resting = math.min(_peekHeight + inset, open);
          _report(resting + _footerHeight);

          final min = (resting / available).clamp(0.0, 1.0);
          final max = math.max(min, (open / available).clamp(0.0, 1.0));
          return DraggableScrollableSheet(
            minChildSize: min,
            initialChildSize: min,
            maxChildSize: max,
            snap: max - min > .01,
            builder: (context, controller) => DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: _radius,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x1F001533),
                      blurRadius: 14,
                      offset: Offset(0, -2)),
                ],
              ),
              child: Material(
                color: AppColors.card,
                borderRadius: _radius,
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  controller: controller,
                  // Always scrollable: a fully open sheet whose content fits
                  // must still take the drag that closes it.
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics()),
                  child: _SizeReporter(
                    onSize: (size) => _set(() => _contentHeight = size.height),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SizeReporter(
                          onSize: (size) =>
                              _set(() => _peekHeight = size.height),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _Grabber(),
                                widget.peek,
                              ],
                            ),
                          ),
                        ),
                        if (widget.more != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: widget.more,
                          ),
                        SizedBox(height: inset),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
      if (hasFooter)
        _SizeReporter(
          onSize: (size) => _set(() => _footerHeight = size.height),
          child: Material(
            color: AppColors.card,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: widget.footer,
              ),
            ),
          ),
        ),
    ]);
  }
}

/// The little handle at the top of the sheet.
class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          key: const Key('map_sheet_grabber'),
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: AppColors.line, borderRadius: BorderRadius.circular(4)),
        ),
      );
}

/// Tells [onSize] its child's size after each layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
      BuildContext context, _RenderSizeReporter renderObject) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final reported = size;
    // After the frame: the listener rebuilds the sheet, which can't happen
    // while it's being laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}
