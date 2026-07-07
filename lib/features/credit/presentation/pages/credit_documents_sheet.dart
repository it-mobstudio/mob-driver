import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    required this.asset,
    this.assetWidth,
    this.assetHeight,
    this.alignAssetToBottom = false,
  });

  final String title;
  final String subtitle;
  final String asset;
  final double? assetWidth;
  final double? assetHeight;
  final bool alignAssetToBottom;
}

const _documents = [
  _DocumentItem(
    title: 'Insert ADDRESS where business SIGNBOARD is there',
    subtitle: 'Physical verification might be conducted',
    asset: 'assets/images/Company name.webp',
    assetWidth: 123,
    assetHeight: 81,
  ),
  _DocumentItem(
    title: 'GSTIN login CREDENTIALS of your business',
    subtitle: '',
    asset: 'assets/images/GST login.webp',
    assetWidth: 120,
    assetHeight: 118,
    alignAssetToBottom: true,
  ),
  _DocumentItem(
    title: 'Client and Business KYC',
    subtitle: 'Aadhar and PAN of business and ALL directors/ partners/ owners',
    asset: 'assets/images/Business KYC.webp',
    assetWidth: 104,
    assetHeight: 116,
  ),
  _DocumentItem(
    title: 'Document formats',
    subtitle:
        'Document formats to be transferred to your letterhead and signed by ALL directors/ partners/ owners',
    asset: 'assets/images/Documents format.webp',
    assetWidth: 104,
    assetHeight: 128,
    alignAssetToBottom: true,
  ),
  _DocumentItem(
    title: 'Uploading 6 months of primary business bank account statement',
    subtitle: 'Mandate by the NBFC for higher credit limit',
    asset: 'assets/images/bank-statement.svg',
    assetWidth: 69,
    assetHeight: 92,
  ),
  _DocumentItem(
    title: 'Need for e-NACH setup upon approval of Line of Credit',
    subtitle: 'E-Nach will be triggered after 90 days, if payment is declined',
    asset: 'assets/images/E nach.svg',
    assetWidth: 104,
    assetHeight: 23,
  ),
];

class _CreditDocumentsSheet extends StatelessWidget {
  const _CreditDocumentsSheet();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight * .75;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final scrollBottomPadding = bottomPadding > 0 ? bottomPadding + 16 : 32.0;

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
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Documents required',
                            style: TextStyle(
                              color: Color(0xFF0A243F),
                              fontSize: 18,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              height: 26 / 18,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          28,
                          16,
                          scrollBottomPadding,
                        ),
                        sliver: SliverList.separated(
                          itemCount: _documents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _DocumentRow(
                              index: index + 1,
                              document: _documents[index],
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
          Positioned(
            bottom: sheetHeight + 16,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: Color(0xFF0A243F),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = constraints.maxWidth < 330 ? 128.0 : 144.0;
        final assetScale = tileSize / 144;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DocumentPreview(
              document: document,
              size: tileSize,
              assetScale: assetScale,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$index. ${document.title}',
                    style: const TextStyle(
                      color: Color(0xFF0A243F),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                    ),
                  ),
                  if (document.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      document.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF767C8F),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.document,
    required this.size,
    required this.assetScale,
  });

  final _DocumentItem document;
  final double size;
  final double assetScale;

  @override
  Widget build(BuildContext context) {
    final assetWidth =
        document.assetWidth == null ? null : document.assetWidth! * assetScale;
    final assetHeight = document.assetHeight == null
        ? null
        : document.assetHeight! * assetScale;
    final child = document.asset.endsWith('.svg')
        ? SvgPicture.asset(
            document.asset,
            width: assetWidth,
            height: assetHeight,
            fit: BoxFit.contain,
          )
        : Image.asset(
            document.asset,
            width: assetWidth,
            height: assetHeight,
            fit: BoxFit.contain,
          );

    return Container(
      width: size,
      height: size,
      alignment: document.alignAssetToBottom
          ? Alignment.bottomCenter
          : Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }
}
