import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

/// A back button pinned above scrolling content. Its frosted-glass (blurred)
/// backdrop only fades in once [frosted] is true, so the bar is invisible
/// over the page's own header until the user scrolls past it.
///
/// Place this as the last child of a [Stack] on top of the page's scroll
/// view; it positions itself and doesn't take any layout space in the flow.
class FrostedNavBar extends StatelessWidget {
  const FrostedNavBar({
    super.key,
    this.onBack,
    this.iconColor = const Color(0xFF0A243F),
    this.frosted = false,
  });

  final VoidCallback? onBack;
  final Color iconColor;
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: frosted ? 16 : 0,
            sigmaY: frosted ? 16 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: frosted
                ? Colors.white.withValues(alpha: .35)
                : Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xFFD0D4DC)),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onBack ??
                            () => context.canPop() ? context.pop() : null,
                        child: Center(child: AppBackIcon(color: iconColor)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
