import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';

enum _MagicQuoteScreen { upload, generating, results, unread, reviewSuccess }

class MagicAiQuotePage extends StatefulWidget {
  const MagicAiQuotePage({super.key});

  static const String routeName = 'MagicAiQuotePage';
  static const String routePath = '/magic-ai-quote';

  @override
  State<MagicAiQuotePage> createState() => _MagicAiQuotePageState();
}

class _MagicAiQuotePageState extends State<MagicAiQuotePage> {
  static const _navy = Color(0xFF092743);
  static const _blue = Color(0xFF0968E8);
  static const _muted = Color(0xFF687482);
  static const _border = Color(0xFFE3E8EF);
  static const _bg = Color(0xFFF5F7FA);
  static const _maxFiles = 6;
  static const _maxTotalBytes = 20 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final RfqBloc _rfqBloc;
  final _noteController = TextEditingController();
  final _brandsController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _projectController = TextEditingController();
  final _gstController = TextEditingController();
  final _emailController = TextEditingController();

  final List<_PickedMagicQuoteFile> _files = [];
  _MagicQuoteScreen _screen = _MagicQuoteScreen.upload;
  Map<String, dynamic>? _quoteResponse;
  String _generatingStatus = 'Uploading your list';

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>();
    _prefillForm();
  }

  @override
  void dispose() {
    _rfqBloc.close();
    _noteController.dispose();
    _brandsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _projectController.dispose();
    _gstController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: BlocConsumer<RfqBloc, RfqState>(
        listener: _onRfqStateChanged,
        builder: (context, state) {
          final submitting = state is MagicQuoteSubmitting;
          return WillPopScope(
            onWillPop: () async {
              if (_screen == _MagicQuoteScreen.upload) return true;
              _handleBack();
              return false;
            },
            child: Scaffold(
              backgroundColor: _bg,
              body: SafeArea(
                child: Column(
                  children: [
                    _header(),
                    Expanded(child: _body(submitting)),
                  ],
                ),
              ),
              bottomNavigationBar: _bottomBar(submitting),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    final title = switch (_screen) {
      _MagicQuoteScreen.upload => 'Magic AI Quote',
      _MagicQuoteScreen.generating => 'Generating quote',
      _MagicQuoteScreen.results => 'Your Quote',
      _MagicQuoteScreen.unread => 'Your Quote',
      _MagicQuoteScreen.reviewSuccess => 'Request submitted',
    };
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: _navy,
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(bool submitting) {
    return switch (_screen) {
      _MagicQuoteScreen.upload => _uploadScreen(submitting),
      _MagicQuoteScreen.generating => _generatingScreen(),
      _MagicQuoteScreen.results => _resultsScreen(),
      _MagicQuoteScreen.unread => _unreadScreen(),
      _MagicQuoteScreen.reviewSuccess => _reviewSuccessScreen(),
    };
  }

  Widget? _bottomBar(bool submitting) {
    final action = switch (_screen) {
      _MagicQuoteScreen.upload => _BottomAction(
          label: 'Generate quote',
          icon: Icons.auto_awesome,
          onPressed: submitting ? null : _submit,
        ),
      _MagicQuoteScreen.results => _BottomAction(
          label: 'Submit for review',
          icon: Icons.check_circle_outline,
          onPressed: () => setState(() {
            _screen = _MagicQuoteScreen.reviewSuccess;
          }),
        ),
      _MagicQuoteScreen.unread => _BottomAction(
          label: 'Upload another list',
          icon: Icons.upload_file_outlined,
          onPressed: _resetToUpload,
        ),
      _MagicQuoteScreen.reviewSuccess => _BottomAction(
          label: 'Done',
          icon: Icons.done,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      _MagicQuoteScreen.generating => null,
    };
    if (action == null) return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: action.onPressed,
            icon: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Icon(action.icon, size: 20),
            label: Text(
              action.label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _blue.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadScreen(bool submitting) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/magicquote.jpeg',
              width: double.infinity,
              height: 142,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Send us your BOQ or material list'),
                const SizedBox(height: 12),
                _uploadDropZone(submitting),
                if (_files.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._files.map(_fileRow),
                ],
                const SizedBox(height: 16),
                _field(
                  'Add note',
                  _noteController,
                  optional: true,
                  hint: 'Mention brands, sizes or delivery notes',
                  minLines: 3,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                _field(
                  'Preferred brands',
                  _brandsController,
                  optional: true,
                  hint: 'e.g. Asian Paints, Jaquar, Havells',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Your details'),
                const SizedBox(height: 14),
                _field(
                  'Name',
                  _nameController,
                  required: true,
                  validator: (value) => _required(value, 'Please enter name'),
                ),
                const SizedBox(height: 18),
                _field(
                  'Phone',
                  _phoneController,
                  required: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) =>
                      value == null || value.trim().length != 10
                          ? 'Enter a valid 10-digit phone number'
                          : null,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        'City',
                        _cityController,
                        required: true,
                        validator: (value) =>
                            _required(value, 'Please enter city'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'State',
                        _stateController,
                        required: true,
                        validator: (value) =>
                            _required(value, 'Please enter state'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _field(
                  'Delivery pincode',
                  _pincodeController,
                  required: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) =>
                      value == null || value.trim().length != 6
                          ? 'Enter a valid pincode'
                          : null,
                ),
                const SizedBox(height: 18),
                _field(
                  'Project name',
                  _projectController,
                  optional: true,
                  hint: 'e.g. Koramangala site',
                ),
                const SizedBox(height: 18),
                _field(
                  'GSTIN',
                  _gstController,
                  optional: true,
                  hint: '15-digit GSTIN',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    return text.length == 15 ? null : 'Enter a valid GSTIN';
                  },
                ),
                const SizedBox(height: 18),
                _field(
                  'Email',
                  _emailController,
                  optional: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    return text.contains('@') ? null : 'Enter a valid email';
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _uploadDropZone(bool submitting) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: submitting ? null : _pickFiles,
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: Color(0xFFC5CCD5)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _files.isEmpty ? 'Add files' : 'Add more files',
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, Excel, Word, JPG or PNG. Up to $_maxFiles files, 20 MB total.',
                      style: GoogleFonts.inter(
                        color: _muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
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

  Widget _fileRow(_PickedMagicQuoteFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: _navy, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatFileSize(file.size),
                  style: GoogleFonts.inter(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => setState(() => _files.remove(file)),
            icon: const Icon(Icons.close, size: 19),
            color: _muted,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          ),
        ],
      ),
    );
  }

  Widget _generatingScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 24),
      children: [
        _card(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _blue,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Generating your quote',
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please don’t close this screen. Takes 30-60 sec.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _generatingStatusRow(_generatingStatus),
            ],
          ),
        ),
      ],
    );
  }

  Widget _generatingStatusRow(String label) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF1EAD66), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              label,
              key: ValueKey(label),
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultsScreen() {
    final payload = _quotePayload(_quoteResponse);
    final quote = _mapValue(payload, 'quote');
    final rfqOrder = _mapValue(payload, 'rfq_order');
    final items = _items(payload);
    final total = _moneyValue(quote, const ['total', 'grand_total']);
    final subtotal = _moneyValue(quote, const ['sub_total', 'subtotal']);
    final discount = _moneyValue(quote, const ['discount']);
    final tax = _moneyValue(quote, const ['sgst']) + _moneyValue(quote, const ['cgst']);
    final quoteTitle = _stringValue(quote, const ['id', 'quote_id']).isEmpty
        ? 'Quote'
        : 'Quote ${_stringValue(quote, const ['id', 'quote_id'])}';
    final rfqNumber = _stringValue(rfqOrder, const ['rfq_id', 'id']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        _quoteTopCard(
          title: quoteTitle,
          status: 'AI generated',
          rfqNumber: rfqNumber,
          city: _cityController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _sectionTitle('Matched items')),
                  Text(
                    '${items.length} items',
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                _emptyMessage(
                  icon: Icons.search_off,
                  title: 'No matched items',
                  text: 'Your request was created, but no product match was returned.',
                )
              else
                ...items.map(_quoteItemRow),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Quote summary'),
              const SizedBox(height: 12),
              _summaryRow('Subtotal', subtotal),
              _summaryRow('Discount', discount),
              _summaryRow('Tax', tax),
              const Divider(height: 24),
              _summaryRow(
                'Estimated total',
                total,
                strong: true,
              ),
              const SizedBox(height: 10),
              Text(
                'AI generated quotes can have mistakes. Review items before placing an order.',
                style: GoogleFonts.inter(
                  color: _muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unreadScreen() {
    final payload = _quotePayload(_quoteResponse);
    final quote = _mapValue(payload, 'quote');
    final rfqOrder = _mapValue(payload, 'rfq_order');
    final quoteId = _stringValue(quote, const ['id', 'quote_id']);
    final rfqNumber = _stringValue(rfqOrder, const ['rfq_id', 'id']);
    final backendMessage = _stringValue(payload, const ['message']);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        _quoteTopCard(
          title: quoteId.isEmpty ? 'Quote' : 'Quote $quoteId',
          status: 'Under review',
          rfqNumber: rfqNumber,
          city: _cityController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
        const SizedBox(height: 14),
        _card(
          child: _emptyMessage(
            icon: Icons.schedule,
            title: 'Our AI hit a snag',
            text: backendMessage.isEmpty
                ? 'Your request is sent. Our team will review your list manually and reach out shortly.'
                : '$backendMessage. Your request is sent for manual review and we\'ll reach out shortly.',
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Your uploads'),
              const SizedBox(height: 10),
              if (_files.isEmpty)
                Text(
                  _noteController.text.trim().isEmpty
                      ? 'No upload details available.'
                      : _noteController.text.trim(),
                  style: GoogleFonts.inter(color: _muted, fontSize: 14),
                )
              else
                ..._files.map(_fileRow),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewSuccessScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 42, 16, 24),
      children: [
        _card(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF169B58),
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Quote sent for review',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our team will validate the items and contact you with the next steps.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _muted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quoteTopCard({
    required String title,
    required String status,
    required String rfqNumber,
    required String city,
    required String pincode,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'Under review'
                      ? const Color(0xFFFFF4E4)
                      : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    color: status == 'Under review'
                        ? const Color(0xFF9B5C00)
                        : _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (rfqNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rfqNumber,
              style: GoogleFonts.inter(color: _muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: _muted, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [city, pincode].where((part) => part.isNotEmpty).join(' - '),
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quoteItemRow(Map<String, dynamic> item) {
    final product = _mapValue(item, 'product');
    final name = _firstNonEmpty(
      [
        _stringValue(item, const ['name', 'product_name', 'item_name']),
        _stringValue(product, const ['name', 'product_name', 'title']),
      ],
    );
    final sku = _firstNonEmpty(
      [
        _stringValue(item, const ['sku', 'mob_sku', 'MOBSKU']),
        _stringValue(product, const ['sku', 'mob_sku', 'MOBSKU']),
      ],
    );
    final quantity = _stringValue(item, const ['quantity', 'qty']);
    final unit = _stringValue(item, const ['unit', 'uom']);
    final lineTotal = _moneyValue(item, const ['total', 'line_total', 'amount']);
    final price = _moneyValue(item, const ['price', 'selling_price', 'rate']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Matched product' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (sku.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sku,
                    style: GoogleFonts.inter(color: _muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    if (quantity.isNotEmpty) 'Qty $quantity',
                    if (unit.isNotEmpty) unit,
                    if (price > 0) '${_formatInr(price)} each',
                  ].join(' | '),
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            lineTotal > 0 ? _formatInr(lineTotal) : '-',
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, num value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: strong ? _navy : _muted,
                fontSize: strong ? 16 : 14,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            _formatInr(value),
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: strong ? 18 : 14,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMessage({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF2FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _blue, size: 32),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _muted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _infoCard() {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFD47B00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Magic Quote works',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Upload a BOQ or type your list. We match products and prepare a quote for review.',
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool optional = false,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final labelText = required
        ? '$label *'
        : optional
            ? '$label  optional'
            : label;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: _navy, fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.inter(
          color: _muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: GoogleFonts.inter(color: _muted, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: _blue, width: 1.6),
        errorBorder: _inputBorder(color: const Color(0xFFE14040)),
        focusedErrorBorder:
            _inputBorder(color: const Color(0xFFE14040), width: 1.6),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: _navy,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAF0F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  OutlineInputBorder _inputBorder({
    Color color = _border,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Future<void> _prefillForm() async {
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _nameController.text = _firstUserValue(user, const [
      'name',
      'full_name',
      'first_name',
      'customer_name',
    ]);
    _phoneController.text = _onlyDigits(
      _firstUserValue(user, const [
        'phone_number',
        'phone',
        'mobile',
        'email_or_phone',
      ]),
    );
    if (_phoneController.text.length > 10) {
      _phoneController.text =
          _phoneController.text.substring(_phoneController.text.length - 10);
    }
    _emailController.text = _firstUserValue(user, const ['email']);

    final address = SelectedAddressStore.cached ?? await SelectedAddressStore.read();
    if (!mounted || address == null) return;
    _applyAddress(address);
  }

  void _applyAddress(AddressEntity address) {
    if (_cityController.text.trim().isEmpty) {
      _cityController.text = address.city;
    }
    if (_stateController.text.trim().isEmpty) {
      _stateController.text = address.state;
    }
    if (_pincodeController.text.trim().isEmpty) {
      _pincodeController.text = address.pincode;
    }
    if (_projectController.text.trim().isEmpty) {
      _projectController.text = address.projectName;
    }
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = address.name;
    }
    if (_phoneController.text.trim().isEmpty) {
      _phoneController.text = _onlyDigits(address.phoneNumber);
    }
    if (_emailController.text.trim().isEmpty) {
      _emailController.text = address.email;
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx', 'doc', 'docx', 'pdf', 'jpeg', 'jpg', 'png'],
      allowMultiple: true,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final next = [..._files];
    for (final file in result.files) {
      if (next.length >= _maxFiles) break;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Unable to read ${file.name}.');
        continue;
      }
      next.add(
        _PickedMagicQuoteFile(
          name: file.name,
          size: file.size,
          file: FFUploadedFile(name: file.name, bytes: bytes),
        ),
      );
    }

    final totalBytes = next.fold<int>(0, (sum, file) => sum + file.size);
    if (totalBytes > _maxTotalBytes) {
      _showMessage('Total upload size should be less than 20 MB.');
      return;
    }
    if (result.files.length + _files.length > _maxFiles) {
      _showMessage('Only $_maxFiles files can be uploaded.');
    }
    setState(() {
      _files
        ..clear()
        ..addAll(next.take(_maxFiles));
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_files.isEmpty && _noteController.text.trim().isEmpty) {
      _showMessage('Please add a file or type your material list in notes.');
      return;
    }
    if (_files.isEmpty) {
      _showMessage('Please upload your BOQ or material list.');
      return;
    }

    setState(() {
      _screen = _MagicQuoteScreen.generating;
      _quoteResponse = null;
      _generatingStatus = 'Uploading your list';
    });
    _rfqBloc.add(
      MagicQuoteSubmitRequested(
        images: _files.map((file) => file.file).toList(growable: false),
        payload: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'state': _stateController.text.trim(),
          'city': _cityController.text.trim(),
          'delivery_pincode': _pincodeController.text.trim(),
          'email': _emailController.text.trim(),
          'gst_number': _gstController.text.trim().toUpperCase(),
          'project_name': _projectController.text.trim(),
          'note': _noteController.text.trim(),
          'preferred_brands': _brandsController.text.trim(),
        },
      ),
    );
  }

  void _onRfqStateChanged(BuildContext context, RfqState state) {
    if (state is MagicQuoteProgress) {
      setState(() => _generatingStatus = state.status);
      return;
    }
    if (state is MagicQuoteSubmitted) {
      final payload = _quotePayload(state.response);
      setState(() {
        _quoteResponse = state.response;
        _screen = _hasGeneratedItems(payload)
            ? _MagicQuoteScreen.results
            : _MagicQuoteScreen.unread;
      });
      return;
    }
    if (state is MagicQuoteError) {
      setState(() => _screen = _MagicQuoteScreen.upload);
      _showMessage(state.message);
    }
  }

  void _handleBack() {
    if (_screen == _MagicQuoteScreen.generating) {
      _showMessage('Please wait while your quote is being generated.');
      return;
    }
    if (_screen != _MagicQuoteScreen.upload) {
      _resetToUpload();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _resetToUpload() {
    setState(() {
      _screen = _MagicQuoteScreen.upload;
      _quoteResponse = null;
    });
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  Map<String, dynamic> _quotePayload(Map<String, dynamic>? response) {
    final candidates = [
      response?['payload'] is Map ? (response!['payload'] as Map)['data'] : null,
      response?['payload'],
      response?['data'] is Map ? (response!['data'] as Map)['data'] : null,
      response?['data'],
      response,
    ];
    for (final candidate in candidates) {
      if (candidate is Map) {
        final map = Map<String, dynamic>.from(candidate);
        if (map.containsKey('rfq_order') ||
            map.containsKey('quote') ||
            map['items'] is List) {
          return map;
        }
        if (map.containsKey('rfq_id') || map.containsKey('id')) {
          return {'rfq_order': map, 'items': const <dynamic>[]};
        }
      }
    }
    return const <String, dynamic>{};
  }

  bool _hasGeneratedItems(Map<String, dynamic> payload) {
    return _mapValue(payload, 'quote').isNotEmpty && _items(payload).isNotEmpty;
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> payload) {
    final rawItems = payload['items'];
    if (rawItems is! List) return const [];
    return rawItems.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList(growable: false);
  }

  Map<String, dynamic> _mapValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  String _stringValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  num _moneyValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value;
      final parsed = num.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  String _firstUserValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  String _formatInr(num value) {
    final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = text.split('.');
    final integer = parts.first;
    if (integer.length <= 3) return '₹$text';
    final lastThree = integer.substring(integer.length - 3);
    final leading = integer.substring(0, integer.length - 3);
    final grouped = leading.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (_) => ',',
    );
    return '₹$grouped,$lastThree${parts.length > 1 ? '.${parts.last}' : ''}';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PickedMagicQuoteFile {
  const _PickedMagicQuoteFile({
    required this.name,
    required this.size,
    required this.file,
  });

  final String name;
  final int size;
  final FFUploadedFile file;
}

class _BottomAction {
  const _BottomAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(14),
        ),
      );
    const dashLength = 5.0;
    const gapLength = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + dashLength).clamp(0.0, metric.length).toDouble(),
          ),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
