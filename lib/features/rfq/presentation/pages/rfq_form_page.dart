// lib/rfq/rfq_form_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/validators/gst_validator.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'rfq_success_page.dart';

class RfqFormPage extends StatefulWidget {
  const RfqFormPage({super.key});

  static const String routeName = 'RfqFormPage';
  static const String routePath = '/rfq';

  @override
  State<RfqFormPage> createState() => _RfqFormPageState();
}

class _RfqFormPageState extends State<RfqFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController(text: '');
  final _phone = TextEditingController(text: '');
  final _email = TextEditingController(text: '');
  final _gst = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();

  bool _howWorksExpanded = false;
  bool _fileAttached = true; // mock state for the sample tile

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _gst.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Content
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                GestureDetector(
                  onTap: () => GoRouter.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: AppBackIcon(),
                  ),
                ),
                Text('Request for quotation',
                    style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Tell us about your requirement',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF6C7C8C))),
                const SizedBox(height: 16),
                _sectionHeader('Customer details',
                    leading: Icons.person_2_outlined),
                const SizedBox(height: 8),
                _formCard(context),
                const SizedBox(height: 16),
                _sectionHeader('Select photos or files',
                    leading: Icons.insert_drive_file_outlined),
                const SizedBox(height: 8),
                _uploadCard(),
                const SizedBox(height: 12),
                if (_fileAttached)
                  _attachedFileTile(onRemove: () {
                    setState(() => _fileAttached = false);
                  }),
                const SizedBox(height: 16),
                _howItWorksCard(),
              ],
            ),

            // Fixed footer CTA (mockup 1 & 2)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, -4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Submit RFQ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- pieces ----------

  Widget _sectionHeader(String title, {IconData? leading}) {
    return Row(
      children: [
        if (leading != null)
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF2F6F9),
            child: Icon(leading, color: const Color(0xFF0A243F), size: 18),
          ),
        if (leading != null) const SizedBox(width: 8),
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    InputDecoration deco(String hint, {String? helper}) => InputDecoration(
          hintText: hint,
          helperText: helper,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(controller: _name, decoration: deco('Name*')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: deco('Phone number*')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: deco('Email Id')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gst,
              decoration: deco('GSTIN (optional)'),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: gstInputFormatters,
              validator: optionalGstValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _city, decoration: deco('City')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _pincode,
                keyboardType: TextInputType.number,
                decoration: deco('Delivery pincode')),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
            color: const Color(0xFFDDE5EE), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        // borderOnForeground: true,
      ),
      child: Column(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE6ECF4),
                  style: BorderStyle.solid,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside),
              // borderStyle: BorderStyle.solid,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline,
                    size: 22, color: Color(0xFF0A243F)),
                const SizedBox(height: 6),
                Text('Add new file',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('xls, doc, pdf, jpeg, png - upto 10 mb',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF6C7C8C))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachedFileTile({required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.7,
                    minHeight: 8,
                    backgroundColor: Color(0xFFEAF0FE),
                    valueColor: AlwaysStoppedAnimation(Color(0xFF2B7FFF)),
                  ),
                ),
                const SizedBox(height: 6),
                Text('5.4mb',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6C7C8C))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }

  Widget _howItWorksCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _howWorksExpanded,
          onExpansionChanged: (v) => setState(() => _howWorksExpanded = v),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How RFQ works',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('View all steps',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF6C7C8C))),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _howItem(1, 'Submit Request',
                'Submit your requirements through the RFQ form'),
            const SizedBox(height: 12),
            _howItem(2, 'Receive Quotation',
                'You will receive a quotation from our side within 24 hrs'),
            const SizedBox(height: 12),
            _howItem(3, 'Finalise',
                'If you like the quotes finalise the order and get it delivered'),
          ],
        ),
      ),
    );
  }

  Widget _howItem(int step, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
            radius: 18, backgroundColor: Colors.white, child: Text('$step')),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(desc,
                  style: GoogleFonts.inter(color: const Color(0xFF6C7C8C))),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? true) {
      GoRouter.of(context).go(RfqSuccessPage.routePath);
    }
  }
}
