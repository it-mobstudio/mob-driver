import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_apply_sheet.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_documents_sheet.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_page_widgets.dart';
import 'package:m_o_b_demand_side/shared/tab_header.dart';

const _creditWhatsappNumber = '918970415365';

class CreditPage extends StatelessWidget {
  static const String routeName = 'Credit';
  static const String routePath = '/credit';

  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const TabHeader(showTopSearchBar: false, showLocationheader: false),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    const CreditHeroBanner(),
                    const SizedBox(height: 24),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'mobCREDIT is for ',
                            style: AppTextStyles.body14Bold.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: '(with GSTIN)',
                            style: AppTextStyles.body14.copyWith(
                              color: AppColors.inputHint,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const CreditSegmentPills(
                      labels: ['Architects', 'Contractors', 'Builders'],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'mobCREDIT terms',
                      style: AppTextStyles.body14Bold.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const CreditTermCard(
                      icon: Icons.currency_rupee_rounded,
                      title: 'Get credit upto 25 lakhs',
                      description:
                          'Credit amount is based on your CIBIL score and tax filings',
                    ),
                    const SizedBox(height: 12),
                    const CreditTermCard(
                      icon: Icons.home_outlined,
                      title: 'No collateral required',
                      description:
                          'Enjoy collateral-free mobCREDIT! Just note that E-NACH is mandatory',
                    ),
                    const SizedBox(height: 12),
                    const CreditTermCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Upto 90 days repayment',
                      description:
                          'Repay anytime within 90 days. The first 21 days post-delivery are interest-free, with daily interest applied thereafter.',
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'How does mobCREDIT work?',
                      style: AppTextStyles.body14Bold.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const CreditHowItWorksMockup(),
                    const SizedBox(height: 24),
                    CreditDocumentsCard(
                      onViewDocuments: () => showCreditDocumentsSheet(context),
                    ),
                    const SizedBox(height: 16),
                    const CreditIndiaCard(),
                    const SizedBox(height: 28),
                    Text(
                      'What our members say',
                      style: AppTextStyles.body14Bold.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const CreditTestimonialsCarousel(
                      testimonials: [
                        CreditTestimonial(
                          quote:
                              'mobCREDIT has simplified the process, eliminating the hassle of constantly requesting credit from suppliers. Now, we focus on what matters most—building! Highly recommend it!',
                          name: 'Sankalp Solanki',
                          role: 'Architect',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CreditSupportCard(onChatTap: () => _chatWithUs(context)),
                    const SizedBox(height: 16),
                    CreditFaqRow(
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: AppComponentStyles.buttonHeight,
                        child: ElevatedButton(
                          onPressed: () => showCreditApplySheet(context),
                          style: AppComponentStyles.primaryButton,
                          child: Text(
                            'Apply for mobCREDIT',
                            style: AppTextStyles.buttonLabel,
                          ),
                        ),
                      ),
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

  Future<void> _chatWithUs(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/$_creditWhatsappNumber?text=${Uri.encodeComponent('Hi, I would like to know more about mobCREDIT')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp')),
      );
    }
  }
}
