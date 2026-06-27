import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';

class CreditHeroBanner extends StatelessWidget {
  const CreditHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A243F), Color(0xFF1B3F5C)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: 10,
              child: Opacity(
                opacity: 0.5,
                child: SvgPicture.asset(
                  'assets/images/Dotsmobcredit.svg',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/images/mobcreditlogo.svg',
                  width: 96,
                  height: 24,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Build now,\n',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 34 / 26,
                              ),
                            ),
                            TextSpan(
                              text: 'pay later',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6FE2A0),
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 34 / 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Image.asset(
                      'assets/images/mobcreditbannerimage.png',
                      width: 70,
                      height: 93,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _heroFeature(Icons.currency_rupee_rounded, 'Upto 25 lakhs'),
                const SizedBox(height: 10),
                _heroFeature(Icons.home_outlined, 'No collateral'),
                const SizedBox(height: 10),
                _heroFeature(
                  Icons.calendar_month_outlined,
                  'Upto 90 days repayment',
                ),
                const SizedBox(height: 20),
                Text(
                  'Powered by Muthoot Finance',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroFeature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class CreditSegmentPills extends StatelessWidget {
  const CreditSegmentPills({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i != 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 1,
                  height: 14,
                  color: const Color(0xFFD6DBE2),
                ),
              ),
            Text(
              labels[i],
              style: AppTextStyles.body14Bold.copyWith(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class CreditTermCard extends StatelessWidget {
  const CreditTermCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.rewardBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body14Bold),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.body14.copyWith(
                    color: AppColors.inputLabel,
                    fontSize: 12,
                    height: 18 / 12,
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

class CreditHowItWorksMockup extends StatelessWidget {
  const CreditHowItWorksMockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepIndicator(),
        const SizedBox(height: 14),
        Text(
          'Use mobCREDIT anywhere',
          style: AppTextStyles.body14Bold.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: AppColors.primaryText,
                    ),
                    const SizedBox(width: 10),
                    Text('Payment details', style: AppTextStyles.body14Bold),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'Pay '),
                            TextSpan(
                              text: '₹26092.00',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' out of '),
                            TextSpan(
                              text: '₹90000.00',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' mobCREDIT available'),
                          ],
                        ),
                        style: GoogleFonts.inter(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MockMobCreditBadgeInfo(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.mutedControl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Pay using Razorpay', style: AppTextStyles.body14),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 16,
                      color: AppColors.inputLabel,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'View all coupons',
                      style: AppTextStyles.body14.copyWith(
                        color: AppColors.inputLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(false),
        _line(),
        _dot(false),
        _line(),
        _dot(true),
      ],
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryText : const Color(0xFFE9ECF1),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _line() {
    return Container(width: 28, height: 2, color: const Color(0xFFE9ECF1));
  }
}

class _MockMobCreditBadgeInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6C6), Color(0xFFD4F4F3)],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 92),
                  child: Text(
                    'Zero% interest for 21 days',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 18 / 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '21.9% per year after 21 days of transaction confirmation',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF67696D),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: 24,
              width: 96,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E20),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/images/mobcreditlogo.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreditDocumentsCard extends StatelessWidget {
  const CreditDocumentsCard({super.key, required this.onViewDocuments});

  final VoidCallback onViewDocuments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep these documents ready',
                  style: AppTextStyles.body14Bold.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onViewDocuments,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    side: const BorderSide(color: AppColors.inputBorder),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View documents'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primaryText,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class CreditIndiaCard extends StatelessWidget {
  const CreditIndiaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3D3E), Color(0xFF155D55)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.5,
              child: SvgPicture.asset(
                'assets/images/Dotsmobcredit.svg',
                width: 150,
                height: 150,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use mobCREDIT across India',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'With any registered sellers',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreditTestimonial {
  const CreditTestimonial({
    required this.quote,
    required this.name,
    required this.role,
  });

  final String quote;
  final String name;
  final String role;
}

class CreditTestimonialsCarousel extends StatefulWidget {
  const CreditTestimonialsCarousel({super.key, required this.testimonials});

  final List<CreditTestimonial> testimonials;

  @override
  State<CreditTestimonialsCarousel> createState() =>
      _CreditTestimonialsCarouselState();
}

class _CreditTestimonialsCarouselState
    extends State<CreditTestimonialsCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.testimonials.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final t = widget.testimonials[i];
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: AppColors.inputHint,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.quote,
                      style: AppTextStyles.body14.copyWith(
                        color: AppColors.inputLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(t.name, style: AppTextStyles.body14Bold),
                    Text(
                      t.role,
                      style: AppTextStyles.body14.copyWith(
                        color: AppColors.inputHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.testimonials.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.testimonials.length, (i) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? AppColors.primaryText
                      : const Color(0xFFD9DDE3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class CreditSupportCard extends StatelessWidget {
  const CreditSupportCard({super.key, required this.onChatTap});

  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6C6), Color(0xFFD4F4F3)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get more clarity about\nmobCREDIT',
                  style: AppTextStyles.body14Bold.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chat with us about limit, how to apply, documents required etc',
                  style: AppTextStyles.body14.copyWith(
                    color: AppColors.inputLabel,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onChatTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble, size: 16),
                  label: const Text('Chat with us'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreditFaqRow extends StatelessWidget {
  const CreditFaqRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDF0F4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Frequently asked questions',
                style: AppTextStyles.body14Bold,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primaryText),
          ],
        ),
      ),
    );
  }
}
