import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/app_card.dart';
import 'package:mob_driver/core/widgets/status_pill.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/data/media/photo_capture.dart';
import 'package:mob_driver/features/driver/domain/entities/driver_profile.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/onboarding/document_sheets.dart';
import 'package:mob_driver/features/driver/presentation/widgets/photo_widgets.dart';

/// The driver's documents as a stack of cards, each showing where it stands
/// (not sent / in review / verified / sent back with a reason) and opening the
/// right upload sheet. Shared by the sign-up flow and the "Documents" page, so
/// fixing a rejected document later looks exactly like adding it the first time.
class DocumentsSection extends StatefulWidget {
  const DocumentsSection({
    super.key,
    required this.profile,
    this.capture = const DevicePhotoCapture(),
  });

  final DriverProfile profile;
  final PhotoCapture capture;

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> {
  bool _photoBusy = false;

  void _done(String message) {
    AppHaptics.success();
    if (mounted) {
      TopSnackBar.show(context,
          message: message, type: TopSnackBarType.success);
    }
  }

  Future<void> _aadhar() async {
    if (await showAadharSheet(context,
        capture: widget.capture, current: widget.profile.aadhar)) {
      _done(tr('Aadhaar submitted for review.'));
    }
  }

  Future<void> _licence() async {
    if (await showLicenceSheet(context,
        capture: widget.capture, current: widget.profile.drivingLicence)) {
      _done(tr('Driving licence submitted for review.'));
    }
  }

  Future<void> _police() async {
    if (await showPoliceSheet(context,
        capture: widget.capture, current: widget.profile.police)) {
      _done(tr('Police certificate submitted for review.'));
    }
  }

  Future<void> _photo() async {
    final cubit = context.read<DriverSessionCubit>();
    final photo = await chooseDocumentPhoto(context, widget.capture);
    if (photo == null || !mounted) return;
    setState(() => _photoBusy = true);
    final failure = await cubit.uploadPhoto(photo);
    if (!mounted) return;
    setState(() => _photoBusy = false);
    if (failure != null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure.message, type: TopSnackBarType.error);
    } else {
      _done(tr('Profile photo updated.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Column(children: [
      _DocumentCard(
        cardKey: 'doc_aadhar',
        icon: Icons.badge_outlined,
        title: tr('Aadhaar card'),
        hint: tr('Front and back, with the 12-digit number'),
        item: p.aadhar,
        required: true,
        onOpen: _aadhar,
      ),
      const SizedBox(height: 12),
      _DocumentCard(
        cardKey: 'doc_licence',
        icon: Icons.credit_card_rounded,
        title: tr('Driving licence'),
        hint: tr('Number, expiry date and a photo of the card'),
        item: p.drivingLicence,
        required: true,
        onOpen: _licence,
      ),
      const SizedBox(height: 12),
      _DocumentCard(
        cardKey: 'doc_police',
        icon: Icons.local_police_outlined,
        title: tr('Police verification'),
        hint:
            tr('Police clearance certificate — needed before your first trip'),
        item: p.police,
        required: false,
        onOpen: _police,
      ),
      const SizedBox(height: 12),
      _PhotoCard(
        photoUrl: p.photoUrl,
        busy: _photoBusy,
        onTap: _photo,
      ),
    ]);
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.hint,
    required this.item,
    required this.required,
    required this.onOpen,
  });

  final String cardKey;
  final IconData icon;
  final String title;
  final String hint;
  final KycItem item;
  final bool required;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final verified = item.status == KycStatus.verified;
    final rejected = item.status == KycStatus.rejected;
    final inReview = item.submitted && item.status == KycStatus.pending;

    final (color, pill) = verified
        ? (AppColors.green, tr('VERIFIED'))
        : rejected
            ? (AppColors.red, tr('SENT BACK'))
            : inReview
                ? (AppColors.orange, tr('IN REVIEW'))
                : (AppColors.muted, required ? tr('REQUIRED') : tr('OPTIONAL'));

    final action = verified
        ? null
        : rejected
            ? tr('Upload again')
            : inReview
                ? tr('Replace')
                : tr('Add');

    final detail = rejected
        ? (item.rejectionNote ?? tr('Please upload it again.'))
        : inReview
            ? [
                'Submitted — being checked.',
                if (item.reference != null) item.reference!,
              ].join(' ')
            : verified
                ? (item.reference ?? tr('Verified by the company.'))
                : hint;

    return AppCard(
      key: Key(cardKey),
      onTap: verified ? null : onOpen,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(13)),
          child: Icon(verified ? Icons.verified_rounded : icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(title,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              StatusPill(pill, color: color),
            ]),
            const SizedBox(height: 4),
            Text(detail,
                key: Key('${cardKey}_detail'),
                style: TextStyle(
                    color: rejected ? AppColors.red : AppColors.muted,
                    fontSize: 12.5,
                    height: 1.35)),
            if (action != null) ...[
              const SizedBox(height: 8),
              Text(action,
                  key: Key('${cardKey}_action'),
                  style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photoUrl,
    required this.busy,
    required this.onTap,
  });

  final String? photoUrl;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = (photoUrl ?? '').isNotEmpty;
    return AppCard(
      key: const Key('doc_photo'),
      onTap: busy ? null : onTap,
      child: Row(children: [
        NetworkThumb(photoUrl,
            size: 42, radius: 13, fallbackIcon: Icons.face_retouching_natural),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(tr('Your photo'),
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              StatusPill(has ? tr('ADDED') : tr('OPTIONAL'),
                  color: has ? AppColors.green : AppColors.muted),
            ]),
            const SizedBox(height: 4),
            Text(tr('A clear photo of your face helps customers trust you.'),
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12.5, height: 1.35)),
          ]),
        ),
        const SizedBox(width: 8),
        if (busy)
          const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4))
        else
          Text(has ? tr('Change') : tr('Add'),
              style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
