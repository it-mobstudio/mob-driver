import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/file_tile.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';
import 'package:m_o_b_demand_side/shared/widgets/frosted_nav_bar.dart';
import 'package:m_o_b_demand_side/shared/validators/gst_validator.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

/// The "Send us your BOQ" intake form: file dropzone + picked-file tiles,
/// note/brands fields, and the customer-details fields (name, phone,
/// pincode, auto-filled city/state, project, GSTIN, email). Mirrors the
/// web's MagicQuote/UploadScreen.jsx — file picking itself (camera/gallery/
/// document plugins) stays in the orchestrator page since it's native
/// platform logic, not presentation.
class UploadScreen extends StatelessWidget {
  const UploadScreen({
    super.key,
    required this.formKey,
    required this.submitting,
    required this.files,
    required this.maxFiles,
    required this.noteController,
    required this.brandsController,
    required this.nameController,
    required this.phoneController,
    required this.pincodeController,
    required this.cityController,
    required this.stateController,
    required this.projectController,
    required this.gstController,
    required this.emailController,
    required this.noteFocusNode,
    required this.pincodeServiceable,
    required this.itemListError,
    required this.onBack,
    required this.onOpenWhatsApp,
    required this.onTapDropzone,
    required this.onRemoveFile,
    required this.onPreviewFile,
  });

  final GlobalKey<FormState> formKey;
  final bool submitting;
  final List<PickedMagicQuoteFile> files;
  final int maxFiles;
  final TextEditingController noteController;
  final TextEditingController brandsController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController pincodeController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController projectController;
  final TextEditingController gstController;
  final TextEditingController emailController;
  final FocusNode noteFocusNode;
  final bool? pincodeServiceable;
  final String itemListError;
  final VoidCallback onBack;
  final VoidCallback onOpenWhatsApp;
  final VoidCallback onTapDropzone;
  final void Function(PickedMagicQuoteFile file) onRemoveFile;
  final void Function(PickedMagicQuoteFile file) onPreviewFile;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: _hero(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: _cards(context),
              ),
            ],
          ),
          FrostedNavBar(
            onBack: onBack,
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      height: 360,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF021107),
            Color(0xFF007736),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 101,
            child: Text(
              'Share your requirement to get',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
          ),
          Positioned(
            top: 120,
            child: Text(
              'Magic AI quote ✦',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 48 / 28,
              ),
            ),
          ),
          Positioned(
            top: 174,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE600),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(-1, 1),
                  ),
                ],
              ),
              child: Text(
                'In 60 secs',
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 14 / 14,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                minHeight: 360,
                maxHeight: 360,
                child: Image.asset(
                  'assets/images/magicquote.jpeg',
                  width: double.infinity,
                  height: 360,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicQuoteSectionTitle(
          'Upload or type item list *',
          fontSize: 15,
        ),
        const SizedBox(height: 2),
        Text(
          'Use at least one option',
          style: GoogleFonts.inter(
            color: const Color(0xFF596378),
            fontSize: 11,
            height: 16 / 11,
          ),
        ),
        const SizedBox(height: 12),
        MagicQuoteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dropZone(),
              if (files.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: files
                      .map(
                        (file) => MagicQuoteFileTile(
                          file: file,
                          onRemove: () => onRemoveFile(file),
                          onPreview: () => onPreviewFile(file),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              _field(
                'Type item list',
                noteController,
                hint: 'Type item list',
                focusNode: noteFocusNode,
                hasError: itemListError.isNotEmpty,
              ),
              if (itemListError.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  itemListError,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE14040),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _field(
                'Preferred brands',
                brandsController,
                optional: true,
                hint: 'Preferred brands',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const MagicQuoteSectionTitle('Your details', fontSize: 15),
        const SizedBox(height: 12),
        MagicQuoteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                'Name',
                nameController,
                required: true,
                validator: (value) => _required(value, 'Please enter name'),
              ),
              const SizedBox(height: 12),
              _field(
                'Phone',
                phoneController,
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
              const SizedBox(height: 12),
              _field(
                'Delivery pincode',
                pincodeController,
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
              if (pincodeServiceable == false) ...[
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
                        "We don't deliver to ${pincodeController.text.trim()} yet",
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
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      'City',
                      cityController,
                      required: true,
                      enabled: false,
                      hint: 'Auto-filled from pincode',
                      validator: (value) =>
                          _required(value, 'Please enter a valid pincode'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      'State',
                      stateController,
                      required: true,
                      enabled: false,
                      hint: 'Auto-filled from pincode',
                      validator: (value) =>
                          _required(value, 'Please enter a valid pincode'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                'Project name',
                projectController,
                optional: true,
                hint: 'e.g. Koramangala site',
              ),
              const SizedBox(height: 12),
              _field(
                'GSTIN',
                gstController,
                optional: true,
                hint: '15-digit GSTIN',
                inputFormatters: gstInputFormatters,
                validator: optionalGstValidator,
              ),
              const SizedBox(height: 12),
              _field(
                'Email',
                emailController,
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
        _plannedDeliveryCard(),
        const SizedBox(height: 14),
        const MagicQuoteHowItWorksCard(),
        const SizedBox(height: 24),
        MagicQuoteHelpCard(onChat: onOpenWhatsApp),
      ],
    );
  }

  Widget _dropZone() {
    return _UploadDropZone(
      submitting: submitting,
      files: files,
      maxFiles: maxFiles,
      onTap: onTapDropzone,
    );
  }

  Widget _plannedDeliveryCard() {
    return MagicQuoteCard(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 76),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is a planned delivery',
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 22 / 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Same/next-day for available stock. Brand timelines apply for custom orders.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF596378),
                    fontSize: 11,
                    height: 16 / 11,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/mobvehicle.webp',
            width: 82,
            height: 54,
            fit: BoxFit.contain,
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
    bool hasError = false,
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
      errorBuilder: (context, errorText) => Transform.translate(
        offset: const Offset(-16, 0),
        child: Text(
          errorText,
          style: AppTextFieldStyles.error,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      minLines: minLines,
      maxLines: maxLines,
      style: AppTextFieldStyles.inputText.copyWith(
        color: enabled
            ? AppTextFieldColors.primaryText
            : AppTextFieldColors.inputHint,
      ),
      decoration: appTextFieldDecoration(
        label: labelText,
        hintText: hint,
        floatingLabelBehavior: hasError
            ? FloatingLabelBehavior.always
            : FloatingLabelBehavior.auto,
        enabled: enabled,
      ).copyWith(
        enabledBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTextFieldColors.error,
                  width: 1.5,
                ),
              )
            : null,
      ),
    );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }
}

class _UploadDropZone extends StatefulWidget {
  const _UploadDropZone({
    required this.submitting,
    required this.files,
    required this.maxFiles,
    required this.onTap,
  });

  final bool submitting;
  final List<PickedMagicQuoteFile> files;
  final int maxFiles;
  final VoidCallback onTap;

  @override
  State<_UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<_UploadDropZone> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _active => !widget.submitting && (_hovered || _pressed);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.submitting ? null : widget.onTap,
      onHover: (value) => setState(() => _hovered = value),
      onHighlightChanged: (value) => setState(() => _pressed = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: _active ? const Color(0xFFF2F7F4) : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: -32,
              child: SvgPicture.asset(
                'assets/images/magicquoteadd.svg',
                width: 64,
                height: 64,
              ),
            ),
            Positioned(
              top: 40,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  Text(
                    widget.files.isEmpty
                        ? 'Add your list/ BOQ'
                        : 'Add more files',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: MagicQuoteColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Photo, PDF, Excel or paste text. Max ${widget.maxFiles} files · 20 MB',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: MagicQuoteColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
