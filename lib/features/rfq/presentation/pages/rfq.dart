import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

import 'rfq_details_page.dart';

const List<({String label, String value})> _kRfqFilterOptions = [
  (label: 'Requested', value: 'Requested'),
  (label: 'Quote Generated', value: 'Quote sent'),
  (label: 'Quote Accepted', value: 'Quote Accepted'),
  (label: 'Order Created', value: 'Order Created'),
];

class RfqPage extends StatefulWidget {
  const RfqPage({super.key});

  static const routeName = 'RfqListPage';
  static const routePath = '/rfqs';

  @override
  State<RfqPage> createState() => _RfqPageState();
}

class _RfqPageState extends State<RfqPage> {
  late final RfqBloc _rfqBloc;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _activeFilterLabel;

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>()..add(RfqListRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _rfqBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _rfqBloc.add(RfqNextPageRequested());
    }
  }

  void _onSearchChanged(String value) {
    if (_activeFilterLabel != null) {
      setState(() => _activeFilterLabel = null);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _rfqBloc.add(RfqQueryChanged(value.trim()));
    });
  }

  void _onSearchCleared() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _activeFilterLabel = null);
    _rfqBloc.add(RfqListRequested());
  }

  void _onFilterSelected(String value, String label) {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _activeFilterLabel = label);
    _rfqBloc.add(RfqQueryChanged(value));
  }

  void _onFilterCleared() {
    setState(() => _activeFilterLabel = null);
    _rfqBloc.add(RfqListRequested());
  }

  Future<void> _openFilterSheet() async {
    final selected =
        await showModalBottomSheet<({String label, String value})?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RfqFilterSheet(activeLabel: _activeFilterLabel),
    );
    if (selected == null) return;
    if (selected.value.isEmpty) {
      _onFilterCleared();
    } else {
      _onFilterSelected(selected.value, selected.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: _RfqBody(
          searchController: _searchController,
          scrollController: _scrollController,
          activeFilterLabel: _activeFilterLabel,
          onSearchChanged: _onSearchChanged,
          onSearchCleared: _onSearchCleared,
          onFilterTap: _openFilterSheet,
        ),
      ),
    );
  }
}

class _RfqBody extends StatelessWidget {
  const _RfqBody({
    required this.searchController,
    required this.scrollController,
    required this.activeFilterLabel,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onFilterTap,
  });

  final TextEditingController searchController;
  final ScrollController scrollController;
  final String? activeFilterLabel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RfqHeader(
          searchController: searchController,
          activeFilterLabel: activeFilterLabel,
          onSearchChanged: onSearchChanged,
          onSearchCleared: onSearchCleared,
          onFilterTap: onFilterTap,
        ),
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
                RfqListLoaded(:final rfqs, :final isLoadingMore) => ColoredBox(
                    color: const Color(0xFFF0F0F0),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: rfqs.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= rfqs.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
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
  const _RfqHeader({
    required this.searchController,
    required this.activeFilterLabel,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onFilterTap,
  });

  final TextEditingController searchController;
  final String? activeFilterLabel;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onFilterTap;

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
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search for quotation',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF59677C),
                          height: 20 / 14,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF0A243F),
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSearchCleared,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF59677C),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: OutlinedButton.icon(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune, size: 14),
              label: Text(
                activeFilterLabel ?? 'Filters',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 18 / 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: activeFilterLabel != null
                    ? const Color(0xFF0360E5)
                    : const Color(0xFF0A243F),
                backgroundColor:
                    activeFilterLabel != null ? const Color(0xFFE6F4FF) : Colors.white,
                minimumSize: const Size(80, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(
                  color: activeFilterLabel != null
                      ? const Color(0xFF0360E5)
                      : const Color(0xFFD8DEE8),
                ),
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

class _RfqFilterSheet extends StatelessWidget {
  const _RfqFilterSheet({required this.activeLabel});

  final String? activeLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activeLabel != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        Navigator.of(context).pop((label: '', value: '')),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0360E5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_kRfqFilterOptions.map(
              (option) => _RfqFilterOptionTile(
                label: option.label,
                selected: activeLabel == option.label,
                onTap: () => Navigator.of(context)
                    .pop((label: option.label, value: option.value)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _RfqFilterOptionTile extends StatelessWidget {
  const _RfqFilterOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F4FF) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: Color(0xFF0360E5), size: 18),
          ],
        ),
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
    final hasProjectTag = (displayStatus == _RfqDisplayStatus.quoteGenerated ||
            displayStatus == _RfqDisplayStatus.quoteAccepted) &&
        item.projectName.isNotEmpty;
    final showQuoteAmount = displayStatus == _RfqDisplayStatus.quoteAccepted;
    final showAction = displayStatus != _RfqDisplayStatus.requested;
    final address = [
      item.city,
      if (item.pincode.isNotEmpty) item.pincode,
    ].where((p) => p.isNotEmpty).join(', ');
    final quoteAmount = item.totalAmount;

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
                _InfoLine(label: 'RFQ ID:', value: item.id),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoLine(label: 'Address:', value: address),
                ],
                if (hasProjectTag) ...[
                  const SizedBox(height: 10),
                  _ProjectChip(project: item.projectName),
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
