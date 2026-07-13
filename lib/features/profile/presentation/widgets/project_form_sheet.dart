import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/constants/india_location_options.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

const _navy = Color(0xFF0A243F);
const _blue = Color(0xFF0360E5);
const _muted = Color(0xFF767C8F);

final _phoneRegex = RegExp(r'^\d{10}$');
// Ported verbatim from mob-web's gstRegex (reusableFunction.js) — the odd
// `[0-3|9]` class (with a literal pipe) is what the server actually accepts.
final _gstRegex = RegExp(r'^[0-3|9][0-9][a-zA-Z0-9]{13}$');

/// Opens the Add/Edit project bottom sheet. Pass [existing] to edit.
///
/// Captures the page's [ProfileBloc] and re-provides it to the sheet: a
/// modal bottom sheet route is a sibling of the page's route in the
/// Navigator/Overlay, not a descendant of the page's `BlocProvider`, so the
/// ambient bloc wouldn't otherwise be reachable from inside it.
Future<void> showProjectFormSheet(BuildContext context, {ProjectEntity? existing}) {
  final bloc = context.read<ProfileBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: _ProjectFormSheet(existing: existing),
    ),
  );
}

class _ProjectFormSheet extends StatefulWidget {
  const _ProjectFormSheet({this.existing});

  final ProjectEntity? existing;

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _projectNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _sitePersonController = TextEditingController();
  final _sitePersonMobileController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _pincodeController = TextEditingController();

  String _projectCity = '';
  String _city = '';
  String _state = '';
  String _addressTag = 'Home';

  bool _useSavedAddress = true;
  int? _selectedAddressId;
  List<AddressEntity> _savedAddresses = const [];
  bool _loadingAddresses = false;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  bool _submitAttempted = false;
  Set<String> _pickerErrors = const {};

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _projectNameController.text = existing.name;
      _projectCity = existing.city;
      _nameController.text = existing.contactName;
      _phoneController.text = existing.contactPhone;
      _emailController.text = existing.email;
      _gstController.text = existing.gstNumber;
      _sitePersonController.text = existing.siteContactName;
      _sitePersonMobileController.text = existing.siteContactPhone;
      _mapLinkController.text = existing.googleMapLink;
      _addressLine1Controller.text = existing.addressLine1;
      _addressLine2Controller.text = existing.addressLine2;
      _pincodeController.text = existing.pincode;
      _city = existing.city;
      _state = existing.state;
      _addressTag = existing.addressTag.isNotEmpty ? existing.addressTag : 'Home';
      _useSavedAddress = false;
    } else {
      _loadSavedAddresses();
    }
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _loadingAddresses = true);
    final (addresses, _) = await sl<AddressRepository>().getAddresses();
    if (!mounted) return;
    setState(() {
      _savedAddresses = (addresses ?? const [])
          .where((a) => a.projectName.trim().isEmpty)
          .toList();
      _loadingAddresses = false;
    });
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _sitePersonController.dispose();
    _sitePersonMobileController.dispose();
    _mapLinkController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted || bytes.isEmpty) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = picked.name;
    });
  }

  Future<void> _pickCity({required bool isProjectCity}) async {
    final selected = await _showOptionPicker(
      context,
      title: 'Select city',
      options: kIndianCityOptions.map((c) => c.label).toList(),
      current: isProjectCity ? _projectCity : _city,
    );
    if (selected == null) return;
    setState(() {
      if (isProjectCity) {
        _projectCity = selected;
        _pickerErrors = {..._pickerErrors}..remove('project_city');
      } else {
        _city = selected;
        final match = kIndianCityOptions.where((c) => c.label == selected);
        if (match.isNotEmpty && match.first.state.isNotEmpty) {
          _state = match.first.state;
        }
        _pickerErrors = {..._pickerErrors}
          ..remove('city')
          ..remove('state');
      }
    });
  }

  Future<void> _pickState() async {
    final selected = await _showOptionPicker(
      context,
      title: 'Select state',
      options: kIndianStateOptions,
      current: _state,
    );
    if (selected == null) return;
    setState(() {
      _state = selected;
      _pickerErrors = {..._pickerErrors}..remove('state');
    });
  }

  void _onSubmit() {
    setState(() => _submitAttempted = true);
    final formValid = _formKey.currentState?.validate() ?? false;

    final errors = <String>{};
    if (_projectCity.trim().isEmpty) errors.add('project_city');

    final needsNewAddressFields = _isEdit || !_useSavedAddress;
    if (needsNewAddressFields) {
      if (_city.trim().isEmpty) errors.add('city');
      if (_state.trim().isEmpty) errors.add('state');
    } else if (_selectedAddressId == null) {
      errors.add('site_delivery');
    }

    setState(() => _pickerErrors = errors);

    if (!formValid || errors.isNotEmpty) {
      if (errors.contains('site_delivery')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an address')),
        );
      }
      return;
    }

    final bloc = context.read<ProfileBloc>();

    if (!_isEdit && _useSavedAddress) {
      bloc.add(ProjectCreateRequested(
        projectName: _projectNameController.text.trim(),
        city: _projectCity,
        siteDeliveryAddressId: _selectedAddressId,
        imageBytes: _pickedImageBytes,
        imageFilename: _pickedImageName,
      ));
      return;
    }

    final addressPayload = <String, dynamic>{
      if (_isEdit) 'id': widget.existing!.siteDeliveryId,
      'name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address_line_1': _addressLine1Controller.text.trim(),
      'address_line_2': _addressLine2Controller.text.trim(),
      'city': _city,
      'state': _state,
      'pincode': _pincodeController.text.trim(),
      'gst_number': _gstController.text.trim(),
      'google_map_link': _mapLinkController.text.trim(),
      'site_person': _sitePersonController.text.trim(),
      'site_person_mobile': _sitePersonMobileController.text.trim(),
      if (_isEdit) 'address_tag': _addressTag,
    };

    if (_isEdit) {
      final existing = widget.existing!;
      bloc.add(ProjectUpdateRequested(
        projectId:
            existing.projectId.isNotEmpty ? existing.projectId : existing.id.toString(),
        projectName: _projectNameController.text.trim(),
        city: _projectCity,
        address: addressPayload,
        imageBytes: _pickedImageBytes,
        imageFilename: _pickedImageName,
      ));
    } else {
      bloc.add(ProjectCreateRequested(
        projectName: _projectNameController.text.trim(),
        city: _projectCity,
        newAddress: addressPayload,
        imageBytes: _pickedImageBytes,
        imageFilename: _pickedImageName,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProjectSaved) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(_isEdit ? 'Project updated' : 'Project created'),
              ),
            );
          } else if (state is ProjectSaveError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final saving = state is ProjectSaving;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEdit ? 'Edit project details' : 'Add new project',
                          style: GoogleFonts.inter(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            saving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: _navy),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _submitAttempted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _imagePicker(),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Project name*',
                            controller: _projectNameController,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 12),
                          _tapField(
                            label: 'Project city*',
                            value: _projectCity,
                            onTap: () => _pickCity(isProjectCity: true),
                            hasError: _pickerErrors.contains('project_city'),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFE9E9E9)),
                          const SizedBox(height: 16),
                          if (!_isEdit && _useSavedAddress)
                            _savedAddressSection()
                          else
                            _newAddressForm(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _submitButton(saving),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _imagePicker() {
    final existingUrl = widget.existing?.imageUrl.trim() ?? '';
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 88,
        height: 88,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTextFieldColors.inputBorder),
        ),
        child: _pickedImageBytes != null
            ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
            : existingUrl.isNotEmpty
                ? Image.network(
                    AppConfig.resolveMediaUrl(existingUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _uploadPlaceholder(),
                  )
                : _uploadPlaceholder(),
      ),
    );
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined, color: _muted, size: 22),
        const SizedBox(height: 4),
        Text(
          'Upload',
          style: GoogleFonts.inter(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _tapField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError
                ? AppTextFieldColors.error
                : AppTextFieldColors.inputBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextFieldStyles.label),
                  Text(
                    value.isEmpty ? 'Select' : value,
                    style: value.isEmpty
                        ? AppTextFieldStyles.hint
                        : AppTextFieldStyles.inputText,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _savedAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Site delivery address',
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _useSavedAddress = false),
              child: Text(
                '+ Add new address',
                style: GoogleFonts.inter(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_loadingAddresses)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_savedAddresses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No saved addresses yet — add a new one below.',
              style: GoogleFonts.inter(color: _muted, fontSize: 12),
            ),
          )
        else
          ..._savedAddresses.map(_savedAddressCard),
        if (_pickerErrors.contains('site_delivery'))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Please select an address',
              style: AppTextFieldStyles.error,
            ),
          ),
      ],
    );
  }

  Widget _savedAddressCard(AddressEntity address) {
    final id = int.tryParse(address.id) ?? 0;
    final selected = _selectedAddressId == id;
    return InkWell(
      onTap: () => setState(() => _selectedAddressId = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF5FF) : Colors.white,
          border: Border.all(
            color: selected ? _blue : AppTextFieldColors.inputBorder,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _blue : _muted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.name,
                    style: GoogleFonts.inter(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.displayAddress,
                    style: GoogleFonts.inter(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (address.addressTag.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  address.addressTag,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _newAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Site delivery address',
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!_isEdit)
              TextButton(
                onPressed: () => setState(() => _useSavedAddress = true),
                child: Text(
                  'Choose saved address',
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Name*',
          controller: _nameController,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Business mobile (for OTP)*',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: _phoneValidator,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'GST (optional)',
          controller: _gstController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(15)],
          validator: _gstValidator,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Site person (for delivery)',
          controller: _sitePersonController,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Site person mobile',
          controller: _sitePersonMobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Google Maps link',
          controller: _mapLinkController,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'House no/ Building name*',
          controller: _addressLine1Controller,
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Road/ Area/ Colony',
          controller: _addressLine2Controller,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Pincode*',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: _requiredValidator,
        ),
        const SizedBox(height: 12),
        _tapField(
          label: 'City*',
          value: _city,
          onTap: () => _pickCity(isProjectCity: false),
          hasError: _pickerErrors.contains('city'),
        ),
        const SizedBox(height: 12),
        _tapField(
          label: 'State*',
          value: _state,
          onTap: _pickState,
          hasError: _pickerErrors.contains('state'),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_isEdit) ...[
          const SizedBox(height: 16),
          Text(
            'Save address as',
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _tagChip('Home'),
              const SizedBox(width: 10),
              _tagChip('Office'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tagChip(String tag) {
    final selected = _addressTag == tag;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _addressTag = tag),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.white,
            border: Border.all(
              color: selected ? _blue : AppTextFieldColors.inputBorder,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            tag,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : _navy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitButton(bool saving) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: saving ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFDFE4EC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEdit ? 'Save changes' : 'Add project',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _phoneValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    if (!_phoneRegex.hasMatch(v)) return 'Enter a valid 10-digit number';
    return null;
  }

  String? _gstValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_gstRegex.hasMatch(v)) return 'Enter a valid GSTIN';
    return null;
  }
}

Future<String?> _showOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) =>
        _OptionPickerSheet(title: title, options: options, current: current),
  );
}

class _OptionPickerSheet extends StatefulWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<String> options;
  final String current;

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered = widget.options;

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options.where((o) => o.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _searchController,
            hintText: 'Search',
            onChanged: _onSearch,
            prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE9E9E9)),
              itemBuilder: (context, index) {
                final option = _filtered[index];
                final selected = option == widget.current;
                return ListTile(
                  title: Text(
                    option,
                    style: GoogleFonts.inter(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: selected ? const Icon(Icons.check, color: _blue) : null,
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
