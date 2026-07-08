import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/map_location_widget.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';

class AddressSelectionWidget extends StatefulWidget {
  const AddressSelectionWidget({
    super.key,
    this.returnToHome = false,
    this.showReferralBonus = false,
  });

  static const String routeName = 'AddressSelection';
  static const String routePath = '/address_selection';

  final bool returnToHome;
  final bool showReferralBonus;

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  static const _navy = Color(0xFF0A243F);
  late final AddressBloc _addressBloc;
  late final AddressRepository _addressRepository;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<AddressEntity> _addresses = const [];
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    _addressBloc = sl<AddressBloc>()..add(AddressLoadRequested());
    _addressRepository = sl<AddressRepository>();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _addressBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressBloc>.value(
      value: _addressBloc,
      child: BlocConsumer<AddressBloc, AddressState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final suggestions = state is AddressSearchLoaded
              ? state.suggestions
              : const <AddressSuggestionEntity>[];
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: _navy,
              elevation: 0,
              title: Text(
                'Search location',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search for area, street name..',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFFAFB4C0),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  _addressBloc.add(AddressLoadRequested());
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: _border(),
                        enabledBorder: _border(),
                        focusedBorder: _border(color: const Color(0xFF0360E5)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: state is AddressLoading || state is AddressSearching
                        ? const Center(child: CircularProgressIndicator())
                        : suggestions.isNotEmpty
                            ? _suggestionsList(suggestions)
                            : _savedAddressContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _savedAddressContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _actionTile(
          icon: Icons.my_location,
          title: 'Detect my location',
          subtitle: 'Use your current GPS location',
          onTap: _detectCurrentLocation,
          loading: _detectingLocation,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.add,
          title: 'Add new address',
          onTap: _openMap,
        ),
        const SizedBox(height: 24),
        Text(
          'Your saved address',
          style: GoogleFonts.inter(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_addresses.isEmpty)
          const _EmptyAddress()
        else
          ..._addresses.map(_savedAddressCard),
      ],
    );
  }

  Widget _suggestionsList(List<AddressSuggestionEntity> suggestions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined, color: _navy),
          title: Text(
            suggestion.primaryText,
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: suggestion.secondaryText.isEmpty
              ? null
              : Text(
                  suggestion.secondaryText,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 12,
                  ),
                ),
          onTap: () => _addressBloc.add(
            AddressLocationDetailsRequested(suggestion.placeId),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool loading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDFE4EC)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0360E5)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF767C8F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SvgPicture.asset(
    'assets/images/Arrow.svg',
    width: 16,
    height: 16,
  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedAddressCard(AddressEntity address) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _completeSelection(address),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDFE4EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF00B878),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address.name.isNotEmpty
                            ? address.name
                            : address.locationName,
                        style: GoogleFonts.inter(
                          color: _navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (address.addressTag.isNotEmpty) _tag(address.addressTag),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address.displayAddress,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF596378),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x0F0360E5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFF0360E5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color color = const Color(0xFFDFE4EC)}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (value.trim().isEmpty) {
        _addressBloc.add(AddressLoadRequested());
      } else {
        _addressBloc.add(AddressSearchRequested(value));
      }
    });
  }

  void _onStateChanged(BuildContext context, AddressState state) {
    if (state is AddressListLoaded) {
      setState(() => _addresses = state.addresses);
    } else if (state is AddressLocationResolved) {
      _completeSelection(_addressFromLocation(state.location));
    } else if (state is AddressError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  Future<void> _openMap([AddressLocationEntity? location]) async {
    final savedAddress = await context.push<AddressEntity>(
      MapLocationWidget.routePath,
      extra: location,
    );
    if (!mounted || savedAddress == null) return;
    await _completeSelection(savedAddress);
  }

  /// Builds a lightweight [AddressEntity] purely for setting the active
  /// delivery location (top nav bar / browsing context). Contact fields
  /// (name, phone, email, site person) are intentionally left blank — those
  /// are only collected when the user explicitly adds a new address via the
  /// "Add new address" button, which opens [MapLocationWidget].
  AddressEntity _addressFromLocation(AddressLocationEntity location) {
    return AddressEntity(
      latitude: location.latitude,
      longitude: location.longitude,
      googleMapLink:
          'https://www.google.com/maps?q=${location.latitude},${location.longitude}',
      formattedAddress: location.formattedAddress,
      city: location.city,
      state: location.state,
      pincode: location.pincode,
      sublocality: location.sublocality,
      locationName: location.locationName,
      name: '',
      email: '',
      addressLine1: '',
      addressLine2: '',
      sitePerson: '',
      sitePersonMobile: '',
      addressTag: '',
      phoneNumber: '',
    );
  }

  Future<void> _detectCurrentLocation() async {
    if (_detectingLocation) return;
    setState(() => _detectingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Location permission is required.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final (location, failure) = await _addressRepository.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      if (failure != null || location == null) {
        _showError(failure?.message ?? 'Unable to resolve your current address.');
        return;
      }
      final address = AddressEntity(
        latitude: location.latitude,
        longitude: location.longitude,
        googleMapLink:
            'https://www.google.com/maps?q=${location.latitude},${location.longitude}',
        formattedAddress: location.formattedAddress,
        city: location.city,
        state: location.state,
        pincode: _resolvePincode(location.pincode, location.formattedAddress),
        sublocality: location.sublocality,
        locationName: location.locationName.trim().isEmpty
            ? 'Current location'
            : location.locationName.trim(),
        name: '',
        email: '',
        addressLine1: '',
        addressLine2: '',
        sitePerson: '',
        sitePersonMobile: '',
        addressTag: '',
        phoneNumber: '',
      );
      if (!mounted) return;
      await _completeSelection(address);
    } catch (_) {
      _showError('Unable to detect your current location.');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  String _resolvePincode(String? postalCode, String address) {
    final direct = postalCode?.trim() ?? '';
    if (RegExp(r'^[1-9][0-9]{5}$').hasMatch(direct)) return direct;
    return RegExp(r'\b[1-9][0-9]{5}\b').firstMatch(address)?.group(0) ?? '';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _completeSelection(AddressEntity address) async {
    await SelectedAddressStore.save(address);
    if (!mounted) return;
    if (widget.returnToHome) {
      context.go(
        HomepageWidget.routePath,
        extra: {'showReferralBonus': widget.showReferralBonus},
      );
    } else {
      context.pop(address);
    }
  }
}

class _EmptyAddress extends StatelessWidget {
  const _EmptyAddress();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text(
          'No saved addresses yet.',
          style: GoogleFonts.inter(color: const Color(0xFF767C8F)),
        ),
      ),
    );
  }
}
