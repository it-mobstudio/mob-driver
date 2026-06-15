import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/personal_info_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  AddressEntity? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final selectedAddress = _selectedAddress;
    final addressLabel = selectedAddress == null
        ? 'Home'
        : selectedAddress.addressTag.trim().isNotEmpty
            ? selectedAddress.addressTag.trim()
            : selectedAddress.locationName.trim().isNotEmpty
                ? selectedAddress.locationName.trim()
                : 'Home';
    final addressText = selectedAddress == null
        ? 'Magarpatta Inner Circle, Magarpatta'
        : _selectedAddressText(selectedAddress);

    return Container(
      color: const Color(0xFF121212),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 14,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectAddress,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/thunder.svg',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '1-4 hrs delivery',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 28 / 19,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            addressLabel,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 18 / 12,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 14,
                          ),
                          Expanded(
                            child: Text(
                              ' - $addressText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 18 / 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.push(ReferralPage.routePath),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD0D4DC)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.card_giftcard_outlined,
                    size: 19,
                    color: Color(0xFF0A243F),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push(PersonalInfoPage.routePath),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD0D4DC)),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/profile.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectAddress() async {
    final selected = await context.push<AddressEntity>(
      AddressSelectionWidget.routePath,
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedAddress = selected);
  }

  String _selectedAddressText(AddressEntity address) {
    final parts = [
      address.addressLine1,
      address.addressLine2,
      address.sublocality,
      address.city,
      address.pincode,
    ].where((part) => part.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (address.formattedAddress.trim().isNotEmpty) {
      return address.formattedAddress.trim();
    }
    return address.locationName.trim();
  }
}
