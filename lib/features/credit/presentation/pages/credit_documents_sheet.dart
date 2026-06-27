import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';

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
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const _documents = [
  _DocumentItem(
    icon: Icons.storefront_outlined,
    title: 'Insert ADDRESS where business SIGNBOARD is there',
    subtitle: 'Physical verification might be conducted',
  ),
  _DocumentItem(
    icon: Icons.lock_outline,
    title: 'GSTIN login CREDENTIALS of your business',
    subtitle: 'We do not store or share your credentials',
  ),
  _DocumentItem(
    icon: Icons.badge_outlined,
    title: 'Client and Business KYC',
    subtitle: 'Aadhar and PAN of business and ALL directors/ partners/ owners',
  ),
  _DocumentItem(
    icon: Icons.description_outlined,
    title: 'Document formats',
    subtitle:
        'Document formats to be transferred to your letterhead and signed by ALL directors/ partners/ owners',
  ),
  _DocumentItem(
    icon: Icons.receipt_long_outlined,
    title: 'Uploading 6 months of primary business bank account statement',
    subtitle: 'Mandate by the NBFC for higher credit limit',
  ),
  _DocumentItem(
    icon: Icons.sync_alt,
    title: 'Need for e-NACH setup upon approval of Line of Credit',
    subtitle: 'E-Nach will be triggered after 90 days, if payment is declined',
  ),
];

class _CreditDocumentsSheet extends StatelessWidget {
  const _CreditDocumentsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Documents required',
                          style: AppTextStyles.screenTitle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: _documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              doc.icon,
                              color: AppColors.primaryText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${doc.title}',
                                  style: AppTextStyles.body14Bold,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doc.subtitle,
                                  style: GoogleFonts.inter(
                                    color: AppColors.inputHint,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    height: 16 / 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
