import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

Future<void> showCreditDocumentsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => const _CreditDocumentsSheet(),
  );
}

class _DocumentItem {
  const _DocumentItem({
    required this.title,
    required this.subtitle,
    required this.preview,
  });

  final String title;
  final String subtitle;
  final _DocumentPreviewType preview;
}

const _documents = [
  _DocumentItem(
    title: 'Insert ADDRESS where business SIGNBOARD is there',
    subtitle: 'Physical verification might be conducted',
    preview: _DocumentPreviewType.signboard,
  ),
  _DocumentItem(
    title: 'GSTIN login CREDENTIALS of your business',
    subtitle: '',
    preview: _DocumentPreviewType.gstin,
  ),
  _DocumentItem(
    title: 'Client and Business KYC',
    subtitle: 'Aadhar and PAN of business and ALL directors/ partners/ owners',
    preview: _DocumentPreviewType.kyc,
  ),
  _DocumentItem(
    title: 'Document formats',
    subtitle:
        'Document formats to be transferred to your letterhead and signed by ALL directors/ partners/ owners',
    preview: _DocumentPreviewType.format,
  ),
  _DocumentItem(
    title: 'Uploading 6 months of primary business bank account statement',
    subtitle: 'Mandate by the NBFC for higher credit limit',
    preview: _DocumentPreviewType.statement,
  ),
  _DocumentItem(
    title: 'Need for e-NACH setup upon approval of Line of Credit',
    subtitle: 'E-Nach will be triggered after 90 days, if payment is declined',
    preview: _DocumentPreviewType.enach,
  ),
];

enum _DocumentPreviewType { signboard, gstin, kyc, format, statement, enach }

class _CreditDocumentsSheet extends StatelessWidget {
  const _CreditDocumentsSheet();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight - 161;

    return SizedBox(
      height: screenHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Material(
                color: Colors.white,
                child: SizedBox(
                  height: sheetHeight,
                  child: SafeArea(
                    top: false,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          sliver: SliverList.separated(
                            itemCount: _documents.length + 1,
                            separatorBuilder: (_, index) =>
                                SizedBox(height: index == 0 ? 26 : 16),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Text(
                                  'Documents required',
                                  style: _docTextStyle(
                                    color: const Color(0xFF0A243F),
                                    size: 18,
                                    weight: FontWeight.w600,
                                    height: 26 / 18,
                                  ),
                                );
                              }
                              return _DocumentRow(
                                index: index,
                                document: _documents[index - 1],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: sheetHeight + 16,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close,
                    color: Color(0xFF0A243F),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.index,
    required this.document,
  });

  final int index;
  final _DocumentItem document;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _DocumentPreview(type: document.preview),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$index. ${document.title}',
                style: _docTextStyle(
                  color: const Color(0xFF0A243F),
                  size: 14,
                  weight: FontWeight.w600,
                  height: 20 / 14,
                ),
              ),
              if (document.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  document.subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    height: 18 / 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.type});

  final _DocumentPreviewType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      height: 144,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: switch (type) {
        _DocumentPreviewType.signboard => const _SignboardPreview(),
        _DocumentPreviewType.gstin => const _GstinPreview(),
        _DocumentPreviewType.kyc => const _KycPreview(),
        _DocumentPreviewType.format => const _LetterheadPreview(),
        _DocumentPreviewType.statement => const _StatementPreview(),
        _DocumentPreviewType.enach => const _EnachPreview(),
      },
    );
  }
}

class _SignboardPreview extends StatelessWidget {
  const _SignboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 78,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1DE),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFC6BDA2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'COMPANY NAME',
            textAlign: TextAlign.center,
            style: _docTextStyle(
              color: const Color(0xFF29384A),
              size: 10,
              weight: FontWeight.w700,
              height: 12 / 10,
            ),
          ),
          const SizedBox(height: 3),
          Container(height: 3, width: 80, color: const Color(0xFFB8B8B8)),
          const SizedBox(height: 4),
          Container(height: 3, width: 64, color: const Color(0xFFCFCFCF)),
        ],
      ),
    );
  }
}

class _GstinPreview extends StatelessWidget {
  const _GstinPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 92,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GST Verification',
            style: _docTextStyle(
              color: const Color(0xFF0A243F),
              size: 8,
              weight: FontWeight.w700,
              height: 10 / 8,
            ),
          ),
          const SizedBox(height: 6),
          _previewLine(width: 92),
          const SizedBox(height: 5),
          _previewField(),
          const SizedBox(height: 5),
          _previewField(),
          const Spacer(),
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0360E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _KycPreview extends StatelessWidget {
  const _KycPreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _idCard(const Color(0xFFF5EEF0), const Color(0xFFD84E4E)),
          const SizedBox(height: 8),
          _idCard(const Color(0xFFFDF4E4), const Color(0xFFF2A33B)),
        ],
      ),
    );
  }

  Widget _idCard(Color bg, Color accent) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(width: 28, height: 28, color: accent.withValues(alpha: .3)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _previewLine(width: double.infinity),
                const SizedBox(height: 4),
                _previewLine(width: double.infinity, color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterheadPreview extends StatelessWidget {
  const _LetterheadPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 128,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 24, height: 8, color: const Color(0xFFE44848)),
          const SizedBox(height: 12),
          for (final width in const [76.0, 64.0, 82.0, 70.0, 58.0]) ...[
            _previewLine(width: width),
            const SizedBox(height: 6),
          ],
          const Spacer(),
          _previewLine(width: 32, color: const Color(0xFFB8B8B8)),
        ],
      ),
    );
  }
}

class _StatementPreview extends StatelessWidget {
  const _StatementPreview();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.receipt_long_outlined,
      size: 72,
      color: Color(0xFFBDBDBD),
    );
  }
}

class _EnachPreview extends StatelessWidget {
  const _EnachPreview();

  @override
  Widget build(BuildContext context) {
    return Text(
      'NACH',
      style: GoogleFonts.inter(
        color: const Color(0xFF8E8E8E),
        fontSize: 30,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
        letterSpacing: 2,
      ),
    );
  }
}

Widget _previewField() {
  return Container(
    height: 12,
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE2E2E2)),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _previewLine({
  required double width,
  Color color = const Color(0xFFD8D8D8),
}) {
  return Container(
    height: 3,
    width: width,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

TextStyle _docTextStyle({
  required Color color,
  required double size,
  required FontWeight weight,
  required double height,
}) {
  return GoogleFonts.inter(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
  );
}
