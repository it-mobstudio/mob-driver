import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/faq_entry.dart';

/// A single collapsible FAQ item styled for mobSTAR's dark theme: tapping the
/// question row expands/collapses the answer beneath it, with the chevron
/// rotating to point down while open. If [FaqEntry.answer] is empty (content
/// not added yet), it renders as a plain static row instead.
class FaqAccordionTile extends StatefulWidget {
  const FaqAccordionTile(
    this.entry, {
    super.key,
    this.expanded,
    this.onExpansionChanged,
  });

  final FaqEntry entry;
  final bool? expanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<FaqAccordionTile> createState() => _FaqAccordionTileState();
}

class _FaqAccordionTileState extends State<FaqAccordionTile> {
  static const _muted = Color(0xFFBEBEC2);
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasAnswer = widget.entry.answer.trim().isNotEmpty;
    final expanded = widget.expanded ?? _expanded;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasAnswer ? () => _setExpanded(!expanded) : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry.question,
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: hasAnswer && expanded ? 0.25 : 0,
                  child: const Icon(
                    Icons.chevron_right,
                    color: _muted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (hasAnswer)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        widget.entry.answer,
                        style: GoogleFonts.inter(
                          color: _muted.withValues(alpha: .8),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  void _setExpanded(bool value) {
    final callback = widget.onExpansionChanged;
    if (callback != null) {
      callback(value);
      return;
    }
    setState(() => _expanded = value);
  }
}
