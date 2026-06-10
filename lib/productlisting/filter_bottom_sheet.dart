// widgets/filter_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  int selectedTab = 2;
  final List<String> tabs = [
    "Categories",
    "Price",
    "Brand",
    "Size",
    "Color",
    "Rating",
    "Delivery",
    "Discount",
    "Availability"
  ];

  final List<String> brandOptions = [
    "Pidilite",
    "Brand name",
    "Asian paints",
    "Brand name",
    "Brand name",
    "Brand name",
    "Brand name",
    "Brand name",
  ];

  final Set<int> selectedBrands = {3, 4};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text("Filters",
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context))
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    // Tabs (left)
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: tabs.length,
                        itemBuilder: (context, index) {
                          final isSelected = selectedTab == index;
                          return InkWell(
                            onTap: () {
                              setState(() => selectedTab = index);
                            },
                            child: Container(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFF5F5F5),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Container(
                                      width: 3,
                                      height: 20,
                                      color: Colors.blue,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tabs[index],
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.black87,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right content
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Search brand",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: const Color(0xFFF2F6F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: brandOptions.length,
                              itemBuilder: (context, index) {
                                final selected = selectedBrands.contains(index);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedBrands.add(index);
                                      } else {
                                        selectedBrands.remove(index);
                                      }
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(brandOptions[index],
                                      style: GoogleFonts.inter(fontSize: 14)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedBrands.clear();
                      });
                    },
                    child: Text("Clear filters",
                        style: GoogleFonts.inter(color: Colors.blue)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text("Apply",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
