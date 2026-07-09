import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/repositories/magic_quote_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/utils/magic_quote_status.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/bloc/magic_quote_bloc.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/add_more_items_sheet.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/delete_confirm_sheet.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/file_tile.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/generating_screen.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';
import 'package:m_o_b_demand_side/shared/image_url.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/quote_item_row.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/results_screen.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/review_questions_sheet.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/review_success_screen.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/swap_product_sheet.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/unread_screen.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/upload_screen.dart';
import 'package:url_launcher/url_launcher.dart';

enum _MagicQuoteScreen { upload, generating, results, unread, reviewSuccess }

/// Orchestrates the Magic Quote flow: holds the intake form state, talks to
/// [MagicQuoteBloc]/[MagicQuoteRepository]/[ProductRepository], and switches between the
/// presentational screens in this folder. Mirrors the web's
/// `pages/home/magic-quote.jsx`, which plays the same role of owning state
/// and wiring it into its own per-screen components.
class MagicAiQuotePage extends StatefulWidget {
  const MagicAiQuotePage({super.key});

  static const String routeName = 'MagicAiQuotePage';
  static const String routePath = '/magic-ai-quote';

  @override
  State<MagicAiQuotePage> createState() => _MagicAiQuotePageState();
}

class _MagicAiQuotePageState extends State<MagicAiQuotePage> {
  static const _navy = MagicQuoteColors.navy;
  static const _blue = MagicQuoteColors.blue;
  static const _muted = MagicQuoteColors.muted;
  static const _border = MagicQuoteColors.border;
  static const _bg = MagicQuoteColors.bg;
  static const _maxFiles = 3;
  static const _maxTotalBytes = 20 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final MagicQuoteBloc _magicQuoteBloc;
  late final MagicQuoteRepository _magicQuoteRepository =
      sl<MagicQuoteRepository>();
  late final ProductRepository _productRepository = sl<ProductRepository>();
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

  final List<PickedMagicQuoteFile> _files = [];
  _MagicQuoteScreen _screen = _MagicQuoteScreen.upload;
  Map<String, dynamic>? _quoteResponse;
  String _generatingStatus = 'Uploading your list';
  String _itemListError = '';

  // ── Live quote-editing state (results screen) ─────────────────────
  // Mirrors the web's ResultsScreen quotePayloadState/itemQuantities/
  // removedItemIds: API mutation responses replace [_quotePayloadOverride]
  // wholesale when the backend returns the refreshed payload; otherwise we
  // fall back to optimistic local bookkeeping in the other three fields.
  Map<String, dynamic>? _quotePayloadOverride;
  final Set<String> _removedItemIds = {};
  final Map<String, num> _itemQuantityOverrides = {};
  String _addingProductSku = '';

  // null = not checked yet, true = serviceable, false = not serviceable
  bool? _pincodeServiceable;
  String _lastCheckedPincode = '';

  @override
  void initState() {
    super.initState();
    _magicQuoteBloc = sl<MagicQuoteBloc>();
    _pincodeController.addListener(_onPincodeChanged);
    _noteController.addListener(_onNoteChanged);
    _prefillForm();
  }

  @override
  void dispose() {
    _magicQuoteBloc.close();
    _pincodeController.removeListener(_onPincodeChanged);
    _noteController.removeListener(_onNoteChanged);
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
    return BlocProvider<MagicQuoteBloc>.value(
      value: _magicQuoteBloc,
      child: BlocConsumer<MagicQuoteBloc, MagicQuoteState>(
        listener: _onMagicQuoteStateChanged,
        builder: (context, state) {
          final submitting = state is MagicQuoteSubmitting;
          return PopScope(
            canPop: _screen == _MagicQuoteScreen.upload,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _handleBack();
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
    if (_screen == _MagicQuoteScreen.reviewSuccess) {
      return const SizedBox.shrink();
    }
    final title = switch (_screen) {
      _MagicQuoteScreen.upload => 'Magic AI Quote',
      _MagicQuoteScreen.generating => 'Reading your list...',
      _MagicQuoteScreen.results => 'Your Quote',
      _MagicQuoteScreen.unread => 'Your Quote',
      _MagicQuoteScreen.reviewSuccess => '',
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
            icon: const AppBackIcon(),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w700,
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
      _MagicQuoteScreen.upload => UploadScreen(
          formKey: _formKey,
          submitting: submitting,
          files: _files,
          maxFiles: _maxFiles,
          noteController: _noteController,
          brandsController: _brandsController,
          nameController: _nameController,
          phoneController: _phoneController,
          pincodeController: _pincodeController,
          cityController: _cityController,
          stateController: _stateController,
          projectController: _projectController,
          gstController: _gstController,
          emailController: _emailController,
          noteFocusNode: _noteFocusNode,
          pincodeServiceable: _pincodeServiceable,
          itemListError: _itemListError,
          onTapDropzone: _showUploadOptionsSheet,
          onRemoveFile: (file) => setState(() => _files.remove(file)),
          onPreviewFile: _previewPickedFile,
        ),
      _MagicQuoteScreen.generating => GeneratingScreen(
          pincode: _pincodeController.text.trim(),
          currentStatus: _generatingStatus,
        ),
      _MagicQuoteScreen.results => ResultsScreen(
          payload: _currentPayload(),
          city: _payloadCity(),
          pincode: _payloadPincode(),
          hasUploadsContext: _hasUploadsContext,
          addingProductSku: _addingProductSku,
          quantityOf: _itemQuantity,
          onQuantityChange: _handleQuantityChange,
          onDeleteItem: _handleDeleteItem,
          onChangeItem: _handleChangeItem,
          onShowAddMoreItems: _showAddMoreItemsSheet,
          onAddRecommended: _handleAddProductBySku,
          onShowUploadsViewer: _showUploadsViewer,
          onShowHelp: _showHelpMenu,
        ),
      _MagicQuoteScreen.unread => _unreadScreen(),
      _MagicQuoteScreen.reviewSuccess => ReviewSuccessScreen(
          rfqNumber: stringValueOf(
            mapValueOf(_currentPayload(), 'rfq_order'),
            const ['rfq_id', 'id'],
          ),
          onBackHome: () => context.go('/'),
          onViewRfqs: () => context.push('/rfqs'),
        ),
    };
  }

  Widget _unreadScreen() {
    final payload = magicQuotePayloadOf(_quoteResponse);
    final quote = mapValueOf(payload, 'quote');
    final rfqOrder = mapValueOf(payload, 'rfq_order');
    return UnreadScreen(
      quoteId: firstNonEmptyOf([
        stringValueOf(quote, const ['id', 'quote_id']),
        stringValueOf(rfqOrder, const ['last_quote_index']),
      ]),
      rfqNumber: stringValueOf(rfqOrder, const ['rfq_id', 'id']),
      city: _payloadCity(),
      pincode: _payloadPincode(),
      hasUploadsContext: _hasUploadsContext,
      onShowUploadsViewer: _showUploadsViewer,
      onOpenWhatsApp: _openWhatsApp,
    );
  }

  Widget? _bottomBar(bool submitting) {
    final action = switch (_screen) {
      _MagicQuoteScreen.upload => _BottomAction(
          label: 'Get Magic AI Quote',
          icon: Icons.auto_awesome,
          onPressed:
              submitting || _pincodeServiceable == false ? null : _submit,
        ),
      _MagicQuoteScreen.results => _BottomAction(
          label: 'Add note & submit',
          icon: Icons.check_circle_outline,
          onPressed: _showReviewQuestionsSheet,
        ),
      _MagicQuoteScreen.unread => _BottomAction(
          label: 'Upload another list',
          icon: Icons.upload_file_outlined,
          onPressed: _resetToUpload,
        ),
      _MagicQuoteScreen.reviewSuccess => null,
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
              disabledBackgroundColor: _blue.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasUploadsContext =>
      _files.isNotEmpty ||
      _noteController.text.trim().isNotEmpty ||
      _apiUploadedFileUrl().isNotEmpty;

  // ── "Submit for review" / "Add more items" sheets ──────────────────

  Future<void> _showReviewQuestionsSheet() async {
    final quote = mapValueOf(_currentPayload(), 'quote');
    final quoteId = stringValueOf(quote, const ['id', 'quote_id']);
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
        return ReviewQuestionsSheet(
          magicQuoteBloc: _magicQuoteBloc,
          quoteId: quoteId,
          onSubmitted: () {
            Navigator.of(sheetContext).pop();
            setState(() => _screen = _MagicQuoteScreen.reviewSuccess);
          },
        );
      },
    );
  }

  Future<void> _showAddMoreItemsSheet(String quoteId) async {
    if (quoteId.isEmpty) {
      _showMessage('Unable to find this quote. Please try again.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return AddMoreItemsSheet(
          productRepository: _productRepository,
          magicQuoteRepository: _magicQuoteRepository,
          quoteId: quoteId,
          onAdded:
              (Map<String, dynamic>? payload, Map<String, dynamic>? addedItem) {
            setState(() {
              if (payload != null) {
                _quotePayloadOverride = payload;
              } else if (addedItem != null) {
                final current = _currentPayload();
                final items = [...itemsOf(current), addedItem];
                _quotePayloadOverride = {...current, 'items': items};
              }
            });
          },
        );
      },
    );
  }

  Future<void> _showHelpMenu() async {
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
                  'Need help?',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _sheetOptionRow(
                  icon: Icons.chat_bubble,
                  label: 'WhatsApp us',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openWhatsApp();
                  },
                ),
                _sheetOptionRow(
                  icon: Icons.call,
                  label: 'Call us',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _callSupport();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _callSupport() async {
    final ok = await launchUrl(Uri.parse('tel:+918660423608'));
    if (!ok) _showMessage('Unable to start a call.');
  }

  Future<void> _openWhatsApp() async {
    final ok = await launchUrl(
      Uri.parse('https://wa.me/918970415365'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) _showMessage('Unable to open WhatsApp.');
  }

  void _previewPickedFile(PickedMagicQuoteFile file) {
    final bytes = file.file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      _showFilePreview(file.name, bytes);
    }
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

  Future<void> _openApiUploadedFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Unable to open this file.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _showMessage('Unable to open this file.');
  }

  Future<void> _showUploadsViewer() async {
    final note = _noteController.text.trim();
    final apiUploadedFile = _apiUploadedFileUrl();
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
                    children: [
                      ..._files.map(
                        (file) => MagicQuoteFileTile(
                          file: file,
                          removable: false,
                          onPreview: () => _previewPickedFile(file),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_files.isEmpty && apiUploadedFile.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Files (1)',
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ApiUploadedFileTile(
                    url: apiUploadedFile,
                    onTap: () => _openApiUploadedFile(apiUploadedFile),
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

  // ── Live quote mutations (qty / delete / add) ───────────────────────

  /// The current quote payload, preferring any live edits
  /// ([_quotePayloadOverride]) over the original create/socket response.
  Map<String, dynamic> _currentPayload() => _withoutRemovedItems(
      _quotePayloadOverride ?? magicQuotePayloadOf(_quoteResponse));

  Map<String, dynamic> _withoutRemovedItems(Map<String, dynamic> payload) {
    if (_removedItemIds.isEmpty) return payload;
    final items = itemsOf(payload)
        .where((item) => !_removedItemIds.contains(_itemId(item)))
        .toList(growable: false);
    return {...payload, 'items': items};
  }

  String _payloadCity() {
    final rfqOrder = mapValueOf(_currentPayload(), 'rfq_order');
    return firstNonEmptyOf([
      stringValueOf(rfqOrder, const ['city', 'delivery_city']),
      _cityController.text,
    ]);
  }

  String _payloadPincode() {
    final rfqOrder = mapValueOf(_currentPayload(), 'rfq_order');
    return firstNonEmptyOf([
      stringValueOf(rfqOrder, const ['delivery_pincode', 'pincode']),
      _pincodeController.text,
    ]);
  }

  String _apiUploadedFileUrl() {
    final payload =
        _quotePayloadOverride ?? magicQuotePayloadOf(_quoteResponse);
    final rfqOrder = mapValueOf(payload, 'rfq_order');
    return firstNonEmptyOf([
      stringValueOf(payload, const ['uploaded_file', 'rfq_file']),
      stringValueOf(rfqOrder, const ['rfq_file', 'uploaded_file']),
    ]);
  }

  String _itemId(Map<String, dynamic> item) => item['id']?.toString() ?? '';

  num _itemQuantity(Map<String, dynamic> item) {
    final id = _itemId(item);
    return _itemQuantityOverrides[id] ?? moneyValueOf(item, const ['quantity']);
  }

  Future<void> _handleQuantityChange(
    Map<String, dynamic> item,
    bool increase,
  ) async {
    final itemId = _itemId(item);
    if (itemId.isEmpty) return;
    final (payload, failure) =
        await _magicQuoteRepository.changeMagicQuoteItemQuantity(
      itemId: itemId,
      increase: increase,
    );
    if (!mounted) return;
    if (failure != null) {
      _showMessage(failure.message);
      return;
    }
    setState(() {
      if (payload != null) {
        _quotePayloadOverride = payload;
      } else {
        final current = _itemQuantity(item);
        _itemQuantityOverrides[itemId] =
            increase ? current + 1 : (current - 1).clamp(0, double.infinity);
      }
    });
  }

  Future<void> _handleDeleteItem(Map<String, dynamic> item) async {
    final itemId = _itemId(item);
    if (itemId.isEmpty) return;
    final product = mapValueOf(item, 'product');
    final name = firstNonEmptyOf([
      stringValueOf(item, const ['name', 'product_name']),
      stringValueOf(product, const ['product_name', 'name']),
    ]);
    final price = moneyValueOf(item, const ['price_after_tax', 'price']);
    final imageUrl = sanitizeImageUrl(firstNonEmptyOf([
      stringValueOf(product, const ['product_image', 'image']),
      stringValueOf(item, const ['product_image']),
    ]));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DeleteConfirmSheet(
          name: name.isEmpty ? 'Product' : name,
          price: price,
          imageUrl: imageUrl,
          onConfirm: () => _deleteItem(itemId),
        );
      },
    );
  }

  Future<bool> _deleteItem(String itemId) async {
    final (payload, failure) =
        await _magicQuoteRepository.deleteMagicQuoteItem(itemId);
    if (!mounted) return false;
    if (failure != null) {
      _showMessage(failure.message);
      return false;
    }
    setState(() {
      if (payload != null) {
        _quotePayloadOverride = payload;
      } else {
        _removedItemIds.add(itemId);
      }
    });
    return true;
  }

  Future<void> _handleChangeItem(Map<String, dynamic> item) async {
    final itemId = _itemId(item);
    final sku = magicQuoteItemSku(item);
    if (itemId.isEmpty || sku.isEmpty) {
      _showMessage('Unable to find this product. Please try again.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SwapProductSheet(
          productRepository: _productRepository,
          magicQuoteRepository: _magicQuoteRepository,
          itemId: itemId,
          mobSku: sku,
          city: _cityController.text.trim(),
          onReplaced: (payload) {
            setState(() {
              if (payload != null) _quotePayloadOverride = payload;
            });
          },
        );
      },
    );
  }

  Future<void> _handleAddProductBySku(String sku) async {
    final quote = mapValueOf(_currentPayload(), 'quote');
    final quoteId = stringValueOf(quote, const ['id', 'quote_id']);
    if (quoteId.isEmpty || sku.isEmpty || _addingProductSku.isNotEmpty) return;

    setState(() => _addingProductSku = sku);
    final (payload, addedItem, failure) =
        await _magicQuoteRepository.addMagicQuoteItem(
      quoteId: quoteId,
      mobSku: sku,
    );
    if (!mounted) return;
    if (failure != null) {
      setState(() => _addingProductSku = '');
      _showMessage(failure.message);
      return;
    }
    setState(() {
      if (payload != null) {
        _quotePayloadOverride = payload;
      } else if (addedItem != null) {
        final current = _currentPayload();
        final items = [...itemsOf(current), addedItem];
        _quotePayloadOverride = {...current, 'items': items};
      }
      _addingProductSku = '';
    });
  }

  // ── Pincode serviceability ───────────────────────────────────────────

  void _onNoteChanged() {
    if (_itemListError.isNotEmpty && _noteController.text.trim().isNotEmpty) {
      setState(() => _itemListError = '');
    }
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
        const [
          'serviceable',
          'is_serviceable',
          'isServiceable',
          'deliverable',
          'status'
        ],
      );
      final isServiceable =
          serviceableFlag ?? (state.isNotEmpty && city.isNotEmpty);
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
      if (nestedData is Map) {
        candidates.add(Map<String, dynamic>.from(nestedData));
      }
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
          return value.toLowerCase() == 'serviceable' ||
              value.toLowerCase() == 'true';
        }
      }
    }
    return null;
  }

  // ── Prefill / upload-options-sheet / file picking ───────────────────

  Future<void> _prefillForm() async {
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _nameController.text = stringValueOf(user, const [
      'name',
      'full_name',
      'first_name',
      'customer_name',
    ]);
    _phoneController.text = _onlyDigits(
      stringValueOf(user, const [
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
    _emailController.text = stringValueOf(user, const ['email']);

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
                _sheetOptionRow(
                  icon: Icons.photo_camera_outlined,
                  label: 'Use Camera',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickFromCamera();
                  },
                ),
                _sheetOptionRow(
                  icon: Icons.image_outlined,
                  label: 'Upload from Gallery',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickFromGallery();
                  },
                ),
                _sheetOptionRow(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'Pick PDF / Excel / Doc',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickDocuments();
                  },
                ),
                _sheetOptionRow(
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

  Widget _sheetOptionRow({
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
      PickedMagicQuoteFile(
        name: shot.name,
        size: bytes.length,
        file: FFUploadedFile(name: shot.name, bytes: bytes),
      ),
    ]);
  }

  Future<void> _pickFromGallery() async {
    final shots = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted || shots.isEmpty) return;
    final picked = <PickedMagicQuoteFile>[];
    for (final shot in shots) {
      final bytes = await shot.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage('Unable to read ${shot.name}.');
        continue;
      }
      picked.add(
        PickedMagicQuoteFile(
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

    final picked = <PickedMagicQuoteFile>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Unable to read ${file.name}.');
        continue;
      }
      picked.add(
        PickedMagicQuoteFile(
          name: file.name,
          size: file.size,
          file: FFUploadedFile(name: file.name, bytes: bytes),
        ),
      );
    }
    await _addPickedFiles(picked);
  }

  Future<void> _addPickedFiles(List<PickedMagicQuoteFile> picked) async {
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
      _itemListError = '';
    });
  }

  // ── Submit / quote-response handling ─────────────────────────────────

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_files.isEmpty && _noteController.text.trim().isEmpty) {
      setState(() => _itemListError = 'Upload a file or type your item list.');
      _noteFocusNode.requestFocus();
      return;
    }

    setState(() {
      _screen = _MagicQuoteScreen.generating;
      _quoteResponse = null;
      _generatingStatus = 'Uploading your list';
    });
    _magicQuoteBloc.add(
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

  void _onMagicQuoteStateChanged(BuildContext context, MagicQuoteState state) {
    if (state is MagicQuoteProgress) {
      setState(() => _generatingStatus = state.status);
      return;
    }
    if (state is MagicQuoteSubmitted) {
      setState(() {
        _quoteResponse = state.response;
        _resetQuoteEditingState();
        if (magicQuoteUploadedFileCountOf(state.response) == 0) {
          _screen = _MagicQuoteScreen.reviewSuccess;
        } else {
          _screen = magicQuoteHasGeneratedItems(state.response)
              ? _MagicQuoteScreen.results
              : _MagicQuoteScreen.unread;
        }
      });
      return;
    }
    if (state is MagicQuoteError) {
      setState(() => _screen = _MagicQuoteScreen.upload);
      _showMessage(state.message);
      return;
    }
    if (state is MagicQuoteRateLimited) {
      setState(() => _screen = _MagicQuoteScreen.upload);
      _showRateLimitSheet(state.message);
    }
  }

  Future<void> _showRateLimitSheet(String message) async {
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
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCDACC),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/ratelimit.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Request limit reached',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'To ensure fair usage and prevent robotic activity, Magic Quote is limited to 3 requests every 30 minutes. Please try again in sometime.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _muted,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Okay',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      _resetQuoteEditingState();
    });
  }

  void _resetQuoteEditingState() {
    _quotePayloadOverride = null;
    _removedItemIds.clear();
    _itemQuantityOverrides.clear();
    _addingProductSku = '';
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ApiUploadedFileTile extends StatelessWidget {
  const _ApiUploadedFileTile({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(url);
    final ext = _extension(name).toUpperCase();
    const tileSize = 84.0;
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: const Color(0xFFF7F9FC),
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: Center(
                    child: Text(
                      ext.isEmpty ? 'FILE' : ext,
                      style: GoogleFonts.inter(
                        color: MagicQuoteColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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
                name,
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
        ],
      ),
    );
  }

  static String _displayName(String url) {
    final path = url.split(RegExp(r'[?#]')).first;
    final name = path.split('/').last;
    if (name.isEmpty) return 'uploaded-file';
    try {
      return Uri.decodeComponent(name);
    } catch (_) {
      return name;
    }
  }

  static String _extension(String name) {
    if (!name.contains('.')) return '';
    return name.split('.').last;
  }
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
