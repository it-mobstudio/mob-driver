import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/show_accept_quote_sheet.dart';

class RfqDetailsPage extends StatefulWidget {
  const RfqDetailsPage({super.key, this.rfqId});

  static const routeName = 'RfqDetailsPage';
  static const routePath = '/rfq-details';

  final String? rfqId;

  @override
  State<RfqDetailsPage> createState() => _RfqDetailsPageState();
}

class _RfqDetailsPageState extends State<RfqDetailsPage> {
  late final RfqBloc _rfqBloc;

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>();
    final id = widget.rfqId?.trim() ?? '';
    if (id.isNotEmpty) {
      _rfqBloc.add(RfqDetailRequested(id));
    }
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: Column(
          children: [
            const _DetailsHeader(),
            Expanded(
              child: BlocBuilder<RfqBloc, RfqState>(
                builder: (context, state) {
                  if ((widget.rfqId ?? '').trim().isEmpty) {
                    return const _DetailsError(message: 'RFQ id not found.');
                  }
                  return switch (state) {
                    RfqInitial() || RfqLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    RfqError(:final message) => _DetailsError(message: message),
                    RfqDetailLoaded(:final rfq) => switch (
                          _parseDetailStatus(rfq.status)) {
                        _RfqDetailStatus.convertedToOrder =>
                          _ConvertedToOrderDetailsBody(rfq: rfq),
                        _RfqDetailStatus.quoteAccepted =>
                          _QuoteAcceptedDetailsBody(rfq: rfq),
                        _RfqDetailStatus.quoteGenerated =>
                          _QuoteGeneratedDetailsBody(rfq: rfq),
                        _ => _RequestedDetailsBody(rfq: rfq),
                      },
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Quotation details',
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
    );
  }
}

class _RequestedDetailsBody extends StatelessWidget {
  const _RequestedDetailsBody({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    final itemCount = rfq.items.isEmpty ? 2 : rfq.items.length;
    final total = rfq.totalAmount > 0 ? rfq.totalAmount : 10800.0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfq.id.isNotEmpty ? rfq.id : 'RFQ_B9867855HJS6',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                _MetaLine(date: _displayDate(rfq.createdAt)),
                const SizedBox(height: 18),
                const _RequestedProgressCard(),
                const SizedBox(height: 22),
                Text(
                  'MOB Quotes',
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A243F),
                    height: 30 / 21,
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/Quotependingillustration.svg',
                    width: 192,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    'Our team is working on your final quotation',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A243F),
                      height: 20 / 15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0A243F),
                        height: 18 / 12,
                      ),
                      children: const [
                        TextSpan(
                            text: 'We should reach out within 5 - 30 mins\n'),
                        TextSpan(text: 'or Call '),
                        TextSpan(
                          text: '+918660423608',
                          style: TextStyle(color: Color(0xFF0360E5)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                _AiQuoteCard(itemCount: itemCount, total: total),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: _UploadsCard(rfq: rfq),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: _HelpCard(),
        ),
      ],
    );
  }
}

class _QuoteGeneratedDetailsBody extends StatelessWidget {
  const _QuoteGeneratedDetailsBody({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    final itemCount = rfq.items.isEmpty ? 2 : rfq.items.length;
    final total = rfq.totalAmount > 0 ? rfq.totalAmount : 10800.0;
    final date = _displayDate(rfq.createdAt);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfq.id.isNotEmpty ? rfq.id : 'RFQ_B9867855HJS6',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                _MetaLine(date: date),
                const SizedBox(height: 16),
                const _QuoteGeneratedProgressCard(),
                const SizedBox(height: 20),
                Text(
                  'MOB Quotes',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 30 / 20,
                  ),
                ),
                const SizedBox(height: 16),
                _QuoteCard(
                  title: 'Quote 2',
                  date: date,
                  itemCount: itemCount,
                  total: total,
                  showAccept: true,
                ),
                const SizedBox(height: 16),
                _QuoteCard(
                  title: 'Quote 1',
                  date: date,
                  itemCount: itemCount,
                  total: total,
                  aiGenerated: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: _UploadsCard(rfq: rfq),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: _HelpCard(),
        ),
      ],
    );
  }
}

class _QuoteAcceptedDetailsBody extends StatelessWidget {
  const _QuoteAcceptedDetailsBody({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    final itemCount = rfq.items.isEmpty ? 2 : rfq.items.length;
    final total = rfq.totalAmount > 0 ? rfq.totalAmount : 10800.0;
    final date = _displayDate(rfq.createdAt);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfq.id.isNotEmpty ? rfq.id : 'RFQ_B9867855HJS6',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                _MetaLine(date: date),
                const SizedBox(height: 16),
                const _QuoteAcceptedProgressCard(),
                const SizedBox(height: 20),
                Text(
                  'MOB Quotes',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 30 / 20,
                  ),
                ),
                const SizedBox(height: 16),
                _QuoteCard(
                  title: 'Quote 2',
                  date: date,
                  itemCount: itemCount,
                  total: total,
                  accepted: true,
                ),
                const SizedBox(height: 16),
                _QuoteCard(
                  title: 'Quote 1',
                  date: date,
                  itemCount: itemCount,
                  total: total,
                  aiGenerated: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: _UploadsCard(rfq: rfq),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: _HelpCard(),
        ),
      ],
    );
  }
}

class _ConvertedToOrderDetailsBody extends StatelessWidget {
  const _ConvertedToOrderDetailsBody({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    final itemCount = rfq.items.isEmpty ? 2 : rfq.items.length;
    final total = rfq.totalAmount > 0 ? rfq.totalAmount : 10800.0;
    final date = _displayDate(rfq.createdAt);
    final id = rfq.id.isNotEmpty ? rfq.id : 'MOB9867855HJS6';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfq.id.isNotEmpty ? rfq.id : 'RFQ_B9867855HJS6',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                _MetaLine(date: date),
                const SizedBox(height: 16),
                const _ConvertedToOrderProgressCard(),
                const SizedBox(height: 20),
                Text(
                  'MOB Quotes',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 30 / 20,
                  ),
                ),
                const SizedBox(height: 16),
                _QuoteCard(
                  title: 'Order ID: $id',
                  date: date,
                  itemCount: itemCount,
                  total: total,
                  convertedToOrder: true,
                ),
                const SizedBox(height: 16),
                _QuoteCard(
                  title: 'Quote 1',
                  date: date,
                  itemCount: itemCount,
                  total: total,
                  aiGenerated: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: _UploadsCard(rfq: rfq),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: _HelpCard(),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          date,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7B8496),
            height: 18 / 12,
          ),
        ),
        Container(
          width: 1,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFFD8DEE8),
        ),
        Expanded(
          child: Text(
            '560095, Koramangala, Bengaluru',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7B8496),
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestedProgressCard extends StatelessWidget {
  const _RequestedProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF08223D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requested',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 24 / 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will receive a quotation from our side within 24 hrs',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 18 / 12,
            ),
          ),
          const Spacer(),
          const _ProgressStepper(),
        ],
      ),
    );
  }
}

class _QuoteGeneratedProgressCard extends StatelessWidget {
  const _QuoteGeneratedProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A243F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote generated',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please accept a quotation to proceed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 18 / 12,
            ),
          ),
          const Spacer(),
          const _ProgressStepper(activeSteps: 2),
        ],
      ),
    );
  }
}

class _QuoteAcceptedProgressCard extends StatelessWidget {
  const _QuoteAcceptedProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A243F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote accepted',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confirm the order by clicking on "Confirm & pay"',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 18 / 12,
            ),
          ),
          const Spacer(),
          const _ProgressStepper(activeSteps: 3),
        ],
      ),
    );
  }
}

class _ConvertedToOrderProgressCard extends StatelessWidget {
  const _ConvertedToOrderProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF285C3B),
            Color(0xFF2D9955),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Converted to order',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Order has been created for this request. Please click on "View order" to check the order status',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({this.activeSteps = 1});

  final int activeSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(active: activeSteps >= 1),
        _StepLine(active: activeSteps >= 1),
        _StepDot(active: activeSteps >= 2),
        _StepLine(active: activeSteps >= 2),
        _StepDot(active: activeSteps >= 3),
        _StepLine(active: activeSteps >= 3),
        _StepDot(active: activeSteps >= 4),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF35C56F) : const Color(0xFF465A70),
        shape: BoxShape.circle,
      ),
      child: active
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 4,
        color: active ? const Color(0xFF35C56F) : const Color(0xFF465A70),
      ),
    );
  }
}

class _AiQuoteCard extends StatelessWidget {
  const _AiQuoteCard({required this.itemCount, required this.total});

  final int itemCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 225,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC675), width: 1.2),
      ),
      child: Stack(
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFC48F),
                  Color(0xFFFFE4CF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Color(0xFFFFA23A),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is AI generated and can have mistakes.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A243F),
                      height: 18 / 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quote 1',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '16 May, 10:25 am',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7B8496),
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 18),
                _QuoteMetric(label: 'Items:', value: itemCount.toString()),
                const SizedBox(height: 6),
                _QuoteMetric(
                  label: 'Total:',
                  value: '\u20B9${total.toStringAsFixed(0)}',
                  valueWeight: FontWeight.w800,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 148,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0A243F),
                        side: const BorderSide(color: Color(0xFFD8DEE8)),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'View quote',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 18 / 12,
                        ),
                      ),
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

const _quoteActionRowPadding = EdgeInsets.fromLTRB(16, 0, 16, 16);
const _quoteActionButtonPadding = EdgeInsets.all(10);
const _quoteActionButtonWidth = 148.0;
const _quoteActionButtonHeight = 36.0;
const _quoteActionButtonGap = 15.0;

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.title,
    required this.date,
    required this.itemCount,
    required this.total,
    this.aiGenerated = false,
    this.showAccept = false,
    this.accepted = false,
    this.convertedToOrder = false,
  });

  final String title;
  final String date;
  final int itemCount;
  final double total;
  final bool aiGenerated;
  final bool showAccept;
  final bool accepted;
  final bool convertedToOrder;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        aiGenerated
            ? 48
            : accepted || convertedToOrder
                ? 48
                : 16,
        0,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: convertedToOrder
                        ? const Color(0xFF0360E5)
                        : const Color(0xFF0A243F),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7B8496),
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 16),
                _QuoteMetric(label: 'Items:', value: itemCount.toString()),
                const SizedBox(height: 6),
                _QuoteMetric(
                  label: 'Total:',
                  value: '\u20B9${total.toStringAsFixed(0)}',
                  valueWeight: FontWeight.w800,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (showAccept || accepted || convertedToOrder)
            Padding(
              padding: _quoteActionRowPadding,
              child: Row(
                children: [
                  const Expanded(
                    child: _QuoteActionButton(
                      label: 'View quote',
                      variant: _QuoteActionButtonVariant.outlined,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: _quoteActionButtonGap),
                  Expanded(
                    child: _QuoteActionButton(
                      label: convertedToOrder
                          ? 'View order'
                          : accepted
                              ? 'Confirm & pay'
                              : 'Accept',
                      variant: _QuoteActionButtonVariant.filled,
                      fullWidth: true,
                      onTap: accepted
                          ? () => context
                              .read<RfqBloc>()
                              .add(RfqPaymentCompletedLocally())
                          : convertedToOrder
                              ? () {}
                              : () async {
                                  final confirmed = await showAcceptQuoteSheet(
                                    context,
                                    quoteTitle: title,
                                    itemsCount: itemCount,
                                    totalAmount: total,
                                    timeText: date,
                                  );
                                  if (!context.mounted || confirmed != true) {
                                    return;
                                  }
                                  context
                                      .read<RfqBloc>()
                                      .add(RfqQuoteAcceptedLocally());
                                },
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: _quoteActionRowPadding,
              child: Align(
                alignment: Alignment.centerRight,
                child: _QuoteActionButton(
                  label: 'View quote',
                  variant: _QuoteActionButtonVariant.outlined,
                ),
              ),
            ),
        ],
      ),
    );

    return Container(
      height: aiGenerated || accepted || convertedToOrder ? 226 : 194,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              aiGenerated ? const Color(0xFFF7B47B) : const Color(0xFFDEDEDE),
          width: aiGenerated ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (convertedToOrder)
            Container(
              height: 32,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: const BoxDecoration(
                color: Color(0xFF2D9955),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'Quote 1 converted to order',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 18 / 12,
                ),
              ),
            ),
          if (accepted)
            Container(
              height: 32,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: const BoxDecoration(
                color: Color(0xFF2D9955),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'Quotation accepted by you',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 18 / 12,
                ),
              ),
            ),
          if (aiGenerated)
            Container(
              height: 32,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFF8C194),
                    Color(0xFFFFE5D0),
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Color(0xFFFFA23A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is AI generated and can have mistakes.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A243F),
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          content,
        ],
      ),
    );
  }
}

enum _QuoteActionButtonVariant { outlined, filled }

class _QuoteActionButton extends StatelessWidget {
  const _QuoteActionButton({
    required this.label,
    required this.variant,
    this.fullWidth = false,
    this.onTap,
  });

  final String label;
  final _QuoteActionButtonVariant variant;
  final bool fullWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == _QuoteActionButtonVariant.filled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : _quoteActionButtonWidth,
        height: _quoteActionButtonHeight,
        padding: _quoteActionButtonPadding,
        decoration: ShapeDecoration(
          color: isFilled ? const Color(0xFF0360E5) : Colors.white,
          shape: RoundedRectangleBorder(
            side: isFilled
                ? BorderSide.none
                : const BorderSide(
                    width: 1,
                    color: Color(0xFFDEDEDE),
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isFilled ? Colors.white : const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteMetric extends StatelessWidget {
  const _QuoteMetric({
    required this.label,
    required this.value,
    this.valueWeight = FontWeight.w700,
  });

  final String label;
  final String value;
  final FontWeight valueWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7B8496),
            height: 20 / 14,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: valueWeight,
            color: const Color(0xFF0A243F),
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}

class _UploadsCard extends StatelessWidget {
  const _UploadsCard({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    final images = rfq.items
        .map((item) => item.imageUrl)
        .where((url) => url.trim().isNotEmpty)
        .take(3)
        .toList();

    return Container(
      height: 372,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your uploads',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A243F),
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                child: _UploadImage(
                  url: index < images.length ? images[index] : '',
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const _InfoParagraph(
            title: 'List',
            body:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam dictum fringilla est, eu dictum magna fermentum eget. Pellentesque lectus augue, aliquam sit amet viverra vitae, semper vel magna.',
          ),
          const SizedBox(height: 18),
          const _InfoParagraph(
            title: 'Preferred brands',
            body:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam dictum fringilla est, eu dictum magna fermentum eget. Pellentesque lectus augue, aliquam sit amet viverra vitae, semper vel magna.',
          ),
        ],
      ),
    );
  }
}

class _UploadImage extends StatelessWidget {
  const _UploadImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 84,
        height: 84,
        color: const Color(0xFFF7F9FC),
        child: url.isEmpty
            ? CustomPaint(painter: _NotePainter())
            : Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}

class _NotePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = const Color(0xFFD8DEE8)
      ..style = PaintingStyle.stroke;
    final line = Paint()
      ..color = const Color(0xFF9DB2DF)
      ..strokeWidth = 1;
    final red = Paint()
      ..color = const Color(0xFFFFA5A5)
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      border,
    );
    canvas.drawLine(const Offset(16, 8), Offset(16, size.height - 8), red);
    for (double y = 14; y < size.height - 8; y += 9) {
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoParagraph extends StatelessWidget {
  const _InfoParagraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A243F),
            height: 16 / 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7C859A),
            height: 16 / 12,
          ),
        ),
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 134,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Need help?',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 17,
                  ),
                ),
              ),
              SizedBox(
                width: 148,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                  label: Text(
                    'Chat with us',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 18 / 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37BD68),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFE2F3EC),
                    child: Icon(Icons.support_agent, color: Color(0xFF0A243F)),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF35C56F),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mob team',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A243F),
                        height: 20 / 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF7EC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Online',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0A243F),
                              height: 18 / 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Replies under 10 mins',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7B8496),
                              height: 18 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF7B8496),
          ),
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

enum _RfqDetailStatus {
  requested,
  quoteGenerated,
  quoteAccepted,
  convertedToOrder,
}

_RfqDetailStatus _parseDetailStatus(String raw) {
  final status = raw.toLowerCase().replaceAll(' ', '_');
  if (status.contains('converted') || status.contains('order')) {
    return _RfqDetailStatus.convertedToOrder;
  }
  if (status.contains('accept') || status.contains('approved')) {
    return _RfqDetailStatus.quoteAccepted;
  }
  if (status.contains('quote') ||
      status.contains('quotation') ||
      status.contains('generated')) {
    return _RfqDetailStatus.quoteGenerated;
  }
  return _RfqDetailStatus.requested;
}
