import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';

const _navy = Color(0xFF0A243F);

class HomeNotServiceableBody extends StatelessWidget {
  const HomeNotServiceableBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          Image.asset(
            'assets/images/notavailable.png',
            width: 180,
            height: 180,
          ),
          const SizedBox(height: 24),
          Text(
            'Not available yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 30 / 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We don't deliver to this location yet. Please change your "
            'delivery address or select a supported city below',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(child: _DashedDivider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Currently serving',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
              ),
              const Expanded(child: _DashedDivider()),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(
                child: _ServiceableCityCard(
                  asset: 'assets/images/mumbai.svg',
                  label: 'Mumbai',
                  // Confirmed active in the serviceable-areas list —
                  // Mumbai's serviceability is limited to a specific set of
                  // pincodes, not the whole city, so this must be one of
                  // them rather than a generic city-center coordinate.
                  pincode: '400001',
                  state: 'Maharashtra',
                  latitude: 18.9388,
                  longitude: 72.8354,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _ServiceableCityCard(
                  asset: 'assets/images/bengaluru.svg',
                  label: 'Bengaluru',
                  // Confirmed active (id 108) in the serviceable-areas list.
                  pincode: '560119',
                  state: 'Karnataka',
                  latitude: 12.9716,
                  longitude: 77.5946,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceableCityCard extends StatelessWidget {
  const _ServiceableCityCard({
    required this.asset,
    required this.label,
    required this.pincode,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String asset;
  final String label;
  final String pincode;
  final String state;
  final double latitude;
  final double longitude;

  Future<void> _selectCity(BuildContext context) async {
    await SelectedAddressStore.save(
      AddressEntity(
        latitude: latitude,
        longitude: longitude,
        googleMapLink: 'https://www.google.com/maps?q=$latitude,$longitude',
        formattedAddress: label,
        city: label,
        state: state,
        pincode: pincode,
        sublocality: '',
        locationName: label,
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
    if (!context.mounted) return;
    context.read<HomeBloc>().add(HomeRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectCity(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(asset, width: 50, height: 40),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/images/RoundArrow.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D4DC)
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
