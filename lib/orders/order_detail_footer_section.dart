part of 'order_detail_page.dart';

class _HelpTile extends StatelessWidget {
  const _HelpTile();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF0A7D83),
              size: 28,
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Text(
                'mob',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -8,
            child: Icon(
              Icons.construction_rounded,
              size: 124,
              color: const Color(0xFF0A243F).withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
