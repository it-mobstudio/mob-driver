import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

enum _ProStatus { notApplied, active, onHold }

class UpgradeToProPage extends StatelessWidget {
  const UpgradeToProPage({super.key});

  static const routeName = 'UpgradeToPro';
  static const routePath = '/profile/upgrade-to-pro';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ProfileLoadRequested()),
      child: const _UpgradeToProView(),
    );
  }
}

class _UpgradeToProView extends StatefulWidget {
  const _UpgradeToProView();

  @override
  State<_UpgradeToProView> createState() => _UpgradeToProViewState();
}

class _UpgradeToProViewState extends State<_UpgradeToProView> {
  static const _navy = Color(0xFF0A243F);
  static const _blue = Color(0xFF0360E5);
  static const _muted = Color(0xFF596378);

  // Ported verbatim from mob-web's gstRegex — same pattern already used in
  // project_form_sheet.dart.
  static final _gstRegex = RegExp(r'^[0-3|9][0-9][a-zA-Z0-9]{13}$');

  final _gstinController = TextEditingController();
  final _businessNameController = TextEditingController();

  bool _prefilled = false;
  bool _submitting = false;
  // Set once this submission succeeds — the backend doesn't flip
  // is_professional on the cart's user_details instantly, so show the
  // active state right away rather than waiting on CartBloc to catch up.
  bool _justUpgraded = false;
  String _fullName = '';

  @override
  void dispose() {
    _gstinController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _gstRegex.hasMatch(_gstinController.text.trim()) &&
      _businessNameController.text.trim().isNotEmpty;

  void _submitUpgrade() {
    final emailOrPhone = AuthSession.instance.emailOrPhone;
    setState(() => _submitting = true);
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested({
            // update_user requires this on every call, independent of what
            // else is being changed (same requirement personal_info_page.dart
            // already works around).
            if (emailOrPhone != null) 'email_or_phone': emailOrPhone,
            'full_name': _fullName,
            'business_name': _businessNameController.text.trim(),
            'gst_number': _gstinController.text.trim(),
          }),
        );
  }

  Future<void> _openWhatsapp() async {
    final uri = Uri.parse('https://wa.me/918970415365');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      TopSnackBar.show(
        context,
        message: 'Unable to open WhatsApp.',
        type: TopSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state case ProfileLoaded(:final profile)) {
          _fullName = profile.name;
          if (!_prefilled) {
            _prefilled = true;
            if (profile.gstin.isNotEmpty) _gstinController.text = profile.gstin;
            if (profile.businessName.isNotEmpty) {
              _businessNameController.text = profile.businessName;
            }
          } else if (_submitting) {
            _submitting = false;
            _justUpgraded = true;
            TopSnackBar.show(
              context,
              message: 'Upgrade request submitted',
              type: TopSnackBarType.success,
            );
          }
        } else if (state case ProfileError(:final message)) {
          if (_submitting) {
            _submitting = false;
            TopSnackBar.show(
              context,
              message: message,
              type: TopSnackBarType.error,
            );
          }
        }
      },
      builder: (context, state) {
        final cartState = context.watch<CartBloc>().state;
        final account = cartState is CartLoaded
            ? cartState.summary.account
            : CartAccountEntity.empty;

        // is_blocked + is_professional both come from user_details in the
        // cart API — a professional account that's blocked (e.g. GST
        // rejected) shows the "on hold" state instead of the upgrade form.
        final status = _justUpgraded || account.isProfessional
            ? _ProStatus.active
            : account.isBlocked
                ? _ProStatus.onHold
                : _ProStatus.notApplied;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F1F2),
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _heroBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      switch (status) {
                        _ProStatus.notApplied => _upgradeForm(),
                        _ProStatus.active => _activeBanner(),
                        _ProStatus.onHold => _onHoldBanner(),
                      },
                      const SizedBox(height: 24),
                      _sectionTitle('Who is this for?'),
                      const SizedBox(height: 12),
                      _whoIsThisForCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Benefits'),
                      const SizedBox(height: 12),
                      _benefitsCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _heroBanner() {
    final topPadding = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: topPadding + 390,
            child: const ColoredBox(color: Color(0xFF191919)),
          ),
          Positioned(
            top: topPadding + 66,
            left: 0,
            right: 0,
            height: 324,
            child: Image.asset(
              'assets/images/pro-topbanner.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: topPadding + 22,
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/mobpro-logo.svg',
                height: 24,
              ),
            ),
          ),
          Positioned(
            top: topPadding + 90,
            left: 28,
            right: 27,
            child: Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Special pricing',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFED7546),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                    ),
                  ),
                  TextSpan(
                    text: ' for construction professionals with ',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 26 / 18,
                    ),
                  ),
                  TextSpan(
                    text: 'GSTIN',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFED7546),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 16,
            left: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/myaccount');
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppBackIcon(
                    color: _navy,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: _navy,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 22 / 16,
      ),
    );
  }

  Widget _upgradeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Upgrade for free'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'GSTIN*',
                controller: _gstinController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Business name*',
                controller: _businessNameController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submitUpgrade : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB6B6B6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Upgrade',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xFFF8FAF7),
            Color(0xFFD7F2E1),
          ],
          stops: [0.0009, 0.999],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF13A05A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/deliveredtick.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your pro account is active',
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onHoldBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xFFF8FAF7),
            Color(0xFFFFE2DE),
          ],
          stops: [0.0009, 0.999],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your pro account is on hold',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The GSTIN shared is not correct. Please reshare your '
                  'GSTIN details.',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _openWhatsapp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/images/whatsapp-plain.svg',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chat with us',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF053961),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/mobPro-alert.png',
            width: 104,
            height: 104,
          ),
        ],
      ),
    );
  }

  Widget _whoIsThisForCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "Register if you're an Architect, Interior Designer, Builder, or "
        'Contractor with a valid GSTIN',
        style: GoogleFonts.inter(
          color: _muted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
        ),
      ),
    );
  }

  Widget _benefitsCard() {
    const items = [
      ('assets/images/viewrfq-icon.svg', 'View RFQ price for items'),
      ('assets/images/placeorder-icon.svg', 'Place order with RFQ price'),
      ('assets/images/superfast-icon.svg', 'Superfast quotation'),
      ('assets/images/prioritysupport-icon.svg', 'Priority support'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    items[i].$1,
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i].$2,
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
