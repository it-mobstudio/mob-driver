import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_appearance.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/app_card.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/choice_sheet.dart';
import 'package:mob_driver/core/widgets/dashed_border.dart';
import 'package:mob_driver/core/widgets/list_skeleton.dart';
import 'package:mob_driver/core/widgets/profile_avatar.dart';
import 'package:mob_driver/core/widgets/status_pill.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mob_driver/features/driver/data/media/photo_capture.dart';
import 'package:mob_driver/features/driver/domain/entities/driver_profile.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The driver's home for everything that isn't today's map: who they are,
/// their trips and wallet, their vehicles, documents and payout details,
/// where their KYC stands, and sign-out. Opened by the dashboard's profile
/// button.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.capture = const DevicePhotoCapture()});

  /// Where the profile picture comes from (camera or gallery).
  final PhotoCapture capture;

  Future<void> _signOut(BuildContext context) async {
    final cubit = context.read<DriverSessionCubit>();
    final auth = context.read<AuthBloc>();

    if (cubit.state.activeTrip != null) {
      TopSnackBar.show(context,
          message: tr('Finish or cancel your active trip before signing out.'),
          type: TopSnackBarType.error);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Sign out?')),
        content: Text(tr(
            'You’ll go offline and stop receiving trips until you sign in again.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(tr('Sign out'), style: TextStyle(color: AppColors.red))),
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
        title: Text(tr('Delete your account?')),
        content: Text(tr(
            'This permanently removes your driver account and personal details. To use the app again you’ll have to sign up and be verified from scratch.\n\nYou can’t delete it while you have an active trip or money left in your wallet.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Keep my account'))),
          TextButton(
              key: const Key('delete_account_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(tr('Delete'), style: TextStyle(color: AppColors.red))),
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
  Widget build(BuildContext context) => BlocBuilder<DriverSessionCubit,
          DriverSessionState>(
      buildWhen: (a, b) =>
          a.activeTrip != b.activeTrip || a.profile != b.profile,
      builder: (context, state) {
        final profile = state.profile;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          // Light status-bar icons over the navy header.
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: profile == null
                ? const SafeArea(
                    child: ListSkeleton(itemCount: 3, itemHeight: 104))
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
                                        title: tr('Trips'),
                                        subtitle: tr('View all trips'),
                                        onTap: () =>
                                            context.go(AppRoutes.trips),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _TileCard(
                                        keyName: 'menu_wallet',
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                        title: tr('Wallet'),
                                        subtitle: tr('Earnings & payouts'),
                                        onTap: () =>
                                            context.go(AppRoutes.wallet),
                                      ),
                                    ),
                                  ]),
                            ),
                            const SizedBox(height: 14),
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: Column(children: [
                                _MenuRow(
                                  keyName: 'menu_edit_details',
                                  icon: Icons.person_outline_rounded,
                                  title: tr('Personal info'),
                                  subtitle: tr(
                                      'Name, contact, address, emergency contact'),
                                  onTap: () =>
                                      context.push(AppRoutes.editProfile),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_vehicle',
                                  icon: Icons.local_shipping_outlined,
                                  title: tr('Duty vehicle'),
                                  subtitle: profile
                                          .currentVehicle?.registrationNumber ??
                                      tr('The vehicle you go on duty with'),
                                  onTap: () => context.go(AppRoutes.vehicle),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_my_vehicles',
                                  icon: Icons.two_wheeler_rounded,
                                  title: tr('My vehicles'),
                                  subtitle: tr(
                                      'Add your own vehicles, with pictures'),
                                  onTap: () =>
                                      context.push(AppRoutes.myVehicles),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_documents',
                                  icon: Icons.folder_open_rounded,
                                  title: tr('Documents'),
                                  subtitle: tr(
                                      'Aadhaar, licence and police certificate'),
                                  onTap: () =>
                                      context.push(AppRoutes.verification),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_payout',
                                  icon: Icons.account_balance_outlined,
                                  title: tr('Payout details'),
                                  subtitle: profile.payout.summary ??
                                      tr('Add a UPI id or bank account'),
                                  onTap: () => context.push(AppRoutes.payout),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            SectionTitle(tr('Settings')),
                            const SizedBox(height: 10),
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: Column(children: [
                                _MenuRow(
                                  keyName: 'menu_language',
                                  icon: Icons.translate_rounded,
                                  title: tr('Language'),
                                  subtitle: AppLanguageController
                                      .instance.value.nativeName,
                                  onTap: () => showLanguagePicker(context),
                                ),
                                const _RowDivider(),
                                _MenuRow(
                                  keyName: 'menu_appearance',
                                  icon: Icons.dark_mode_outlined,
                                  title: tr('Appearance'),
                                  subtitle: appearanceLabel(
                                      AppAppearance.instance.value),
                                  onTap: () => showAppearancePicker(context),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            SectionTitle(tr('Verification')),
                            const SizedBox(height: 10),
                            _KycCard(profile: profile),
                            if ((profile.emergencyContactName ?? '')
                                    .isNotEmpty ||
                                (profile.emergencyContactPhone ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 18),
                              SectionTitle(tr('Emergency contact')),
                              const SizedBox(height: 10),
                              AppCard(
                                child: Column(children: [
                                  InfoRow(tr('Name'),
                                      profile.emergencyContactName ?? '—'),
                                  InfoRow(
                                      tr('Phone'),
                                      formatPhone(
                                          profile.emergencyContactPhone)),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 22),
                            SecondaryButton(
                              key: const Key('sign_out'),
                              label: tr('Sign out'),
                              icon: Icons.logout_rounded,
                              color: AppColors.red,
                              onPressed: () => _signOut(context),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: TextButton(
                                key: const Key('delete_account'),
                                onPressed: () => _deleteAccount(context),
                                child: Text(tr('Delete my account'),
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 13)),
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
        ? (tr('VERIFIED DRIVER'), AppColors.mint, Icons.verified_rounded)
        : switch (profile.onboardingStatus) {
            OnboardingStatus.underReview => (
                tr('UNDER REVIEW'),
                const Color(0xFFFFC466),
                Icons.hourglass_top_rounded
              ),
            OnboardingStatus.actionRequired => (
                tr('ACTION NEEDED'),
                const Color(0xFFFF8A93),
                Icons.error_outline_rounded
              ),
            _ => (
                tr('KYC INCOMPLETE'),
                const Color(0xFFFF8A93),
                Icons.gpp_maybe_outlined
              ),
          };
    return ColoredBox(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Material(
              color: AppColors.card,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('profile_back'),
                onTap: () => context.go(AppRoutes.dashboard),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.ink,
                      size: 20,
                      semanticLabel: tr('Back')),
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
                          tr('No vehicle'),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key(keyName),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: AppColors.ink, size: 26),
              const SizedBox(height: 14),
              Text(title,
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted, size: 20),
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

/// Profile → Language: English, हिन्दी or ಕನ್ನಡ, each written in its own
/// script so a driver can find theirs whatever the app is showing now.
Future<void> showLanguagePicker(BuildContext context) async {
  final chosen = await showChoiceSheet<AppLanguage>(
    context,
    title: tr('Choose language'),
    selected: AppLanguageController.instance.value,
    choices: [
      for (final language in AppLanguage.values)
        Choice(
          key: Key('language_${language.code}'),
          value: language,
          label: language.nativeName,
          hint: language == AppLanguage.english ? null : language.englishName,
        ),
    ],
  );
  if (chosen != null) await AppLanguageController.instance.choose(chosen);
}

/// Profile → Appearance: light, dark, or the phone's own setting.
Future<void> showAppearancePicker(BuildContext context) async {
  final chosen = await showChoiceSheet<ThemeMode>(
    context,
    title: tr('Appearance'),
    selected: AppAppearance.instance.value,
    choices: [
      for (final mode in ThemeMode.values)
        Choice(
            key: Key('appearance_${mode.name}'),
            value: mode,
            label: appearanceLabel(mode)),
    ],
  );
  if (chosen != null) await AppAppearance.instance.choose(chosen);
}

String appearanceLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => tr('Same as phone'),
      ThemeMode.light => tr('Light'),
      ThemeMode.dark => tr('Dark'),
    };

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
            Icon(icon, color: AppColors.ink, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
    return AppCard(
      onTap: () => context.push(AppRoutes.verification),
      child: Column(children: [
        _row(tr('Aadhaar'), profile.aadhar),
        const Divider(height: 22),
        _row(
          tr('Driving licence'),
          profile.drivingLicence,
          detail: expiry == null
              ? null
              : tr('Valid till {p0}',
                  {'p0': DateFormat('d MMM yyyy').format(expiry)}),
        ),
        const Divider(height: 22),
        _row(tr('Police verification'), profile.police),
      ]),
    );
  }

  Widget _row(String title, KycItem item, {String? detail}) {
    final (color, label, icon) = switch (item.status) {
      KycStatus.verified => (
          AppColors.green,
          tr('VERIFIED'),
          Icons.verified_rounded
        ),
      KycStatus.rejected => (
          AppColors.red,
          tr('REJECTED'),
          Icons.cancel_rounded
        ),
      KycStatus.pending => (
          AppColors.orange,
          tr('PENDING'),
          Icons.hourglass_top_rounded
        ),
    };
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (detail != null)
            Text(detail,
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          if (item.status == KycStatus.rejected &&
              (item.rejectionNote ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(item.rejectionNote!,
                  style: TextStyle(color: AppColors.red, fontSize: 12)),
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
                ? tr('MOB Driver')
                : tr('MOB Driver · v{version} ({buildNumber})',
                    {'version': info.version, 'buildNumber': info.buildNumber}),
            style: TextStyle(color: AppColors.muted, fontSize: 11.5),
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
        message: failure?.message ?? tr('Profile photo updated.'),
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
          child: ProfileAvatar(profile.fullName,
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
              color: AppColors.button,
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
