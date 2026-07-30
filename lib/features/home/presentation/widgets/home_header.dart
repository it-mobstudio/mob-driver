import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/domain/repositories/cart_repository.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';
import 'package:m_o_b_demand_side/features/home/domain/store_delivery_label.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_account.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

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
    SelectedAddressStore.addListener(_onSelectedAddressChanged);
    _loadSelectedAddress();
    _loadStoreStatus();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthSessionChanged);
    SelectedAddressStore.removeListener(_onSelectedAddressChanged);
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

    final isOpen = storeStatus?.isOpen ?? true;
    // Figma shows a small "Scheduled after ..." subtitle above a bold
    // "Delivery tomorrow"/"Delivery today" headline when closed, both derived
    // from the raw store message — distinct from the shared
    // storeDeliveryLabel() used by cart/checkout (which mirrors web's single
    // raw-message line and has no dedicated "closed" wording of its own).
    final closedParts = storeClosedDeliveryParts(storeStatus);
    final closedSubtitle = !isOpen ? closedParts.subtitle : '';
    final deliveryText =
        !isOpen ? closedParts.title : storeDeliveryLabel(storeStatus);
    final deliveryIcon = storeStatus?.isOpen == false
        ? 'assets/images/timer-delivery.svg'
        : 'assets/images/thunder.svg';
    final profilePictureUrl = _profilePictureUrl();
    final notServiceable = context.watch<HomeBloc>().state is HomeNotServiceable;
    final cartState = context.watch<CartBloc>().state;
    final mobStarLevel =
        cartState is CartLoaded ? cartState.summary.account.membership : 'Bronze';

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
                        child: notServiceable
                            ? const Padding(
                                key: ValueKey('delivery-not-serviceable'),
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: _NotServiceablePill(),
                              )
                            : _storeStatusLoading
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
                                      '$deliveryIcon|$deliveryText|$closedSubtitle',
                                    ),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (closedSubtitle.isNotEmpty) ...[
                                        Text(
                                          closedSubtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            height: 18 / 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
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
                            width: 8,
                            height: 8,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => context.push(MobstarPage.routePath),
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 72,
                  height: 36,
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        'assets/images/mobstaricon_base.svg',
                        width: 72,
                        height: 36,
                      ),
                      // Positioned to match the star's bounding box from the
                      // original flat mobstaricon.svg (x: 8.04-27.02,
                      // y: 9-27.02) so swapping tiers doesn't shift the star.
                      Positioned(
                        left: 8,
                        top: 9,
                        child: SvgPicture.asset(
                          _mobStarAsset(mobStarLevel),
                          width: 19,
                          height: 18,
                        ),
                      ),
                    ],
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

  void _onSelectedAddressChanged() {
    if (!mounted) return;
    setState(() => _selectedAddress = SelectedAddressStore.cached);
    _refreshHomeForSelectedCity();
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
    await _syncDeliveryAddressToOrder(selected);
  }

  Future<void> _syncDeliveryAddressToOrder(AddressEntity address) async {
    final deliveryId = int.tryParse(address.id) ?? 0;
    if (deliveryId == 0) return;

    CartSummaryEntity? summary;
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded) {
      summary = cartState.summary;
    } else {
      final (loadedSummary, failure) = await sl<CartRepository>().getCart();
      if (!mounted || failure != null) return;
      summary = loadedSummary;
    }
    if (summary == null) return;

    final cartId = int.tryParse(summary.cartId) ?? 0;
    if (cartId == 0) return;

    final result = await sl<CheckoutRepository>().updateAddressToOrder({
      'cart_id': cartId,
      'order_delivery_address': deliveryId,
      'order_billing_address': deliveryId,
    });
    final failure = result.$2;
    if (!mounted) return;
    if (failure != null) {
      TopSnackBar.show(
        context,
        message: failure.message,
        type: TopSnackBarType.error,
      );
      return;
    }
    context.read<CartBloc>().add(CartLoadRequested());
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
      return;
    }

    // New user, or an existing user with no saved address at all — proactively
    // ask for their location instead of waiting for them to notice the header.
    await _promptForLocation();
  }

  Future<void> _promptForLocation() async {
    final selected = await context.push<AddressEntity>(
      '${AddressSelectionWidget.routePath}?hideBack=true',
      extra: {
        'showBackButton': false,
        'autoDetectCurrentLocation': true,
      },
    );
    if (!mounted || selected == null) return;
    await SelectedAddressStore.save(selected);
  }

  void _refreshHomeForSelectedCity() {
    if (!mounted) return;
    context.read<HomeBloc>().add(HomeRefreshRequested());
    setState(() => _storeStatusLoading = true);
    _loadStoreStatus();
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

  // Mirrors the same level->asset mapping used on my_account.dart and
  // mobstar_page.dart, so the header badge always matches the tier shown on
  // the full mobSTAR pages.
  String _mobStarAsset(String level) {
    final lower = level.toLowerCase();
    if (lower.contains('diamond') || lower.contains('dimond')) {
      return 'assets/images/mobStar/dimond.svg';
    }
    if (lower.contains('platinum')) return 'assets/images/mobStar/platinum.svg';
    if (lower.contains('gold')) return 'assets/images/mobStar/gold.svg';
    if (lower.contains('silver')) return 'assets/images/mobStar/silver.svg';
    return 'assets/images/mobStar/bronze.svg';
  }
}

class _NotServiceablePill extends StatelessWidget {
  const _NotServiceablePill();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/images/error.svg', width: 20, height: 20),
        const SizedBox(width: 8),
        Text(
          'Not serviceable',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 28 / 19,
          ),
        ),
      ],
    );
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
