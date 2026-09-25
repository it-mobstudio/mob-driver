import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/document_sheets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/item_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Why an item wasn't handed over. The last is free text.
const kNotDeliveredReasons = [
  'Customer refused it',
  'Item damaged',
  'Item missing or short',
  'Wrong item',
  'Other',
];

/// The checklist the company asked for: at the drop the driver confirms each
/// item ("delivered", or "couldn't deliver" with why), optionally with a photo
/// taken on the spot. Those answers are the delivery history — and until every
/// item has one, the backend won't take payment or complete the trip.
///
/// For a finished trip (or one that never asked for verification) the same page
/// is a read-only record.
class ItemVerificationPage extends StatefulWidget {
  const ItemVerificationPage({
    super.key,
    required this.tripId,
    this.capture = const DevicePhotoCapture(),
  });

  static const routeName = 'DriverTripItems';

  final String tripId;
  final PhotoCapture capture;

  @override
  State<ItemVerificationPage> createState() => _ItemVerificationPageState();
}

class _ItemVerificationPageState extends State<ItemVerificationPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();

  /// Loaded only when this isn't the driver's live trip (a finished one opened
  /// from history); the live trip is read from the session so it stays current.
  Trip? _fetched;
  String? _loadError;

  /// The item whose request is in flight (for its own spinner).
  String? _busyItem;

  @override
  void initState() {
    super.initState();
    if (_cubit.state.activeTrip?.id != widget.tripId) _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loadError = null);
    final (trip, failure) = await _cubit.fetchTrip(widget.tripId);
    if (!mounted) return;
    setState(() {
      _fetched = trip;
      if (trip == null) {
        _loadError = failure?.message ?? 'Could not load this order.';
      }
    });
  }

  Trip? _trip(DriverSessionState state) =>
      state.activeTrip?.id == widget.tripId ? state.activeTrip : _fetched;

  Future<void> _answer(
    Trip trip,
    TripItem item, {
    required ItemStatus status,
    String? note,
    CapturedPhoto? photo,
  }) async {
    setState(() => _busyItem = item.id);
    final (result, failure) = await _cubit.verifyItem(trip.id, item.id,
        status: status, note: note, photo: photo);
    if (!mounted) return;
    setState(() => _busyItem = null);
    if (result == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? 'Couldn’t save that. Try again.',
          type: TopSnackBarType.error);
      return;
    }
    AppHaptics.success();
  }

  Future<void> _undo(Trip trip, TripItem item) async {
    setState(() => _busyItem = item.id);
    final (result, failure) = await _cubit.resetItem(trip.id, item.id);
    if (!mounted) return;
    setState(() => _busyItem = null);
    if (result == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? 'Couldn’t undo that. Try again.',
          type: TopSnackBarType.error);
    }
  }

  /// A picture for an item that's already been answered: re-sends the same
  /// answer with the photo attached (the backend keeps the note as it was).
  Future<void> _addPhoto(Trip trip, TripItem item) async {
    final photo = await takeGeoPhoto(context, widget.capture,
        caption: trip.photoCaption('Delivery', item), locate: _cubit.currentFix);
    if (photo == null || !mounted) return;
    await _answer(trip, item,
        status: item.status, note: item.driverNote, photo: photo);
  }

  Future<void> _reportProblem(Trip trip, TripItem item) async {
    final result = await showModalBottomSheet<_Problem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProblemSheet(
          item: item,
          capture: widget.capture,
          caption: trip.photoCaption('Delivery problem', item),
          locate: _cubit.currentFix),
    );
    if (result == null || !mounted) return;
    await _answer(trip, item,
        status: ItemStatus.notDelivered,
        note: result.note,
        photo: result.photo);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
        builder: (context, state) {
          final trip = _trip(state);
          return Scaffold(
            backgroundColor: DriverColors.surface,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: DriverColors.ink,
              title: Text(
                  trip != null && trip.verifyItems && trip.status.isActive
                      ? 'Check items'
                      : 'Items',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 19)),
            ),
            body:
                trip == null ? _placeholder() : _content(trip, state.tripBusy),
          );
        },
      );

  Widget _placeholder() => _loadError == null
      ? const Center(child: CircularProgressIndicator())
      : CenteredMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load this order',
          message: _loadError,
          actionLabel: 'Retry',
          onAction: _fetch,
        );

  Widget _content(Trip trip, bool tripBusy) {
    final verifying = trip.verifyItems;
    final live = trip.status == TripStatus.inProgress && verifying;
    final pending = [
      for (final i in trip.items)
        if (i.isPending) i
    ];
    final answered = [
      for (final i in trip.items)
        if (!i.isPending) i
    ];

    Widget entry(TripItem item) => verifying && !item.isPending
        ? _AnsweredRow(
            item: item,
            editable: live,
            busy: _busyItem == item.id,
            locked: tripBusy && _busyItem != item.id,
            onUndo: () => _undo(trip, item),
            onPhoto: () => _addPhoto(trip, item),
          )
        : _ItemCard(
            item: item,
            editable: live,
            verifyItems: verifying,
            busy: _busyItem == item.id,
            locked: tripBusy && _busyItem != item.id,
            onDelivered: () =>
                _answer(trip, item, status: ItemStatus.delivered),
            onProblem: () => _reportProblem(trip, item),
          );

    // What's left comes first, so the next thing to do is always at the top;
    // answered items settle below as compact rows.
    final entries = <Widget>[
      if (verifying) ...[
        if (pending.isNotEmpty)
          _SectionLabel('TO CHECK', pending.length,
              key: const Key('section_to_check')),
        for (final item in pending) entry(item),
        if (answered.isNotEmpty)
          _SectionLabel('DONE', answered.length,
              key: const Key('section_done')),
        for (final item in answered) entry(item),
      ] else ...[
        _SectionLabel('ITEMS', trip.items.length),
        for (final item in trip.items) entry(item),
      ],
    ];

    return Column(children: [
      if (verifying) _Progress(trip: trip),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: entries.length,
          separatorBuilder: (_, i) => SizedBox(
              height: entries[i] is _SectionLabel
                  ? 8
                  : entries[i + 1] is _SectionLabel
                      ? 20
                      : 10),
          itemBuilder: (_, i) => entries[i],
        ),
      ),
      if (live) _Footer(trip: trip),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.count, {super.key});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Row(children: [
          Text(label,
              style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 11.5,
                  letterSpacing: .9,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
                color: DriverColors.line,
                borderRadius: BorderRadius.circular(8)),
            child: Text('$count',
                style: const TextStyle(
                    color: DriverColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final total = trip.items.length;
    final done = trip.resolvedItemCount;
    final finished = total > 0 && done == total;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(finished ? 'All $total checked' : '$done of $total checked',
              key: const Key('items_progress'),
              style: TextStyle(
                  color: finished ? DriverColors.green : DriverColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          if (finished)
            const Icon(Icons.check_circle_rounded,
                color: DriverColors.green, size: 26),
        ]),
        const SizedBox(height: 10),
        ItemProgressBar(items: trip.items),
        const SizedBox(height: 10),
        Text(itemTally(trip.items),
            key: const Key('items_tally'),
            style: const TextStyle(
                color: DriverColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
        if (done == 0) ...[
          const SizedBox(height: 4),
          const Text(
              'Hand each item over, then tap Delivered. Something wrong? Tap Problem.',
              style: TextStyle(
                  color: DriverColors.muted, fontSize: 12.5, height: 1.35)),
        ],
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final left = trip.pendingItemCount;
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 12, 18, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Color(0x14000000), blurRadius: 14, offset: Offset(0, -3)),
      ]),
      child: PrimaryButton(
        key: const Key('items_done'),
        label: left > 0
            ? '$left item${left == 1 ? '' : 's'} left to check'
            : trip.isCod && !trip.isPaid
                ? 'Continue to payment'
                : 'Continue',
        icon: left == 0 ? Icons.arrow_forward_rounded : null,
        color: DriverColors.green,
        onPressed: left == 0
            ? () => context.canPop()
                ? context.pop()
                : context.go(DriverRoutes.trip(trip.id))
            : null,
      ),
    );
  }
}

/// An item still to check (or, on a finished order, a plain line of the list):
/// what it is, how many, anything the sender wants the driver to know — and the
/// two answers as big, explicit buttons.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.editable,
    required this.verifyItems,
    required this.busy,
    required this.locked,
    required this.onDelivered,
    required this.onProblem,
  });

  final TripItem item;
  final bool editable;
  final bool verifyItems;
  final bool busy;

  /// Another item's request is in flight: hold this one still.
  final bool locked;
  final VoidCallback onDelivered;
  final VoidCallback onProblem;

  @override
  Widget build(BuildContext context) {
    final sku = (item.sku ?? '').trim();
    final notes = (item.notes ?? '').trim();
    return DriverCard(
      key: Key('item_${item.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetworkThumb(item.imageUrl, size: 60, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  QuantityChip(item.quantityLabel),
                  if (sku.isNotEmpty)
                    Text(sku,
                        style: const TextStyle(
                            color: DriverColors.muted, fontSize: 12.5)),
                ],
              ),
              if (notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.info_outline_rounded,
                              size: 15, color: DriverColors.orange),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(notes,
                              style: const TextStyle(
                                  color: DriverColors.ink,
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                ),
            ]),
          ),
        ]),
        if (verifyItems) ...[
          const SizedBox(height: 14),
          if (!editable)
            const StatusPill('NOT CHECKED', color: DriverColors.muted)
          else
            Row(children: [
              Expanded(
                flex: 3,
                child: _ActionButton(
                  key: Key('item_delivered_${item.id}'),
                  label: 'Delivered',
                  icon: Icons.check_rounded,
                  color: DriverColors.green,
                  filled: true,
                  busy: busy,
                  enabled: !locked,
                  onTap: onDelivered,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _ActionButton(
                  key: Key('item_problem_${item.id}'),
                  label: 'Problem',
                  icon: Icons.report_gmailerrorred_rounded,
                  color: DriverColors.red,
                  busy: false,
                  enabled: !locked && !busy,
                  onTap: onProblem,
                ),
              ),
            ]),
        ],
      ]),
    );
  }
}

/// An item that has its answer: one compact, tinted row — the verdict, the time
/// or the reason, its photo — instead of a full card, so the list you still
/// have to work through stays short.
class _AnsweredRow extends StatelessWidget {
  const _AnsweredRow({
    required this.item,
    required this.editable,
    required this.busy,
    required this.locked,
    required this.onUndo,
    required this.onPhoto,
  });

  final TripItem item;
  final bool editable;
  final bool busy;
  final bool locked;
  final VoidCallback onUndo;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final delivered = item.status == ItemStatus.delivered;
    final color = delivered ? DriverColors.green : DriverColors.red;
    final hasPhoto = (item.proofImageUrl ?? '').isNotEmpty;
    final note = (item.driverNote ?? '').trim();
    return Container(
      key: Key('item_${item.id}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(delivered ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DriverColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                QuantityChip(item.quantityLabel, compact: true),
              ]),
              const SizedBox(height: 3),
              Text(
                  delivered
                      ? 'Delivered${item.verifiedAt == null ? '' : ' · ${formatClock(item.verifiedAt)}'}'
                      : 'Not delivered',
                  key: Key('item_status_${item.id}'),
                  style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800)),
              if (note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(note,
                      style: const TextStyle(
                          color: DriverColors.ink,
                          fontSize: 12.5,
                          height: 1.35)),
                ),
            ]),
          ),
          if (editable)
            busy
                ? const Padding(
                    padding: EdgeInsets.only(left: 8, top: 4),
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : GestureDetector(
                    key: Key('item_undo_${item.id}'),
                    onTap: locked ? null : onUndo,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(10, 4, 2, 8),
                      child: Text('Undo',
                          style: TextStyle(
                              color: DriverColors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
        ]),
        if (hasPhoto)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(children: [
              NetworkThumb(item.proofImageUrl,
                  size: 44, radius: 10, fallbackIcon: Icons.photo_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Photo saved',
                    style: TextStyle(
                        color: DriverColors.muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
              if (editable)
                TextButton(
                  key: Key('item_photo_${item.id}'),
                  onPressed: locked || busy ? null : onPhoto,
                  child: const Text('Retake'),
                ),
            ]),
          )
        else if (editable)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: Key('item_photo_${item.id}'),
              onPressed: locked || busy ? null : onPhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Add photo'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    final content = busy
        ? SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: filled ? Colors.white : color))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return PressScale(
      enabled: active,
      child: SizedBox(
        height: 48,
        child: filled
            ? ElevatedButton(
                onPressed: active ? onTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: color.withValues(alpha: .5),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: shape,
                  textStyle: const TextStyle(fontFamily: 'Inter', 
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                child: content,
              )
            : OutlinedButton(
                onPressed: active ? onTap : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: .3)),
                  shape: shape,
                  textStyle: const TextStyle(fontFamily: 'Inter', 
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                child: content,
              ),
      ),
    );
  }
}

// -- "Problem" sheet -----------------------------------------------------------------

class _Problem {
  const _Problem(this.note, this.photo);
  final String note;
  final CapturedPhoto? photo;
}

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet({
    required this.item,
    required this.capture,
    required this.caption,
    required this.locate,
  });
  final TripItem item;
  final PhotoCapture capture;
  final String caption;
  final Future<GeoPoint?> Function() locate;

  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  final _other = TextEditingController();
  String? _reason;
  CapturedPhoto? _photo;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String? get _note {
    if (_reason == null) return null;
    if (_reason != 'Other') return _reason;
    final text = _other.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) => DriverSheet(
        title: 'What went wrong?',
        subtitle:
            '${widget.item.name} · Qty ${widget.item.quantityLabel}. This is recorded with the order.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(children: [
              for (final reason in kNotDeliveredReasons)
                RadioListTile<String>(
                  key: Key('problem_reason_$reason'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: reason,
                  title: Text(reason),
                ),
            ]),
          ),
          if (_reason == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DriverTextField(
                key: const Key('problem_other'),
                controller: _other,
                label: 'Tell us what happened',
                maxLength: 200,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ),
          const SizedBox(height: 12),
          PhotoTile(
            key: const Key('problem_photo'),
            label: 'Photo of the problem',
            optional: true,
            height: 96,
            photo: _photo,
            onTap: () async {
              final p = await takeGeoPhoto(context, widget.capture,
                  caption: widget.caption, locate: widget.locate);
              if (p != null) setState(() => _photo = p);
            },
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            key: const Key('problem_confirm'),
            label: 'Record as not delivered',
            color: DriverColors.red,
            onPressed: _note == null
                ? null
                : () => Navigator.pop(context, _Problem(_note!, _photo)),
          ),
        ]),
      );
}
