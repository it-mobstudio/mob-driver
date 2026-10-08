import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';

/// Covers the app with a spinner and [message] while [task] runs, so the
/// driver knows something is happening (and can't tap twice meanwhile).
Future<T> runWithProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() task,
) async {
  final entry = OverlayEntry(builder: (_) => _ProgressOverlay(message));
  Overlay.of(context, rootOverlay: true).insert(entry);
  try {
    return await task();
  } finally {
    entry.remove();
  }
}

class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
        key: const Key('progress_overlay'),
        color: const Color(0x80000000),
        child: Center(
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: AppColors.button),
                ),
                const SizedBox(width: 14),
                Text(message,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      );
}
