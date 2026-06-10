import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_theme.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/location_search_sheet.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/map_location_widget.dart';

class AddressSelectionWidget extends StatelessWidget {
  const AddressSelectionWidget({super.key});

  static const routeName = 'AddressSelection';
  static const routePath = '/address_selection';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressBloc>()..add(AddressLoadRequested()),
      child: const _AddressSelectionView(),
    );
  }
}

class _AddressSelectionView extends StatelessWidget {
  const _AddressSelectionView();

  Future<void> _search(BuildContext context) async {
    final place =
        await showLocationSearchSheet(context, context.read<AddressBloc>());
    if (place != null && context.mounted) {
      await context.push(MapLocationWidget.routePath, extra: place);
      if (context.mounted) {
        context.read<AddressBloc>().add(AddressLoadRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        title: const Text('Search location'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                readOnly: true,
                onTap: () => _search(context),
                decoration: InputDecoration(
                  hintText: 'Search for area, street name...',
                  prefixIcon: Icon(Icons.search, color: theme.border),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.my_location,
                label: 'Detect my location',
                onTap: () async {
                  await context.push(MapLocationWidget.routePath);
                  if (context.mounted) {
                    context.read<AddressBloc>().add(AddressLoadRequested());
                  }
                },
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.add,
                label: 'Add new address',
                onTap: () => context.push(MapLocationWidget.routePath),
              ),
              const SizedBox(height: 24),
              Text(
                'Your saved address',
                style: theme.typography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<AddressBloc, AddressState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null && state.addresses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: () => context
                                  .read<AddressBloc>()
                                  .add(AddressLoadRequested()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.addresses.isEmpty) {
                      return const Center(child: Text('No saved addresses yet.'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<AddressBloc>().add(AddressLoadRequested());
                        await context.read<AddressBloc>().stream.firstWhere(
                              (next) => !next.isLoading,
                            );
                      },
                      child: ListView.separated(
                        itemCount: state.addresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) =>
                            _AddressCard(address: state.addresses[index]),
                      ),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return ListTile(
      onTap: onTap,
      tileColor: theme.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.border),
      ),
      leading: Icon(icon, color: theme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final AddressEntity address;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address.name.isEmpty ? 'Saved address' : address.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(address.displayAddress),
          if (address.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(address.phoneNumber),
          ],
          if (address.addressTag.isNotEmpty) ...[
            const SizedBox(height: 8),
            Chip(label: Text(address.addressTag)),
          ],
        ],
      ),
    );
  }
}
