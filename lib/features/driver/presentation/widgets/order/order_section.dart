import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';

/// The 8 px grey band between an order screen's sections.
class OrderSectionGap extends StatelessWidget {
  const OrderSectionGap({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 8, color: AppColors.surface);
}

/// A white section with the order screens' standard padding.
class OrderSection extends StatelessWidget {
  const OrderSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.card,
        child: Padding(padding: padding, child: child),
      );
}

/// `Upload photo *` — a field label, with a red star when it's required.
class OrderFieldLabel extends StatelessWidget {
  const OrderFieldLabel(this.text,
      {super.key, this.required = false, this.trailing});

  final String text;
  final bool required;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(text,
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w800)),
        if (required)
          Text(' *',
              style: TextStyle(
                  color: AppColors.red,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ]);
}

/// The app bar's "Help" pill: headset icon and label, vertically centred.
/// With no [onTap] it explains where to turn for help.
class HelpChip extends StatelessWidget {
  const HelpChip({super.key, this.onTap});

  final VoidCallback? onTap;

  void _explain(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Need help?')),
          content: Text(tr(
              'Contact your operations team about this order — they can step in from their end.')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          key: const Key('help_chip'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ?? () => _explain(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.headset_mic_outlined, size: 16, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(tr('Help'),
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

/// `#MOB9867855HJ` over `16 May 2026, 10:25 am`.
class OrderHeader extends StatelessWidget {
  const OrderHeader({super.key, required this.reference, this.placedAt});

  final String reference;
  final DateTime? placedAt;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reference,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800)),
          if (placedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy, h:mm a')
                  .format(placedAt!.toLocal())
                  .replaceAll('AM', 'am')
                  .replaceAll('PM', 'pm'),
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ],
      );
}

/// The company's note for the driver, on a soft amber card.
class OrderNoteCard extends StatelessWidget {
  const OrderNoteCard({super.key, required this.note, this.title = 'Note'});

  final String note;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('order_note'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.orangeSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange.withValues(alpha: .35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.sticky_note_2_outlined,
                size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(title),
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(note.trim(),
                  style: TextStyle(
                      color: AppColors.ink, fontSize: 13, height: 1.4)),
            ]),
          ),
        ]),
      );
}
