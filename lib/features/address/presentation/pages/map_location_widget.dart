import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';

class MapLocationWidget extends StatefulWidget {
  const MapLocationWidget({super.key, this.initialLocation});

  static const String routeName = 'MapLocation';
  static const String routePath = '/map_location';

  final AddressLocationEntity? initialLocation;

  @override
  State<MapLocationWidget> createState() => _MapLocationWidgetState();
}

class _MapLocationWidgetState extends State<MapLocationWidget> {
  static const _navy = Color(0xFF0A243F);
  static const _blue = Color(0xFF0360E5);
  static const _border = Color(0xFFDFE4EC);

  late final AddressBloc _addressBloc;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  final _sitePersonController = TextEditingController();
  final _sitePhoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _projectController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng _pickedLatLng = const LatLng(12.9716, 77.5946);
  String _formattedAddress = '';
  String _city = '';
  String _state = '';
  String _pincode = '';
  String _sublocality = '';
  String _locationName = 'Selected location';
  String _addressTag = 'Home';
  bool _saveAsProject = false;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _addressBloc = sl<AddressBloc>();
    _prefillUserDetails();
    final initial = widget.initialLocation;
    if (initial != null) {
      _applyLocation(initial);
    } else {
      _loadCurrentLocation();
    }
  }

  @override
  void dispose() {
    _addressBloc.close();
    _mapController?.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _sitePersonController.dispose();
    _sitePhoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _emailController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressBloc>.value(
      value: _addressBloc,
      child: BlocConsumer<AddressBloc, AddressState>(
        listener: _onAddressStateChanged,
        builder: (context, state) {
          final isSaving = state is AddressSaving;
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          _mapSection(),
                          _addressForm(),
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

  Widget _mapSection() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickedLatLng,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_pickedLatLng, 16),
                );
              },
              onCameraMove: (position) => _pickedLatLng = position.target,
              onCameraIdle: () => _reverseGeocode(_pickedLatLng),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30),
              child: Icon(Icons.location_pin, color: _navy, size: 42),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.pop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'current-location',
              backgroundColor: Colors.white,
              foregroundColor: _blue,
              onPressed: _loadCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressForm() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x26000000), blurRadius: 34),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF00C889),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _resolvingAddress
                                ? 'Fetching address...'
                                : _locationName,
                            style: GoogleFonts.inter(
                              color: _navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formattedAddress.isEmpty
                                ? 'Move the map to choose a location'
                                : _formattedAddress,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF596378),
                              fontSize: 11,
                              height: 16 / 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _field(
                  controller: _nameController,
                  label: 'Name (Project manager)*',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _phoneController,
                  label: 'Business mobile (for OTP)*',
                  keyboardType: TextInputType.phone,
                  inputFormatters: _phoneFormatters,
                  validator: _phoneValidator,
                  suffixIcon: Icons.contact_phone_outlined,
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _gstController,
                  hint: 'GSTIN (optional)',
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [LengthLimitingTextInputFormatter(15)],
                ),
              ],
            ),
          ),
          const SizedBox(
              height: 12, child: ColoredBox(color: Color(0xFFF7F7F7))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                _field(
                  controller: _sitePersonController,
                  hint: 'Site person (for delivery)',
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _sitePhoneController,
                  hint: 'Site person mobile',
                  keyboardType: TextInputType.phone,
                  inputFormatters: _phoneFormatters,
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _addressLine1Controller,
                  hint: 'House no/ Building name*',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _addressLine2Controller,
                  hint: 'Road/ Area/ Colony',
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _emailController,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          _addressTags(),
          _projectSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _addressTags() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save address as',
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _tagChip('Home', Icons.home_outlined),
                _tagChip('Office', Icons.business_center_outlined),
                _tagChip('Others', Icons.location_on_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String label, IconData icon) {
    final selected = _addressTag == label;
    return InkWell(
      onTap: () => setState(() => _addressTag = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x0F0360E5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _blue : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? _blue : _navy),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Save as project',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _saveAsProject,
                onChanged: (value) => setState(() => _saveAsProject = value),
              ),
            ],
          ),
          _projectBenefit('Easy filter for all your RFQ and Orders'),
          const SizedBox(height: 8),
          _projectBenefit('Dedicated site address for projects'),
          if (_saveAsProject) ...[
            const SizedBox(height: 16),
            _field(
              controller: _projectController,
              label: 'Project name',
              hint: 'Enter project name',
              validator: _requiredValidator,
            ),
          ],
        ],
      ),
    );
  }

  Widget _projectBenefit(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFFF47745), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(color: _navy, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    String? label,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(
        color: _navy,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFAFB4C0),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF767C8F),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 19),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: _blue),
        errorBorder: _inputBorder(color: Colors.red),
      ),
    );
  }

  Widget _saveButton(bool isSaving) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
    );
  }

  OutlineInputBorder _inputBorder({Color color = _border}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  List<TextInputFormatter> get _phoneFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _phoneValidator(String? value) {
    return value == null || value.trim().length != 10
        ? 'Enter a valid 10-digit number'
        : null;
  }

  void _prefillUserDetails() {
    final user = AuthSession.instance.userDetails ?? const {};
    _nameController.text = (user['name'] ?? user['full_name'] ?? '').toString();
    _phoneController.text =
        (user['phone'] ?? user['phone_number'] ?? user['mobile'] ?? '')
            .toString();
    _emailController.text = (user['email'] ?? '').toString();
    _gstController.text =
        (user['gstin'] ?? user['gst_number'] ?? '').toString();
  }

  void _applyLocation(AddressLocationEntity location) {
    _pickedLatLng = LatLng(location.latitude, location.longitude);
    _formattedAddress = location.formattedAddress;
    _city = location.city;
    _state = location.state;
    _pincode = _resolvePincode(
      location.pincode,
      location.formattedAddress,
    );
    _sublocality = location.sublocality;
    _locationName = location.locationName.isEmpty
        ? 'Selected location'
        : location.locationName;
  }

  Future<void> _loadCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = LatLng(position.latitude, position.longitude);
      _pickedLatLng = location;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16),
      );
      await _reverseGeocode(location);
    } catch (_) {
      _showMessage('Unable to detect your current location.');
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    if (!mounted) return;
    setState(() => _resolvingAddress = true);
    try {
      final results = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (results.isEmpty || !mounted) return;
      final place = results.firstWhere(
        (item) => (item.postalCode ?? '').trim().isNotEmpty,
        orElse: () => results.first,
      );
      final address = [
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ].where((part) => (part ?? '').trim().isNotEmpty).join(', ');
      setState(() {
        _formattedAddress = address;
        _city = place.locality ?? '';
        _state = place.administrativeArea ?? '';
        _pincode = _resolvePincode(place.postalCode, address);
        _sublocality = place.subLocality ?? '';
        _locationName = (place.name ?? '').trim().isEmpty
            ? 'Selected location'
            : place.name!;
      });
    } catch (_) {
      _showMessage('Unable to resolve this address.');
    } finally {
      if (mounted) setState(() => _resolvingAddress = false);
    }
  }

  void _saveAddress() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_formattedAddress.isEmpty) {
      _showMessage('Please select a valid map location.');
      return;
    }
    final missingLocationFields = <String>[
      if (_city.trim().isEmpty) 'city',
      if (_state.trim().isEmpty) 'state',
      if (_pincode.trim().isEmpty) 'pincode',
      if (_sublocality.trim().isEmpty) 'sublocality',
      if (_locationName.trim().isEmpty) 'location name',
    ];
    if (missingLocationFields.isNotEmpty) {
      _showMessage(
        'Location is missing ${missingLocationFields.join(', ')}. '
        'Move the map pin slightly and try again.',
      );
      return;
    }
    _addressBloc.add(
      AddressSaveRequested(
        AddressEntity(
          latitude: _pickedLatLng.latitude,
          longitude: _pickedLatLng.longitude,
          googleMapLink:
              'https://www.google.com/maps?q=${_pickedLatLng.latitude},'
              '${_pickedLatLng.longitude}',
          formattedAddress: _formattedAddress,
          city: _city,
          state: _state,
          pincode: _pincode,
          sublocality: _sublocality,
          locationName: _locationName,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim(),
          sitePerson: _sitePersonController.text.trim(),
          sitePersonMobile: _sitePhoneController.text.trim(),
          addressTag: _addressTag,
          phoneNumber: _phoneController.text.trim(),
          projectName: _saveAsProject ? _projectController.text.trim() : '',
        ),
      ),
    );
  }

  String _resolvePincode(String? postalCode, String address) {
    final direct = postalCode?.trim() ?? '';
    if (RegExp(r'^[1-9][0-9]{5}$').hasMatch(direct)) return direct;

    return RegExp(r'\b[1-9][0-9]{5}\b')
            .firstMatch(address)
            ?.group(0) ??
        '';
  }

  void _onAddressStateChanged(BuildContext context, AddressState state) {
    if (state is AddressSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully.')),
      );
      context.pop(state.address);
    } else if (state is AddressError) {
      _showMessage(state.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
