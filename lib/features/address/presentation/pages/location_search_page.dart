import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/recent_address_searches_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/address_picker.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

/// A focused, full-page location search — autofocuses the search field on
/// open and shows recent searches before the user types, mirroring the
/// dedicated search pages used by delivery apps instead of the inline
/// search that used to live directly on [AddressSelectionWidget].
///
/// Resolves the picked suggestion and pops with the resolved
/// [AddressLocationEntity] (or `null` if the user backs out) — the caller
/// (`AddressSelectionWidget`) applies it, exactly like it already does for
/// "Current location".
class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  static const String routeName = 'LocationSearch';
  static const String routePath = '/location_search';

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  static const _navy = Color(0xFF0A243F);

  late final AddressBloc _addressBloc;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<AddressSuggestionEntity> _recent = const [];
  bool _hasQuery = false;

  // The suggestion currently being resolved, so it can be recorded into
  // recent-searches once `AddressLocationResolved` arrives — that state only
  // carries the resolved location, not which suggestion produced it.
  AddressSuggestionEntity? _pendingSuggestion;

  @override
  void initState() {
    super.initState();
    _addressBloc = sl<AddressBloc>();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await RecentAddressSearchesStore.read();
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _addressBloc.close();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _hasQuery = value.trim().isNotEmpty);
    _debounce?.cancel();
    if (value.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _addressBloc.add(AddressSearchRequested(value));
    });
  }

  void _selectSuggestion(AddressSuggestionEntity suggestion) {
    _pendingSuggestion = suggestion;
    _addressBloc.add(AddressLocationDetailsRequested(suggestion.placeId));
  }

  Future<void> _onStateChanged(BuildContext _, AddressState state) async {
    if (state is AddressLocationResolved) {
      final suggestion = _pendingSuggestion;
      if (suggestion != null) await RecentAddressSearchesStore.add(suggestion);
      if (!mounted) return;
      context.pop(state.location);
    } else if (state is AddressError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressBloc>.value(
      value: _addressBloc,
      child: BlocConsumer<AddressBloc, AddressState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final suggestions = state is AddressSearchLoaded
              ? state.suggestions
              : const <AddressSuggestionEntity>[];
          final isSearching =
              state is AddressSearching || state is AddressLoading;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: _navy,
              elevation: 0,
              leading: IconButton(
                icon: const AppBackIcon(),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Search location',
                style: GoogleFonts.inter(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      onChanged: _onChanged,
                      style: GoogleFonts.inter(
                        color: _navy,
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
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D4DC)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D4DC)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0360E5),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _hasQuery
                        ? _suggestionsList(suggestions, isSearching)
                        : _recentList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _suggestionsList(
    List<AddressSuggestionEntity> suggestions,
    bool isSearching,
  ) {
    if (isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (suggestions.isEmpty) {
      return Center(
        child: Text(
          'No matching places found.',
          style: GoogleFonts.inter(color: const Color(0xFF767C8F)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return AddressSuggestionTile(
          suggestion: suggestion,
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  Widget _recentList() {
    if (_recent.isEmpty) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent searches',
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () async {
                await RecentAddressSearchesStore.clear();
                if (!mounted) return;
                setState(() => _recent = const []);
              },
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0360E5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final suggestion in _recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AddressSuggestionTile(
              suggestion: suggestion,
              icon: Icons.history,
              onTap: () => _selectSuggestion(suggestion),
            ),
          ),
      ],
    );
  }
}
