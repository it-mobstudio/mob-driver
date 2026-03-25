import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationWidget extends StatefulWidget {
  const MapLocationWidget({super.key});

  static const String routeName = 'MapLocation';
  static const String routePath = '/map_location';

  @override
  State<MapLocationWidget> createState() => _MapLocationWidgetState();
}

class _MapLocationWidgetState extends State<MapLocationWidget> {
  GoogleMapController? _map;
  LatLng? _currentLatLng;
  LatLng? _pickedLatLng;
  String? _address;
  bool _loadingAddr = false;

  final CameraPosition _defaultCamera =
      const CameraPosition(target: LatLng(12.9716, 77.5946), zoom: 14.5);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final hasPerm = await _ensureLocationPermission();
      if (!hasPerm) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _pickedLatLng = _currentLatLng;

      // Move camera once map is ready
      if (_map != null) {
        _map!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
      }
      _reverseGeocode(_pickedLatLng!);
      setState(() {});
    } catch (_) {
      // keep default camera; optionally show a snackbar
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // Reverse geocode the current pickedLatLng
  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _loadingAddr = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final line = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country
        ].where((e) => (e ?? '').trim().isNotEmpty).join(', ');
        setState(() => _address = line);
      }
    } catch (_) {
      // swallow, keep old address
    } finally {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  void _onCameraIdle() {
    if (_map == null) return;
    final size = MediaQuery.of(context).size;
    _map!.getVisibleRegion().then((_) async {
      if (!mounted) {
        return;
      }
      final target = await _map!.getLatLng(ScreenCoordinate(
        x: (size.width ~/ 2),
        y: (size.height ~/ 2),
      ));
      _pickedLatLng = target;
      _reverseGeocode(target);
    });
  }

  void _centerOnCurrent() {
    if (_currentLatLng != null && _map != null) {
      _map!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 16));
      _pickedLatLng = _currentLatLng;
      _reverseGeocode(_pickedLatLng!);
    } else {
      _initLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // MAP
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: _defaultCamera,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (c) {
                  _map = c;
                  // If we already have GPS, center now
                  if (_currentLatLng != null) {
                    _map!.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLatLng!, 16),
                    );
                  }
                },
                onCameraIdle: _onCameraIdle,
              ),
            ),

            // TOP BAR + SEARCH
            Positioned(
              left: 8,
              right: 8,
              top: 0,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text('Select delivery location',
                          style: GoogleFonts.inter(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _searchField(),
                ],
              ),
            ),

            // PIN TOOLTIP
            Positioned(
              left: 24,
              right: 24,
              top: 180,
              child: _pinTooltip(),
            ),

            // CENTER PIN
            Positioned(
              top: MediaQuery.of(context).size.height * 0.42,
              left: MediaQuery.of(context).size.width * 0.5 - 14,
              child: const Icon(Icons.location_on,
                  size: 36, color: Colors.black87),
            ),

            // USE CURRENT LOCATION
            Positioned(
              left: 16,
              right: 16,
              bottom: 220,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _useCurrentLocationButton(onTap: _centerOnCurrent),
              ),
            ),

            // ADDRESS + CONFIRM
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _bottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        readOnly: true,
        onTap: () {
          // TODO: hook to Places Autocomplete and animate camera to result
        },
        decoration: InputDecoration(
          hintText: 'Search for area, street name..',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E8EE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E8EE)),
          ),
        ),
      ),
    );
  }

  Widget _pinTooltip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('Your order will be delivered here',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Please place the pin accurately on the map',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _useCurrentLocationButton({required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.my_location),
      label: Text('Use current location',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A243F),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE1E6ED)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _bottomSheet(BuildContext context) {
    final addr = _loadingAddr
        ? 'Fetching address…'
        : (_address ?? 'Move the map to pick a location');

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Address card shows CURRENT address instead of “Ganga classic”
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place, color: Color(0xFF1DB954)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current location',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          addr,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF6C7C8C)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _centerOnCurrent,
                    child: const Text('CHANGE'),
                  )
                ],
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_pickedLatLng == null || _address == null)
                      ? null
                      : () {
                          // Return selection or navigate
                          Navigator.pop(context, {
                            'latLng': _pickedLatLng,
                            'address': _address,
                          });
                          // Or: GoRouter.of(context).go(CheckoutAddressPage.routePath);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('Confirm & proceed',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
