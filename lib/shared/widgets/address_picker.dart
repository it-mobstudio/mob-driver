import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';

/// The saved-address-picker UI, shared by the nav bar's full-page
/// AddressSelectionWidget, My Account's "Addresses" menu, cart's "Change"
/// bottom sheet, and checkout's delivery/billing "Change" bottom sheet.
///
/// Fully controlled — no navigation or network calls of its own. Each
/// caller supplies the address list, search/suggestion state, and
/// callbacks, then wraps this in whatever chrome fits (a Scaffold body for
/// full pages, a Material sheet for bottom sheets).
class AddressPickerBody extends StatelessWidget {
  const AddressPickerBody({
    super.key,
    required this.addresses,
    required this.onSelectAddress,
    required this.onEditAddress,
    required this.onDeleteAddress,
    required this.onAddNewAddress,
    this.selectedAddressId,
    this.showSearch = true,
    this.showQuickActions = false,
    this.searchController,
    this.onSearchChanged,
    this.suggestions = const [],
    this.onSelectSuggestion,
    this.isSearching = false,
    this.isLoadingAddresses = false,
    this.detectingCurrentLocation = false,
    this.onCurrentLocation,
    this.onMapsLink,
  });

  final List<AddressEntity> addresses;
  final String? selectedAddressId;
  final ValueChanged<AddressEntity> onSelectAddress;
  final ValueChanged<AddressEntity> onEditAddress;
  final ValueChanged<AddressEntity> onDeleteAddress;
  final VoidCallback onAddNewAddress;

  final bool showSearch;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<AddressSuggestionEntity> suggestions;
  final ValueChanged<AddressSuggestionEntity>? onSelectSuggestion;
  final bool isSearching;
  final bool isLoadingAddresses;
  final bool showQuickActions;
  final bool detectingCurrentLocation;
  final VoidCallback? onCurrentLocation;
  final VoidCallback? onMapsLink;

  static const _navy = Color(0xFF0A243F);

  @override
  Widget build(BuildContext context) {
    final showSuggestions = showSearch && suggestions.isNotEmpty;
    final savedAddresses = _orderedSavedAddresses();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showSearch) ...[
          _searchField(),
          const SizedBox(height: 16),
        ],
        if (showQuickActions && !showSuggestions) ...[
          Row(
            children: [
              Expanded(
                child: _quickActionPill(
                  svgAsset: 'assets/images/currentlocation.svg',
                  label: 'Current location',
                  loading: detectingCurrentLocation,
                  onTap: onCurrentLocation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionPill(
                  svgAsset: 'assets/images/Maps icon app.png',
                  label: 'Maps link',
                  onTap: onMapsLink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (showSuggestions)
          ..._suggestionTiles()
        else ...[
          _addNewAddressTile(),
          const SizedBox(height: 24),
          Text(
            'Your saved address',
            style: GoogleFonts.inter(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoadingAddresses)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (addresses.isEmpty)
            const _EmptySavedAddress()
          else
            ...savedAddresses.map(
              (address) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AddressPickerCard(
                  address: address,
                  isSelected: selectedAddressId != null &&
                      selectedAddressId == address.id,
                  onTap: () => onSelectAddress(address),
                  onEdit: () => onEditAddress(address),
                  onDelete: () => onDeleteAddress(address),
                ),
              ),
            ),
        ],
      ],
    );
  }

  List<AddressEntity> _orderedSavedAddresses() {
    final selectedId = selectedAddressId?.trim() ?? '';
    if (selectedId.isEmpty) return addresses;

    final selected = <AddressEntity>[];
    final others = <AddressEntity>[];
    for (final address in addresses) {
      if (address.id.trim() == selectedId) {
        selected.add(address);
      } else {
        others.add(address);
      }
    }
    return [...selected, ...others];
  }

  Widget _searchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: GoogleFonts.inter(
        color: const Color(0xFF0A243F),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search for area, street name..',
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFFAFB4C0),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SvgPicture.asset(
            'assets/images/Searchicon.svg',
            width: 16,
            height: 16,
            fit: BoxFit.contain,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD0D4DC),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD0D4DC),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF0360E5),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _quickActionPill({
    required String svgAsset,
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFDFE1E7),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF596378),
                  ),
                )
              else
                SizedBox(
                  width: 16,
                  height: 16,
                  child: svgAsset.toLowerCase().endsWith('.svg')
                      ? SvgPicture.asset(
                          svgAsset,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          svgAsset,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF596378),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 20 / 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addNewAddressTile() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onAddNewAddress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFDFE1E7),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
                color: Color(0xFF2973F0),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add new address',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2973F0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _suggestionTiles() {
    if (isSearching) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    return suggestions
        .map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AddressSuggestionTile(
              suggestion: suggestion,
              onTap: onSelectSuggestion == null
                  ? null
                  : () => onSelectSuggestion!(suggestion),
            ),
          ),
        )
        .toList();
  }
}

/// A single search-result (or recent-search) row: a location icon, the
/// place's primary/secondary text. Shared by [AddressPickerBody]'s inline
/// suggestion list and `LocationSearchPage`'s dedicated search/recents list
/// so both render identically.
class AddressSuggestionTile extends StatelessWidget {
  const AddressSuggestionTile({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.icon = Icons.location_on_outlined,
  });

  final AddressSuggestionEntity suggestion;
  final VoidCallback? onTap;
  final IconData icon;

  static const _navy = Color(0xFF0A243F);
  static const _muted = Color(0xFF767C8F);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: _navy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.primaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (suggestion.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        suggestion.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySavedAddress extends StatelessWidget {
  const _EmptySavedAddress();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text(
          'No saved addresses yet.',
          style: GoogleFonts.inter(color: const Color(0xFF767C8F)),
        ),
      ),
    );
  }
}

/// A single saved-address row: name (+ "SELECTED" badge), address text,
/// tag/project pills, and the edit/delete overflow menu.
class AddressPickerCard extends StatelessWidget {
  const AddressPickerCard({
    super.key,
    required this.address,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  final AddressEntity address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  static const _navy = Color(0xFF0A243F);
  static const _muted = Color(0xFF596378);
  static const _border = Color(0xFFDFE4EC);

  @override
  Widget build(BuildContext context) {
    final name = address.name.trim().isNotEmpty
        ? address.name.trim()
        : (address.locationName.trim().isNotEmpty
            ? address.locationName.trim()
            : 'Saved address');
    final addressText = _fullAddressText(address);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const _SelectedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addressText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 16 / 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (address.addressTag.trim().isNotEmpty)
                        _AddressPill(
                          text: address.addressTag.trim(),
                          color: const Color(0xFFF7F7F7),
                        ),
                      if (address.projectName.trim().isNotEmpty)
                        _AddressPill(
                          text:
                              address.projectName.trim().startsWith('Project:')
                                  ? address.projectName.trim()
                                  : 'Project: ${address.projectName.trim()}',
                          color: const Color(0xFFFFD911),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit address'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete address'),
                    ),
                ],
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/images/Menu.svg',
                    width: 12,
                    height: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fullAddressText(AddressEntity address) {
    final lineParts = [
      address.addressLine1,
      address.addressLine2,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

    final parts = [
      if (lineParts.isEmpty) address.formattedAddress,
      ...lineParts,
      address.city,
      address.state,
      address.pincode,
    ];

    final seen = <String>{};
    return parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => seen.add(part.toLowerCase()))
        .join(', ');
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F7EC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SELECTED',
            style: GoogleFonts.inter(
              color: const Color(0xFF13A05A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 16 / 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // maxWidth bounds the Text directly so its ellipsis can kick in — a Row
    // wrapper here would give Text unbounded width (Row lays out non-flex
    // children loosely) and overflow instead of truncating.
    return Container(
      height: 20,
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
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
