import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Who the driver is, where their KYC stands, and sign-out.
class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage(
      {super.key, this.capture = const DevicePhotoCapture()});

  /// Where the profile picture comes from (camera or gallery).
  final PhotoCapture capture;

  static const routeName = 'DriverProfile';
  static const routePath = DriverRoutes.profile;

  Future<void> _signOut(BuildContext context) async {
    final cubit = context.read<DriverSessionCubit>();
    final auth = context.read<AuthBloc>();

    if (cubit.state.activeTrip != null) {
      TopSnackBar.show(context,
          message: 'Finish or cancel your active trip before signing out.',
          type: TopSnackBarType.error);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You’ll go offline and stop receiving trips until you sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out',
                  style: TextStyle(color: DriverColors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Go off duty first: a signed-out phone can't answer a trip, and the
    // backend would otherwise keep matching this driver to one.
    if (cubit.state.isOnline) {
      final failure = await cubit.goOffline();
      if (failure != null) {
        if (context.mounted) {
          TopSnackBar.show(context,
              message: failure.message, type: TopSnackBarType.error);
        }
        return;
      }
    }
    auth.add(AuthSignOutRequested());
  }

  /// App stores require an in-app way to delete an account that was created in
  /// the app. The backend refuses while it would strand something (an active
  /// trip, or money still owed to the driver) and says so in plain words.
  Future<void> _deleteAccount(BuildContext context) async {
    final cubit = context.read<DriverSessionCubit>();
    final auth = context.read<AuthBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'This permanently removes your driver account and personal details. '
            'To use the app again you’ll have to sign up and be verified from scratch.\n\n'
            'You can’t delete it while you have an active trip or money left in your wallet.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep my account')),
          TextButton(
              key: const Key('delete_account_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: DriverColors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    if (cubit.state.isOnline) {
      final offline = await cubit.goOffline();
      if (offline != null) {
        if (context.mounted) {
          TopSnackBar.show(context,
              message: offline.message, type: TopSnackBarType.error);
        }
        return;
      }
    }
    final failure = await cubit.deleteAccount();
    if (!context.mounted) return;
    if (failure != null) {
      TopSnackBar.show(context,
          message: failure.message, type: TopSnackBarType.error);
      return;
    }
    auth.add(AuthSignOutRequested());
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
          builder: (context, state) {
        final profile = state.profile;
        return Scaffold(
          backgroundColor: DriverColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: DriverColors.ink,
            automaticallyImplyLeading: false,
            leading: BackButton(
                key: const Key('profile_back'),
                onPressed: () => context.go(DriverRoutes.dashboard)),
            title: const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          ),
          body: profile == null
              ? const DriverListSkeleton(itemCount: 3, itemHeight: 104)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  children: [
                      DriverCard(
                        child: Row(children: [
                          _ProfilePhoto(profile: profile, capture: capture),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(profile.fullName,
                                      key: const Key('profile_name'),
                                      style: const TextStyle(
                                          color: DriverColors.ink,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(formatPhone(profile.phoneNumber),
                                      style: const TextStyle(
                                          color: DriverColors.muted,
                                          fontSize: 13)),
                                ]),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      const SectionTitle('Account'),
                      const SizedBox(height: 10),
                      DriverCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          _MenuRow(
                            keyName: 'menu_edit_details',
                            icon: Icons.person_outline_rounded,
                            title: 'Edit details',
                            subtitle:
                                'Name, contact, address, emergency contact',
                            onTap: () => context.push(DriverRoutes.editProfile),
                          ),
                          const Divider(height: 1, indent: 60),
                          _MenuRow(
                            keyName: 'menu_my_vehicles',
                            icon: Icons.two_wheeler_rounded,
                            title: 'My vehicles',
                            subtitle: 'Add your own vehicles, with pictures',
                            onTap: () => context.push(DriverRoutes.myVehicles),
                          ),
                          const Divider(height: 1, indent: 60),
                          _MenuRow(
                            keyName: 'menu_documents',
                            icon: Icons.folder_open_rounded,
                            title: 'Documents',
                            subtitle: 'Aadhaar, licence and police certificate',
                            onTap: () =>
                                context.push(DriverRoutes.verification),
                          ),
                          const Divider(height: 1, indent: 60),
                          _MenuRow(
                            keyName: 'menu_payout',
                            icon: Icons.account_balance_outlined,
                            title: 'Payout details',
                            subtitle: profile.payout.summary ??
                                'Add a UPI id or bank account',
                            onTap: () => context.push(DriverRoutes.payout),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      const SectionTitle('Verification'),
                      const SizedBox(height: 10),
                      _KycCard(profile: profile),
                      if ((profile.emergencyContactName ?? '').isNotEmpty ||
                          (profile.emergencyContactPhone ?? '').isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const SectionTitle('Emergency contact'),
                        const SizedBox(height: 10),
                        DriverCard(
                          child: Column(children: [
                            InfoRow(
                                'Name', profile.emergencyContactName ?? '—'),
                            InfoRow('Phone',
                                formatPhone(profile.emergencyContactPhone)),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SecondaryButton(
                        key: const Key('sign_out'),
                        label: 'Sign out',
                        icon: Icons.logout_rounded,
                        color: DriverColors.red,
                        onPressed: () => _signOut(context),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          key: const Key('delete_account'),
                          onPressed: () => _deleteAccount(context),
                          child: const Text('Delete my account',
                              style: TextStyle(
                                  color: DriverColors.muted, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(child: _VersionLabel()),
                    ]),
        );
      });
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: DriverColors.blue, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: DriverColors.muted, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: DriverColors.muted),
          ]),
        ),
      );
}

class _KycCard extends StatelessWidget {
  const _KycCard({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final expiry = profile.licenceExpiry;
    return DriverCard(
      onTap: () => context.push(DriverRoutes.verification),
      child: Column(children: [
        _row('Aadhaar', profile.aadhar),
        const Divider(height: 22),
        _row(
          'Driving licence',
          profile.drivingLicence,
          detail: expiry == null
              ? null
              : 'Valid till ${DateFormat('d MMM yyyy').format(expiry)}',
        ),
        const Divider(height: 22),
        _row('Police verification', profile.police),
      ]),
    );
  }

  Widget _row(String title, KycItem item, {String? detail}) {
    final (color, label, icon) = switch (item.status) {
      KycStatus.verified => (
          DriverColors.green,
          'VERIFIED',
          Icons.verified_rounded
        ),
      KycStatus.rejected => (
          DriverColors.red,
          'REJECTED',
          Icons.cancel_rounded
        ),
      KycStatus.pending => (
          DriverColors.orange,
          'PENDING',
          Icons.hourglass_top_rounded
        ),
    };
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (detail != null)
            Text(detail,
                style:
                    const TextStyle(color: DriverColors.muted, fontSize: 12)),
          if (item.status == KycStatus.rejected &&
              (item.rejectionNote ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(item.rejectionNote!,
                  style:
                      const TextStyle(color: DriverColors.red, fontSize: 12)),
            ),
        ]),
      ),
      StatusPill(label, color: color, icon: icon),
    ]);
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (_, snapshot) {
          final info = snapshot.data;
          return Text(
            info == null
                ? 'MOB Driver'
                : 'MOB Driver · v${info.version} (${info.buildNumber})',
            style: const TextStyle(color: DriverColors.muted, fontSize: 11.5),
          );
        },
      );
}

/// The driver's picture, with a camera badge: tap to take a new one or pick one
/// from the gallery. The profile updates as soon as it's saved.
class _ProfilePhoto extends StatefulWidget {
  const _ProfilePhoto({required this.profile, required this.capture});

  final DriverProfile profile;
  final PhotoCapture capture;

  @override
  State<_ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<_ProfilePhoto> {
  bool _busy = false;

  Future<void> _change() async {
    final cubit = context.read<DriverSessionCubit>();
    final photo = await chooseDocumentPhoto(context, widget.capture);
    if (photo == null || !mounted) return;
    setState(() => _busy = true);
    final failure = await cubit.uploadPhoto(photo);
    if (!mounted) return;
    setState(() => _busy = false);
    TopSnackBar.show(context,
        message: failure?.message ?? 'Profile photo updated.',
        type:
            failure == null ? TopSnackBarType.success : TopSnackBarType.error);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return GestureDetector(
      key: const Key('profile_photo'),
      onTap: _busy ? null : _change,
      behavior: HitTestBehavior.opaque,
      child: Stack(clipBehavior: Clip.none, children: [
        DriverAvatar(profile.fullName, size: 64, photoUrl: profile.photoUrl),
        if (_busy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(64 * .32)),
              child: const Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4))),
            ),
          ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: DriverColors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.photo_camera_rounded,
                size: 13, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
