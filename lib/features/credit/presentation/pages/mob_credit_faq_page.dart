import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class MobCreditFaqPage extends StatefulWidget {
  const MobCreditFaqPage({super.key});

  static const routeName = 'MobCreditFaq';
  static const routePath = '/credit/faqs';

  @override
  State<MobCreditFaqPage> createState() => _MobCreditFaqPageState();
}

class _MobCreditFaqPageState extends State<MobCreditFaqPage> {
  static const _background = Color(0xFF0B0B18);
  static const _card = Color(0xFF23232D);
  static const _text = Color(0xFFE8E8EC);
  static const _muted = Color(0xFFB8B8C1);

  int? _expandedIndex;

  static const _faqs = <({String question, String answer})>[
    (
      question:
          'I have submitted the application as per the link provided. What are my next steps?',
      answer:
          'Congratulations on starting this journey. There are two possible outcomes:\n\n'
          'OUTCOME 01:\n'
          'Your account has been pushed for activation along with a request for an increase in the line-of-credit limit. If there is a further increase, we will send you another link to accept the upgraded limit and set up eNACH for the higher limit.\n\n'
          'OUTCOME 02:\n'
          'Some documents may still be pending, such as director/owner KYC, board resolution or consent for a CRIF pull. We will contact you with the required details. Once the limit is confirmed, a link will be sent again for you to accept the amount as described in Outcome 01.',
    ),
    (
      question: 'What documents are required for onboarding?',
      answer: 'Documents required for onboarding are:\n\n'
          '1. Private Limited Company or LLP\n'
          '• Company PAN (mandatory)\n'
          '• KYC for all directors — PAN and Aadhaar (mandatory)\n'
          '• MoA and AoA (mandatory)\n'
          '• Certificate of Incorporation (mandatory)\n'
          '• Board Resolution (mandatory)\n'
          '• Consent letter for CRIF pull for all directors (mandatory)\n'
          '• GST Registration Certificate (mandatory)\n\n'
          '2. Partnership firm\n'
          '• Firm PAN (mandatory)\n'
          '• KYC for both partners — PAN and Aadhaar (mandatory)\n'
          '• Partnership Agreement (mandatory)\n'
          '• Consent letter for CRIF pull for all partners (mandatory)\n'
          '• GST Registration Certificate (mandatory)\n\n'
          '3. Proprietorship\n'
          '• GST Registration Certificate (mandatory)\n'
          '• Consent letter for CRIF pull (mandatory)\n'
          '• Proprietor KYC — PAN and Aadhaar (mandatory)',
    ),
    (
      question:
          'Can I call and talk to someone to understand the process better?',
      answer: 'Yes, absolutely!\n\n'
          '1. WhatsApp: 8970415365\n'
          '2. Call: 8660423608\n'
          '3. Email: finance@madoverbuildings.com',
    ),
    (
      question: 'What happens if my application is rejected?',
      answer:
          'We are sorry that the line of credit was not approved. Systems are automatically aligned with RBI mandates.\n\n'
          'You may take these steps to improve your credit score and apply again in the future:\n'
          '• Monitor business credit reports regularly\n'
          '• Pay your bills on time\n'
          '• Avoid frequently maxing out your credit card\n'
          '• File your GSTIN returns on time\n\n'
          'IMPORTANT: In the meantime, you can build your spend data by purchasing with mob. This can help us reapply in 2–3 months.',
    ),
    (
      question:
          'Which address should I mention? Is there a physical verification process?',
      answer:
          'Yes, physical verification will be done after the account is activated. Please mention your current office address while filling out the application form.',
    ),
    (
      question: 'What is eNACH and is it mandatory?',
      answer:
          'eNACH is an electronic mandate that enables automated repayments from your bank account. It is mandatory when the approved limit is more than ₹5 lakh.',
    ),
    (
      question:
          "Can I give a Post Dated Cheque ('PDC') instead of doing eNACH? Will it affect my credit limit?",
      answer:
          'Yes, you may provide a PDC after the limit is confirmed. However, eNACH is recommended for future limit increases. Please schedule a call with our finance team after starting the application process.\n\n'
          'WhatsApp: 8970415365\n'
          'Call: 8660423608\n'
          'Email: finance@madoverbuildings.com',
    ),
    (
      question: 'What are the key features and benefits of the program?',
      answer:
          'mobCREDIT offers several benefits for architects, contractors, interior designers and builders:\n\n'
          '• A 21-day interest-free period followed by 69 days at 0.06% interest per day, providing an overall 90-day repayment cycle\n'
          '• A credit program specially curated by mob for construction and interior professionals in India\n'
          '• mobCREDIT can be used for purchases through mob across all available product ranges and quantities',
    ),
    (
      question:
          'Are there any hidden charges like processing or transaction fees I should be aware of?',
      answer:
          'No, there are no hidden charges. Processing and transaction charges do not apply to mobCREDIT clients. All charges and details will be reconfirmed during registration. Feel free to contact us to discuss this further.',
    ),
    (
      question:
          'Why is the disbursal amount in the agreement higher than my approved or sanctioned credit limit?',
      answer:
          'The higher amount in the agreement indicates the maximum limit that may become available after you complete a few mobCREDIT transactions and become eligible for a limit increase.',
    ),
    (
      question:
          'Can I use mobCREDIT with suppliers outside Mad Over Buildings?',
      answer:
          "Yes. mobCREDIT can be used across India with any registered supplier through MOB's partner platform.",
    ),
    (
      question:
          'Can I make payments using a debit or credit card? What repayment methods are allowed?',
      answer:
          'Only bank transfers and UPI transfers are accepted for repayment. Credit-card and debit-card repayments are not allowed.',
    ),
    (
      question: 'Who is eligible for the mobCREDIT program?',
      answer:
          'mobCREDIT is specially curated for architects, contractors, interior designers and builders. Business owners between 25 and 60 years of age may apply, subject to credit-policy changes. Applicants above 60 years require a co-applicant.',
    ),
    (
      question:
          'What is the typical timeline for credit limit approvals and activations?',
      answer:
          'Approval and activation typically take 2–5 working days after the application process is completed. If the limit is above ₹5 lakh, completion of an additional eNACH process will be required.',
    ),
    (
      question: 'What happens if I make a late payment?',
      answer: 'Under the mobCREDIT program:\n\n'
          '• The first 21 days from the delivery date are interest-free.\n'
          '• From day 21 through day 90, payment is not considered late, but interest accumulates daily at 0.06%.\n'
          '• After 90 days from delivery, late charges may apply and the delay may affect your CIBIL score.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _faqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  return _faqCard(index, faq.question, faq.answer);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.pop(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(child: AppBackIcon(size: 16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Frequently asked questions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqCard(int index, String question, String answer) {
    final isExpanded = _expandedIndex == index;
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(
          () => _expandedIndex = isExpanded ? null : index,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 20 / 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: isExpanded ? .25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.chevron_right,
                      color: _muted,
                      size: 18,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, right: 24),
                        child: Text(
                          answer,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
