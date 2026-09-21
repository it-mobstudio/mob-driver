import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/documents_section.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/personal_details_form.dart';

/// First-run set-up for a driver who signed themselves up: who you are, then
/// your documents. Shown full-screen over the app (see ScaffoldWithNavBar)
/// exactly as long as [OnboardingStatus.needsSetup] — the moment the driver's
/// Aadhaar and licence are in, the backend's answer changes and this simply
/// gives way to the app.
///
/// Where the driver is comes from the server (a saved profile means they're on
/// documents next time they open the app), not from anything remembered here.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.capture = const DevicePhotoCapture()});

  final PhotoCapture capture;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  /// 0 = about you, 1 = documents. Null until first built from the profile.
  int? _step;

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

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
        buildWhen: (a, b) => a.profile != b.profile,
        builder: (context, state) {
          final profile = state.profile;
          if (profile == null) return const SizedBox.shrink();
          final step = _step ??= profile.isProfileComplete ? 1 : 0;

          return Scaffold(
            key: const Key('onboarding'),
            backgroundColor: DriverColors.surface,
            body: SafeArea(
              child: Column(children: [
                _Header(step: step, onSignOut: _signOut),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(step),
                      child: step == 0
                          ? _DetailsStep(
                              profile: profile,
                              onSaved: () => setState(() => _step = 1),
                            )
                          : _DocumentsStep(
                              profile: profile,
                              capture: widget.capture,
                              onEditDetails: () => setState(() => _step = 0),
                            ),
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
  const _Header({required this.step, required this.onSignOut});
  final int step;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Set up your driver account',
                  style: TextStyle(
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
              for (var i = 0; i < 2; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= step ? DriverColors.blue : DriverColors.line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                if (i == 0) const SizedBox(width: 6),
              ],
            ]),
          ),
          const SizedBox(height: 10),
          Text('Step ${step + 1} of 2',
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
          const Text(
              'Add your Aadhaar card and driving licence and we’ll verify them — usually within a day. You’ll be able to take trips as soon as you’re approved.',
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
