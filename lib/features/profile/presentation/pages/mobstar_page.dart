import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_points_page.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class MobstarPage extends StatelessWidget {
  const MobstarPage({super.key});

  static const routeName = 'Mobstar';
  static const routePath = '/mobstar';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(MobstarLoadRequested()),
      child: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: _MobstarView(),
      ),
    );
  }
}

class _MobstarView extends StatelessWidget {
  const _MobstarView();

  static const gold = Color(0xFFD99A3E);
  static const muted = Color(0xFFBEBEC2);

  @override
  Widget build(BuildContext context) {
    final mobstar = context.select<ProfileBloc, MobstarEntity>((bloc) {
      final state = bloc.state;
      return state is MobstarLoaded ? state.mobstar : MobstarEntity.empty;
    });
    final points = mobstar.points;
    final valueText = mobstar.actualMoney % 1 == 0
        ? mobstar.actualMoney.toStringAsFixed(0)
        : mobstar.actualMoney.toStringAsFixed(2);
    final rewardPercent = mobstar.percentage * 100;
    final rewardText =
        rewardPercent == 0 ? '0%' : '${_trimNumber(rewardPercent)}%';

    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 468,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF000000), Color(0xFF505AB1)],
                              stops: [.12, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 66,
                          left: 16,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(
                              side: BorderSide(color: Color(0xFFD0D4DC)),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.pop(),
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Center(child: AppBackIcon()),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 128,
                          left: 0,
                          right: 0,
                          child: Center(child: _MobstarLogo()),
                        ),
                        Positioned(
                          top: 172,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Get points on every order you place!',
                            textAlign: TextAlign.center,
                            style: _text(13, muted, FontWeight.w500,
                                height: 20 / 13),
                          ),
                        ),
                        const Positioned(
                          top: 224,
                          left: 0,
                          right: 0,
                          child:
                              Center(child: _SectionLabel('YOUR MEMBERSHIP')),
                        ),
                        Positioned(
                          top: 258,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 184,
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .4),
                                  borderRadius: BorderRadius.circular(40)),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(mobstar.membership,
                                        style: _text(
                                            14, Colors.white, FontWeight.w500)),
                                    SvgPicture.asset(
                                        _levelAsset(mobstar.membership),
                                        width: 24,
                                        height: 23),
                                  ]),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 330,
                          left: 16,
                          right: 16,
                          child: Material(
                            color: Colors.white.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  context.push(MobstarPointsPage.routePath),
                              child: Container(
                                height: 114,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .15)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                        Text('mobSTAR points',
                                            style: _text(
                                                13, muted, FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.stars_rounded,
                                                  color: Color(0xFFFFC928),
                                                  size: 22),
                                              const SizedBox(width: 7),
                                              Text('$points',
                                                  style: _text(28, Colors.white,
                                                      FontWeight.w900,
                                                      height: 42 / 28)),
                                              const SizedBox(width: 9),
                                              Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: .2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16)),
                                                  child: Text('₹$valueText',
                                                      style: _text(
                                                          13,
                                                          Colors.white70,
                                                          FontWeight.w500))),
                                            ]),
                                        const SizedBox(height: 4),
                                        Text('4 points = ₹1',
                                            style: _text(
                                                13, muted, FontWeight.w500)),
                                      ])),
                                  const Center(
                                    child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Color(0xFFF0F3F5),
                                        child: Icon(Icons.chevron_right,
                                            size: 20,
                                            color: Color(0xFF273A6A))),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const _SectionLabel('YOUR BENEFITS'),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Expanded(
                          child: _BenefitCard(
                              asset: 'assets/images/Xpoints.svg',
                              title: '$rewardText rewards',
                              subtitle: 'on every purchase')),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _BenefitCard(
                              asset: 'assets/images/freeimg.svg',
                              title: '${mobstar.freeDelivery} FREE',
                              subtitle: 'deliveries')),
                    ]),
                  ),
                  const SizedBox(height: 40),
                  const _SectionLabel('LEVEL UPGRADE'),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _LevelCard(mobstar: mobstar),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showAllLevelsSheet(context, mobstar),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('View all levels',
                                style: _text(14, muted, FontWeight.w500)),
                            const SizedBox(width: 5),
                            const Icon(Icons.chevron_right,
                                color: muted, size: 18)
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      height: 2,
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFF4B4B55),
                                  style: BorderStyle.solid)))),
                  const SizedBox(height: 38),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('Frequently asked questions',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)))),
                  const SizedBox(height: 13),
                  for (final question in const [
                    'What is mobSTAR loyalty program?',
                    'When do mobSTAR points expire?',
                    'How do I redeem my mobSTAR points?',
                    'View all FAQ’s'
                  ])
                    _FaqRow(question),
                  const SizedBox(height: 172),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static TextStyle _text(double size, Color color, FontWeight weight,
          {double? height}) =>
      GoogleFonts.inter(
          color: color, fontSize: size, fontWeight: weight, height: height);

  static Future<void> _showAllLevelsSheet(
    BuildContext context,
    MobstarEntity mobstar,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .6),
      builder: (context) => _AllLevelsSheet(mobstar: mobstar),
    );
  }

  static String _trimNumber(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  static String _levelAsset(String level) {
    final lower = level.toLowerCase();
    if (lower.contains('diamond') || lower.contains('dimond')) {
      return 'assets/images/mobStar/dimond.svg';
    }
    if (lower.contains('platinum')) return 'assets/images/mobStar/platinum.svg';
    if (lower.contains('gold')) return 'assets/images/mobStar/gold.svg';
    if (lower.contains('silver')) return 'assets/images/mobStar/silver.svg';
    return 'assets/images/mobStar/bronze.svg';
  }
}

class _MobstarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/images/mobstar.svg',
        width: 184,
        height: 32,
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SvgPicture.asset('assets/images/leftdot.svg', width: 43, height: 6),
        const SizedBox(width: 10),
        Text(text,
            style: GoogleFonts.inter(
                color: const Color(0xFFD4A914),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12)),
        const SizedBox(width: 10),
        SvgPicture.asset('assets/images/rightdot.svg', width: 42, height: 6)
      ]);
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard(
      {required this.asset, required this.title, required this.subtitle});
  final String asset;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
      height: 129,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .1))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SvgPicture.asset(asset, width: 48, height: 48),
        const SizedBox(height: 12),
        Text(title,
            style: GoogleFonts.inter(
                color: _MobstarView.gold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 20 / 16)),
        Text(subtitle,
            style: GoogleFonts.inter(
                color: _MobstarView.muted, fontSize: 14, height: 20 / 14))
      ]));
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.mobstar});

  final MobstarEntity mobstar;

  // No API field gives progress-toward-next-level directly, and
  // purchase_limit is just the flat target — not something to subtract or
  // divide against other fields ourselves.
  double get progress => 0;

  @override
  Widget build(BuildContext context) {
    final remainingText =
        mobstar.purchaseLimit.round().toString().replaceAllMapped(
              RegExp(r'\B(?=(\d{3})+(?!\d))'),
              (_) => ',',
            );
    final nextMembership = mobstar.nextMembership;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(mobstar.membership,
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Text(nextMembership,
                    style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 34,
                    right: 34,
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF41414B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOut,
                            width: constraints.maxWidth * progress,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF996E37), Color(0xFFFFB75C)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF161722),
                      child: SvgPicture.asset(
                          _MobstarView._levelAsset(mobstar.membership),
                          width: 24,
                          height: 23),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF161722),
                      child: SvgPicture.asset(
                          _MobstarView._levelAsset(nextMembership),
                          width: 24,
                          height: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'Shop for ₹$remainingText to reach $nextMembership level',
              style: GoogleFonts.inter(color: _MobstarView.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllLevelsSheet extends StatelessWidget {
  const _AllLevelsSheet({required this.mobstar});

  final MobstarEntity mobstar;

  static const _levels = [
    _LevelInfo(
      name: 'Bronze',
      points: '1.0 x',
      spend: 'Free',
      color: Color(0xFFC9792C),
      asset: 'assets/images/mobStar/bronze.svg',
    ),
    _LevelInfo(
      name: 'Silver',
      points: '1.25 x',
      spend: '₹250,000',
      color: Color(0xFFC9C9C9),
      asset: 'assets/images/mobStar/silver.svg',
    ),
    _LevelInfo(
      name: 'Gold',
      points: '1.50 x',
      spend: '₹1,200,000',
      color: Color(0xFFFFC400),
      asset: 'assets/images/mobStar/gold.svg',
    ),
    _LevelInfo(
      name: 'Platinum',
      points: '1.75 x',
      spend: '₹2,500,000',
      color: Color(0xFF9F9F9F),
      asset: 'assets/images/mobStar/platinum.svg',
    ),
    _LevelInfo(
      name: 'Diamond',
      points: '2.0 x',
      spend: '₹4,857,143',
      color: Color(0xFF22C7F2),
      asset: 'assets/images/mobStar/dimond.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .62,
      widthFactor: 1,
      child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ColoredBox(
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.only(left: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 44,
                            child: Text('LEVEL', style: _levelHeaderStyle),
                          ),
                          Expanded(
                            flex: 28,
                            child: Text('POINTS', style: _levelHeaderStyle),
                          ),
                          Expanded(
                            flex: 36,
                            child: Text(
                              'MIN SPEND IN\nA YEAR',
                              textAlign: TextAlign.right,
                              style: _levelHeaderStyle,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Color(0xFF0A243F),
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _levels.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE2E2E2),
                        ),
                        itemBuilder: (context, index) => _LevelSheetRow(
                          level: _levels[index],
                          current: _isCurrentLevel(_levels[index].name),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  static TextStyle get _levelHeaderStyle => GoogleFonts.inter(
        color: const Color(0xFF596378),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 18 / 12,
      );

  bool _isCurrentLevel(String name) =>
      mobstar.membership.toLowerCase().contains(name.toLowerCase());
}

class _LevelInfo {
  const _LevelInfo({
    required this.name,
    required this.points,
    required this.spend,
    required this.color,
    required this.asset,
  });

  final String name;
  final String points;
  final String spend;
  final Color color;
  final String asset;
}

class _LevelSheetRow extends StatelessWidget {
  const _LevelSheetRow({required this.level, required this.current});

  final _LevelInfo level;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (current) const _CurrentLevelBadge(),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _LevelName(level: level, current: current),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 28,
              child: Text(
                level.points,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
            Expanded(
              flex: 36,
              child: Text(
                level.spend,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLevelBadge extends StatelessWidget {
  const _CurrentLevelBadge();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-16, 0),
      child: Container(
        height: 24,
        padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF313A78), Color(0xFF424B97)],
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(
          'You are here',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 18 / 12,
          ),
        ),
      ),
    );
  }
}

class _LevelName extends StatelessWidget {
  const _LevelName({required this.level, required this.current});

  final _LevelInfo level;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          level.asset,
          width: 28,
          height: 28,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            level.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color:
                  current ? const Color(0xFF0360E5) : const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .1))),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    color: _MobstarView.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
        const Icon(Icons.chevron_right, color: _MobstarView.muted, size: 20)
      ]));
}
