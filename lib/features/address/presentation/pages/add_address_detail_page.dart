import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/confirm_delivery_location_page.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

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
  static const _contactsChannel =
      MethodChannel('m_o_b_demand_side/contact_picker');

  late final AddressBloc _addressBloc;
  late final AddressRepository _addressRepository;

  /// The pin location backing this form — starts as [AddAddressDetailPage.location]
  /// but is replaced in place when "Change" resolves a different pin, so the
  /// user edits the same form instead of losing their progress and being
  /// bounced back out to the address list.
  late AddressEntity _location = widget.location;
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
    _addressRepository = sl<AddressRepository>();
    final existing = widget.existingAddress;
    if (existing != null) {
      _prefillFromExisting(existing);
      _resolveLocationLabelIfNeeded();
    } else {
      _prefillReceiverDetails();
    }
  }

  /// Saved addresses usually carry lat/long but no `formattedAddress` (that's
  /// pin-drop metadata, never stored) — so the summary card falls back to
  /// echoing the user's own typed address lines back at them, which reads as
  /// a mismatch. Resolve the real place name from the coordinates instead,
  /// same lookup the map picker uses, and only fall back to the typed
  /// address when there's no usable lat/long to resolve.
  Future<void> _resolveLocationLabelIfNeeded() async {
    final hasFormattedAddress = _location.formattedAddress.trim().isNotEmpty;
    final hasCoordinates = _location.latitude != 0 && _location.longitude != 0;
    if (hasFormattedAddress || !hasCoordinates) return;

    final (resolved, failure) = await _addressRepository.reverseGeocode(
      _location.latitude,
      _location.longitude,
    );
    if (!mounted || failure != null || resolved == null) return;
    if (resolved.formattedAddress.trim().isEmpty) return;

    setState(() {
      _location = AddressEntity(
        id: _location.id,
        latitude: _location.latitude,
        longitude: _location.longitude,
        googleMapLink: _location.googleMapLink,
        formattedAddress: resolved.formattedAddress,
        city: resolved.city.trim().isEmpty ? _location.city : resolved.city,
        state:
            resolved.state.trim().isEmpty ? _location.state : resolved.state,
        pincode: resolved.pincode.trim().isEmpty
            ? _location.pincode
            : resolved.pincode,
        sublocality: resolved.sublocality.trim().isEmpty
            ? _location.sublocality
            : resolved.sublocality,
        locationName: resolved.locationName.trim().isEmpty
            ? _location.locationName
            : resolved.locationName,
        name: _location.name,
        email: _location.email,
        addressLine1: _location.addressLine1,
        addressLine2: _location.addressLine2,
        sitePerson: _location.sitePerson,
        sitePersonMobile: _location.sitePersonMobile,
        addressTag: _location.addressTag,
        phoneNumber: _location.phoneNumber,
        isLocationServiceable: _location.isLocationServiceable,
        projectName: _location.projectName,
        mobCredit: _location.mobCredit,
        gstNumber: _location.gstNumber,
      );
    });
  }

  void _prefillFromExisting(AddressEntity existing) {
    _houseFloorController.text = existing.addressLine1;
    _buildingAreaController.text = existing.addressLine2;
    _gstController.text = existing.gstNumber;
    if (existing.addressTag.trim().isNotEmpty) {
      _addressTag = _normalizeAddressTag(existing.addressTag);
    }
    _projectNameController.text = existing.projectName;
    _receiverNameController.text = existing.name;
    _receiverPhoneController.text = existing.phoneNumber;
  }

  /// The API returns tags in whatever case they were originally stored in
  /// (e.g. "HOME" from older/web-created addresses), but the chips below
  /// compare against exact title-case labels — normalize so a saved address
  /// still shows its tag as selected instead of matching neither chip.
  static String _normalizeAddressTag(String tag) {
    final trimmed = tag.trim();
    switch (trimmed.toLowerCase()) {
      case 'home':
        return 'Home';
      case 'project':
        return 'Project';
      default:
        return trimmed;
    }
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
              bottom: false,
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

  /// Opens the map picker to adjust the pin, then applies the newly
  /// confirmed location to this same form — rather than popping straight
  /// back out to the address list, which is what a bare `context.pop()`
  /// here used to do (there's no map page underneath in the edit flow,
  /// since editing pushes straight to this page).
  Future<void> _changeLocation() async {
    final confirmed = await context.push<AddressEntity>(
      ConfirmDeliveryLocationPage.routePath,
      extra: AddressLocationEntity(
        latitude: _location.latitude,
        longitude: _location.longitude,
        formattedAddress: _location.formattedAddress,
        city: _location.city,
        state: _location.state,
        pincode: _location.pincode,
        sublocality: _location.sublocality,
        locationName: _location.locationName,
      ),
    );
    if (!mounted || confirmed == null) return;

    // A pin moved to a different spot invalidates whatever house/floor and
    // building/area text the user already typed for the old spot — clear it
    // so a stale description doesn't silently ride along with the new
    // location, matching how other delivery apps handle a map re-pin.
    final moved = confirmed.latitude != _location.latitude ||
        confirmed.longitude != _location.longitude;

    setState(() {
      _location = confirmed;
      if (moved) {
        _houseFloorController.clear();
        _buildingAreaController.clear();
      }
    });
  }

  /// Editing a saved address (rather than a freshly-confirmed map pin) means
  /// `locationName`/`formattedAddress` are usually empty — those are pin-drop
  /// metadata that a stored address never carried — so fall back to the
  /// contact name and the structured address fields, same as the saved
  /// address list cards in `address_picker.dart`.
  String get _locationTitle {
    final name = _location.name.trim();
    if (name.isNotEmpty) return name;
    final locationName = _location.locationName.trim();
    if (locationName.isNotEmpty) return locationName;
    return 'Saved address';
  }

  String get _locationSubtitle {
    final formatted = _location.formattedAddress.trim();
    if (formatted.isNotEmpty) return formatted;
    return _location.displayAddress;
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
                  _locationTitle,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _locationSubtitle,
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
            onPressed: _changeLocation,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AppTextField(
            label: 'House no & Floor*',
            controller: _houseFloorController,
            hintText: 'House no & Floor*',
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Building/ Area/ Colony',
            controller: _buildingAreaController,
            hintText: 'Building/ Area/ Colony',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'GSTIN (optional)',
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
              _tagChip(
                label: 'Home',
                selectedIcon: 'assets/images/homeaddselect.svg',
                unselectedIcon: 'assets/images/homeadd.svg',
              ),
              const SizedBox(width: 10),
              _tagChip(
                label: 'Project',
                selectedIcon: 'assets/images/projectselect.svg',
                unselectedIcon: 'assets/images/project.svg',
              ),
            ],
          ),
          if (_addressTag == 'Project') ...[
            const SizedBox(height: 20),
            AppTextField(
              label: 'Project name*',
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

  Widget _tagChip({
    required String label,
    required String selectedIcon,
    required String unselectedIcon,
  }) {
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
          border: Border.all(
            color: selected ? _navy : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              selected ? selectedIcon : unselectedIcon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
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
            hintText: 'Receiver Name*',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _receiverPhoneController,
            label: 'Receiver ph no*',
            hintText: 'Receiver Ph no*',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            showClearButton: false,
            suffixIcon: SizedBox(
              width: 88,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _receiverPhoneController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) {
                        return const SizedBox(width: 40, height: 48);
                      }
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _receiverPhoneController.clear(),
                        child: const SizedBox(
                          width: 40,
                          height: 48,
                          child: Center(
                            child: _ClearIconCircle(),
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickReceiverContact,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: SvgPicture.asset(
                        'assets/images/receiverinumicon.svg',
                        width: 19,
                        height: 19,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          latitude: _location.latitude,
          longitude: _location.longitude,
          googleMapLink: _location.googleMapLink,
          formattedAddress: _location.formattedAddress,
          city: _location.city,
          state: _location.state,
          pincode: _location.pincode,
          sublocality: _location.sublocality,
          locationName: _location.locationName,
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

  Future<void> _pickReceiverContact() async {
    FocusScope.of(context).unfocus();
    try {
      final contact = await _contactsChannel.invokeMapMethod<String, String>(
        'pickPhoneContact',
      );
      if (!mounted || contact == null) return;

      final phone = _normalizePhone(contact['phone'] ?? '');
      if (phone.isEmpty) {
        _showMessage('Selected contact has no valid phone number.');
        return;
      }

      setState(() {
        _receiverPhoneController.text = phone;
        final name = contact['name']?.trim() ?? '';
        if (_receiverNameController.text.trim().isEmpty && name.isNotEmpty) {
          _receiverNameController.text = name;
        }
      });
    } on MissingPluginException {
      if (!mounted) return;
      _showMessage('Contact picker is available on mobile devices.');
    } on PlatformException catch (e) {
      if (!mounted || e.code == 'CANCELLED') return;
      _showMessage(e.message ?? 'Unable to pick a contact.');
    }
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    TopSnackBar.show(
      context,
      message: message,
      type: TopSnackBarType.info,
    );
  }

  void _onStateChanged(BuildContext context, AddressState state) {
    if (state is AddressSaved) {
      TopSnackBar.show(
        context,
        message: 'Address saved successfully.',
        type: TopSnackBarType.success,
      );
      context.pop(state.address);
    } else if (state is AddressError) {
      TopSnackBar.show(
        context,
        message: state.message,
        type: TopSnackBarType.error,
      );
    }
  }
}

/// Matches AppTextField's built-in clear-button styling exactly, so the
/// receiver-phone field's hand-rolled clear icon (needed here since it
/// shares its suffix area with the contact-picker icon) doesn't look like a
/// different control from every other field's clear button.
class _ClearIconCircle extends StatelessWidget {
  const _ClearIconCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFB5B5B5),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 12,
      ),
    );
  }
}
