import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

class GeneratingScreen extends StatelessWidget {
  const GeneratingScreen({
    super.key,
    required this.pincode,
    required this.currentStatus,
  });

  final String pincode;
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        _warningBanner(),
        const SizedBox(height: 22),
        const Center(child: _ScanningDocumentCard()),
        const SizedBox(height: 26),
        Text(
          'Putting your quote together',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: MagicQuoteColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: GoogleFonts.inter(
              color: MagicQuoteColors.muted,
              fontSize: 14,
              height: 1.4,
            ),
            children: [
              const TextSpan(
                text: 'Reading your list, matching brands and checking '
                    'live prices for ',
              ),
              TextSpan(
                text: pincode.isEmpty ? 'your area' : pincode,
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          child: LinearProgressIndicator(
            minHeight: 6,
            backgroundColor: Color(0xFFE3E8EF),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1EAD66)),
          ),
        ),
        const SizedBox(height: 18),
        _statusRow(currentStatus),
      ],
    );
  }

  Widget _warningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Please don't close this screen",
            style: GoogleFonts.inter(
              color: const Color(0xFF8A5A00),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Takes 30-60 sec',
            style: GoogleFonts.inter(
              color: const Color(0xFFB07D1F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF1EAD66), size: 20),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            label,
            key: ValueKey(label),
            style: GoogleFonts.inter(
              color: MagicQuoteColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanningDocumentCard extends StatefulWidget {
  const _ScanningDocumentCard();

  @override
  State<_ScanningDocumentCard> createState() => _ScanningDocumentCardState();
}

class _ScanningDocumentCardState extends State<_ScanningDocumentCard>
    with SingleTickerProviderStateMixin {
  static const _cardWidth = 220.0;
  static const _cardHeight = 250.0;
  static const _scanHeight = 56.0;
  static const _rowWidthFactors = [0.9, 0.75, 0.55, 0.65, 0.45, 0.6];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I need these products',
                    style: GoogleFonts.caveat(
                      color: const Color(0xFF0A243F),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._rowWidthFactors.map(_skeletonRow),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final top = (_cardHeight + _scanHeight) * _controller.value -
                    _scanHeight;
                return Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  height: _scanHeight,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1EAD66).withValues(alpha: 0),
                            const Color(0xFF1EAD66).withValues(alpha: 0.16),
                            const Color(0xFF1EAD66).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonRow(double widthFactor) {
    const checkboxSize = 14.0;
    const gap = 8.0;
    const maxBarWidth = _cardWidth - 16 - 16 - checkboxSize - gap;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: checkboxSize,
            height: checkboxSize,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE3EC)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: gap),
          Container(
            width: maxBarWidth * widthFactor,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
