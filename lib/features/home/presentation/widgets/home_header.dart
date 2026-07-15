import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/features/home/domain/store_delivery_label.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_account.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  AddressEntity? _selectedAddress;
  StoreOpenStatusEntity? _storeStatus;
  bool _storeStatusLoading = true;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuthSessionChanged);
    _loadSelectedAddress();
    _loadStoreStatus();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthSessionChanged);
    super.dispose();
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

    final deliveryText = storeDeliveryLabel(storeStatus);
    final deliveryIcon = storeStatus?.isOpen == false
        ? 'assets/images/timer-delivery.svg'
        : 'assets/images/thunder.svg';
    final profilePictureUrl = _profilePictureUrl();

    return Container(
      color: const Color(0xFF0A3C35),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _storeStatusLoading
                            ? const Padding(
                                key: ValueKey('delivery-loading'),
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: SkeletonBox(
                                  width: 130,
                                  height: 18,
                                  borderRadius: 6,
                                ),
                              )
                            : deliveryText.isEmpty
                                ? const SizedBox(
                                    key: ValueKey('delivery-empty'),
                                    height: 28,
                                  )
                                : Column(
                                    key: ValueKey(
                                      '$deliveryIcon|$deliveryText',
                                    ),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
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
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                                height: 28 / 19,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                      ),
                      Row(
                        children: [
                          Text(
                            addressLabel,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
                                fontWeight: FontWeight.w600,
                                height: 18 / 12,
                              ),
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/images/address-down.svg',
                            width: 10,
                            height: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push(MobstarPage.routePath),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 72,
                  height: 36,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/images/mobstaricon.svg',
                    width: 72,
                    height: 36,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _ProfileAvatar(profilePictureUrl: profilePictureUrl),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onAuthSessionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _profilePictureUrl() {
    return AppConfig.resolveMediaUrl(
      AuthSession.instance.userDetails?['profile_picture']?.toString(),
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

    // No cached selection for the current session (fresh login, or this
    // account never picked one) — the current user's own saved addresses
    // are the source of truth, never whatever a previous account left behind.
    final (addresses, failure) = await sl<AddressRepository>().getAddresses();
    if (!mounted) return;
    if (failure == null && addresses != null && addresses.isNotEmpty) {
      final firstSavedAddress = addresses.first;
      await SelectedAddressStore.save(firstSavedAddress);
      if (!mounted) return;
      setState(() => _selectedAddress = firstSavedAddress);
      return;
    }

    // New user, or an existing user with no saved address at all — proactively
    // ask for their location instead of waiting for them to notice the header.
    await _promptForLocation();
  }

  Future<void> _promptForLocation() async {
    final selected = await context.push<AddressEntity>(
      AddressSelectionWidget.routePath,
    );
    if (!mounted || selected == null) return;
    await SelectedAddressStore.save(selected);
    setState(() => _selectedAddress = selected);
  }

  Future<void> _loadStoreStatus() async {
    final (status, failure) = await sl<HomeRepository>().getStoreOpenStatus();
    if (!mounted) return;
    setState(() {
      _storeStatusLoading = false;
      if (failure == null && status != null) _storeStatus = status;
    });
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profilePictureUrl});

  final String profilePictureUrl;

  @override
  Widget build(BuildContext context) {
    if (profilePictureUrl.isEmpty || profilePictureUrl == 'null') {
      return const _ProfileIconFallback();
    }

    return Image.network(
      profilePictureUrl,
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ProfileIconFallback(),
    );
  }
}

class _ProfileIconFallback extends StatelessWidget {
  const _ProfileIconFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SvgPicture.asset(
        'assets/images/profile.svg',
        width: 15,
        height: 18,
      ),
    );
  }
}
