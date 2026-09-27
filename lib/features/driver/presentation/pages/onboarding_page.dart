import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/documents_section.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/my_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/personal_details_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/vehicle_art.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Joining as a driver, start to finish: who you are, your documents, your
/// vehicle — then a "we're reviewing your request" screen until the company
/// approves you. Shown full-screen over the app (see ScaffoldWithNavBar) for
/// as long as [OnboardingStatus.needsSetup], i.e. until approval: nobody looks
/// for rides before they're verified.
///
/// Which step shows comes from the server's `onboarding_status`, so uploading
/// the last document moves the driver on by itself and reopening the app puts
/// them back where they were. "Edit my details" is the only manual detour.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.capture = const DevicePhotoCapture()});

  final PhotoCapture capture;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  /// Set only while the driver has gone back to a step themselves.
  int? _override;

  static const _steps = 3;

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You can sign in again any time — your progress is saved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          TextButton(
              key: const Key('onboarding_sign_out_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out',
                  style: TextStyle(color: DriverColors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(AuthSignOutRequested());
    }
  }

  /// 0 details, 1 documents, 2 vehicle, 3 waiting for review.
  static int _stepFor(DriverProfile p) => switch (p.onboardingStatus) {
        OnboardingStatus.profileIncomplete => 0,
        OnboardingStatus.documentsRequired || OnboardingStatus.actionRequired => 1,
        OnboardingStatus.vehicleRequired => 2,
        _ => 3,
      };

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
        buildWhen: (a, b) => a.profile != b.profile,
        builder: (context, state) {
          final profile = state.profile;
          if (profile == null) return const SizedBox.shrink();
          final step = _override ?? _stepFor(profile);

          return Scaffold(
            key: const Key('onboarding'),
            backgroundColor: DriverColors.surface,
            body: SafeArea(
              child: Column(children: [
                _Header(step: step, steps: _steps, onSignOut: _signOut),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                          position: Tween(begin: const Offset(.04, 0), end: Offset.zero).animate(a),
                          child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(step),
                      child: switch (step) {
                        0 => _DetailsStep(
                            profile: profile,
                            onSaved: () => setState(() => _override = null),
                          ),
                        1 => _DocumentsStep(
                            profile: profile,
                            capture: widget.capture,
                            onEditDetails: () => setState(() => _override = 0),
                          ),
                        2 => _VehicleStep(
                            onBack: () => setState(() => _override = 1),
                          ),
                        _ => _ReviewStep(profile: profile),
                      },
                    ),
                  ),
                ),
              ]),
            ),
          );
        },
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.steps, required this.onSignOut});
  final int step;
  final int steps;
  final VoidCallback onSignOut;

  static const _names = ['About you', 'Documents', 'Your vehicle'];

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(step >= steps ? 'Almost there' : 'Set up your driver account',
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
            TextButton(
                key: const Key('onboarding_sign_out'),
                onPressed: onSignOut,
                child: const Text('Sign out')),
          ]),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(children: [
              for (var i = 0; i < steps; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < step
                          ? DriverColors.green
                          : i == step
                              ? DriverColors.blue
                              : DriverColors.line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                if (i < steps - 1) const SizedBox(width: 6),
              ],
            ]),
          ),
          const SizedBox(height: 10),
          Text(
              step >= steps
                  ? 'Submitted · waiting for approval'
                  : 'Step ${step + 1} of $steps · ${_names[step]}',
              key: const Key('onboarding_step'),
              style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({required this.profile, required this.onSaved});
  final DriverProfile profile;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          const Text('Tell us about yourself',
              style: TextStyle(
                  color: DriverColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              'These details go on your driver profile. Use your name exactly as it appears on your driving licence.',
              style: TextStyle(
                  color: DriverColors.muted, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 22),
          PersonalDetailsForm(
            profile: profile,
            submitLabel: 'Continue',
            onSaved: onSaved,
          ),
        ],
      );
}

class _DocumentsStep extends StatelessWidget {
  const _DocumentsStep({
    required this.profile,
    required this.capture,
    required this.onEditDetails,
  });

  final DriverProfile profile;
  final PhotoCapture capture;
  final VoidCallback onEditDetails;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          const Text('Upload your documents',
              style: TextStyle(
                  color: DriverColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (profile.onboardingStatus == OnboardingStatus.actionRequired) ...[
            const InfoBanner(
              key: Key('onboarding_fix_banner'),
              icon: Icons.error_outline_rounded,
              color: DriverColors.red,
              text: 'Something needs fixing — see the note on the document below and upload it again.',
            ),
            const SizedBox(height: 12),
          ],
          const Text(
              'Add your Aadhaar card and driving licence. Next you’ll add your vehicle, then we review everything — usually within a day.',
              style: TextStyle(
                  color: DriverColors.muted, fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 20),
          DocumentsSection(profile: profile, capture: capture),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              key: const Key('onboarding_edit_details'),
              onPressed: onEditDetails,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Edit my details'),
            ),
          ),
        ],
      );
}


/// The driver's own vehicle — its type (picked from pictures), number plate
/// and photos. At least one vehicle with a photo moves them on to review.
class _VehicleStep extends StatefulWidget {
  const _VehicleStep({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<_VehicleStep> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  List<MyVehicle>? _vehicles;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (vehicles, _) = await _cubit.loadMyVehicles();
    if (mounted) setState(() => _vehicles = vehicles ?? const []);
  }

  Future<void> _add() async {
    await context.push(DriverRoutes.newVehicle);
    if (!mounted) return;
    setState(() => _busy = true);
    await _load();
    // The server decides when the vehicle is enough to move on to review.
    await _cubit.load(silent: true);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        const Text('Add your vehicle',
            style: TextStyle(color: DriverColors.ink, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text(
            'Pick what you drive — bike, auto, mini truck or truck — then add its number plate and a clear photo. This decides which orders you get.',
            style: TextStyle(color: DriverColors.muted, fontSize: 13.5, height: 1.4)),
        const SizedBox(height: 20),
        if (vehicles == null)
          const DriverListSkeletonInline(itemCount: 1, itemHeight: 96)
        else ...[
          for (final v in vehicles) ...[
            DriverCard(
              key: Key('onboarding_vehicle_${v.id}'),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: v.photos.isNotEmpty
                      ? Image.network(v.photos.first.url, width: 72, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => VehicleArt(name: v.vehicleTypeName, width: 72))
                      : VehicleArt(name: v.vehicleTypeName, width: 72),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.registrationNumber,
                        style: const TextStyle(color: DriverColors.ink, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(v.vehicleTypeName ?? '',
                        style: const TextStyle(color: DriverColors.muted, fontSize: 12.5)),
                  ]),
                ),
                if (v.photos.isEmpty)
                  const StatusPill('Add a photo', color: DriverColors.orange)
                else
                  const Icon(Icons.check_circle_rounded, color: DriverColors.green),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          PrimaryButton(
            key: const Key('onboarding_add_vehicle'),
            label: vehicles.isEmpty ? 'Add my vehicle' : 'Add another vehicle',
            icon: Icons.add_rounded,
            loading: _busy,
            onPressed: _add,
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to documents'),
          ),
        ),
      ],
    );
  }
}

/// Everything's in: tells the driver their request is with the company, what
/// was submitted, and keeps checking — the screen lifts itself the moment
/// they're approved.
class _ReviewStep extends StatefulWidget {
  const _ReviewStep({required this.profile});
  final DriverProfile profile;

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<_ReviewStep> with WidgetsBindingObserver {
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _check(quiet: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(quiet: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool quiet = false}) async {
    if (_checking) return;
    if (!quiet) setState(() => _checking = true);
    await context.read<DriverSessionCubit>().load(silent: true);
    if (mounted && !quiet) {
      setState(() => _checking = false);
      TopSnackBar.show(context, message: 'Still under review — we’ll let you in as soon as you’re approved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    Widget row(String label, KycItem? item, {String? done}) {
      final status = item?.status;
      final (text, color, icon) = done != null
          ? (done, DriverColors.green, Icons.check_circle_rounded)
          : status == KycStatus.verified
              ? ('Verified', DriverColors.green, Icons.verified_rounded)
              : status == KycStatus.rejected
                  ? ('Needs fixing', DriverColors.red, Icons.error_rounded)
                  : (item?.submitted ?? false)
                      ? ('In review', DriverColors.orange, Icons.schedule_rounded)
                      : ('Not needed yet', DriverColors.muted, Icons.remove_circle_outline_rounded);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: DriverColors.ink, fontWeight: FontWeight.w600))),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );
    }

    return ListView(
      key: const Key('onboarding_review'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(color: Color(0xFFE7F7EF), shape: BoxShape.circle),
              child: const Icon(Icons.task_alt_rounded, color: DriverColors.green, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Thanks! We’re reviewing your request',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.ink, fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 8),
        const Text(
            'Our team is checking your documents and vehicle — usually within 24 hours. You can start taking rides as soon as you’re approved; this screen updates by itself.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.muted, fontSize: 13.5, height: 1.45)),
        const SizedBox(height: 22),
        DriverCard(
          child: Column(children: [
            row('Your details', null, done: 'Submitted'),
            const Divider(height: 1),
            row('Aadhaar card', p.aadhar),
            const Divider(height: 1),
            row('Driving licence', p.drivingLicence),
            const Divider(height: 1),
            row('Police verification', p.police),
            const Divider(height: 1),
            row('Your vehicle', null, done: 'Submitted'),
          ]),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          key: const Key('onboarding_check_status'),
          label: 'Check status',
          icon: Icons.refresh_rounded,
          loading: _checking,
          onPressed: _check,
        ),
      ],
    );
  }
}
