import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFF090A15),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 468,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
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
                          child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF0A243F)),
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
                      style: _text(13, muted, FontWeight.w500, height: 20 / 13),
                    ),
                  ),
                  const Positioned(
                    top: 224,
                    left: 0,
                    right: 0,
                    child: Center(child: _SectionLabel('YOUR MEMBERSHIP')),
                  ),
                  Positioned(
                    top: 258,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                          width: 184,
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: .4), borderRadius: BorderRadius.circular(40)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(mobstar.membership, style: _text(14, Colors.white, FontWeight.w500)),
                            SvgPicture.asset('assets/images/goldstar.svg', width: 24, height: 23),
                          ]),
                        ),
                    ),
                  ),
                  Positioned(
                    top: 330,
                    left: 16,
                    right: 16,
                    child: Container(
                          width: 343,
                          height: 114,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: .15)),
                          ),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('mobSTAR points', style: _text(13, muted, FontWeight.w500)),
                              Row(children: [
                                const Icon(Icons.stars_rounded, color: Color(0xFFFFC928), size: 22),
                                const SizedBox(width: 7),
                                Text('$points', style: _text(28, Colors.white, FontWeight.w900, height: 42 / 28)),
                                const SizedBox(width: 9),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(16)), child: Text('₹$valueText', style: _text(13, Colors.white70, FontWeight.w500))),
                              ]),
                              Text('4 points = ₹1', style: _text(13, muted, FontWeight.w500)),
                            ])),
                            const CircleAvatar(radius: 12, backgroundColor: Color(0xFFF0F3F5), child: Icon(Icons.chevron_right, size: 20, color: Color(0xFF273A6A))),
                          ]),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const _SectionLabel('YOUR BENEFITS'),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: _BenefitCard(asset: 'assets/images/Xpoints.svg', title: '1X points', subtitle: 'on every purchase')),
                SizedBox(width: 15),
                Expanded(child: _BenefitCard(asset: 'assets/images/freeimg.svg', title: 'FREE', subtitle: 'deliveries')),
              ]),
            ),
            const SizedBox(height: 40),
            const _SectionLabel('LEVEL UPGRADE'),
            const SizedBox(height: 16),
            const _LevelCard(),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('View all levels', style: _text(14, muted, FontWeight.w500)), const SizedBox(width: 5), const Icon(Icons.chevron_right, color: muted, size: 18)]),
            const SizedBox(height: 40),
            Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 2, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF4B4B55), style: BorderStyle.solid)))),
            const SizedBox(height: 38),
            const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 16), child: Text('Frequently asked questions', style: TextStyle(fontFamily: 'Inter', color: gold, fontSize: 12, fontWeight: FontWeight.w600)))),
            const SizedBox(height: 13),
            for (final question in const ['What is mobSTAR loyalty program?', 'When do mobSTAR points expire?', 'How do I redeem my mobSTAR points?', 'View all FAQ’s'])
              _FaqRow(question),
            const SizedBox(height: 172),
          ],
        ),
      ),
    );
  }

  static TextStyle _text(double size, Color color, FontWeight weight, {double? height}) => GoogleFonts.inter(color: color, fontSize: size, fontWeight: weight, height: height);
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
  const _SectionLabel(this.text); final String text;
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/images/leftdot.svg', width: 43, height: 6), const SizedBox(width: 10), Text(text, style: GoogleFonts.inter(color: const Color(0xFFD4A914), fontSize: 12, fontWeight: FontWeight.w600, height: 18 / 12)), const SizedBox(width: 10), SvgPicture.asset('assets/images/rightdot.svg', width: 42, height: 6)]);
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.asset, required this.title, required this.subtitle}); final String asset; final String title; final String subtitle;
  @override Widget build(BuildContext context) => Container(height: 129, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .1))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.asset(asset, width: 48, height: 48), const SizedBox(height: 12), Text(title, style: GoogleFonts.inter(color: _MobstarView.gold, fontSize: 16, fontWeight: FontWeight.w700, height: 20 / 16)), Text(subtitle, style: GoogleFonts.inter(color: _MobstarView.muted, fontSize: 14, height: 20 / 14))]));
}

class _LevelCard extends StatelessWidget {
  const _LevelCard();
  @override Widget build(BuildContext context) => Container(width: 343, height: 130, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .1))), child: Column(children: [Padding(padding: const EdgeInsets.fromLTRB(15, 14, 15, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bronze', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)), Text('Silver', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))])), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [CircleAvatar(radius: 20, backgroundColor: const Color(0xFF161722), child: SvgPicture.asset('assets/images/goldstar.svg', width: 24, height: 23)), Expanded(child: Container(height: 8, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFC57B2C), Color(0xFFE2E2E2), Color(0xFF41414B)]), borderRadius: BorderRadius.circular(8)))), CircleAvatar(radius: 20, backgroundColor: const Color(0xFF161722), child: SvgPicture.asset('assets/images/silverstar.svg', width: 24, height: 24))])), const Spacer(), Container(height: 32, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))), child: Text('Shop for ₹250,000 before 16 Oct to reach Silver level', style: GoogleFonts.inter(color: _MobstarView.muted, fontSize: 11)))]));
}

class _FaqRow extends StatelessWidget {
  const _FaqRow(this.text); final String text;
  @override Widget build(BuildContext context) => Container(height: 48, margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .1))), child: Row(children: [Expanded(child: Text(text, style: GoogleFonts.inter(color: _MobstarView.muted, fontSize: 13, fontWeight: FontWeight.w500))), const Icon(Icons.chevron_right, color: _MobstarView.muted, size: 20)]));
}
