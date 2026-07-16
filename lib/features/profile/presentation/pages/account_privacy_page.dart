import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

Future<void> _showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .6),
    builder: (context) => const _DeleteAccountSheet(),
  );
}

class AccountPrivacyPage extends StatelessWidget {
  const AccountPrivacyPage({super.key});

  static const routeName = 'AccountPrivacy';
  static const routePath = '/account-privacy';

  static const _navy = Color(0xFF0A243F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PrivacyHeader(onBack: () => context.pop()),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF0F0F0),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: const [
                    _PrivacyPolicyCard(),
                    SizedBox(height: 8),
                    _ViewAllButton(),
                    SizedBox(height: 16),
                    _DeleteAccountCard(),
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

class _PrivacyHeader extends StatelessWidget {
  const _PrivacyHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 66,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.expand(),
                onPressed: onBack,
                icon: const AppBackIcon(),
              ),
            ),
          ),
          Text(
            'Account privacy',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AccountPrivacyPage._navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 22 / 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account privacy and policy',
            style: GoogleFonts.inter(
              color: AccountPrivacyPage._navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 22 / 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We take privacy very seriously. It is a legal requirement as well. '
            'madoverbuildings.com (herein referred to as MOB) is always committed '
            'to protect your privacy when you visit our App/ website. These policies '
            'only apply to our App/ website and not to other companies, individuals '
            'or organizations who display our link. In similar fashion, our App/ '
            'website might contain links or promotional details from other websites. '
            'MOB recommends referring to their privacy policies if you are accessing '
            'their website. MOB indemnifies itself against all data use on and '
            'reservations made via third party websites/agents.',
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF0360E5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View all',
              style: GoogleFonts.inter(
                color: const Color(0xFF0360E5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showDeleteAccountSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFFDE4E2),
                    shape: OvalBorder(),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/deleteicon.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request to delete account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AccountPrivacyPage._navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your account will be closed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8A8A8A),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF1F1F2),
                    shape: OvalBorder(),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/greaterarrow.svg',
                    width: 6,
                    height: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends StatelessWidget {
  const _DeleteAccountSheet();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = bottomInset > 0 ? bottomInset : 16.0;

    return SizedBox(
      height: 516,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 40, 16, bottomPadding),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/deleteimage.webp',
                    width: 190,
                    height: 136,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    "We're sorry to see you go",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AccountPrivacyPage._navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 26 / 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please submit a request below, and our team\n'
                    'will contact you shortly to complete the\n'
                    'deletion.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AccountPrivacyPage._navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF0483E),
                              side: const BorderSide(
                                color: Color(0xFFF0483E),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Submit request',
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 21 / 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF0360E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Go back',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 21 / 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/images/close.svg',
                width: 44,
                height: 44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
