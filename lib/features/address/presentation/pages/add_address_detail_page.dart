import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

class AddAddressDetailPage extends StatefulWidget {
  const AddAddressDetailPage({
    super.key,
    required this.location,
    this.existingAddress,
  });

  static const String routeName = 'AddAddressDetail';
  static const String routePath = '/add_address_detail';

  /// The confirmed pin location (lat/lng + resolved address) carried over
  /// from [ConfirmDeliveryLocationPage].
  final AddressEntity location;

  /// When editing a saved address, its current details — the form
  /// pre-fills from this instead of the signed-in user's profile, and
  /// saving PATCHes this address (by id) instead of creating a new one.
  final AddressEntity? existingAddress;

  @override
  State<AddAddressDetailPage> createState() => _AddAddressDetailPageState();
}

class _AddAddressDetailPageState extends State<AddAddressDetailPage> {
  static const _navy = Color(0xFF0A243F);
  static const _blue = Color(0xFF0360E5);
  static const _border = Color(0xFFDFE4EC);

  late final AddressBloc _addressBloc;
  final _formKey = GlobalKey<FormState>();
  final _houseFloorController = TextEditingController();
  final _buildingAreaController = TextEditingController();
  final _gstController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  String _addressTag = 'Home';

  @override
  void initState() {
    super.initState();
    _addressBloc = sl<AddressBloc>();
    final existing = widget.existingAddress;
    if (existing != null) {
      _prefillFromExisting(existing);
    } else {
      _prefillReceiverDetails();
    }
  }

  void _prefillFromExisting(AddressEntity existing) {
    _houseFloorController.text = existing.addressLine1;
    _buildingAreaController.text = existing.addressLine2;
    _gstController.text = existing.gstNumber;
    if (existing.addressTag.trim().isNotEmpty) {
      _addressTag = existing.addressTag.trim();
    }
    _projectNameController.text = existing.projectName;
    _receiverNameController.text = existing.name;
    _receiverPhoneController.text = existing.phoneNumber;
  }

  @override
  void dispose() {
    _addressBloc.close();
    _houseFloorController.dispose();
    _buildingAreaController.dispose();
    _gstController.dispose();
    _projectNameController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  void _prefillReceiverDetails() {
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _receiverNameController.text =
        (user['name'] ?? user['full_name'] ?? '').toString();
    _receiverPhoneController.text =
        (user['phone'] ?? user['phone_number'] ?? user['mobile'] ?? '')
            .toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressBloc>.value(
      value: _addressBloc,
      child: BlocConsumer<AddressBloc, AddressState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final isSaving = state is AddressSaving;
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: _navy,
              elevation: 0,
              leading: IconButton(
                icon: const AppBackIcon(),
                onPressed: () => context.pop(),
              ),
              title: Text(
                widget.existingAddress != null
                    ? 'Edit address detail'
                    : 'Add address detail',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _locationSummaryCard(),
                          const SizedBox(height: 24),
                          _sectionTitle('Address details'),
                          const SizedBox(height: 12),
                          _addressDetailsCard(),
                          const SizedBox(height: 24),
                          _sectionTitle('Save address as'),
                          const SizedBox(height: 12),
                          _addressTagSelector(),
                          const SizedBox(height: 24),
                          _sectionTitle('Receiver details'),
                          const SizedBox(height: 12),
                          _receiverDetailsCard(),
                        ],
                      ),
                    ),
                  ),
                  _saveButton(isSaving),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: _navy,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _locationSummaryCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/images/marker-green.svg',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.location.locationName,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.location.formattedAddress,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF596378),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _blue,
              side: const BorderSide(color: _blue),
              fixedSize: const Size(85, 38),
              minimumSize: const Size(85, 38),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Change',
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(0),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   // borderRadius: BorderRadius.circular(18),
      // ),
      child: Column(
        children: [
          AppTextField(
            controller: _houseFloorController,
            hintText: 'House no & Floor*',
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _buildingAreaController,
            hintText: 'Building/ Area/ Colony',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _gstController,
            hintText: 'GSTIN (optional)',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(15)],
          ),
        ],
      ),
    );
  }

  Widget _addressTagSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tagChip('Home', Icons.home_outlined),
              const SizedBox(width: 12),
              _tagChip('Project', Icons.apartment_outlined),
            ],
          ),
          if (_addressTag == 'Project') ...[
            const SizedBox(height: 20),
            AppTextField(
              controller: _projectNameController,
              hintText: 'Project name*',
              textInputAction: TextInputAction.next,
              validator: (value) => _addressTag == 'Project' &&
                      (value == null || value.trim().isEmpty)
                  ? 'Required'
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagChip(String label, IconData icon) {
    final selected = _addressTag == label;
    return InkWell(
      onTap: () => setState(() => _addressTag = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _navy : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : _navy),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : _navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiverDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          AppTextField(
            controller: _receiverNameController,
            label: 'Receiver Name*',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _receiverPhoneController,
            label: 'Receiver ph no*',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            suffixIcon: const Icon(Icons.contact_phone_outlined, size: 19),
            validator: (value) => value == null || value.trim().length != 10
                ? 'Enter a valid 10-digit number'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _saveButton(bool isSaving) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Save address',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _saveAddress() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _addressBloc.add(
      AddressSaveRequested(
        AddressEntity(
          id: widget.existingAddress?.id ?? '',
          latitude: widget.location.latitude,
          longitude: widget.location.longitude,
          googleMapLink: widget.location.googleMapLink,
          formattedAddress: widget.location.formattedAddress,
          city: widget.location.city,
          state: widget.location.state,
          pincode: widget.location.pincode,
          sublocality: widget.location.sublocality,
          locationName: widget.location.locationName,
          name: _receiverNameController.text.trim(),
          email: '',
          addressLine1: _houseFloorController.text.trim(),
          addressLine2: _buildingAreaController.text.trim(),
          sitePerson: '',
          sitePersonMobile: '',
          addressTag: _addressTag,
          phoneNumber: _receiverPhoneController.text.trim(),
          projectName: _addressTag == 'Project'
              ? _projectNameController.text.trim()
              : '',
          gstNumber: _gstController.text.trim(),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, AddressState state) {
    if (state is AddressSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully.')),
      );
      context.pop(state.address);
    } else if (state is AddressError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }
}
