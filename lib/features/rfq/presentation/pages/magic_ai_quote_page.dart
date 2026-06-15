import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_success_page.dart';

class MagicAiQuotePage extends StatefulWidget {
  const MagicAiQuotePage({super.key});

  static const String routeName = 'MagicAiQuotePage';
  static const String routePath = '/magic-ai-quote';

  @override
  State<MagicAiQuotePage> createState() => _MagicAiQuotePageState();
}

class _MagicAiQuotePageState extends State<MagicAiQuotePage> {
  static const _navy = Color(0xFF092743);
  static const _muted = Color(0xFF858585);
  static const _border = Color(0xFFD1D5D8);
  static const _blue = Color(0xFF0968E8);

  final _formKey = GlobalKey<FormState>();
  late final RfqBloc _rfqBloc;
  final _noteController = TextEditingController();
  final _brandsController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController(text: '411013');
  final _projectController = TextEditingController();
  final _gstinController = TextEditingController();
  final _emailController = TextEditingController();

  String _deliveryLocation = 'Bengaluru';
  bool _isHowItWorksExpanded = false;
  FFUploadedFile? _selectedFile;
  int _selectedFileSize = 0;

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>();
  }

  @override
  void dispose() {
    _rfqBloc.close();
    _noteController.dispose();
    _brandsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _projectController.dispose();
    _gstinController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: BlocConsumer<RfqBloc, RfqState>(
        listener: _onRfqStateChanged,
        builder: (context, state) => _buildPage(state is MagicQuoteSubmitting),
      ),
    );
  }

  Widget _buildPage(bool isSubmitting) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 28),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Image.asset(
                      'assets/images/magicquote.jpeg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildListCard(),
                          const SizedBox(height: 14),
                          _buildDetailsCard(),
                          const SizedBox(height: 14),
                          _buildDeliveryNotice(),
                          const SizedBox(height: 14),
                          _buildHowItWorks(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomAction(isSubmitting: isSubmitting),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 21),
            color: _navy,
          ),
          const SizedBox(width: 5),
          Text(
            'Magic AI Quote',
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Send us your list'),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Add your list or BOQ',
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickFile,
              child: CustomPaint(
                painter: const _DashedBorderPainter(
                  color: Color(0xFFC8CDD0),
                  radius: 14,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 42,
                          weight: 300,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add your list/ BOQ',
                              style: GoogleFonts.inter(
                                color: _navy,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedFile == null
                                  ? 'Photo, PDF, Excel or text\nMax 1 file | 20 MB'
                                  : '${_selectedFile!.name}\n'
                                      '${_formatFileSize(_selectedFileSize)}',
                              style: GoogleFonts.inter(
                                color: _muted,
                                fontSize: 14,
                                height: 1.45,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedFile != null)
                        IconButton(
                          tooltip: 'Remove file',
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _selectedFileSize = 0;
                            });
                          },
                          icon: const Icon(Icons.close, color: _navy),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _labeledField(
            label: 'Add note',
            optional: true,
            controller: _noteController,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: 'Preferred brands',
            optional: true,
            controller: _brandsController,
            hintText: 'e.g. Asian Paints, Jaquar, Havells',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your details'),
          const SizedBox(height: 18),
          _labeledField(
            label: 'Name',
            required: true,
            controller: _nameController,
            hintText: 'Your name',
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: 'Phone',
            required: true,
            controller: _phoneController,
            hintText: '10 digits',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) => value == null || value.trim().length != 10
                ? 'Enter a valid 10-digit phone number'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLocationField()),
              const SizedBox(width: 14),
              Expanded(
                child: _labeledField(
                  label: 'Delivery pincode',
                  required: true,
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) =>
                      value == null || value.trim().length != 6
                          ? 'Enter 6 digits'
                          : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: 'Project name',
            optional: true,
            controller: _projectController,
            hintText: 'e.g. Whitefield Villa Renovation',
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: 'GSTIN',
            optional: true,
            controller: _gstinController,
            hintText: '15-digit GSTIN',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(15)],
          ),
          const SizedBox(height: 16),
          _labeledField(
            label: 'Email',
            optional: true,
            controller: _emailController,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Delivery location', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _deliveryLocation,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _navy),
          decoration: _inputDecoration(),
          style: GoogleFonts.inter(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: const ['Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad', 'Chennai']
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(city, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _deliveryLocation = value);
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryNotice() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE1D7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.local_shipping,
                  color: Color(0xFF008B7E),
                  size: 31,
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.schedule, color: _navy, size: 17),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is a planned delivery',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Same/next-day for available stock. Brand timelines apply '
                  'for custom orders.',
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
      ),
    );
  }

  Widget _buildHowItWorks() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _isHowItWorksExpanded = !_isHowItWorksExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 15),
              child: Row(
                children: [
                  Expanded(child: _sectionTitle('How it works')),
                  AnimatedRotation(
                    turns: _isHowItWorksExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 18, 22),
                  child: Column(
                    children: [
                      _howStep(
                        number: 1,
                        title: 'Upload list',
                        subtitle: 'Photo, PDF, Excel or text',
                      ),
                      const SizedBox(height: 22),
                      _howStep(
                        number: 2,
                        title: 'Get Magic AI Quote in 30 secs',
                        subtitle: 'We match brands, sizes & in-stock prices',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isHowItWorksExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _howStep({
    required int number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F8),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: _muted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction({required bool isSubmitting}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F6),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Magic AI Quote',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.auto_awesome_outlined, size: 22),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool optional = false,
    String? hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required: required, optional: optional),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          minLines: minLines,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: _navy, fontSize: 16),
          decoration: _inputDecoration(hintText: hintText),
        ),
      ],
    );
  }

  Widget _fieldLabel(
    String label, {
    bool required = false,
    bool optional = false,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.inter(
                color: const Color(0xFFE05B55),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (optional)
            TextSpan(
              text: '  (optional)',
              style: GoogleFonts.inter(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: _muted, fontSize: 16),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      constraints: const BoxConstraints(minHeight: 56),
      border: _fieldBorder(),
      enabledBorder: _fieldBorder(),
      focusedBorder: _fieldBorder(color: _blue, width: 1.5),
      errorBorder: _fieldBorder(color: const Color(0xFFE05B55)),
      focusedErrorBorder:
          _fieldBorder(color: const Color(0xFFE05B55), width: 1.5),
    );
  }

  OutlineInputBorder _fieldBorder({Color color = _border, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: _navy,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'xls',
        'xlsx',
        'csv',
        'txt',
      ],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > 20 * 1024 * 1024) {
      _showMessage('Please select a file smaller than 20 MB.');
      return;
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage('Unable to read the selected file.');
      return;
    }

    setState(() {
      _selectedFile = FFUploadedFile(name: file.name, bytes: bytes);
      _selectedFileSize = file.size;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final image = _selectedFile;
    if (image == null) {
      _showMessage('Please add your list or BOQ.');
      return;
    }

    _rfqBloc.add(
      MagicQuoteSubmitRequested(
        image: image,
        payload: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'state': _stateForCity(_deliveryLocation),
          'city': _deliveryLocation,
          'delivery_pincode': _pincodeController.text.trim(),
          'email': _emailController.text.trim(),
          'note': _noteController.text.trim(),
          'preferred_brands': _brandsController.text.trim(),
        },
      ),
    );
  }

  void _onRfqStateChanged(BuildContext context, RfqState state) {
    if (state is MagicQuoteSubmitted) {
      context.go(RfqSuccessPage.routePath);
      return;
    }
    if (state is MagicQuoteError) {
      _showMessage(state.message);
    }
  }

  String _stateForCity(String city) {
    return switch (city) {
      'Mumbai' => 'Maharashtra',
      'Delhi' => 'Delhi',
      'Hyderabad' => 'Telangana',
      'Chennai' => 'Tamil Nadu',
      _ => 'Karnataka',
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

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
          Radius.circular(radius),
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
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
