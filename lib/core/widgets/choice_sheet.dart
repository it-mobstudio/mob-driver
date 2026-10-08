import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';

/// One option in a [showChoiceSheet].
class Choice<T> {
  const Choice({required this.value, required this.label, this.hint, this.key});

  final T value;
  final String label;

  /// A second line, smaller (e.g. a language's English name).
  final String? hint;
  final Key? key;
}

/// A bottom sheet listing [choices] with [selected] ticked. Resolves to the
/// chosen value, or null when dismissed.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<Choice<T>> choices,
  required T selected,
}) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Material(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final choice in choices)
                  ListTile(
                    key: choice.key,
                    contentPadding: EdgeInsets.zero,
                    title: Text(choice.label,
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    subtitle: choice.hint == null
                        ? null
                        : Text(choice.hint!,
                            style: TextStyle(color: AppColors.muted)),
                    trailing: choice.value == selected
                        ? Icon(Icons.check_circle_rounded,
                            color: AppColors.button)
                        : Icon(Icons.circle_outlined, color: AppColors.line),
                    onTap: () => Navigator.pop(sheetContext, choice.value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
