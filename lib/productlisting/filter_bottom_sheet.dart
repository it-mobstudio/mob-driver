import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.sections,
    this.initialSectionKey,
    this.title = 'Filters',
    this.showSidebar = true,
    this.selectedValuesByKey = const <String, Set<String>>{},
    this.onSelectionChanged,
  });

  final List<BrowseFilterSection> sections;
  final String? initialSectionKey;
  final String title;
  final bool showSidebar;
  final Map<String, Set<String>> selectedValuesByKey;
  final ValueChanged<Map<String, Set<String>>>? onSelectionChanged;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  int _selectedTab = 0;
  String _searchQuery = '';
  final Map<String, Set<String>> _selectedValuesByKey = <String, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _selectedTab = _preferredInitialTab(widget.sections, widget.initialSectionKey);
    _selectedValuesByKey.addAll(
      widget.selectedValuesByKey.map(
        (key, value) => MapEntry(key, Set<String>.from(value)),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant FilterBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedTab >= widget.sections.length) {
      _selectedTab = _preferredInitialTab(widget.sections, widget.initialSectionKey);
    }
  }

  int _preferredInitialTab(
    List<BrowseFilterSection> sections,
    String? initialSectionKey,
  ) {
    if (initialSectionKey != null) {
      final index =
          sections.indexWhere((section) => section.key == initialSectionKey);
      if (index >= 0) return index;
    }
    return 0;
  }

  void _setOptionSelected(String key, String value, bool selected) {
    final selectedValues = _selectedValuesByKey.putIfAbsent(
      key,
      () => <String>{},
    );
    if (selected) {
      selectedValues.add(value);
    } else {
      selectedValues.remove(value);
      if (selectedValues.isEmpty) {
        _selectedValuesByKey.remove(key);
      }
    }
  }

  Map<String, Set<String>> _selectedValuesSnapshot() {
    return _selectedValuesByKey.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    );
  }

  int get _selectedCount {
    return _selectedValuesByKey.values.fold<int>(
      0,
      (count, values) => count + values.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final selectedSection = sections.isNotEmpty ? sections[_selectedTab] : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                _Header(
                  title: widget.title,
                  onClose: () => Navigator.pop(context),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7E7)),
                Expanded(
                  child: sections.isEmpty
                      ? const _EmptyFilters()
                      : widget.showSidebar
                          ? Row(
                          children: [
                            _FilterSidebar(
                              sections: sections,
                              selectedTab: _selectedTab,
                              onSelected: (index) {
                                setState(() {
                                  _selectedTab = index;
                                  _searchQuery = '';
                                });
                              },
                            ),
                            Expanded(
                              child: _FilterOptionsPane(
                                section: selectedSection!,
                                scrollController: scrollController,
                                searchQuery: _searchQuery,
                                selectedValues:
                                    _selectedValuesByKey[selectedSection.key] ??
                                        <String>{},
                                onSearchChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                onOptionChanged: (option, selected) {
                                  setState(() {
                                    _setOptionSelected(
                                      selectedSection.key,
                                      option.value,
                                      selected,
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                          : _FilterOptionsPane(
                              section: selectedSection!,
                              scrollController: scrollController,
                              searchQuery: _searchQuery,
                              selectedValues:
                                  _selectedValuesByKey[selectedSection.key] ??
                                      <String>{},
                              onSearchChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              onOptionChanged: (option, selected) {
                                setState(() {
                                  _setOptionSelected(
                                    selectedSection.key,
                                    option.value,
                                    selected,
                                  );
                                });
                              },
                            ),
                ),
                if (sections.isNotEmpty)
                  _FilterActions(
                    selectedCount: _selectedCount,
                    onClear: () {
                      setState(() {
                        _selectedValuesByKey.clear();
                      });
                    },
                    onApply: () {
                      widget.onSelectionChanged?.call(
                        _selectedValuesSnapshot(),
                      );
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterActions extends StatelessWidget {
  const _FilterActions({
    required this.selectedCount,
    required this.onClear,
    required this.onApply,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 76,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE7E7E7)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              height: 48,
              child: OutlinedButton(
                onPressed: selectedCount == 0 ? null : onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0A243F),
                  disabledForegroundColor: const Color(0xFFB5B5B5),
                  side: BorderSide(
                    color: selectedCount == 0
                        ? const Color(0xFFE7E7E7)
                        : const Color(0xFFDFE4EC),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear all',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF0360E5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB5B5B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    selectedCount == 0
                        ? 'Apply filters'
                        : 'Apply filters ($selectedCount)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 22 / 15,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close,
              color: Color(0xFF0A243F),
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _FilterSidebar extends StatelessWidget {
  const _FilterSidebar({
    required this.sections,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<BrowseFilterSection> sections;
  final int selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      color: const Color(0xFFF1F1F2),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = index == selectedTab;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(index),
            child: Container(
              height: 49,
              color: isSelected ? Colors.white : const Color(0xFFF1F1F2),
              child: Stack(
                children: [
                  if (isSelected)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0360E5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    left: 16,
                    right: 8,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        section.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? const Color(0xFF0360E5)
                              : const Color(0xFF0A243F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterOptionsPane extends StatelessWidget {
  const _FilterOptionsPane({
    required this.section,
    required this.scrollController,
    required this.searchQuery,
    required this.selectedValues,
    required this.onSearchChanged,
    required this.onOptionChanged,
  });

  final BrowseFilterSection section;
  final ScrollController scrollController;
  final String searchQuery;
  final Set<String> selectedValues;
  final ValueChanged<String> onSearchChanged;
  final void Function(BrowseFilterOption option, bool selected) onOptionChanged;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final options = section.options.where((option) {
      if (query.isEmpty) return true;
      return option.label.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
      child: Column(
        children: [
          if (section.searchable) ...[
            _SearchField(
              hintText: 'Search ${section.label.toLowerCase()}',
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 13),
          ],
          Expanded(
            child: options.isEmpty
                ? const _NoOptions()
                : ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return _FilterOptionRow(
                        option: option,
                        selected: selectedValues.contains(option.value),
                        onChanged: (selected) =>
                            onOptionChanged(option, selected),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: const Color(0x990A243F),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF0A243F),
            size: 18,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDEDEDE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0360E5)),
          ),
        ),
      ),
    );
  }
}

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.option,
    required this.selected,
    required this.onChanged,
  });

  final BrowseFilterOption option;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!selected),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0360E5) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF0360E5)
                      : const Color(0xFF7E868A),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.count > 0 ? '${option.label} (${option.count})' : option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF676A6C),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilters extends StatelessWidget {
  const _EmptyFilters();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No filters available',
        style: GoogleFonts.inter(
          color: const Color(0xFF676A6C),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _NoOptions extends StatelessWidget {
  const _NoOptions();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        'No options',
        style: GoogleFonts.inter(
          color: const Color(0xFF676A6C),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
