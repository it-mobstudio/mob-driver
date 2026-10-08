import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The driver's home for everything that isn't today's map: who they are,
/// their trips and wallet, their vehicles, documents and payout details,
/// where their KYC stands, and sign-out. Opened by the dashboard's profile
/// button.
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Light status-bar icons over the navy header.
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: DriverColors.surface,
            body: profile == null
                ? const SafeArea(
                    child: DriverListSkeleton(itemCount: 3, itemHeight: 104))
                : ListView(padding: EdgeInsets.zero, children: [
                    _Header(profile: profile, capture: capture),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Two to a row, half the width each.
                            IntrinsicHeight(
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _TileCard(
                                        keyName: 'menu_trips',
                                        icon: Icons.inventory_2_outlined,
                                        title: 'Trips',
                                        subtitle: 'View all trips',
                                        onTap: () =>
                                            context.go(DriverRoutes.trips),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _TileCard(
                                        keyName: 'menu_wallet',
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                        title: 'Wallet',
                                        subtitle: 'Earnings & payouts',
                                        onTap: () =>
                                            context.go(DriverRoutes.wallet),
                                      ),
                                    ),
                                  ]),
                            ),
                            const SizedBox(height: 14),
                            DriverCard(
                              padding: EdgeInsets.zero,
                              child: Column(children: [
                                _MenuRow(
                                  keyName: 'menu_edit_details',
                                  icon: Icons.person_outline_rounded,
                                  title: 'Personal info',
                                  subtitle:
                                      'Name, contact, address, emergency contact',
                                  onTap: () =>
                                      context.push(DriverRoutes.editProfile),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_vehicle',
                                  icon: Icons.local_shipping_outlined,
                                  title: 'Duty vehicle',
                                  subtitle: profile.currentVehicle
                                          ?.registrationNumber ??
                                      'The vehicle you go on duty with',
                                  onTap: () => context.go(DriverRoutes.vehicle),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_my_vehicles',
                                  icon: Icons.two_wheeler_rounded,
                                  title: 'My vehicles',
                                  subtitle:
                                      'Add your own vehicles, with pictures',
                                  onTap: () =>
                                      context.push(DriverRoutes.myVehicles),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_documents',
                                  icon: Icons.folder_open_rounded,
                                  title: 'Documents',
                                  subtitle:
                                      'Aadhaar, licence and police certificate',
                                  onTap: () =>
                                      context.push(DriverRoutes.verification),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_payout',
                                  icon: Icons.account_balance_outlined,
                                  title: 'Payout details',
                                  subtitle: profile.payout.summary ??
                                      'Add a UPI id or bank account',
                                  onTap: () =>
                                      context.push(DriverRoutes.payout),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            const SectionTitle('Verification'),
                            const SizedBox(height: 10),
                            _KycCard(profile: profile),
                            if ((profile.emergencyContactName ?? '')
                                    .isNotEmpty ||
                                (profile.emergencyContactPhone ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const SectionTitle('Emergency contact'),
                              const SizedBox(height: 10),
                              DriverCard(
                                child: Column(children: [
                                  InfoRow('Name',
                                      profile.emergencyContactName ?? '—'),
                                  InfoRow(
                                      'Phone',
                                      formatPhone(
                                          profile.emergencyContactPhone)),
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
                                        color: DriverColors.muted,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(child: _VersionLabel()),
                          ]),
                    ),
                  ]),
          ),
        );
      });
}

/// The navy band at the top: the way back, the driver's picture, name and
/// number, and where they stand (verified or not, and their duty vehicle).
class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.capture});

  final DriverProfile profile;
  final PhotoCapture capture;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = profile.isEligible
        ? ('VERIFIED DRIVER', DriverColors.mint, Icons.verified_rounded)
        : switch (profile.onboardingStatus) {
            OnboardingStatus.underReview => (
                'UNDER REVIEW',
                const Color(0xFFFFC466),
                Icons.hourglass_top_rounded
              ),
            OnboardingStatus.actionRequired => (
                'ACTION NEEDED',
                const Color(0xFFFF8A93),
                Icons.error_outline_rounded
              ),
            _ => (
                'KYC INCOMPLETE',
                const Color(0xFFFF8A93),
                Icons.gpp_maybe_outlined
              ),
          };
    return ColoredBox(
      color: DriverColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('profile_back'),
                onTap: () => context.go(DriverRoutes.dashboard),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded,
                      color: DriverColors.ink,
                      size: 20,
                      semanticLabel: 'Back'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              _ProfilePhoto(profile: profile, capture: capture),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName,
                          key: const Key('profile_name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(formatPhone(profile.phoneNumber),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: .65),
                              fontSize: 13.5)),
                    ]),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  color: const Color(0xFF000A1A),
                  borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6)),
                ),
                const Icon(Icons.local_shipping_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                      profile.currentVehicle?.registrationNumber ??
                          'No vehicle',
                      key: const Key('header_vehicle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// One of the two half-width cards under the header: an icon, what it opens,
/// and a line about it.
class _TileCard extends StatelessWidget {
  const _TileCard({
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
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key(keyName),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: DriverColors.ink, size: 26),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DriverColors.muted, fontSize: 13)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: DriverColors.muted, size: 20),
              ]),
            ]),
          ),
        ),
      );
}

/// The dashed line between two rows of the menu card.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: DashedDivider(),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(children: [
            Icon(icon, color: DriverColors.ink, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 15,
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
        ClipOval(
          child: DriverAvatar(profile.fullName,
              size: 64, photoUrl: profile.photoUrl),
        ),
        if (_busy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .7),
                  shape: BoxShape.circle),
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
