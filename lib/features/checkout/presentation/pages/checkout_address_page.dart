import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_order_review_page.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';

class CheckoutAddressPage extends StatelessWidget {
  static const routeName = 'CheckoutAddressPage';
  static const routePath = '/checkout/address';

  const CheckoutAddressPage({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/cart');
    }
  }

  void _showAddressDrawer(
      BuildContext context, List<CartAddressEntity> addresses) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AddressSelectionDrawer(
          addresses: addresses,
          onAddAddress: () {
            Navigator.of(sheetContext).pop();
            _openAddressFlow(context);
          },
        );
      },
    );
  }

  Future<void> _openAddressFlow(BuildContext context) async {
    final savedAddress = await context.push(
      AddressSelectionWidget.routePath,
    );
    if (!context.mounted || savedAddress == null) return;
    context.read<CartBloc>().add(CartLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CheckoutHeader(onBack: () => _goBack(context)),
            Expanded(
              child: Container(
                color: const Color(0xFFF0F0F0),
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    return switch (state) {
                      CartInitial() || CartLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      CartError(:final message) => ErrorStateView(
                          title: 'Unable to load checkout',
                          message: message,
                          onRetry: () =>
                              context.read<CartBloc>().add(CartLoadRequested()),
                        ),
                      CartRequiresLogin() => const Center(
                          child: Text('Please login to continue.'),
                        ),
                      CartLoaded(:final summary) => Stack(
                          children: [
                            ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 118),
                              children: [
                                _DeliveryAddressCard(
                                  name: summary.shippingRecipientName,
                                  address: summary.shippingAddress,
                                  phone: summary.shippingPhone,
                                  actionLabel: summary.hasDeliveryAddress
                                      ? 'Change'
                                      : 'Add',
                                  onAction: () => _showAddressDrawer(
                                      context, summary.savedAddresses),
                                ),
                                const SizedBox(height: 12),
                                const _SameAddressRow(),
                                const SizedBox(height: 20),
                                _BillingAddressCard(
                                  address: summary.billingAddress,
                                  gstNumber: summary.billingGstNumber,
                                  actionLabel:
                                      summary.billingAddress.trim().isNotEmpty
                                          ? 'Change'
                                          : 'Add',
                                  onAction: () => _showAddressDrawer(
                                      context, summary.savedAddresses),
                                ),
                                const SizedBox(height: 20),
                                const _CouponsCard(),
                                const SizedBox(height: 20),
                                OrderDetailsCard(
                                  subtotal: summary.subtotal,
                                  shipping: summary.shipping,
                                  tax: summary.tax,
                                  savings: summary.savings,
                                  total: summary.total,
                                  rewardPoints: summary.rewardPoints,
                                ),
                              ],
                            ),
                            _BottomActionBar(
                              onPressed: () =>
                                  context.go(CheckoutOrderReviewPage.routePath),
                            ),
                          ],
                        ),
                    };
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Add address detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0A243F),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.47,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 48,
                height: 50,
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF0A243F),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.name,
    required this.address,
    required this.phone,
    required this.actionLabel,
    required this.onAction,
  });

  final String name;
  final String address;
  final String phone;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Add address';
    final displayAddress = address.trim().isNotEmpty
        ? address.trim()
        : 'Select a delivery address to continue';
    final displayPhone = phone.trim();

    return _CheckoutCard(
      height: 106,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 262,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 262,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Deliver to:',
                          style: TextStyle(
                            color: Color(0xFF67696D),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                          ),
                        ),
                        TextSpan(
                          text: ' $displayName',
                          style: const TextStyle(
                            color: Color(0xFF0A243F),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 262,
                  child: Text(
                    [
                      displayAddress,
                      if (displayPhone.isNotEmpty) displayPhone,
                    ].join('\n'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF67696D),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.50,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Text(
              actionLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF2973F0),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SameAddressRow extends StatelessWidget {
  const _SameAddressRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF767C8F)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Use same address for delivery and billing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0A243F),
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _BillingAddressCard extends StatelessWidget {
  const _BillingAddressCard({
    required this.address,
    required this.gstNumber,
    required this.actionLabel,
    required this.onAction,
  });

  final String address;
  final String gstNumber;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final displayAddress = address.trim();
    final displayGstNumber = gstNumber.trim();

    return _CheckoutCard(
      height: 128,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Billing address',
                  style: TextStyle(
                    color: Color(0xFF0A243F),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0360E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 20,
            child: displayGstNumber.isNotEmpty
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text(
                          'GST NO: $displayGstNumber',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A243F),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 16 / 11,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Text(
            displayAddress.isNotEmpty
                ? displayAddress
                : 'Add billing address to continue',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF767C8F),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponsCard extends StatelessWidget {
  const _CouponsCard();

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.discount_outlined,
            color: Color(0xFF0A243F),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'View all coupons',
              style: const TextStyle(
                color: Color(0xFF0A243F),
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.54,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFF767C8F),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _AddressSelectionDrawer extends StatelessWidget {
  const _AddressSelectionDrawer({
    required this.addresses,
    required this.onAddAddress,
  });

  final List<CartAddressEntity> addresses;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 656 / 812,
        widthFactor: 1,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select partner',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 22 / 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.close,
                              color: Color(0xFF0A243F),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _AddAddressTile(onTap: onAddAddress),
                  const SizedBox(height: 16),
                  Text(
                    'Your saved address',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: addresses.isEmpty
                        ? _EmptyAddressState(onAddAddress: onAddAddress)
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _SavedAddressCard(
                                address: addresses[index],
                                onTap: () => Navigator.of(context).pop(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAddressTile extends StatelessWidget {
  const _AddAddressTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF0A243F),
              size: 16,
            ),
            const SizedBox(width: 12),
            Text(
              'Add new address',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 20 / 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.onTap,
  });

  final CartAddressEntity address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.name.trim().isNotEmpty
                        ? address.name.trim()
                        : 'Saved address',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 20 / 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF767C8F),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              address.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF767C8F),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (address.tag.trim().isNotEmpty)
                  _AddressPill(
                    text: address.tag.trim(),
                    color: const Color(0xFFE6EEF9),
                  ),
                if (address.project.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: _AddressPill(
                      text: address.project.trim().startsWith('Project:')
                          ? address.project.trim()
                          : 'Project: ${address.project.trim()}',
                      color: const Color(0xFFFFEFCE),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 16 / 11,
        ),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.onAddAddress});

  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onAddAddress,
        child: Text(
          'No saved address. Add new address',
          style: GoogleFonts.inter(
            color: const Color(0xFF0360E5),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF0360E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save and continue',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 22 / 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.child,
    this.height,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
