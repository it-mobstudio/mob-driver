import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

class DeleteConfirmSheet extends StatefulWidget {
  const DeleteConfirmSheet({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onConfirm,
  });

  final String name;
  final num price;
  final String imageUrl;
  final Future<bool> Function() onConfirm;

  @override
  State<DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<DeleteConfirmSheet> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    final success = await widget.onConfirm();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove this item?',
              style: GoogleFonts.inter(
                color: MagicQuoteColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can always add it back from the catalog below.',
              style: GoogleFonts.inter(
                  color: MagicQuoteColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Colors.white,
                      child: widget.imageUrl.isEmpty
                          ? const Icon(Icons.inventory_2_outlined,
                              color: MagicQuoteColors.navy)
                          : Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.inventory_2_outlined,
                                color: MagicQuoteColors.navy,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: MagicQuoteColors.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.price > 0)
                          Text(
                            '${formatInr(widget.price)} /unit',
                            style: GoogleFonts.inter(
                                color: MagicQuoteColors.muted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isDeleting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: MagicQuoteColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                          color: MagicQuoteColors.navy,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : _delete,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFE14040),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Remove',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
