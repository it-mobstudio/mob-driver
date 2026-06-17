import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

class ReferralSuccessDialog {
  ReferralSuccessDialog._();

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required double walletBalance,
    int validDays = 90,
    VoidCallback? onViewWallet,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Referral reward',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => _ReferralSuccessSheet(
        amount: amount,
        walletBalance: walletBalance,
        validDays: validDays,
        onViewWallet: onViewWallet,
      ),
    );
  }
}

class _ReferralSuccessSheet extends StatelessWidget {
  const _ReferralSuccessSheet({
    required this.amount,
    required this.walletBalance,
    required this.validDays,
    this.onViewWallet,
  });

  final double amount;
  final double walletBalance;
  final int validDays;
  final VoidCallback? onViewWallet;

  @override
  Widget build(BuildContext context) {
    final amountStr = amount == amount.truncateToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final balanceStr = walletBalance == walletBalance.truncateToDouble()
        ? walletBalance.toStringAsFixed(0)
        : walletBalance.toStringAsFixed(2);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner image header
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/images/mobReferalBanner.webp',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    Text(
                      '₹$amountStr',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'added to mobwallet',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Valid for $validDays days',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE85D26),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Wallet balance pill button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onViewWallet?.call();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'mobwallet balance: ₹$balanceStr',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF0A243F),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF0A243F),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
