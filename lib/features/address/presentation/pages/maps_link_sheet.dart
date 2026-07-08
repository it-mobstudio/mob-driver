import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

/// Lets the user paste a Google Maps share link instead of dragging the pin
/// or searching. Resolved entirely client-side: follow the link's redirects
/// (short `maps.app.goo.gl` links only carry coordinates after redirecting)
/// to find the lat/lng embedded in the final URL, reverse-geocode it via the
/// same Google API the map screen already uses, then run the resolved
/// pincode through the existing `/utility/serviceble/` check (the same one
/// checkout uses) for the Serviceable/Unserviceable badge.
Future<AddressLocationEntity?> showMapsLinkSheet(BuildContext context) {
  return showModalBottomSheet<AddressLocationEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => const _MapsLinkSheet(),
  );
}

class _MapsLinkSheet extends StatefulWidget {
  const _MapsLinkSheet();

  @override
  State<_MapsLinkSheet> createState() => _MapsLinkSheetState();
}

class _MapsLinkSheetState extends State<_MapsLinkSheet> {
  static const _navy = Color(0xFF0A243F);
  static const _blue = Color(0xFF0360E5);

  final _linkController = TextEditingController();
  Timer? _debounce;
  bool _resolving = false;
  String? _error;
  bool? _serviceable;
  AddressLocationEntity? _resolvedLocation;

  @override
  void dispose() {
    _debounce?.cancel();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
              'Delivery google maps link',
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _linkController,
              label: 'Maps link*',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              keyboardType: TextInputType.url,
              onChanged: _onLinkChanged,
            ),
            if (_resolving) ...[
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  color: const Color(0xFFC13615),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (_resolvedLocation != null) ...[
              const SizedBox(height: 16),
              _serviceabilityBadge(),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canSelect ? _select : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDFE4EC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Select',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSelect => _resolvedLocation != null && _serviceable == true;

  Widget _serviceabilityBadge() {
    final serviceable = _serviceable == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: serviceable
            ? const Color(0xFFE3F7EC)
            : const Color(0xFFFFE9E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            serviceable ? 'Serviceable' : 'Unserviceable',
            style: GoogleFonts.inter(
              color: serviceable
                  ? const Color(0xFF13A05A)
                  : const Color(0xFFE53935),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _resolvedLocation!.formattedAddress,
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _onLinkChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _resolvedLocation = null;
      _serviceable = null;
      _error = null;
    });
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _resolveLink(trimmed);
    });
  }

  Future<void> _resolveLink(String link) async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final finalUrl = await _followRedirects(link);
      final coordinates = _extractLatLng(finalUrl);
      if (coordinates == null) {
        setState(() {
          _error = "Couldn't read a location from that link.";
          _resolving = false;
        });
        return;
      }
      final (location, failure) =
          await sl<AddressRepository>().reverseGeocode(
        coordinates.$1,
        coordinates.$2,
      );
      if (!mounted) return;
      if (failure != null || location == null) {
        setState(() {
          _error = failure?.message ?? 'Unable to resolve this address.';
          _resolving = false;
        });
        return;
      }
      setState(() => _resolvedLocation = location);
      await _checkServiceability(location.pincode);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't read a location from that link.";
      });
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<String> _followRedirects(String link) async {
    final url = link.startsWith('http') ? link : 'https://$link';
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        followRedirects: true,
        maxRedirects: 6,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final response = await dio.get<dynamic>(url);
    return response.realUri.toString();
  }

  /// Checks the most precise pattern first: Google's internal `!3d..!4d..`
  /// marks the exact dropped pin, while `@lat,lng` is only the camera
  /// center (can drift from the actual pin on a place page).
  (double, double)? _extractLatLng(String url) {
    final pinMatch =
        RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(url);
    if (pinMatch != null) {
      final lat = double.tryParse(pinMatch.group(1)!);
      final lng = double.tryParse(pinMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    final atMatch = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    final qMatch =
        RegExp(r'[?&](?:q|query)=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(url);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    return null;
  }

  Future<void> _checkServiceability(String pincode) async {
    if (pincode.trim().isEmpty) {
      setState(() => _serviceable = false);
      return;
    }
    try {
      final response = await DioClient.instance.dio.get<dynamic>(
        '/utility/serviceble/',
        queryParameters: {'pincode': pincode},
      );
      final data = response.data;
      final isServiceable = data is Map
          ? (data['status'] == true || data['serviceable'] == true)
          : false;
      if (!mounted) return;
      setState(() => _serviceable = isServiceable);
    } catch (_) {
      if (!mounted) return;
      setState(() => _serviceable = false);
    }
  }

  void _select() {
    final location = _resolvedLocation;
    if (location == null) return;
    Navigator.of(context).pop(location);
  }
}
