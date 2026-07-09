import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
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

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth > 480 ? 480.0 : constraints.maxWidth;
          final sheetHeight =
              (constraints.maxHeight * 0.58).clamp(380.0, 430.0).toDouble();
          final heroHeight = (maxWidth * 0.42).clamp(128.0, 168.0).toDouble();
          const closeButtonSize = 44.0;

          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: maxWidth,
              height: sheetHeight + closeButtonSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: closeButtonSize,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(color: Colors.white),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: heroHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFFF3A43D),
                                            Color(0xFFF7C46D),
                                            Color(0xFFE89032),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    'assets/images/mobReferalBanner.webp',
                                    width: maxWidth,
                                    height: heroHeight,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: heroHeight,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: Colors.white,
                              child: Column(
                                children: [
                                  const SizedBox(height: 18),
                                  Text(
                                    '₹$amountStr',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0A243F),
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'added to mobwallet',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0A243F),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 20 / 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Valid for $validDays days',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFE9441F),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 16 / 12,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      onViewWallet?.call();
                                    },
                                    child: Container(
                                      width: maxWidth * 0.68,
                                      constraints: const BoxConstraints(
                                        minWidth: 230,
                                        maxWidth: 306,
                                      ),
                                      height: 44,
                                      padding: const EdgeInsets.only(
                                        left: 18,
                                        right: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF4F4F4),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'mobwallet balance: ₹$balanceStr',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF0A243F),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                height: 16 / 12,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF0A243F),
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: closeButtonSize / 2,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: SvgPicture.asset(
                        'assets/images/closeicon.svg',
                        width: closeButtonSize,
                        height: closeButtonSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
