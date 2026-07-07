import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';

/// mobCREDIT (Rupifi-powered buy-now-pay-later) account status. Mirrors the
/// web app's ApplyCreditOrApprovedCredit component so every screen that
/// shows a mobCREDIT summary agrees on what state the user is in.
enum MobCreditStatus {
  /// No application on file (`primary_status` empty) — show an apply
  /// prompt rather than a balance.
  notApplied,
  active,
  amountDue,
  rejected,
  inProgress,
  inactive,
}

MobCreditStatus resolveMobCreditStatus(CartAccountEntity account) {
  final accountStatus = account.rupifiAccountStatus.trim().toUpperCase();
  final primaryStatus = account.rupifiPrimaryStatus.trim().toUpperCase();

  // The web app's ApplyCreditOrApprovedCredit gates "not applied" on
  // account_status being empty, not primary_status — a never-applied
  // customer's rupifiDetails can still carry a non-empty primary_status
  // placeholder, which previously caused this to fall through to
  // MobCreditStatus.inactive instead of notApplied.
  if (accountStatus.isEmpty) return MobCreditStatus.notApplied;
  if (accountStatus == 'ACTIVE') return MobCreditStatus.active;
  if (accountStatus == 'AMOUNT_DUE') return MobCreditStatus.amountDue;

  switch (primaryStatus) {
    case 'REJECTED':
      return MobCreditStatus.rejected;
    case 'PRE_APPROVED':
    case 'PRE_APPROVAL_PENDING':
    case 'INCOMPLETE':
    case 'UNDER_REVIEW':
      return MobCreditStatus.inProgress;
    default:
      return MobCreditStatus.inactive;
  }
}

String formatRupees(double value) {
  final text =
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  return '₹$text';
}

/// Reusable mobCREDIT summary card — drop into any card list (My Account,
/// checkout, home) and it renders the right look for whatever state the
/// user's mobCREDIT account is currently in.
class MobCreditCard extends StatelessWidget {
  const MobCreditCard({
    super.key,
    required this.account,
    required this.onManage,
    required this.onApply,
  });

  /// Existing account snapshot (usually `CartSummaryEntity.account`).
  final CartAccountEntity account;

  /// Tapped for any status where the user already has an application on
  /// file — typically navigates to the mobCREDIT dashboard.
  final VoidCallback onManage;

  /// Tapped only in the [MobCreditStatus.notApplied] state — typically
  /// navigates to the mobCREDIT application flow.
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final status = resolveMobCreditStatus(account);
    return switch (status) {
      MobCreditStatus.notApplied => _ApplyCard(onTap: onApply),
      MobCreditStatus.active =>
        _ActiveCard(account: account, onTap: onManage),
      MobCreditStatus.amountDue =>
        _AmountDueCard(account: account, onTap: onManage),
      MobCreditStatus.rejected => _StatusCard(
          account: account,
          label: 'REJECTED',
          labelColor: const Color(0xFFFF6B5E),
          onTap: onManage,
        ),
      MobCreditStatus.inProgress => _InProgressCard(onTap: onManage),
      MobCreditStatus.inactive => _StatusCard(
          account: account,
          label: 'INACTIVE',
          labelColor: Colors.white.withValues(alpha: 0.6),
          onTap: onManage,
        ),
    };
  }
}

const _kCardRadius = 16.0;

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.gradient,
    required this.onTap,
    required this.child,
  });

  final Gradient gradient;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_kCardRadius),
          gradient: gradient,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kCardRadius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardLogoRow extends StatelessWidget {
  const _CardLogoRow({required this.trailing});

  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/mobcreditlogo.svg',
          width: 92,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Expanded(child: trailing),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          color: Colors.white.withValues(alpha: 0.9),
          size: 16,
        ),
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.account, required this.onTap});

  final CartAccountEntity account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final creditLimit = account.rupifiCurrentLimit;
    // rupifiDetails.balance is already the remaining spendable amount, not
    // an amount-utilized figure to subtract from the limit (confirmed
    // against a real account: current_limit 100000, balance 6729.2 —
    // "Available balance" is 6729.2, not 93270.8).
    final available = account.rupifiBalance;

    return _CardShell(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF55A77B), Color(0xFF0D889C)],
      ),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardLogoRow(
            trailing: Text(
              'Credit limit: ${formatRupees(creditLimit)}',
              textAlign: TextAlign.right,
              softWrap: true,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 20 / 13,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Available balance',
                  softWrap: true,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 20 / 13,
                  ),
                ),
              ),
              Text(
                formatRupees(available),
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 24 / 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountDueCard extends StatelessWidget {
  const _AmountDueCard({required this.account, required this.onTap});

  final CartAccountEntity account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final due = account.rupifiBalance;

    return _CardShell(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFC6362A), Color(0xFF7A1F17)],
      ),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLogoRow(
            trailing: Text(
              'Amount due: ${formatRupees(due)}',
              textAlign: TextAlign.right,
              softWrap: true,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 20 / 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please clear your due amount to activate mobCREDIT',
            softWrap: true,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.account,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final CartAccountEntity account;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF3A4552), Color(0xFF232A33)],
      ),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/mobcreditlogo.svg',
                width: 92,
                height: 24,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 18 / 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Available balance',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 20 / 13,
                  ),
                ),
              ),
              Text(
                formatRupees(account.rupifiBalance),
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 20 / 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      gradient: const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF3A4552), Color(0xFF232A33)],
      ),
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/mobcreditlogo.svg',
            width: 92,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'IN PROGRESS',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pre approved, incomplete or under review',
                  textAlign: TextAlign.right,
                  softWrap: true,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 16 / 11,
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

class _ApplyCard extends StatelessWidget {
  const _ApplyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      gradient: const LinearGradient(
        begin: Alignment(0.50, 0.00),
        end: Alignment(1.07, 1.27),
        colors: [Color(0xFF043860), Color(0xFF0973C6)],
      ),
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/mobcreditlogo.svg',
            width: 92,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Build now, pay later',
              softWrap: true,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 20 / 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Apply now',
              style: GoogleFonts.inter(
                color: const Color(0xFF053961),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
