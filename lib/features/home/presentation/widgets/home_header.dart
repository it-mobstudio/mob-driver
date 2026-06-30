import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_account.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  AddressEntity? _selectedAddress;
  StoreOpenStatusEntity? _storeStatus;

  @override
  void initState() {
    super.initState();
    _loadSelectedAddress();
    _loadStoreStatus();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAddress = _selectedAddress;
    final storeStatus = _storeStatus;
    final addressLabel = selectedAddress == null
        ? 'Select location'
        : selectedAddress.addressTag.trim().isNotEmpty
            ? selectedAddress.addressTag.trim()
            : selectedAddress.locationName.trim().isNotEmpty
                ? selectedAddress.locationName.trim()
                : 'Home';
    final addressText = selectedAddress == null
        ? 'Tap to set your delivery address'
        : _selectedAddressText(selectedAddress);
    final deliveryText = storeStatus?.message.trim().isNotEmpty == true
        ? '${storeStatus!.message.trim()} delivery'
        : '';
    final deliveryIcon = storeStatus?.isOpen == false
        ? 'assets/images/timer-delivery.svg'
        : 'assets/images/thunder.svg';

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
                            deliveryIcon,
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deliveryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 28 / 19,
                              ),
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
                          // const Icon(
                          //   Icons.keyboard_arrow_down,
                          //   color: Colors.white,
                          //   size: 14,
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push(ReferralPage.routePath),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 72,
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
                onTap: () => context.push(MyAccountWidget.routePath),
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
    await SelectedAddressStore.save(selected);
    setState(() => _selectedAddress = selected);
  }

  Future<void> _loadSelectedAddress() async {
    final selected = await SelectedAddressStore.read();
    if (!mounted) return;
    if (selected != null) {
      setState(() => _selectedAddress = selected);
      return;
    }

    final (addresses, failure) = await sl<AddressRepository>().getAddresses();
    if (!mounted || failure != null || addresses == null || addresses.isEmpty) {
      return;
    }
    final firstSavedAddress = addresses.first;
    await SelectedAddressStore.save(firstSavedAddress);
    if (!mounted) return;
    setState(() => _selectedAddress = firstSavedAddress);
  }

  Future<void> _loadStoreStatus() async {
    final (status, failure) = await sl<HomeRepository>().getStoreOpenStatus();
    if (!mounted || failure != null || status == null) return;
    setState(() => _storeStatus = status);
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
