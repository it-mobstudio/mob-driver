import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/address_selection/map_location_widget.dart';
import 'package:m_o_b_demand_side/homepage/homepage_widget.dart';
import '../core/app_runtime/flutter_flow_theme.dart';

class AddressSelectionWidget extends StatelessWidget {
  const AddressSelectionWidget({super.key});

  static String routeName = 'AddressSelection';
  static String routePath = '/address_selection';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0.0,
        title: Text('Search location',
            style: theme.typography.titleLarge.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for area, street name..',
                  prefixIcon: Icon(Icons.search, color: theme.border),
                  filled: true,
                  fillColor: theme.secondaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  GoRouter.of(context)
                      .go(MapLocationWidget.routePath); // Navigate to map location page
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.my_location, color: theme.primary),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detect my location',
                              style: theme.typography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: theme.textDarkGrey)),
                          Text('Koramangala, Bengaluru',
                              style: theme.typography.bodyMedium
                                  .copyWith(color: theme.textDarkGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: theme.primary),
                      const SizedBox(width: 8),
                      Text('Add new address',
                          style: theme.typography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Your saved address',
                  style: theme.typography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _addressCard(
                        context,
                        'Corey Howell',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                    _addressCard(
                        context,
                        'Lando Norris',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                    _addressCard(
                        context,
                        'Johnathan Wick',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                    _addressCard(
                        context,
                        'Corey Howell',
                        '66138 Legros Mission Suite 804 Eden Plain Apt. 613, Behind starbucks Chennai, 600009',
                        'Home',
                        'Project: Hotel California'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressCard(BuildContext context, String name, String address,
      String tag, String project) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).go(HomepageWidget.routePath);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: theme.typography.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.more_horiz, color: theme.border),
              ],
            ),
            const SizedBox(height: 4),
            Text(address,
                style: theme.typography.bodyMedium
                    .copyWith(color: theme.textDarkGrey, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag,
                      style: theme.typography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(project,
                      style: theme.typography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
