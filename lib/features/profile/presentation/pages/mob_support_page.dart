import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:url_launcher/url_launcher.dart';

class MobSupportPage extends StatelessWidget {
  const MobSupportPage({super.key});

  static const routeName = 'MobSupport';
  static const routePath = '/mob-support';
  static const _navy = Color(0xFF0A243F);
  static const _grey = Color(0xFF8A8A8A);

  Future<void> _launch(BuildContext context, Uri uri, String error) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SupportHeader(onBack: () => context.pop()),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF0F0F0),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Text('How can we help?',
                        style: GoogleFonts.inter(
                            color: _navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 36 / 24)),
                    const SizedBox(height: 20),
                    _SupportOption(
                      asset: 'assets/images/callsupport.svg',
                      iconBackground: const Color(0xFFDFF8F9),
                      title: 'Call support',
                      subtitle: 'No wait time',
                      onTap: () => _launch(
                          context,
                          Uri.parse('tel:+918660423608'),
                          'Unable to start a call.'),
                    ),
                    const SizedBox(height: 12),
                    _SupportOption(
                      asset: 'assets/images/whatsapp-plain.svg',
                      iconBackground: const Color(0xFFDDF5E2),
                      title: 'Chat with us',
                      subtitle: 'Replies in under 10 mins',
                      onTap: () => _launch(
                          context,
                          Uri.parse('https://wa.me/918970415365'),
                          'Unable to open WhatsApp.'),
                    ),
                    const SizedBox(height: 12),
                    _SupportOption(
                      asset: 'assets/images/sendanemail.svg',
                      iconBackground: const Color(0xFFE2EFFD),
                      title: 'Send an email',
                      subtitle: 'Replies within 24 hrs',
                      onTap: () => _launch(
                          context,
                          Uri.parse('mailto:support@madoverbuildings.com'),
                          'Unable to open an email app.'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 66,
      color: Colors.white,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 343,
        height: 48,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: InkWell(
                onTap: onBack,
                child: const SizedBox(
                  width: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackIcon(size: 14),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 30,
              top: 13,
              child: SizedBox(
                width: 281,
                child: Text(
                  'mob support',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: MobSupportPage._navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 22 / 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption(
      {required this.asset,
      required this.iconBackground,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final String asset;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: iconBackground, shape: BoxShape.circle),
                  child: SvgPicture.asset(asset, width: 24, height: 24)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            color: MobSupportPage._navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 20 / 14)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: MobSupportPage._grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 18 / 12)),
                  ])),
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F1F2),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  'assets/images/greaterarrow.svg',
                  width: 6,
                  height: 10,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
