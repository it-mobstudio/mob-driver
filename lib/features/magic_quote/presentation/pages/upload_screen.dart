import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/file_tile.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';
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
  final VoidCallback onTapDropzone;
  final void Function(PickedMagicQuoteFile file) onRemoveFile;
  final void Function(PickedMagicQuoteFile file) onPreviewFile;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                Image.asset(
                  'assets/images/magicquote.jpeg',
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
                // Positioned(
                //   top: 18,
                //   left: 20,
                //   child: SvgPicture.asset(
                //     'assets/images/banner-spark.svg',
                //     width: 28,
                //     height: 28,
                //   ),
                // ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: _cards(context),
          ),
        ],
      ),
    );
  }

  Widget _cards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MagicQuoteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MagicQuoteSectionTitle('Upload or type item list'),
              const SizedBox(height: 12),
              Text(
                'Use at least one option. Photo, PDF, Excel or text - up to 20 MB',
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              _field(
                'Type item list',
                noteController,
                hint:
                    'Add product details, quantities, sizes, or special requirements',
                focusNode: noteFocusNode,
                minLines: 3,
                maxLines: 4,
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
              const SizedBox(height: 14),
              _field(
                'Preferred brands',
                brandsController,
                optional: true,
                hint: 'e.g. Asian Paints, Jaquar, Havells',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        MagicQuoteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MagicQuoteSectionTitle('Your details'),
              const SizedBox(height: 14),
              _field(
                'Name',
                nameController,
                required: true,
                validator: (value) => _required(value, 'Please enter name'),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 18),
              _field(
                'Project name',
                projectController,
                optional: true,
                hint: 'e.g. Koramangala site',
              ),
              const SizedBox(height: 18),
              _field(
                'GSTIN',
                gstController,
                optional: true,
                hint: '15-digit GSTIN',
                inputFormatters: gstInputFormatters,
                validator: optionalGstValidator,
              ),
              const SizedBox(height: 18),
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
        _infoCard(),
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

  Widget _infoCard() {
    return MagicQuoteCard(
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
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/rfq_truck_timer.svg',
              width: 30,
              height: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Magic Quote works',
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Upload a BOQ or type your list. We match products and prepare a quote for review.',
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.muted,
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
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: Color(0xFFC5CCD5)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 54,
                height: 54,
                transformAlignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scaleByDouble(
                    _active ? 1.05 : 1.0,
                    _active ? 1.05 : 1.0,
                    _active ? 1.05 : 1.0,
                    1.0,
                  )
                  ..rotateZ(_active ? math.pi / 2 : 0),
                decoration: BoxDecoration(
                  color:
                      _active ? const Color(0xFF0A243F) : MagicQuoteColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.files.isEmpty
                          ? 'Add your list/ BOQ'
                          : 'Add more files',
                      style: GoogleFonts.inter(
                        color: MagicQuoteColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Photo, PDF, Excel or paste text\nMax ${widget.maxFiles} files · 20 MB',
                      style: GoogleFonts.inter(
                        color: MagicQuoteColors.muted,
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
