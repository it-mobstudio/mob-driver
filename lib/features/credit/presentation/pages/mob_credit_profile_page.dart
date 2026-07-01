import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

class MobCreditProfilePage extends StatelessWidget {
  const MobCreditProfilePage({super.key});

  static const String routeName = 'ProfileMobCredit';
  static const String routePath = '/profile/mob-credit';

  static const _primary = Color(0xFF0A243F);
  static const _muted = Color(0xFF767C8F);
  static const _pale = Color(0xFFF8FAF7);

  @override
  Widget build(BuildContext context) {
    return const _MobCreditDashboard();
  }
}

class _MobCreditDashboard extends StatelessWidget {
  const _MobCreditDashboard();

  static const _sampleTransactions = [
    _MobCreditTransaction(
      orderId: 'OD20250910004507',
      amount: -500,
      debitedAt: '18 Aug 2026, 03:53 PM',
    ),
    _MobCreditTransaction(
      orderId: 'OD20250910004507',
      amount: -500,
      debitedAt: '18 Aug 2026, 03:53 PM',
    ),
    _MobCreditTransaction(
      orderId: 'OD20250910004507',
      amount: -500,
      debitedAt: '18 Aug 2026, 03:53 PM',
    ),
    _MobCreditTransaction(
      orderId: 'OD20250910004507',
      amount: -500,
      debitedAt: '18 Aug 2026, 03:53 PM',
    ),
    _MobCreditTransaction(
      orderId: 'OD20250910004507',
      amount: -500,
      debitedAt: '18 Aug 2026, 03:53 PM',
    ),
    _MobCreditTransaction(
      orderId: 'OD20250910004507',
      amount: -500,
      debitedAt: '18 Aug 2026, 03:53 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rupifiDetails = _rupifiDetails(AuthSession.instance.userDetails);
    final creditLimit = _numValue(
      rupifiDetails,
      const ['sanctioned', 'credit_limit', 'limit', 'total_limit'],
      fallback: 1000000,
    );
    final availableBalance = _numValue(
      rupifiDetails,
      const ['available', 'available_balance', 'balance', 'current_limit'],
      fallback: 800000,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight =
              constraints.maxHeight < 812 ? 812.0 : constraints.maxHeight;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _MobCreditDashboardTop(
                  availableBalance: availableBalance,
                  creditLimit: creditLimit,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Transactions',
                    style: _inter(
                      color: MobCreditProfilePage._primary,
                      size: 15,
                      weight: FontWeight.w700,
                      height: 22 / 15,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: _TransactionsPanel(transactions: _sampleTransactions),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: SizedBox(height: minHeight > 812 ? 0 : 1),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobCreditDashboardTop extends StatelessWidget {
  const _MobCreditDashboardTop({
    required this.availableBalance,
    required this.creditLimit,
    required this.onBack,
  });

  final double availableBalance;
  final double creditLimit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + 278,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: 262,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF181818),
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: .9,
                  colors: [
                    Color(0xFF347A59),
                    Color(0xFF181818),
                  ],
                  stops: [0, .62],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: top + 16,
            child: _DashboardBackButton(onTap: onBack),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: top + 74,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/mobcreditlogo.svg',
                width: 183,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: _CreditBalanceCard(
              availableBalance: availableBalance,
              creditLimit: creditLimit,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsPanel extends StatelessWidget {
  const _TransactionsPanel({required this.transactions});

  final List<_MobCreditTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => const Divider(
          height: 20,
          thickness: 1,
          color: Color(0xFFE2E2E2),
        ),
        itemBuilder: (context, index) {
          return _TransactionRow(transaction: transactions[index]);
        },
      ),
    );
  }
}

class _DashboardBackButton extends StatelessWidget {
  const _DashboardBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.arrow_back,
            size: 20,
            color: MobCreditProfilePage._primary,
          ),
        ),
      ),
    );
  }
}

class _CreditBalanceCard extends StatelessWidget {
  const _CreditBalanceCard({
    required this.availableBalance,
    required this.creditLimit,
  });

  final double availableBalance;
  final double creditLimit;

  @override
  Widget build(BuildContext context) {
    final ratio = creditLimit <= 0 ? 0.0 : availableBalance / creditLimit;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Available balance',
            style: _inter(
              color: const Color(0xFF596378),
              size: 13,
              weight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currency(availableBalance),
            style: _inter(
              color: MobCreditProfilePage._primary,
              size: 28,
              weight: FontWeight.w900,
              height: 42 / 28,
            ),
          ),
          const SizedBox(height: 12),
          _CreditProgressBar(
            value: ratio.clamp(0, 1).toDouble(),
          ),
          const SizedBox(height: 10),
          Text(
            'Credit limit: ${_plainCurrency(creditLimit)} ',
            textAlign: TextAlign.center,
            style: _inter(
              color: const Color(0xFF596378),
              size: 13,
              weight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditProgressBar extends StatelessWidget {
  const _CreditProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = (constraints.maxWidth * value).clamp(0.0, 248.0);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: const Color(0xFFF0F0F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillWidth,
                  height: 12,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.00, 0.50),
                      end: Alignment(0.67, 0.50),
                      colors: [Color(0xFFBAECB5), Color(0xFF05CA8F)],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final _MobCreditTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Order ID: '),
                      TextSpan(
                        text: transaction.orderId,
                        style: const TextStyle(color: Color(0xFF0360E5)),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 14,
                    weight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _signedCurrency(transaction.amount),
                textAlign: TextAlign.right,
                style: _inter(
                  color: MobCreditProfilePage._primary,
                  size: 14,
                  weight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Debited on ${transaction.debitedAt}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _inter(
                color: const Color(0xFF596378),
                size: 11,
                weight: FontWeight.w400,
                height: 16 / 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobCreditTransaction {
  const _MobCreditTransaction({
    required this.orderId,
    required this.amount,
    required this.debitedAt,
  });

  final String orderId;
  final double amount;
  final String debitedAt;
}

class MobCreditHero extends StatelessWidget {
  const MobCreditHero({
    super.key,
    this.onBack,
    this.showBackButton = true,
  });

  final VoidCallback? onBack;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final logoTop = top + (showBackButton ? 44 : 23);
    final titleTop = top + (showBackButton ? 96 : 83);
    return SizedBox(
      height: 448,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/mobcreditbg.svg',
                fit: BoxFit.fill,
              ),
            ),
            if (showBackButton)
              Positioned(
                left: 16,
                top: top + 10,
                child: Material(
                  color: Colors.white.withValues(alpha: .12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child:
                          Icon(Icons.arrow_back, color: Colors.white, size: 19),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 25,
              top: logoTop,
              child: SvgPicture.asset(
                'assets/images/mobcredwithtick.svg',
                width: 146,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 16,
              top: titleTop,
              child: SvgPicture.asset(
                'assets/images/paylater.svg',
                width: 156,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 16,
              top: top + 196,
              child: const _HeroFeature(
                icon: 'assets/images/uptoo25lakh.svg',
                label: 'Upto 25 lakhs',
              ),
            ),
            Positioned(
              left: 16,
              top: top + 236,
              child: const _HeroFeature(
                icon: 'assets/images/collateral.svg',
                label: 'No collateral',
              ),
            ),
            Positioned(
              left: 16,
              top: top + 276,
              child: const _HeroFeature(
                icon: 'assets/images/replayment.svg',
                label: 'Upto 90 days repayment',
              ),
            ),
            Positioned(
              right: -1,
              bottom: 0,
              child: Image.asset(
                'assets/images/mobcreditarchitect.webp',
                width: 158,
                height: 250,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Positioned(
              left: 16,
              bottom: 26,
              child: Row(
                children: [
                  Text(
                    'Powered by',
                    style: _inter(
                      color: Colors.white.withValues(alpha: .6),
                      size: 12,
                      weight: FontWeight.w400,
                      height: 18 / 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    'assets/images/muthoot.svg',
                    width: 65,
                    height: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: 22, height: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: _inter(
            color: Colors.white,
            size: 14,
            weight: FontWeight.w500,
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}

class MobCreditSectionTitle extends StatelessWidget {
  MobCreditSectionTitle(String text, {super.key}) : span = TextSpan(text: text);
  const MobCreditSectionTitle.rich(this.span, {super.key});

  final TextSpan span;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      span,
      style: _inter(
        color: MobCreditProfilePage._primary,
        size: 16,
        weight: FontWeight.w700,
        height: 24 / 16,
      ),
    );
  }
}

class MobCreditAudiencePills extends StatelessWidget {
  const MobCreditAudiencePills({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MobCreditProfilePage._pale,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pillText('Architects'),
          _divider(),
          _pillText('Contractors'),
          _divider(),
          _pillText('Builders'),
        ],
      ),
    );
  }

  Widget _pillText(String text) {
    return Text(
      text,
      style: _inter(
        color: MobCreditProfilePage._primary,
        size: 14,
        weight: FontWeight.w500,
        height: 20 / 14,
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 2,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class MobCreditTermCard extends StatelessWidget {
  const MobCreditTermCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.height = 98,
  });

  final String icon;
  final String title;
  final String description;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 343,
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: ShapeDecoration(
        color: const Color(0xFFF8FAF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(icon, width: 32, height: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 17,
                    weight: FontWeight.w700,
                    height: 24 / 17,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 263,
                  child: Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(
                      color: const Color(0xFF0A243F),
                      size: 12,
                      weight: FontWeight.w400,
                      height: 1.50,
                    ),
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

class MobCreditHowItWorksCard extends StatelessWidget {
  const MobCreditHowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 456,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1F1F2), Color(0xFFBDE6E3)],
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          const Positioned(top: 16, child: _StepDots()),
          Positioned(
            top: 72,
            child: Text(
              'Use mobCREDIT anywhere',
              style: _inter(
                color: MobCreditProfilePage._primary,
                size: 17,
                weight: FontWeight.w700,
                height: 24 / 17,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Image.asset(
              'assets/images/mobileimg.webp',
              width: 248,
              height: 319,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          _dot('1', false),
          _line(),
          _dot('2', false),
          _line(),
          _dot('3', true),
        ],
      ),
    );
  }

  Widget _dot(String text, bool active) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? MobCreditProfilePage._primary : const Color(0xFFF1F1F2),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: _inter(
          color: active ? Colors.white : MobCreditProfilePage._muted,
          size: 12,
          weight: FontWeight.w700,
          height: 18 / 12,
        ),
      ),
    );
  }

  Widget _line() {
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class MobCreditDocumentsCard extends StatelessWidget {
  const MobCreditDocumentsCard({
    super.key,
    required this.onViewDocuments,
  });

  final VoidCallback onViewDocuments;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Stack(
        children: [
          SizedBox(
            height: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep these\ndocuments ready',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 17,
                    weight: FontWeight.w700,
                    height: 24 / 17,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onViewDocuments,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF053961),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View documents',
                      style: _inter(
                        color: const Color(0xFF053961),
                        size: 12,
                        weight: FontWeight.w600,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -16,
            bottom: -8,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/Documentsrequired.webp',
                width: 133,
                height: 113,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobCreditIndiaCard extends StatelessWidget {
  const MobCreditIndiaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: 10,
            child: SvgPicture.asset(
              'assets/images/indiamap.svg',
              width: 112,
              height: 122,
            ),
          ),
          SizedBox(
            height: 128,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use mobCREDIT\nacross India',
                    style: _inter(
                      color: MobCreditProfilePage._primary,
                      size: 17,
                      weight: FontWeight.w700,
                      height: 24 / 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'With any registered sellers',
                    style: _inter(
                      color: const Color(0xFF053961),
                      size: 12,
                      weight: FontWeight.w600,
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [MobCreditProfilePage._pale, Color(0xFFD6EDEA)],
        ),
      ),
      child: child,
    );
  }
}

class MobCreditTestimonialCard extends StatelessWidget {
  const MobCreditTestimonialCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: MobCreditProfilePage._pale,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote,
            color: Color(0xFFD9D9D9),
            size: 30,
          ),
          const SizedBox(height: 14),
          Text(
            'mobCREDIT has simplified the process, eliminating the hassle of constantly requesting credit from suppliers. Now, we focus on what matters most—building! Highly recommend it!',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: _inter(
              color: MobCreditProfilePage._muted,
              size: 12,
              weight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
          const Spacer(),
          Text(
            'Sankalp Solanki',
            style: _inter(
              color: MobCreditProfilePage._primary,
              size: 12,
              weight: FontWeight.w600,
              height: 18 / 12,
            ),
          ),
          Text(
            'Architect',
            style: _inter(
              color: MobCreditProfilePage._muted,
              size: 12,
              weight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class MobCreditSupportCard extends StatelessWidget {
  const MobCreditSupportCard({
    super.key,
    required this.onChatTap,
  });

  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [MobCreditProfilePage._pale, Color(0xFFD7F2E1)],
        ),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: 185,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get more clarity about mobCREDIT',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 16,
                    weight: FontWeight.w700,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chat with us about limit, how to apply, documents required etc',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 12,
                    weight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: onChatTap,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF37BD68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: SvgPicture.asset(
                      'assets/images/whatsapp.svg',
                      width: 18,
                      height: 18,
                    ),
                    label: Text(
                      'Chat with us',
                      style: _inter(
                        color: Colors.white,
                        size: 12,
                        weight: FontWeight.w600,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 12,
            child: IgnorePointer(
              child: SvgPicture.asset(
                'assets/images/chatwithus.svg',
                width: 118,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobCreditFaqRow extends StatelessWidget {
  const MobCreditFaqRow({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDEDEDE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Frequently asked questions',
                  style: _inter(
                    color: MobCreditProfilePage._primary,
                    size: 13,
                    weight: FontWeight.w500,
                    height: 20 / 13,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: MobCreditProfilePage._primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _rupifiDetails(Map<String, dynamic>? userDetails) {
  if (userDetails == null) return const {};
  for (final key in const [
    'rupifiDetails',
    'rupifi_details',
    'mob_credit',
    'rupifi',
    'credit',
    'credit_details',
  ]) {
    final value = userDetails[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return const {};
}

double _numValue(
  Map<String, dynamic> map,
  List<String> keys, {
  required double fallback,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '').trim());
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

String _currency(double value) {
  final formatter = NumberFormat('#,##0.##', 'en_IN');
  return '₹${formatter.format(value)}';
}

String _plainCurrency(double value) {
  final formatter = NumberFormat('0.##', 'en_IN');
  return '₹${formatter.format(value)}';
}

String _signedCurrency(double value) {
  final prefix = value < 0 ? '-' : '';
  return '$prefix${_currency(value.abs())}';
}

TextStyle _inter({
  required Color color,
  required double size,
  required FontWeight weight,
  double? height,
}) {
  return GoogleFonts.inter(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
  );
}
