part of 'order_detail_page.dart';

class _HelpTile extends StatelessWidget {
  const _HelpTile();

  static const _whatsappNumber = '918970415365';

  Future<void> _openWhatsapp(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse('https://wa.me/$_whatsappNumber'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      TopSnackBar.show(
        context,
        message: 'Unable to open WhatsApp.',
        type: TopSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openWhatsapp(context),
      child: Container(
        height: 80,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFDFF8F9),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset(
                    'assets/images/supportagent.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help with your order?',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
                  Text(
                    'Contact us about any issues',
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
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Color(0xFF0A243F),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoFooter extends StatelessWidget {
  const _PromoFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFCBEFF9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Text(
            'Making\nconstruction\nreliable',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 40 / 32,
            ).copyWith(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFF3991E2), Color(0xFF81D9C3)],
                ).createShader(const Rect.fromLTWH(0, 0, 260, 130)),
            ),
          ),
          Positioned(
            left: 0,
            top: 140,
            child: Container(
              height: 36,
              padding: const EdgeInsets.only(
                top: 8,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 80,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: SizedBox(
                    width: 56,
                    height: 15,
                    child: SvgPicture.asset(
                      'assets/images/mobinorderdetails.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -8,
            child: SvgPicture.asset(
              'assets/images/orders-fotterbanner.svg',
              width: 124,
            ),
          ),
        ],
      ),
    );
  }
}
