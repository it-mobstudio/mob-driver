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
import 'package:m_o_b_demand_side/features/address/presentation/pages/add_address_detail_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/confirm_delivery_location_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/maps_link_sheet.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';
import 'package:m_o_b_demand_side/shared/widgets/address_picker.dart';

class AddressSelectionWidget extends StatefulWidget {
  const AddressSelectionWidget({
    super.key,
    this.returnToHome = false,
    this.showReferralBonus = false,
    this.showSearch = true,
    this.title,
  });

  static const String routeName = 'AddressSelection';
  static const String routePath = '/address_selection';

  final bool returnToHome;
  final bool showReferralBonus;

  /// My Account's "Addresses" menu and the RFQ "Recheck prices" flow reuse
  /// this same page but as a plain address-book manager — no live location
  /// search/quick-pick pills, just "Add new address" + the saved list. The
  /// nav bar entry point keeps both (the default).
  final bool showSearch;

  /// Overrides the default title (which otherwise falls back to
  /// 'Search location' / 'Addresses' based on [showSearch]).
  final String? title;

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  late final AddressBloc _addressBloc;
  late final AddressRepository _addressRepository;
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<AddressEntity> _addresses = const [];
  bool _loadingAddresses = true;
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
          final suggestions = widget.showSearch && state is AddressSearchLoaded
              ? state.suggestions
              : const <AddressSuggestionEntity>[];
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A243F),
              elevation: 0,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: SvgPicture.asset(
                  'assets/images/Back.svg',
                  width: 12,
                  height: 12,
                ),
              ),
              title: Text(
                widget.title ??
                    (widget.showSearch ? 'Search location' : 'Addresses'),
                style: const TextStyle(
                  color: Color(0xFF0A243F),
                  fontSize: 15,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.47,
                ),
              ),
            ),
            body: SafeArea(
              child: AddressPickerBody(
                addresses: _addresses,
                selectedAddressId: SelectedAddressStore.cached?.id,
                isLoadingAddresses: _loadingAddresses,
                showSearch: widget.showSearch,
                showQuickActions: widget.showSearch,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                suggestions: suggestions,
                isSearching: state is AddressSearching,
                onSelectSuggestion: (suggestion) => _addressBloc.add(
                  AddressLocationDetailsRequested(suggestion.placeId),
                ),
                detectingCurrentLocation: _detectingLocation,
                onCurrentLocation: _detectCurrentLocation,
                onMapsLink: _openMapsLinkSheet,
                onAddNewAddress: _openMap,
                onSelectAddress: _completeSelection,
                onEditAddress: _editAddress,
                onDeleteAddress: _deleteAddress,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSearchChanged(String value) {
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
      setState(() {
        _addresses = state.addresses;
        _loadingAddresses = false;
      });
    } else if (state is AddressLocationResolved) {
      _confirmOnMap(state.location);
    } else if (state is AddressError) {
      setState(() => _loadingAddresses = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  /// "Add new address" — confirm a pin on the map, then collect receiver
  /// details and actually save it to the address book (unlike
  /// [_confirmOnMap], which only sets the nav bar's browsing location).
  /// Defaults to a Bengaluru city-center pin when no location is already
  /// known; [ConfirmDeliveryLocationPage] resolves the real address for it
  /// as soon as the map loads.
  Future<void> _openMap([AddressLocationEntity? location]) async {
    final confirmed = await context.push<AddressEntity>(
      ConfirmDeliveryLocationPage.routePath,
      extra: location ??
          const AddressLocationEntity(
            latitude: 12.9716,
            longitude: 77.5946,
            formattedAddress: '',
            city: '',
            state: '',
            pincode: '',
            sublocality: '',
            locationName: '',
          ),
    );
    if (!mounted || confirmed == null) return;
    final savedAddress = await context.push<AddressEntity>(
      AddAddressDetailPage.routePath,
      extra: confirmed,
    );
    if (!mounted || savedAddress == null) return;
    setState(() => _addresses = [..._addresses, savedAddress]);
    await _completeSelection(savedAddress);
  }

  Future<void> _editAddress(AddressEntity address) async {
    final updated = await context.push<AddressEntity>(
      AddAddressDetailPage.routePath,
      extra: address,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _addresses = [
        for (final existing in _addresses)
          if (existing.id == updated.id) updated else existing,
      ];
    });
    if (SelectedAddressStore.cached?.id == updated.id) {
      await SelectedAddressStore.save(updated);
    }
  }

  Future<void> _deleteAddress(AddressEntity address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete address?'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final (success, failure) =
        await _addressRepository.deleteAddress(address.id);
    if (!mounted) return;
    if (!success) {
      _showError(failure?.message ?? 'Unable to delete address.');
      return;
    }
    setState(() {
      _addresses = _addresses.where((a) => a.id != address.id).toList();
    });
    if (SelectedAddressStore.cached?.id == address.id) {
      await SelectedAddressStore.clear();
    }
  }

  /// Lets the user confirm/adjust the pin on the map before it's applied as
  /// the active delivery location — used for both "detect my location" and
  /// picking a search suggestion, so a resolved GPS/place lookup never
  /// silently takes effect without the user seeing and confirming it first.
  Future<void> _confirmOnMap(AddressLocationEntity location) async {
    final confirmed = await context.push<AddressEntity>(
      ConfirmDeliveryLocationPage.routePath,
      extra: location,
    );
    if (!mounted || confirmed == null) return;
    await _completeSelection(confirmed);
  }

  Future<void> _openMapsLinkSheet() async {
    final location = await showMapsLinkSheet(context);
    if (!mounted || location == null) return;
    await _confirmOnMap(location);
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
        _showError(
            failure?.message ?? 'Unable to resolve your current address.');
        return;
      }
      await _confirmOnMap(location);
    } catch (_) {
      _showError('Unable to detect your current location.');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
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
