import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/data/mobstar_faq_data.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/faq_accordion_tile.dart';

/// Full mobSTAR FAQ list, reached from the "View all FAQ's" row on the
/// mobSTAR page — mirrors just the "Frequently asked questions" section of
/// the web mobSTAR page, nothing else from it.
class MobstarFaqPage extends StatefulWidget {
  const MobstarFaqPage({super.key});

  static const routeName = 'MobstarFaq';
  static const routePath = '/mobstar/faq';

  @override
  State<MobstarFaqPage> createState() => _MobstarFaqPageState();
}

class _MobstarFaqPageState extends State<MobstarFaqPage> {
  int? _expandedFaqIndex;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF090A15),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF090A15),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF090A15),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Material(
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
                    const SizedBox(width: 12),
                    Text(
                      'Frequently asked questions',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                  children: [
                    for (final indexedEntry in mobstarFaqEntries.indexed)
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
