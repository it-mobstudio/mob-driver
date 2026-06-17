import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';

import 'rfq_details_page.dart';

class RfqPage extends StatefulWidget {
  const RfqPage({super.key});

  static const routeName = 'RfqListPage';
  static const routePath = '/rfqs';

  @override
  State<RfqPage> createState() => _RfqPageState();
}

class _RfqPageState extends State<RfqPage> {
  late final RfqBloc _rfqBloc;

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>()..add(RfqListRequested());
  }

  @override
  void dispose() {
    _rfqBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: const Scaffold(
        backgroundColor: Color(0xFFF0F0F0),
        body: _RfqBody(),
      ),
    );
  }
}

class _RfqBody extends StatelessWidget {
  const _RfqBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RfqHeader(),
        Expanded(
          child: BlocBuilder<RfqBloc, RfqState>(
            builder: (context, state) {
              return switch (state) {
                RfqInitial() || RfqLoading() => const ColoredBox(
                    color: Color(0xFFF0F0F0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                RfqError(:final message) => ColoredBox(
                    color: const Color(0xFFF0F0F0),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6F7788),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                RfqListLoaded(:final rfqs) when rfqs.isEmpty => ColoredBox(
                    color: const Color(0xFFF0F0F0),
                    child: Center(
                      child: Text(
                        "No RFQ's yet.",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6F7788),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                RfqListLoaded(:final rfqs) => ColoredBox(
                    color: const Color(0xFFF0F0F0),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: rfqs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RfqCard(item: rfqs[index]),
                        );
                      },
                    ),
                  ),
                _ => const SizedBox.shrink(),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _RfqHeader extends StatelessWidget {
  const _RfqHeader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F0F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 116,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF0A243F),
                        size: 22,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                  ),
                  Text(
                    'Quotation request',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A243F),
                      height: 24 / 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/search'),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.search,
                      size: 22,
                      color: Color(0xFF0A243F),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Search for quotation',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF59677C),
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune, size: 14),
              label: Text(
                'Filters',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 18 / 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0A243F),
                backgroundColor: Colors.white,
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(color: Color(0xFFD8DEE8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RfqDisplayStatus {
  requested,
  quoteGenerated,
  quoteAccepted,
  convertedToOrder,
}

extension _RfqDisplayStatusX on _RfqDisplayStatus {
  String get label => switch (this) {
        _RfqDisplayStatus.requested => 'Requested',
        _RfqDisplayStatus.quoteGenerated => 'Quote generated',
        _RfqDisplayStatus.quoteAccepted => 'Quote accepted',
        _RfqDisplayStatus.convertedToOrder => 'Converted to order',
      };

  Color get iconBackgroundColor => switch (this) {
        _RfqDisplayStatus.requested => const Color(0xFFF2F3F5),
        _RfqDisplayStatus.quoteGenerated => const Color(0xFFD2FFE5),
        _RfqDisplayStatus.quoteAccepted => const Color(0xFFD2FFE5),
        _RfqDisplayStatus.convertedToOrder => const Color(0xFFD2FFE5),
      };

  String get assetPath => switch (this) {
        _RfqDisplayStatus.requested => 'assets/images/requested.svg',
        _RfqDisplayStatus.quoteGenerated => 'assets/images/RFQgenerated.svg',
        _RfqDisplayStatus.quoteAccepted => 'assets/images/Delivered.svg',
        _RfqDisplayStatus.convertedToOrder =>
          'assets/images/RFQconvertedtoorder.svg',
      };
}

_RfqDisplayStatus _parseStatus(String raw) {
  final status = raw.toLowerCase().replaceAll(' ', '_');
  if (status.contains('converted') || status.contains('order')) {
    return _RfqDisplayStatus.convertedToOrder;
  }
  if (status.contains('accept') || status.contains('approved')) {
    return _RfqDisplayStatus.quoteAccepted;
  }
  if (status.contains('quote') ||
      status.contains('quotation') ||
      status.contains('generated')) {
    return _RfqDisplayStatus.quoteGenerated;
  }
  return _RfqDisplayStatus.requested;
}

class _RfqCard extends StatelessWidget {
  const _RfqCard({required this.item});

  final RfqEntity item;

  @override
  Widget build(BuildContext context) {
    final displayStatus = _parseStatus(item.status);
    final hasProjectTag = displayStatus == _RfqDisplayStatus.quoteGenerated ||
        displayStatus == _RfqDisplayStatus.quoteAccepted;
    final showQuoteAmount = displayStatus == _RfqDisplayStatus.quoteAccepted;
    final showAction = displayStatus != _RfqDisplayStatus.requested;
    final quoteAmount = item.totalAmount > 0 ? item.totalAmount : 10800;

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StatusIcon(status: displayStatus),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayStatus.label,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A243F),
                              height: 24 / 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _displayDate(item.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7B8496),
                              height: 20 / 14,
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
          const Divider(height: 1, thickness: 1, color: Color(0xFFE9EAEE)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(
                  label: 'RFQ ID:',
                  value: item.id.isNotEmpty ? item.id : 'MOB9867855HJS6',
                ),
                const SizedBox(height: 6),
                const _InfoLine(
                  label: 'Pincode:',
                  value: '560095, Koramangala, Bengaluru',
                ),
                if (hasProjectTag) ...[
                  const SizedBox(height: 10),
                  const _ProjectChip(project: 'Hotel California'),
                ],
              ],
            ),
          ),
          if (showQuoteAmount) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE9EAEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quote 1',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7B8496),
                              height: 18 / 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\u20B9 ${quoteAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0A243F),
                              height: 24 / 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        RfqDetailsPage.routePath,
                        extra: item.id,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0360E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Confirm & pay',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 18 / 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (showAction) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE9EAEE)),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  if (displayStatus == _RfqDisplayStatus.convertedToOrder) {
                    return;
                  }
                  context.push(
                    RfqDetailsPage.routePath,
                    extra: item.id,
                  );
                },
                child: Text(
                  displayStatus == _RfqDisplayStatus.convertedToOrder
                      ? 'View order'
                      : 'View quotation',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0360E5),
                    height: 18 / 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final opensDetails = displayStatus == _RfqDisplayStatus.requested ||
        displayStatus == _RfqDisplayStatus.quoteGenerated ||
        displayStatus == _RfqDisplayStatus.quoteAccepted;

    if (!opensDetails) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(
          RfqDetailsPage.routePath,
          extra: item.id,
        ),
        child: card,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final _RfqDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: status.iconBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        status.assetPath,
        width: 28,
        height: 28,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6F7788),
          height: 18 / 12,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: Color(0xFF0A243F),
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.project});

  final String project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFDE17),
            Color(0xFFFFF2A3),
            Color(0xFFFFFEF4),
          ],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Project: $project',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0A243F),
          height: 18 / 12,
        ),
      ),
    );
  }
}

String _displayDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '16 May, 10:25 am';
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return trimmed;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'pm' : 'am';
  return '${parsed.day} ${months[parsed.month - 1]}, $hour12:$minute $period';
}
