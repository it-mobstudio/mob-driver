import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/maps_link_sheet.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

/// Lets the user drag-confirm the exact pin location before it's applied as
/// the active delivery location shown in the top nav bar — the step that
/// was missing between "detect my location"/picking a search result and
/// the location silently taking effect. Scoped only to that nav-bar
/// location: no contact/receiver details are collected here — those are
/// only gathered by [MapLocationWidget]'s explicit "Add new address" flow.
class ConfirmDeliveryLocationPage extends StatefulWidget {
  const ConfirmDeliveryLocationPage({super.key, required this.initialLocation});

  static const String routeName = 'ConfirmDeliveryLocation';
  static const String routePath = '/confirm_delivery_location';

  final AddressLocationEntity initialLocation;

  @override
  State<ConfirmDeliveryLocationPage> createState() =>
      _ConfirmDeliveryLocationPageState();
}

class _ConfirmDeliveryLocationPageState
    extends State<ConfirmDeliveryLocationPage> {
  static const _navy = Color(0xFF0A243F);
  static const _blue = Color(0xFF0360E5);
  static const _border = Color(0xFFDFE4EC);
  static const _bodyText = Color(0xFF596378);

  late final AddressRepository _addressRepository;
  GoogleMapController? _mapController;
  late LatLng _pickedLatLng;
  late AddressLocationEntity _resolved;
  bool _resolvingAddress = false;
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    _addressRepository = sl<AddressRepository>();
    _resolved = widget.initialLocation;
    _pickedLatLng = LatLng(
      widget.initialLocation.latitude,
      widget.initialLocation.longitude,
    );
    // "Add new address" opens this with a bare default pin (no resolved
    // address yet) — detect-location/search callers already pass a fully
    // resolved location, so this is a no-op for them.
    if (_resolved.formattedAddress.trim().isEmpty) {
      _reverseGeocode(_pickedLatLng);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _mapSection()),
            _confirmCard(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const AppBackIcon(),
              onPressed: () => context.pop(),
            ),
          ),
          Text(
            'Select delivery location',
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapSection() {
    return Stack(
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
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) => _pickedLatLng = position.target,
            onCameraIdle: () => _reverseGeocode(_pickedLatLng),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: _searchBar(),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tooltip(),
                const SizedBox(height: 8),
                Transform.translate(
                  offset: Offset(0, -2),
                  child: const _MapPin(),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Row(
            children: [
              Expanded(child: _mapsLinkChip()),
              const SizedBox(width: 12),
              Expanded(child: _currentLocationChip()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x1A000000),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.pop(),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Icon(Icons.search, color: _navy, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search for area, street name..',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _bodyText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tooltip() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your order will be delivered here',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 16 / 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Please place the pin accurately on the map',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -7,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 14,
              height: 14,
              color: const Color(0xFF202020),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapsLinkChip() {
    return _pillButton(
      iconAsset: 'assets/images/googlemarker.svg',
      label: 'Maps link',
      onTap: _openMapsLinkSheet,
    );
  }

  Widget _currentLocationChip() {
    return _pillButton(
      iconAsset: 'assets/images/currentlocation.svg',
      label: 'Current location',
      loading: _detectingLocation,
      onTap: _detectingLocation ? null : _useCurrentLocation,
    );
  }

  Widget _pillButton({
    required String iconAsset,
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x1A000000),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                SvgPicture.asset(
                  iconAsset,
                  width: 17,
                  height: 17,
                ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _bodyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/marker-green.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _resolvingAddress
                      ? 'Fetching address...'
                      : _resolved.locationName,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 20 / 15,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'CHANGE',
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _resolved.formattedAddress.isEmpty
                  ? 'Move the map to choose a location'
                  : _resolved.formattedAddress,
              style: GoogleFonts.inter(
                color: _bodyText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _resolvingAddress || _resolved.formattedAddress.isEmpty
                  ? null
                  : _confirm,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Confirm & proceed',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyResolvedLocation(AddressLocationEntity location) async {
    setState(() {
      _resolved = location;
      _pickedLatLng = LatLng(location.latitude, location.longitude);
    });
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickedLatLng, 16),
    );
  }

  Future<void> _openMapsLinkSheet() async {
    final location = await showMapsLinkSheet(context);
    if (!mounted || location == null) return;
    await _applyResolvedLocation(location);
  }

  Future<void> _useCurrentLocation() async {
    if (_detectingLocation) return;
    setState(() => _detectingLocation = true);
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final location = LatLng(position.latitude, position.longitude);
      _pickedLatLng = location;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16),
      );
      await _reverseGeocode(location);
    } catch (_) {
      _showMessage('Unable to detect your current location.');
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    if (!mounted) return;
    setState(() => _resolvingAddress = true);
    final (resolved, failure) = await _addressRepository.reverseGeocode(
      location.latitude,
      location.longitude,
    );
    if (!mounted) return;
    if (failure == null && resolved != null) {
      setState(() => _resolved = resolved);
    }
    setState(() => _resolvingAddress = false);
  }

  String _resolvePincode(String? postalCode, String address) {
    final direct = postalCode?.trim() ?? '';
    if (RegExp(r'^[1-9][0-9]{5}$').hasMatch(direct)) return direct;
    return RegExp(r'\b[1-9][0-9]{5}\b').firstMatch(address)?.group(0) ?? '';
  }

  void _confirm() {
    final resolved = _resolved;
    context.pop(
      AddressEntity(
        latitude: _pickedLatLng.latitude,
        longitude: _pickedLatLng.longitude,
        googleMapLink:
            'https://www.google.com/maps?q=${_pickedLatLng.latitude},${_pickedLatLng.longitude}',
        formattedAddress: resolved.formattedAddress,
        city: resolved.city,
        state: resolved.state,
        pincode: _resolvePincode(resolved.pincode, resolved.formattedAddress),
        sublocality: resolved.sublocality,
        locationName: resolved.locationName.trim().isEmpty
            ? 'Selected location'
            : resolved.locationName.trim(),
        name: '',
        email: '',
        addressLine1: '',
        addressLine2: '',
        sitePerson: '',
        sitePersonMobile: '',
        addressTag: '',
        phoneNumber: '',
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/MapMarker.svg',
      width: 36,
      height: 48,
      fit: BoxFit.contain,
    );
  }
}
