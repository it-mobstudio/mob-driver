import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/faq_entry.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_faq_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_points_page.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/faq_accordion_tile.dart';

class MobstarPage extends StatelessWidget {
  const MobstarPage({super.key});

  static const routeName = 'Mobstar';
  static const routePath = '/mobstar';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(MobstarLoadRequested()),
      child: const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Color(0xFF090A15),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF090A15),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: _MobstarView(),
      ),
    );
  }
}

class _MobstarView extends StatefulWidget {
  const _MobstarView();

  static const gold = Color(0xFFD99A3E);
  static const muted = Color(0xFFBEBEC2);

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

  @override
  State<_MobstarView> createState() => _MobstarViewState();
}

class _MobstarViewState extends State<_MobstarView> {
  int? _expandedFaqIndex;

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
    final rewardText = '${_MobstarView._trimNumber(mobstar.percentage)}X points';

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
                          decoration: ShapeDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.topRight,
                              colors: [Colors.black, Color(0xFF505AB1)],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: SvgPicture.asset(
                            'assets/images/Starbgmobstar.svg',
                            // width: 170,
                            // height: 170,
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
                          top: 180,
                          left: 0,
                          right: 0,
                          child: Text(
                            'Get points on every order you place!',
                            textAlign: TextAlign.center,
                            style: _MobstarView._text(
                                13, _MobstarView.muted, FontWeight.w500,
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
                                        style: _MobstarView._text(
                                            14, Colors.white, FontWeight.w500)),
                                    SvgPicture.asset(
                                        _MobstarView._levelAsset(
                                            mobstar.membership),
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
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () =>
                                  context.push(MobstarPointsPage.routePath),
                              child: Container(
                                height: 114,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: ShapeDecoration(
                                  color: Colors.white.withValues(alpha: .05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
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
                                                style: _MobstarView._text(
                                                    13,
                                                    _MobstarView.muted,
                                                    FontWeight.w500)),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              height: 42,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/images/points.svg',
                                                    width: 20,
                                                    height: 20,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Transform.translate(
                                                    offset: const Offset(0, 2),
                                                    child: Text(
                                                      '$points',
                                                      style: _MobstarView._text(
                                                        28,
                                                        Colors.white,
                                                        FontWeight.w900,
                                                        height: 1,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Transform.translate(
                                                    offset: const Offset(0, 1),
                                                    child: Container(
                                                      height: 24,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10),
                                                      decoration:
                                                          ShapeDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: .2),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Text(
                                                        '₹$valueText',
                                                        style:
                                                            _MobstarView._text(
                                                          13,
                                                          Colors.white70,
                                                          FontWeight.w500,
                                                          height: 20 / 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('4 points = ₹1',
                                                style: _MobstarView._text(
                                                    13,
                                                    _MobstarView.muted,
                                                    FontWeight.w500)),
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
                              title: rewardText,
                              subtitle: 'on every purchase')),
                      const SizedBox(width: 15),
                      const Expanded(
                          child: _BenefitCard(
                              asset: 'assets/images/freeimg.svg',
                              title: 'FREE',
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
                        onTap: () =>
                            _MobstarView._showAllLevelsSheet(context, mobstar),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('View all levels',
                                style: _MobstarView._text(
                                    14, _MobstarView.muted, FontWeight.w500)),
                            const SizedBox(width: 5),
                            const Icon(Icons.chevron_right,
                                color: _MobstarView.muted, size: 18)
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _DottedDivider(),
                  ),
                  const SizedBox(height: 38),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('Frequently asked questions',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: _MobstarView.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 18 / 12)))),
                  const SizedBox(height: 13),
                  for (final indexedEntry in _faqEntries.indexed)
                    FaqAccordionTile(
                      indexedEntry.$2,
                      expanded: _expandedFaqIndex == indexedEntry.$1,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedFaqIndex =
                              expanded ? indexedEntry.$1 : null;
                        });
                      },
                    ),
                  _FaqRow(
                    'View all FAQ’s',
                    onTap: () => context.push(MobstarFaqPage.routePath),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
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
          borderRadius: BorderRadius.circular(16)),
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

  @override
  Widget build(BuildContext context) {
    final progress = mobstar.purchaseLimit <= 0
        ? 0.0
        : (mobstar.points / mobstar.purchaseLimit).clamp(0.0, 1.0);
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
                    child: SizedBox(
                      height: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: Color(0xFF41414B)),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress,
                                heightFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient:
                                        _levelGradient(mobstar.membership),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: Color(0xFF131313),
                        shape: OvalBorder(
                          side: BorderSide(
                            color: Color(0xFF53545B),
                          ),
                        ),
                      ),
                      child: SvgPicture.asset(
                        _MobstarView._levelAsset(mobstar.membership),
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const ShapeDecoration(
                        color: Color(0xFF131313),
                        shape: OvalBorder(
                          side: BorderSide(
                            color: Color(0xFF53545B),
                          ),
                        ),
                      ),
                      child: SvgPicture.asset(
                        _MobstarView._levelAsset(nextMembership),
                        width: 24,
                        height: 24,
                      ),
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

  static LinearGradient _levelGradient(String membership) {
    final level = membership.toLowerCase();

    if (level.contains('diamond') || level.contains('dimond')) {
      return const LinearGradient(
        begin: Alignment(1, .5),
        end: Alignment(.1, .5),
        colors: [Color(0xFF59D9FC), Color(0xFFC0C0BF)],
      );
    }
    if (level.contains('platinum')) {
      return const LinearGradient(
        begin: Alignment(1, .5),
        end: Alignment(.1, .5),
        colors: [Color(0xFF59D9FC), Color(0xFFC0C0BF)],
      );
    }
    if (level.contains('gold')) {
      return const LinearGradient(
        begin: Alignment(.1, .5),
        end: Alignment(1, .5),
        colors: [Color(0xFFE9B305), Color(0xFFC0C0BF)],
      );
    }
    if (level.contains('silver')) {
      return const LinearGradient(
        begin: Alignment(1, .5),
        end: Alignment(.1, .5),
        colors: [Color(0xFFE9B305), Color(0xFFC0C0BF)],
      );
    }
    return const LinearGradient(
      begin: Alignment(.1, .5),
      end: Alignment(1, .5),
      colors: [Color(0xFFAD6F33), Color(0xFFC0C0BF)],
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
      asset: 'assets/images/mobStar/bronze.svg',
    ),
    _LevelInfo(
      name: 'Silver',
      points: '1.25 x',
      spend: '₹250,000',
      asset: 'assets/images/mobStar/silver.svg',
    ),
    _LevelInfo(
      name: 'Gold',
      points: '1.50 x',
      spend: '₹1,200,000',
      asset: 'assets/images/mobStar/gold.svg',
    ),
    _LevelInfo(
      name: 'Platinum',
      points: '1.75 x',
      spend: '₹2,500,000',
      asset: 'assets/images/mobStar/platinum.svg',
    ),
    _LevelInfo(
      name: 'Diamond',
      points: '2.0 x',
      spend: '₹4,857,143',
      asset: 'assets/images/mobStar/dimond.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .62,
      widthFactor: 1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -61,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/images/close.svg',
                width: 44,
                height: 44,
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F0),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text('LEVEL', style: _levelHeaderStyle),
                            ),
                            SizedBox(
                              width: 108,
                              child: Text(
                                'POINTS',
                                textAlign: TextAlign.center,
                                style: _levelHeaderStyle,
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 86,
                                  child: Text(
                                    'MIN SPEND IN A YEAR',
                                    textAlign: TextAlign.right,
                                    style: _levelHeaderStyle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _levels.length,
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
          ),
        ],
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
    required this.asset,
  });

  final String name;
  final String points;
  final String spend;
  final String asset;
}

class _LevelSheetRow extends StatelessWidget {
  const _LevelSheetRow({
    required this.level,
    required this.current,
  });

  final _LevelInfo level;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE2E2E2),
            ),
          ),
          if (current)
            const Positioned(
              left: 0,
              top: 0,
              child: _CurrentLevelBadge(),
            ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _LevelName(level: level),
                  ),
                  SizedBox(
                    width: 108,
                    child: Text(
                      level.points,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  Expanded(
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
          ),
        ],
      ),
    );
  }
}

class _CurrentLevelBadge extends StatelessWidget {
  const _CurrentLevelBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 20 / 13,
        ),
      ),
    );
  }
}

class _LevelName extends StatelessWidget {
  const _LevelName({required this.level});

  final _LevelInfo level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          level.asset,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            level.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

const _faqEntries = <FaqEntry>[
  FaqEntry(
    'What is mobSTAR loyalty program?',
    "The mobSTAR Loyalty Program is Mad Over Buildings' exclusive loyalty "
        'program for material purchases. Earn mobSTAR points every time you '
        'buy directly through MOB and unlock more rewards & benefits as you '
        'level up. There are five levels: Bronze, Silver, Gold, Platinum, '
        'and Diamond.',
  ),
  FaqEntry(
    'When do mobSTAR points expire?',
    'mobSTAR points are valid for one year from the date they are credited '
        'to your account. Any unused points will expire after this period, '
        'so be sure to redeem them in time to enjoy your rewards.',
  ),
  FaqEntry(
    'How do I redeem my mobSTAR points?',
    'You can redeem your points during checkout when placing an order. '
        'Simply select the points option. If your points cover the total '
        'amount, no additional payment is needed. If not, you can pay the '
        'remaining balance using any other available payment method.',
  ),
];

class _FaqRow extends StatelessWidget {
  const _FaqRow(this.text, {this.onTap});
  final String text;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(
                child: Text(text,
                    style: GoogleFonts.inter(
                        color: _MobstarView.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, color: _MobstarView.muted, size: 20)
          ])));
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dotWidth = 2.0;
          const gap = 3.0;
          final count = (constraints.maxWidth / (dotWidth + gap)).floor();

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => const SizedBox(
                width: dotWidth,
                height: 1,
                child: ColoredBox(color: Color(0xFF4B4B55)),
              ),
            ),
          );
        },
      ),
    );
  }
}
