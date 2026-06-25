import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

enum _MagicQuoteScreen { upload, generating, results, unread, reviewSuccess }

class MagicAiQuotePage extends StatefulWidget {
  const MagicAiQuotePage({super.key});

  static const String routeName = 'MagicAiQuotePage';
  static const String routePath = '/magic-ai-quote';

  @override
  State<MagicAiQuotePage> createState() => _MagicAiQuotePageState();
}

class _MagicAiQuotePageState extends State<MagicAiQuotePage> {
  static const _navy = AppColors.primaryText;
  static const _blue = Color(0xFF0968E8);
  static const _muted = Color(0xFF687482);
  static const _border = Color(0xFFE3E8EF);
  static const _bg = Color(0xFFF5F7FA);
  static const _maxFiles = 6;
  static const _maxTotalBytes = 20 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final RfqBloc _rfqBloc;
  final _noteFocusNode = FocusNode();
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

  // null = not checked yet, true = serviceable, false = not serviceable
  bool? _pincodeServiceable;
  String _lastCheckedPincode = '';

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>();
    _pincodeController.addListener(_onPincodeChanged);
    _prefillForm();
  }

  @override
  void dispose() {
    _rfqBloc.close();
    _pincodeController.removeListener(_onPincodeChanged);
    _noteFocusNode.dispose();
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
      _MagicQuoteScreen.generating => 'Reading your list...',
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
          onPressed:
              submitting || _pincodeServiceable == false ? null : _submit,
        ),
      _MagicQuoteScreen.results => _BottomAction(
          label: 'Submit for review',
          icon: Icons.check_circle_outline,
          onPressed: _showReviewQuestionsSheet,
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
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.zero,
              topRight: Radius.zero,
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Image.asset(
              'assets/images/magicquote.jpeg',
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: _uploadScreenCards(submitting),
          ),
        ],
      ),
    );
  }

  Widget _uploadScreenCards(bool submitting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Send us your BOQ or material list'),
              const SizedBox(height: 12),
              _uploadDropZone(submitting),
              if (_files.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _files.map(_fileTile).toList(),
                ),
              ],
              const SizedBox(height: 16),
              _field(
                'Add note',
                _noteController,
                optional: true,
                hint: 'Mention brands, sizes or delivery notes',
                focusNode: _noteFocusNode,
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
                validator: (value) => value == null || value.trim().length != 10
                    ? 'Enter a valid 10-digit phone number'
                    : null,
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
                validator: (value) => value == null || value.trim().length != 6
                    ? 'Enter a valid pincode'
                    : null,
              ),
              if (_pincodeServiceable == false) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFE14040),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "We don't deliver to ${_pincodeController.text.trim()} yet",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE14040),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      'City',
                      _cityController,
                      required: true,
                      enabled: false,
                      hint: 'Auto-filled from pincode',
                      validator: (value) =>
                          _required(value, 'Please enter a valid pincode'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'State',
                      _stateController,
                      required: true,
                      enabled: false,
                      hint: 'Auto-filled from pincode',
                      validator: (value) =>
                          _required(value, 'Please enter a valid pincode'),
                    ),
                  ),
                ],
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
    );
  }

  Widget _uploadDropZone(bool submitting) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: submitting ? null : _showUploadOptionsSheet,
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
                      _files.isEmpty ? 'Add your list/ BOQ' : 'Add more files',
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photo, PDF, Excel or paste text\nMax $_maxFiles files · 20 MB',
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

  static const _imageExtensions = ['jpg', 'jpeg', 'png'];

  bool _isImageFile(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return _imageExtensions.contains(ext);
  }

  Widget _fileTile(_PickedMagicQuoteFile file, {bool removable = true}) {
    final bytes = file.file.bytes;
    final isImage = _isImageFile(file.name) && bytes != null && bytes.isNotEmpty;
    const tileSize = 84.0;
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: tileSize,
              height: tileSize,
              color: const Color(0xFFF7F9FC),
              child: InkWell(
                onTap: isImage ? () => _showFilePreview(file.name, bytes) : null,
                child: isImage
                    ? Image.memory(
                        bytes,
                        width: tileSize,
                        height: tileSize,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          (file.name.contains('.')
                                  ? file.name.split('.').last
                                  : file.name)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            color: _navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (removable)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: () => setState(() => _files.remove(file)),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF687482),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _generatingScreen() {
    final pincode = _pincodeController.text.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      children: [
        _generatingWarningBanner(),
        const SizedBox(height: 22),
        const Center(child: _ScanningDocumentCard()),
        const SizedBox(height: 26),
        Text(
          'Putting your quote together',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 14,
              height: 1.4,
            ),
            children: [
              const TextSpan(
                text: 'Reading your list, matching brands and checking '
                    'live prices for ',
              ),
              TextSpan(
                text: pincode.isEmpty ? 'your area' : pincode,
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          child: LinearProgressIndicator(
            minHeight: 6,
            backgroundColor: Color(0xFFE3E8EF),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1EAD66)),
          ),
        ),
        const SizedBox(height: 18),
        _generatingStatusRow(_generatingStatus),
      ],
    );
  }

  Widget _generatingWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Please don't close this screen",
            style: GoogleFonts.inter(
              color: const Color(0xFF8A5A00),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Takes 30-60 sec',
            style: GoogleFonts.inter(
              color: const Color(0xFFB07D1F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _generatingStatusRow(String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF1EAD66), size: 20),
        const SizedBox(width: 10),
        AnimatedSwitcher(
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
      ],
    );
  }

  Future<void> _showReviewQuestionsSheet() async {
    final quote = _mapValue(_quotePayload(_quoteResponse), 'quote');
    final quoteId = _stringValue(quote, const ['id', 'quote_id']);
    if (quoteId.isEmpty) {
      _showMessage('Unable to find this quote. Please try again.');
      return;
    }
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _ReviewQuestionsSheet(
          rfqBloc: _rfqBloc,
          quoteId: quoteId,
          onSubmitted: () {
            Navigator.of(sheetContext).pop();
            setState(() => _screen = _MagicQuoteScreen.reviewSuccess);
          },
        );
      },
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
    final tax =
        _moneyValue(quote, const ['sgst']) + _moneyValue(quote, const ['cgst']);
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
                  text:
                      'Your request was created, but no product match was returned.',
                )
              else
                ...items.indexed.map((entry) => _quoteItemRow(entry.$2, entry.$1)),
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
            title: 'Uh oh, our AI hit a snag',
            text: "Don't worry, your request is sent. Our team will review "
                "your list manually and reach out shortly!",
          ),
        ),
        const SizedBox(height: 14),
        _needHelpCard(),
      ],
    );
  }

  Widget _needHelpCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Need help?'),
          const SizedBox(height: 6),
          Text(
            "Chat with our team and we'll get your list reviewed quickly.",
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat_bubble, size: 18),
              label: Text(
                'Chat with us',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF1EAD66),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final ok = await launchUrl(
      Uri.parse('https://wa.me/918970415365'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) _showMessage('Unable to open WhatsApp.');
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
          if (_hasUploadsContext) ...[
            const SizedBox(height: 12),
            _uploadsSummaryRow(),
          ],
          const SizedBox(height: 12),
          _aiDisclaimerRow(),
        ],
      ),
    );
  }

  bool get _hasUploadsContext =>
      _files.isNotEmpty || _noteController.text.trim().isNotEmpty;

  Widget _aiDisclaimerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE9A23B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'This is AI generated and can have mistakes',
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadsSummaryRow() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _showUploadsViewer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.attachment, color: _navy, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your uploads',
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'View',
              style: GoogleFonts.inter(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: _blue),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilePreview(String name, Uint8List bytes) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: _navy, size: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUploadsViewer() async {
    final note = _noteController.text.trim();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your uploads & note',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_files.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Files (${_files.length})',
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _files
                        .map((file) => _fileTile(file, removable: false))
                        .toList(),
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Note',
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note,
                    style: GoogleFonts.inter(color: _navy, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _noMatchItemRow(int idx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFAD7D7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFAD7D7),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${idx + 1}',
              style: GoogleFonts.inter(
                color: const Color(0xFFB3261E),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Don't worry! Please submit and our team will be in touch",
                style: GoogleFonts.inter(
                  color: const Color(0xFFB3261E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteItemRow(Map<String, dynamic> item, int idx) {
    if (item['is_product_available'] == false) {
      return _noMatchItemRow(idx);
    }
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
    final lineTotal =
        _moneyValue(item, const ['total', 'line_total', 'amount']);
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
    bool enabled = true,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
    FocusNode? focusNode,
  }) {
    final labelText = required
        ? '$label *'
        : optional
            ? '$label  optional'
            : label;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        color: enabled ? _navy : _muted,
        fontSize: 15,
      ),
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
        fillColor: enabled ? Colors.white : const Color(0xFFF5F7FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        disabledBorder: _inputBorder(),
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
        fontWeight: FontWeight.w800,
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

    final address =
        SelectedAddressStore.cached ?? await SelectedAddressStore.read();
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

  Future<void> _showUploadOptionsSheet() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E8EF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Add your shopping list',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We accept handwritten lists, PDFs, Excel, or even '
                  'WhatsApp screenshots.',
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _uploadSheetOption(
                  icon: Icons.photo_camera_outlined,
                  label: 'Use Camera',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickFromCamera();
                  },
                ),
                _uploadSheetOption(
                  icon: Icons.image_outlined,
                  label: 'Upload from Gallery',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickFromGallery();
                  },
                ),
                _uploadSheetOption(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'Pick PDF / Excel / Doc',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickDocuments();
                  },
                ),
                _uploadSheetOption(
                  icon: Icons.notes_outlined,
                  label: 'Paste text',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _focusNoteField();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _uploadSheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _navy, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA3B2)),
          ],
        ),
      ),
    );
  }

  void _focusNoteField() {
    Future.delayed(
      const Duration(milliseconds: 150),
      () {
        if (!mounted) return;
        _noteFocusNode.requestFocus();
      },
    );
  }

  Future<void> _pickFromCamera() async {
    if (_files.length >= _maxFiles) {
      _showMessage('Only $_maxFiles files can be uploaded.');
      return;
    }
    final shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted || shot == null) return;
    final bytes = await shot.readAsBytes();
    if (bytes.isEmpty) {
      _showMessage('Unable to read the captured photo.');
      return;
    }
    await _addPickedFiles([
      _PickedMagicQuoteFile(
        name: shot.name,
        size: bytes.length,
        file: FFUploadedFile(name: shot.name, bytes: bytes),
      ),
    ]);
  }

  Future<void> _pickFromGallery() async {
    final shots = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted || shots.isEmpty) return;
    final picked = <_PickedMagicQuoteFile>[];
    for (final shot in shots) {
      final bytes = await shot.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage('Unable to read ${shot.name}.');
        continue;
      }
      picked.add(
        _PickedMagicQuoteFile(
          name: shot.name,
          size: bytes.length,
          file: FFUploadedFile(name: shot.name, bytes: bytes),
        ),
      );
    }
    await _addPickedFiles(picked);
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx', 'doc', 'docx', 'pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final picked = <_PickedMagicQuoteFile>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Unable to read ${file.name}.');
        continue;
      }
      picked.add(
        _PickedMagicQuoteFile(
          name: file.name,
          size: file.size,
          file: FFUploadedFile(name: file.name, bytes: bytes),
        ),
      );
    }
    await _addPickedFiles(picked);
  }

  Future<void> _addPickedFiles(List<_PickedMagicQuoteFile> picked) async {
    if (!mounted || picked.isEmpty) return;
    final next = [..._files, ...picked];

    final totalBytes = next.fold<int>(0, (sum, file) => sum + file.size);
    if (totalBytes > _maxTotalBytes) {
      _showMessage('Total upload size should be less than 20 MB.');
      return;
    }
    if (next.length > _maxFiles) {
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

  void _onPincodeChanged() {
    final digits = _pincodeController.text.trim();
    if (digits.length != 6) {
      _lastCheckedPincode = '';
      if (_pincodeServiceable != null ||
          _cityController.text.isNotEmpty ||
          _stateController.text.isNotEmpty) {
        setState(() {
          _pincodeServiceable = null;
          _cityController.clear();
          _stateController.clear();
        });
      }
      return;
    }
    _checkPincodeServiceability(digits);
  }

  Future<void> _checkPincodeServiceability(String pincode) async {
    if (pincode == _lastCheckedPincode) return;
    _lastCheckedPincode = pincode;
    try {
      final response = await DioClient.instance.dio.get<dynamic>(
        '/utility/serviceble/',
        queryParameters: {'pincode': pincode},
      );
      final candidates = _pincodeResponseCandidates(response.data);
      final state = _firstFromCandidates(
        candidates,
        const ['state', 'state_name', 'stateName'],
      );
      final city = _firstFromCandidates(
        candidates,
        const ['city', 'city_name', 'cityName', 'district'],
      );
      final serviceableFlag = _firstBoolFromCandidates(
        candidates,
        const ['serviceable', 'is_serviceable', 'isServiceable', 'deliverable', 'status'],
      );
      final isServiceable = serviceableFlag ?? (state.isNotEmpty && city.isNotEmpty);
      if (!mounted) return;
      setState(() {
        _pincodeServiceable = isServiceable;
        if (state.isNotEmpty) _stateController.text = state;
        if (city.isNotEmpty) _cityController.text = city;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _pincodeServiceable = null);
    }
  }

  /// Pincode-check responses are observed both flat (`{status, city, ...}`)
  /// and nested (`{data: {city, ...}}` / `{data: {data: {...}}}`). Returns
  /// every plausible payload map, most-nested first, so lookups can just
  /// scan in order.
  List<Map<String, dynamic>> _pincodeResponseCandidates(dynamic body) {
    if (body is! Map) return const [];
    final flat = Map<String, dynamic>.from(body);
    final candidates = <Map<String, dynamic>>[];
    final data = flat['data'];
    if (data is Map) {
      final nested = Map<String, dynamic>.from(data);
      final nestedData = nested['data'];
      if (nestedData is Map) candidates.add(Map<String, dynamic>.from(nestedData));
      candidates.add(nested);
    }
    candidates.add(flat);
    return candidates;
  }

  String _firstFromCandidates(
    List<Map<String, dynamic>> candidates,
    List<String> keys,
  ) {
    for (final map in candidates) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      for (final nestedKey in ['location', 'address']) {
        final nested = map[nestedKey];
        if (nested is! Map) continue;
        for (final key in keys) {
          final value = nested[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
      }
    }
    return '';
  }

  bool? _firstBoolFromCandidates(
    List<Map<String, dynamic>> candidates,
    List<String> keys,
  ) {
    for (final map in candidates) {
      for (final key in keys) {
        final value = map[key];
        if (value is bool) return value;
        if (value is String) {
          return value.toLowerCase() == 'serviceable' || value.toLowerCase() == 'true';
        }
      }
    }
    return null;
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  Map<String, dynamic> _quotePayload(Map<String, dynamic>? response) {
    final candidates = [
      response?['payload'] is Map
          ? (response!['payload'] as Map)['data']
          : null,
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

class _ScanningDocumentCard extends StatefulWidget {
  const _ScanningDocumentCard();

  @override
  State<_ScanningDocumentCard> createState() => _ScanningDocumentCardState();
}

class _ScanningDocumentCardState extends State<_ScanningDocumentCard>
    with SingleTickerProviderStateMixin {
  static const _cardWidth = 220.0;
  static const _cardHeight = 250.0;
  static const _scanHeight = 56.0;
  static const _rowWidthFactors = [0.9, 0.75, 0.55, 0.65, 0.45, 0.6];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I need these products',
                    style: GoogleFonts.caveat(
                      color: const Color(0xFF0A243F),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._rowWidthFactors.map(_skeletonRow),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final top = (_cardHeight + _scanHeight) * _controller.value -
                    _scanHeight;
                return Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  height: _scanHeight,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1EAD66).withValues(alpha: 0),
                            const Color(0xFF1EAD66).withValues(alpha: 0.16),
                            const Color(0xFF1EAD66).withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonRow(double widthFactor) {
    const checkboxSize = 14.0;
    const gap = 8.0;
    const maxBarWidth = _cardWidth - 16 - 16 - checkboxSize - gap;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: checkboxSize,
            height: checkboxSize,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDE3EC)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: gap),
          Container(
            width: maxBarWidth * widthFactor,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFF3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
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

/// "Submit for review" bottom sheet: fetches the dynamic questionnaire via
/// [MagicQuoteQuestionsRequested] and submits answers + a free-text note via
/// [MagicQuoteReviewSubmitRequested]. Mirrors the web app's
/// MagicQuote/ReviewQuestionsModal.jsx.
class _ReviewQuestionsSheet extends StatefulWidget {
  const _ReviewQuestionsSheet({
    required this.rfqBloc,
    required this.quoteId,
    required this.onSubmitted,
  });

  final RfqBloc rfqBloc;
  final String quoteId;
  final VoidCallback onSubmitted;

  @override
  State<_ReviewQuestionsSheet> createState() => _ReviewQuestionsSheetState();
}

class _ReviewQuestionsSheetState extends State<_ReviewQuestionsSheet> {
  static const _noteQuestionId = 'specific_preferences_note';
  static const _navy = AppColors.primaryText;
  static const _muted = Color(0xFF687482);
  static const _blue = Color(0xFF0968E8);
  static const _border = Color(0xFFE3E8EF);

  final _noteController = TextEditingController();
  final Map<String, String> _answers = {};

  List<Map<String, dynamic>> _questions = const [];
  bool _isLoadingQuestions = true;
  bool _isSubmitting = false;
  String _fetchError = '';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _fetchQuestions() {
    setState(() {
      _isLoadingQuestions = true;
      _fetchError = '';
    });
    widget.rfqBloc.add(MagicQuoteQuestionsRequested());
  }

  List<Map<String, dynamic>> get _visibleQuestions =>
      _questions.where((q) => q['id'] != _noteQuestionId).toList();

  Map<String, dynamic>? get _noteQuestion {
    for (final question in _questions) {
      if (question['id'] == _noteQuestionId) return question;
    }
    return null;
  }

  bool get _hasUnansweredRequired => _visibleQuestions.any(
        (q) =>
            q['required'] == true &&
            (_answers[q['id']?.toString() ?? ''] ?? '').isEmpty,
      );

  bool get _isSubmitDisabled =>
      _isSubmitting ||
      _isLoadingQuestions ||
      _visibleQuestions.isEmpty ||
      _hasUnansweredRequired;

  void _onBlocState(BuildContext context, RfqState state) {
    if (state is MagicQuoteQuestionsLoaded) {
      setState(() {
        _questions = state.questions;
        _isLoadingQuestions = false;
      });
    } else if (state is MagicQuoteQuestionsError) {
      setState(() {
        _isLoadingQuestions = false;
        _fetchError = state.message;
      });
    } else if (state is MagicQuoteReviewSubmitting) {
      setState(() => _isSubmitting = true);
    } else if (state is MagicQuoteReviewSubmitted) {
      setState(() => _isSubmitting = false);
      widget.onSubmitted();
    } else if (state is MagicQuoteReviewError) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  void _submit() {
    if (_isSubmitDisabled) return;
    final note = _noteController.text.trim();
    final answers = Map<String, String>.from(_answers);
    answers[_noteQuestionId] = note;
    widget.rfqBloc.add(
      MagicQuoteReviewSubmitRequested(
        quoteId: widget.quoteId,
        questionnaireAnswers: answers,
        additionalInstructions: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notePlaceholder = (_noteQuestion?['placeholder']?.toString() ?? '')
        .trim();
    final noteSubtitle = (_noteQuestion?['question']?.toString() ?? '').trim();

    return BlocListener<RfqBloc, RfqState>(
      bloc: widget.rfqBloc,
      listener: _onBlocState,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: 'Additional instructions ',
                    style: GoogleFonts.inter(
                      color: _navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: '(optional)',
                        style: GoogleFonts.inter(
                          color: _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  noteSubtitle.isNotEmpty
                      ? noteSubtitle
                      : 'Have any specific preferences or noticed something '
                          'missing? Drop us a note!',
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 4,
                  style: GoogleFonts.inter(color: _navy, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: notePlaceholder.isNotEmpty
                        ? notePlaceholder
                        : 'e.g. need a specific brand, flagged a missing '
                            'item, delivery preferences...',
                    hintStyle: GoogleFonts.inter(color: _muted, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _blue, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _questionsBody(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitDisabled ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _blue.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit for review',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionsBody() {
    if (_isLoadingQuestions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_fetchError.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _fetchError,
            style: GoogleFonts.inter(color: const Color(0xFFE14040)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _fetchQuestions, child: const Text('Retry')),
        ],
      );
    }
    if (_visibleQuestions.isEmpty) {
      return Text(
        'No questions are available right now.',
        style: GoogleFonts.inter(color: _muted, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _visibleQuestions.map(_questionTile).toList(),
    );
  }

  Widget _questionTile(Map<String, dynamic> question) {
    final id = question['id']?.toString() ?? '';
    final label = question['question']?.toString() ?? '';
    final isRequired = question['required'] == true;
    final options = (question['options'] as List? ?? const [])
        .whereType<Map>()
        .map((o) => Map<String, dynamic>.from(o))
        .toList();
    final selected = _answers[id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.inter(color: const Color(0xFFE14040)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final value = opt['value']?.toString() ?? opt['label']?.toString() ?? '';
              final optionLabel = opt['label']?.toString() ?? value;
              final isSelected = selected == value;
              return ChoiceChip(
                label: Text(optionLabel),
                selected: isSelected,
                onSelected: (_) => setState(() => _answers[id] = value),
                selectedColor: _blue.withValues(alpha: 0.12),
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.inter(
                  color: isSelected ? _blue : _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: isSelected ? _blue : _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
