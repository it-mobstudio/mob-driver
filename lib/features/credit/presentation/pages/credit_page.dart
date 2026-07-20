import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_apply_sheet.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_documents_sheet.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_profile_page.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_faq_page.dart';
import 'package:m_o_b_demand_side/shared/widgets/frosted_nav_bar.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

const _creditWhatsappNumber = '918970415365';

/// Entry point for the bottom nav bar's mob Credit tab.
class CreditTabPage extends StatelessWidget {
  const CreditTabPage({super.key});

  @override
  Widget build(BuildContext context) => const CreditPage();
}

class CreditPage extends StatelessWidget {
  static const String routeName = 'Credit';
  static const String routePath = '/credit';

  const CreditPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: MobCreditHero(showBackButton: false),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 112),
                sliver: SliverList.list(
                  children: [
                    const MobCreditSectionTitle.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'mobCREDIT is for',
                            style: TextStyle(
                              color: Color(0xFF0A243F),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              height: 1.50,
                            ),
                          ),
                          TextSpan(
                            text: ' (with GSTIN)',
                            style: TextStyle(
                              color: Color(0xFF0A243F),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const MobCreditAudiencePills(),
                    const SizedBox(height: 40),
                    MobCreditSectionTitle('mobCREDIT terms'),
                    const SizedBox(height: 12),
                    const MobCreditTermCard(
                      icon: 'assets/images/getcreditterm.svg',
                      title: 'Get credit upto 25 lakhs',
                      description:
                          'Credit amount is based on your CIBIL score and tax filings',
                    ),
                    const SizedBox(height: 16),
                    const MobCreditTermCard(
                      icon: 'assets/images/nocollateralterm.svg',
                      title: 'No collateral required',
                      description:
                          'Enjoy collateral-free mobCREDIT! Just note that E-NACH is mandatory',
                    ),
                    const SizedBox(height: 16),
                    const MobCreditTermCard(
                      icon: 'assets/images/repaymentterm.svg',
                      title: 'Upto 90 days repayment',
                      description:
                          'Repay anytime within 90 days. The first 21 days post-delivery are interest-free, with daily interest applied thereafter.',
                    ),
                    const SizedBox(height: 40),
                    MobCreditSectionTitle('How does mobCREDIT work?'),
                    const SizedBox(height: 12),
                    const MobCreditHowItWorksCard(),
                    const SizedBox(height: 40),
                    MobCreditDocumentsCard(
                      onViewDocuments: () => showCreditDocumentsSheet(context),
                    ),
                    const SizedBox(height: 20),
                    const MobCreditIndiaCard(),
                    const SizedBox(height: 40),
                    MobCreditSectionTitle('What our members say'),
                    const SizedBox(height: 12),
                    const MobCreditTestimonialsCarousel(),
                    const SizedBox(height: 30),
                    MobCreditSupportCard(
                      onChatTap: () => _chatWithUs(context),
                    ),
                    const SizedBox(height: 40),
                    MobCreditFaqRow(
                      onTap: () => context.push(MobCreditFaqPage.routePath),
                    ),
                    showBackButton
                        ? const SizedBox(height: 20)
                        : const SizedBox(height: 70),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FFFFFF), Colors.white],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => showCreditApplySheet(context),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF0360E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply for mobCREDIT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 21 / 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showBackButton)
            FrostedNavBar(
              iconColor: AppColors.primaryText,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/myaccount');
                }
              },
            ),
        ],
      ),
    );
  }

  Future<void> _chatWithUs(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/$_creditWhatsappNumber?text=${Uri.encodeComponent('Hi, I would like to know more about mobCREDIT')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      TopSnackBar.show(
        context,
        message: 'Unable to open WhatsApp',
        type: TopSnackBarType.error,
      );
    }
  }
}
