import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/documents_section.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

/// Where the driver's documents stand and how to fix any the company sent back.
/// Reached from the dashboard's verification card and from the profile.
class DriverVerificationPage extends StatelessWidget {
  const DriverVerificationPage({
    super.key,
    this.capture = const DevicePhotoCapture(),
  });

  static const routeName = 'DriverVerification';
  static const routePath = DriverRoutes.verification;

  final PhotoCapture capture;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DriverColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: DriverColors.ink,
          title: const Text('Documents',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: BlocBuilder<DriverSessionCubit, DriverSessionState>(
          builder: (context, state) {
            final profile = state.profile;
            if (profile == null) {
              return const DriverListSkeleton(itemCount: 4, itemHeight: 96);
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
          'You’re verified. You can go online and take trips.',
          DriverColors.green,
          Icons.verified_rounded
        ),
      OnboardingStatus.actionRequired => (
          'Some documents were sent back. Fix them below and we’ll review them again.',
          DriverColors.red,
          Icons.error_outline_rounded
        ),
      _ => (
          'Your documents are being reviewed — usually within a day. We’ll unlock trips as soon as you’re approved.',
          DriverColors.orange,
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
    return DriverCard(
      child: Row(children: [
        Icon(soon ? Icons.warning_amber_rounded : Icons.event_available_rounded,
            color: soon ? DriverColors.orange : DriverColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Licence valid until ${formatDate(profile.licenceExpiry)}',
                style: const TextStyle(
                    color: DriverColors.ink, fontWeight: FontWeight.w700)),
            if (soon)
              Text(
                days < 0
                    ? 'It has expired — your account will be locked.'
                    : 'Expires in $days day${days == 1 ? '' : 's'} — renew it to keep taking trips.',
                style:
                    const TextStyle(color: DriverColors.orange, fontSize: 12.5),
              ),
          ]),
        ),
      ]),
    );
  }
}
