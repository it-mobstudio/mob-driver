import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';

Future<PlaceDetails?> showLocationSearchSheet(
  BuildContext context,
  AddressBloc bloc,
) {
  return showModalBottomSheet<PlaceDetails>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _LocationSearchSheet(),
    ),
  );
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBloc, AddressState>(
      listenWhen: (previous, current) =>
          previous.selectedPlace != current.selectedPlace &&
          current.selectedPlace != null,
      listener: (context, state) => Navigator.pop(context, state.selectedPlace),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) =>
                    context.read<AddressBloc>().add(AddressSearchRequested(value)),
                decoration: InputDecoration(
                  hintText: 'Search for area, street name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _controller.clear,
                    icon: const Icon(Icons.close),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<AddressBloc, AddressState>(
                  builder: (context, state) {
                    if (state.isSearching) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null) {
                      return Center(child: Text(state.error!));
                    }
                    if (state.suggestions.isEmpty) {
                      return const Center(
                        child: Text('Enter at least 3 characters to search.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: state.suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = state.suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(suggestion.mainText),
                          subtitle: suggestion.secondaryText.isEmpty
                              ? null
                              : Text(suggestion.secondaryText),
                          onTap: () => context
                              .read<AddressBloc>()
                              .add(AddressPlaceSelected(suggestion.placeId)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
