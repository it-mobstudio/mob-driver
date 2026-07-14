import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/show_accept_quote_sheet.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

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
                    RfqDetailLoaded(:final rfq) => _RfqDetailsBody(rfq: rfq),
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
                icon: const AppBackIcon(),
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

class _RfqDetailsBody extends StatelessWidget {
  const _RfqDetailsBody({required this.rfq});

  final RfqEntity rfq;

  bool get _isMagicQuote => rfq.status == 'Magic Quote';

  @override
  Widget build(BuildContext context) {
    final date = _displayDate(rfq.createdAt);
    final detailStatus = _parseDetailStatus(rfq.status);
    final progressCard = switch (detailStatus) {
      _RfqDetailStatus.convertedToOrder =>
        const _ConvertedToOrderProgressCard(),
      _RfqDetailStatus.quoteAccepted => const _QuoteAcceptedProgressCard(),
      _RfqDetailStatus.quoteGenerated => const _QuoteGeneratedProgressCard(),
      _ => const _RequestedProgressCard(),
    };

    final hasItemsSelectedContent = rfq.files.isNotEmpty ||
        rfq.rfqRemarks.isNotEmpty ||
        rfq.preferredBrands.isNotEmpty ||
        rfq.comments.isNotEmpty ||
        rfq.deliveryInstructions.isNotEmpty;

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
                  rfq.id,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                _MetaLine(date: date, address: _rfqAddress(rfq)),
                const SizedBox(height: 18),
                progressCard,
                for (final quote in rfq.convertedToOrderQuotes) ...[
                  const SizedBox(height: 16),
                  _RealQuoteCard(quote: quote, disableAccept: true),
                ],
                for (final quote in rfq.acceptedQuotes) ...[
                  const SizedBox(height: 16),
                  _RealQuoteCard(quote: quote, disableAccept: true),
                ],
              ],
            ),
          ),
        ),
        ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (_isMagicQuote || rfq.magicQuotes.isNotEmpty)
                  _MagicQuoteDescriptionRow()
                else if (rfq.newQuotes.isNotEmpty)
                  const _QuoteSupportInstruction()
                else
                  Text(
                    'Our team is working on it. We will reach back to '
                    'you within 24 hrs',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0A243F),
                      height: 20 / 13,
                    ),
                  ),
                const SizedBox(height: 16),
                if (rfq.magicQuotes.isNotEmpty) ...[
                  for (final quote in rfq.magicQuotes) ...[
                    _RealQuoteCard(quote: quote, disableAccept: true),
                    const SizedBox(height: 16),
                  ],
                ] else if (rfq.newQuotes.isNotEmpty)
                  for (final quote in rfq.newQuotes) ...[
                    _RealQuoteCard(
                      quote: quote,
                      disableAccept: rfq.acceptedQuotes.isNotEmpty ||
                          rfq.status == 'Order Created',
                    ),
                    const SizedBox(height: 16),
                  ]
                else if (!_isMagicQuote)
                  const _NoQuotesFound(),
              ],
            ),
          ),
        ),
        if (hasItemsSelectedContent)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _ItemsSelectedCard(rfq: rfq),
          ),
        if (rfq.quoteRequestedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _RequestedItemsByVendorCard(rfq: rfq),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: _HelpCard(),
        ),
      ],
    );
  }
}

class _MagicQuoteDescriptionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Column sizes to its widest child by default — since the headline text
    // is narrower than the full card, the whole group would otherwise hug
    // the left edge (the outer Column here uses crossAxisAlignment.start)
    // instead of actually centering within the card's full width.
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/magic-quote-unread-snag.svg',
            width: 160,
            height: 102,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'Our team is working on your final quotation',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A243F),
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF0A243F),
                height: 18 / 12,
              ),
              children: [
                const TextSpan(text: 'We should reach out within 5 - 30 mins\n'),
                const TextSpan(text: 'or Call '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _SupportPhoneLink(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0360E5),
                      height: 18 / 12,
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

class _NoQuotesFound extends StatelessWidget {
  const _NoQuotesFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Color(0xFFB9C0CB),
            ),
            const SizedBox(height: 12),
            Text(
              'No quotes found!',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6F7788),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsSelectedCard extends StatelessWidget {
  const _ItemsSelectedCard({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (rfq.files.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: rfq.files.take(3).toList().asMap().entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(right: e.key == 2 ? 0 : 12),
                  child: _UploadImage(url: e.value),
                );
              }).toList(),
            ),
          ],
          if (rfq.rfqRemarks.isNotEmpty) ...[
            const SizedBox(height: 18),
            _InfoBlock(title: 'Item list', body: rfq.rfqRemarks),
          ],
          if (rfq.preferredBrands.isNotEmpty) ...[
            const SizedBox(height: 18),
            _InfoBlock(title: 'Preferred brands', body: rfq.preferredBrands),
          ],
          if (rfq.comments.isNotEmpty) ...[
            const SizedBox(height: 18),
            _InfoBlock(title: 'Comments', body: rfq.comments),
          ],
          if (rfq.deliveryInstructions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Delivery instructions',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A243F),
                height: 16 / 12,
              ),
            ),
            const SizedBox(height: 6),
            for (final instruction in rfq.deliveryInstructions)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      instruction.key,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7C859A),
                        height: 16 / 12,
                      ),
                    ),
                    Text(
                      instruction.value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A243F),
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

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

class _RequestedItemsByVendorCard extends StatelessWidget {
  const _RequestedItemsByVendorCard({required this.rfq});

  final RfqEntity rfq;

  @override
  Widget build(BuildContext context) {
    final vendors = rfq.quoteRequestedItems.keys.toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A243F),
                height: 24 / 17,
              ),
              children: [
                TextSpan(text: '${rfq.requestedItemsTotalCount} items '),
                TextSpan(
                  text: '(${vendors.length} suborder request)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 14),
                ),
              ],
            ),
          ),
          for (final vendor in vendors) ...[
            const SizedBox(height: 16),
            Text(
              'Mob partner: $vendor',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A243F),
                height: 20 / 13,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in rfq.quoteRequestedItems[vendor]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0A243F),
                            height: 20 / 13,
                          ),
                          children: [
                            TextSpan(text: '${item.productName}\n'),
                            TextSpan(
                              text: 'MOBSKU: ${item.mobSku}',
                              style: const TextStyle(
                                color: Color(0xFF7B8496),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Qty:',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF7B8496),
                          ),
                        ),
                        Text(
                          '${item.qty}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A243F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.date, this.address = ''});

  final String date;
  final String address;

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
        if (address.isNotEmpty) ...[
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFD8DEE8),
          ),
          Expanded(
            child: Text(
              address,
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

const _quoteActionRowPadding = EdgeInsets.fromLTRB(0, 16, 0, 0);
const _quoteActionButtonPadding = EdgeInsets.all(10);
const _quoteActionButtonHeight = 36.0;
const _quoteActionButtonGap = 12.0;

class _RealQuoteCard extends StatelessWidget {
  const _RealQuoteCard({required this.quote, this.disableAccept = false});

  final RfqQuoteEntity quote;
  final bool disableAccept;

  bool get _canAccept => quote.isNew && !quote.isMagicQuote && !disableAccept;

  Future<void> _openUrl(String url) => openExternalUrl(url);

  @override
  Widget build(BuildContext context) {
    final dateText = _displayDate(quote.date);
    final quoteTitle = 'Quote ${quote.index}';

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quote.isMagicQuote
              ? const Color(0xFFF7B47B)
              : const Color(0xFFDEDEDE),
          width: quote.isMagicQuote ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explicit top-corner clip on each banner — relying solely on the
          // outer Container's Clip.antiAlias left a hairline square seam at
          // the top-right corner where the banner's rect met the card's
          // rounded border. Radius is inset by the border's own width (1px
          // for the grey/green cards, 2px for the orange magic-quote one) so
          // it sits flush just inside the border stroke.
          if (quote.isConvertedToOrder)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Container(
                height: 32,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                color: const Color(0xFF2D9955),
                alignment: Alignment.centerLeft,
                child: Text(
                  '$quoteTitle converted to order',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 18 / 12,
                  ),
                ),
              ),
            )
          else if (quote.isAccepted)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Container(
                height: 32,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                color: const Color(0xFF2D9955),
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
            )
          else if (quote.isMagicQuote)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: Container(
                height: 32,
                width: double.infinity,
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
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quoteTitle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: quote.isConvertedToOrder
                              ? const Color(0xFF0360E5)
                              : const Color(0xFF0A243F),
                          height: 24 / 16,
                        ),
                      ),
                    ),
                    Text(
                      dateText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7B8496),
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _QuoteMetric(
                    label: 'Items:', value: quote.itemsCount.toString()),
                const SizedBox(height: 6),
                _QuoteMetric(
                  label: 'Total:',
                  value: '₹${quote.total.toStringAsFixed(0)}',
                  valueWeight: FontWeight.w800,
                ),
                Padding(
                  padding: _quoteActionRowPadding,
                  child: Wrap(
                    spacing: _quoteActionButtonGap,
                    runSpacing: 10,
                    children: [
                      if (_canAccept)
                        _QuoteActionButton(
                          label: 'Accept',
                          variant: _QuoteActionButtonVariant.filled,
                          onTap: () async {
                            final confirmed = await showAcceptQuoteSheet(
                              context,
                              quoteTitle: quoteTitle,
                              itemsCount: quote.itemsCount,
                              totalAmount: quote.total,
                              timeText: dateText,
                            );
                            if (!context.mounted || confirmed != true) return;
                            context
                                .read<RfqBloc>()
                                .add(RfqQuoteAcceptedLocally(quote.quoteId));
                          },
                        ),
                      _QuoteActionButton(
                        label: 'View quote',
                        variant: _QuoteActionButtonVariant.outlined,
                        onTap: quote.quotationPdfUrl.isEmpty
                            ? null
                            : () => _openUrl(quote.quotationPdfUrl),
                      ),
                      if (quote.isConvertedToOrder && quote.orderId.isNotEmpty)
                        _QuoteActionButton(
                          label: 'View order',
                          variant: _QuoteActionButtonVariant.filled,
                          onTap: () => context.push(
                            OrderDetailPage.routePath,
                            extra: quote.orderId,
                          ),
                        ),
                      if (quote.checkoutUrl.isNotEmpty)
                        _QuoteActionButton(
                          label: 'Confirm & pay',
                          variant: _QuoteActionButtonVariant.filled,
                          onTap: () => _openUrl(quote.checkoutUrl),
                        ),
                    ],
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

enum _QuoteActionButtonVariant { outlined, filled }

class _QuoteActionButton extends StatelessWidget {
  const _QuoteActionButton({
    required this.label,
    required this.variant,
    this.onTap,
  });

  final String label;
  final _QuoteActionButtonVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == _QuoteActionButtonVariant.filled;
    final isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? 0.4 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
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

class _QuoteSupportInstruction extends StatelessWidget {
  const _QuoteSupportInstruction();

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0A243F),
      height: 20 / 13,
    );
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          const TextSpan(
            text: 'Click on the "Accept" button to select the quote '
                'you want to proceed with. For any changes like '
                'quantity, partial order, etc. please contact mob '
                'support at ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _SupportPhoneLink(
              label: '+91 8660423608',
              style: style.copyWith(color: const Color(0xFF0360E5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPhoneLink extends StatelessWidget {
  const _SupportPhoneLink({
    this.label = '+918660423608',
    required this.style,
  });

  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Call $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _callSupport,
        child: Text(
          label,
          style: style,
        ),
      ),
    );
  }
}

Future<void> _callSupport() async {
  await launchUrl(
    Uri.parse('tel:+918660423608'),
    mode: LaunchMode.externalApplication,
  );
}

/// Opens any URL in the platform's best available viewer — a browser tab on
/// web, or the OS-registered app (PDF reader, Office, Google Drive, etc.) on
/// mobile. Flutter has no built-in renderer for doc/docx/xls/xlsx and
/// `webview_flutter` doesn't support web (see kIsWeb guard in
/// RupifiPaymentWebviewPage), so handing off to the platform is the one
/// approach that works uniformly for every file type on every platform.
Future<void> openExternalUrl(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

const _imageFileExtensions = {'.jpg', '.jpeg', '.png'};

String _fileExtension(String url) {
  final withoutQuery = url.split('?').first;
  final dot = withoutQuery.lastIndexOf('.');
  if (dot == -1) return '';
  return withoutQuery.substring(dot).toLowerCase();
}

bool _isImageFile(String url) =>
    _imageFileExtensions.contains(_fileExtension(url));

class _UploadImage extends StatelessWidget {
  const _UploadImage({required this.url});

  final String url;

  Future<void> _open(BuildContext context) async {
    if (url.isEmpty) return;
    if (_isImageFile(url)) {
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close file preview',
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => _UploadFilePreviewOverlay(url: url),
      );
      return;
    }
    // pdf/doc/docx/xls/xlsx — no in-app renderer, hand off to the platform.
    await openExternalUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 84,
          height: 84,
          color: const Color(0xFFF7F9FC),
          child: switch (url.isEmpty ? null : _fileExtension(url)) {
            null => CustomPaint(painter: _NotePainter()),
            '.jpg' ||
            '.jpeg' ||
            '.png' =>
              Image.network(url, fit: BoxFit.cover),
            _ => _FileTypeIcon(extension: _fileExtension(url)),
          },
        ),
      ),
    );
  }
}

class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({required this.extension});

  final String extension;

  ({IconData icon, Color color}) get _style => switch (extension) {
        '.pdf' => (
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFE0402E)
          ),
        '.doc' || '.docx' => (
            icon: Icons.description_rounded,
            color: const Color(0xFF2B6BE0)
          ),
        '.xls' || '.xlsx' => (
            icon: Icons.table_chart_rounded,
            color: const Color(0xFF1F9254)
          ),
        _ => (
            icon: Icons.insert_drive_file_rounded,
            color: const Color(0xFF7B8496)
          ),
      };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.color, size: 32),
          if (extension.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              extension.replaceFirst('.', '').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: style.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadFilePreviewOverlay extends StatelessWidget {
  const _UploadFilePreviewOverlay({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF0A243F),
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                  onPressed: () => launchUrl(
                    Uri.parse('https://wa.me/918970415365'),
                    mode: LaunchMode.externalApplication,
                  ),
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

String _rfqAddress(RfqEntity rfq) {
  return [
    rfq.city,
    if (rfq.pincode.isNotEmpty) rfq.pincode,
  ].where((p) => p.isNotEmpty).join(', ');
}

String _displayDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
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
  switch (raw) {
    case 'Order Created':
    case 'Order Converted':
      return _RfqDetailStatus.convertedToOrder;
    case 'Quote Accepted':
      return _RfqDetailStatus.quoteAccepted;
    case 'Quote sent':
    case 'Magic Quote':
      return _RfqDetailStatus.quoteGenerated;
    case 'Requested':
      return _RfqDetailStatus.requested;
  }

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
