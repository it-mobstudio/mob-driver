import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/invoice_actions.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// The order's invoice, with the three things a driver does with it at the
/// door: download it, send it to the customer on WhatsApp, or share the file
/// anywhere the phone can.
class InvoiceCard extends StatefulWidget {
  const InvoiceCard({
    super.key,
    required this.trip,
    this.actions = const DeviceInvoiceActions(),
  });

  final Trip trip;
  final InvoiceActions actions;

  @override
  State<InvoiceCard> createState() => _InvoiceCardState();
}

enum _Action { download, whatsApp, share }

class _InvoiceCardState extends State<InvoiceCard> {
  _Action? _busy;

  Trip get _trip => widget.trip;
  String get _url => _trip.invoiceUrl ?? '';

  bool get _hasNumber => (_trip.invoiceNumber ?? '').isNotEmpty;

  String get _label =>
      _hasNumber ? 'Invoice ${_trip.invoiceNumber}' : 'Invoice';

  /// What lands in the customer's WhatsApp chat: a greeting by name when the
  /// company gave one, and the link (WhatsApp can't take a file this way).
  String get _message {
    final name = (_trip.drop.contactName ?? '').trim();
    final what = _hasNumber ? 'invoice ${_trip.invoiceNumber}' : 'invoice';
    return 'Hi${name.isEmpty ? '' : ' $name'}, here is your $what: $_url';
  }

  Future<void> _run(_Action action, Future<String?> Function() call) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    final problem = await call();
    if (!mounted) return;
    setState(() => _busy = null);
    if (problem != null) {
      AppHaptics.error();
      TopSnackBar.show(context, message: problem, type: TopSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) => DriverCard(
        key: const Key('invoice_card'),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: DriverColors.blue.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_rounded,
                  color: DriverColors.blue, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label,
                        key: const Key('invoice_title'),
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800)),
                    const Text('Give it to the customer at the door',
                        style:
                            TextStyle(color: DriverColors.muted, fontSize: 12)),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _button(
              keyName: 'invoice_download',
              action: _Action.download,
              icon: Icons.download_rounded,
              label: 'Download',
              onTap: () =>
                  _run(_Action.download, () => widget.actions.download(_url)),
            ),
            const SizedBox(width: 8),
            _button(
              keyName: 'invoice_whatsapp',
              action: _Action.whatsApp,
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF1FA855),
              onTap: () => _run(
                  _Action.whatsApp,
                  () => widget.actions.whatsApp(
                      phone: _trip.drop.contactPhone, message: _message)),
            ),
            const SizedBox(width: 8),
            _button(
              keyName: 'invoice_share',
              action: _Action.share,
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onTap: () => _run(
                  _Action.share,
                  () => widget.actions.shareFile(
                        _url,
                        fileName: invoiceFileName(_url,
                            invoiceNumber: _trip.invoiceNumber),
                        message: _message,
                      )),
            ),
          ]),
        ]),
      );

  Widget _button({
    required String keyName,
    required _Action action,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = DriverColors.ink,
  }) {
    final busy = _busy == action;
    return Expanded(
      child: PressScale(
        enabled: _busy == null,
        child: SizedBox(
          height: 42,
          child: OutlinedButton(
            key: Key(keyName),
            onPressed: _busy == null ? onTap : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              side: BorderSide(color: color.withValues(alpha: .28)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            child: busy
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: color))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 5),
                    Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis)),
                  ]),
          ),
        ),
      ),
    );
  }
}
