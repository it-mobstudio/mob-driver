import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/app_card.dart';
import 'package:mob_driver/core/widgets/info_banner.dart';
import 'package:mob_driver/core/widgets/list_skeleton.dart';
import 'package:mob_driver/features/driver/data/media/photo_capture.dart';
import 'package:mob_driver/features/driver/domain/entities/driver_profile.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/onboarding/documents_section.dart';

/// Where the driver's documents stand and how to fix any the company sent back.
/// Reached from the dashboard's verification card and from the profile.
class VerificationPage extends StatelessWidget {
  const VerificationPage({
    super.key,
    this.capture = const DevicePhotoCapture(),
  });

  final PhotoCapture capture;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          foregroundColor: AppColors.ink,
          title: Text(tr('Documents'),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: BlocBuilder<DriverSessionCubit, DriverSessionState>(
          buildWhen: (a, b) => a.profile != b.profile,
          builder: (context, state) {
            final profile = state.profile;
            if (profile == null) {
              return const ListSkeleton(itemCount: 4, itemHeight: 96);
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                _StatusBanner(profile: profile),
                const SizedBox(height: 16),
                DocumentsSection(profile: profile, capture: capture),
                if (profile.licenceExpiry != null) ...[
                  const SizedBox(height: 16),
                  _LicenceExpiry(profile: profile),
                ],
              ],
            );
          },
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = switch (profile.onboardingStatus) {
      OnboardingStatus.approved => (
          tr('You’re verified. You can go online and take trips.'),
          AppColors.green,
          Icons.verified_rounded
        ),
      OnboardingStatus.actionRequired => (
          tr('Some documents were sent back. Fix them below and we’ll review them again.'),
          AppColors.red,
          Icons.error_outline_rounded
        ),
      _ => (
          tr('Your documents are being reviewed — usually within a day. We’ll unlock trips as soon as you’re approved.'),
          AppColors.orange,
          Icons.hourglass_top_rounded
        ),
    };
    return InfoBanner(
      key: const Key('verification_status'),
      text: text,
      color: color,
      icon: icon,
    );
  }
}

class _LicenceExpiry extends StatelessWidget {
  const _LicenceExpiry({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final days = profile.licenceDaysLeft;
    final soon = days != null && days <= 30;
    return AppCard(
      child: Row(children: [
        Icon(soon ? Icons.warning_amber_rounded : Icons.event_available_rounded,
            color: soon ? AppColors.orange : AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                tr('Licence valid until {p0}',
                    {'p0': formatDate(profile.licenceExpiry)}),
                style: TextStyle(
                    color: AppColors.ink, fontWeight: FontWeight.w700)),
            if (soon)
              Text(
                days < 0
                    ? tr('It has expired — your account will be locked.')
                    : tr(
                        'Expires in {days} day{p0} — renew it to keep taking trips.',
                        {'days': days, 'p0': days == 1 ? '' : 's'}),
                style: TextStyle(color: AppColors.orange, fontSize: 12.5),
              ),
          ]),
        ),
      ]),
    );
  }
}
