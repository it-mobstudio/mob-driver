import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: SvgPicture.asset(
                  'assets/images/close.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
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
                const SizedBox(height: 28),
                AppTextField(
                  hintText: 'Maps link*',
                  controller: _linkController,
                  label: 'Maps link*',
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
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
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
        ],
      ),
    );
  }

  // Serviceability only drives the informational badge below — selecting a
  // pasted link is still allowed either way, matching the web app (which
  // never disables its "Select" button on unserviceable addresses).
  bool get _canSelect => _resolvedLocation != null;

  Widget _serviceabilityBadge() {
    final serviceable = _serviceable == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: serviceable ? const Color(0xFFE2F6DB) : const Color(0xFFFFE9E9),
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

    // Two genuinely different failure modes were sharing one error message
    // ("Couldn't read a location from that link"), which pointed at the
    // wrong step whenever it was actually the reverse-geocode call that
    // failed rather than the link parsing — split so the real cause shows.
    (double, double)? coordinates;
    String finalUrl;
    try {
      finalUrl = await _followRedirects(link);
      coordinates = _extractLatLng(finalUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't read a location from that link.";
        _resolving = false;
      });
      return;
    }
    if (coordinates == null) {
      // Links shared for a named place (a business, a hotel listing) carry
      // no raw coordinates at all — Google resolves those via an internal
      // feature id, leaving only a free-text address in `q=`/`query=`.
      // Resolve that text the same way search-as-you-type does instead of
      // failing outright.
      final placeText = _extractPlaceQueryText(finalUrl);
      final resolvedByText =
          placeText == null ? null : await _resolvePlaceByText(placeText);
      if (resolvedByText != null) {
        setState(() => _resolvedLocation = resolvedByText);
        await _checkServiceability(resolvedByText.pincode);
        if (mounted) setState(() => _resolving = false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = "Couldn't read a location from that link.";
        _resolving = false;
      });
      return;
    }

    try {
      final (location, failure) = await sl<AddressRepository>().reverseGeocode(
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to resolve this address: $e';
        _resolving = false;
      });
      return;
    }

    if (mounted) setState(() => _resolving = false);
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

  /// Every query-parameter name Google's various maps.google.com /
  /// google.com/maps URL shapes have used for "the place this link points
  /// to" — search links (`q`/`query`), the newer share-link API
  /// (`query` again), and older directions links (`daddr`, `destination`,
  /// `ll`). Checked as both a coordinate pair and, in
  /// [_extractPlaceQueryText], free text.
  static const _locationParamNames = [
    'q',
    'query',
    'daddr',
    'destination',
    'll'
  ];

  /// Checks the most precise pattern first: Google's internal `!3d..!4d..`
  /// marks the exact dropped pin, `@lat,lng` is the camera center (can drift
  /// from the actual pin on a place page), and the various
  /// `q=`/`daddr=`/etc. params cover links that encode the coordinate pair
  /// directly instead.
  (double, double)? _extractLatLng(String url) {
    final pinMatch = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(url);
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
    final paramGroup = _locationParamNames.join('|');
    final qMatch = RegExp('[?&](?:$paramGroup)=(-?\\d+\\.\\d+),(-?\\d+\\.\\d+)')
        .firstMatch(url);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }
    return null;
  }

  /// Pulls the free-text place name out of whichever "destination" param
  /// the link used, for links that carry no raw coordinates at all — skips
  /// `ll` (always a coordinate pair, never a place name) and the numeric
  /// "lat,lng" case already handled by [_extractLatLng].
  String? _extractPlaceQueryText(String url) {
    final paramGroup =
        _locationParamNames.where((name) => name != 'll').join('|');
    final match = RegExp('[?&](?:$paramGroup)=([^&]+)').firstMatch(url);
    if (match == null) return null;
    final text = Uri.decodeQueryComponent(match.group(1)!).trim();
    if (text.isEmpty) return null;
    if (RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$').hasMatch(text)) return null;
    return text;
  }

  /// Resolves a bare place name/address the same way search-as-you-type
  /// does: autocomplete for a matching place, then its details for the
  /// actual coordinates. Returns null on any failure so the caller can fall
  /// back to the generic "couldn't read a location" error.
  Future<AddressLocationEntity?> _resolvePlaceByText(String text) async {
    try {
      final repository = sl<AddressRepository>();
      final (suggestions, searchFailure) =
          await repository.searchLocations(text);
      if (searchFailure != null || suggestions == null || suggestions.isEmpty) {
        return null;
      }
      final (location, detailsFailure) =
          await repository.getLocationDetails(suggestions.first.placeId);
      return detailsFailure != null ? null : location;
    } catch (_) {
      return null;
    }
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
