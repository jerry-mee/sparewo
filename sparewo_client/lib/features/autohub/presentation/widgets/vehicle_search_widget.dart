// lib/features/autohub/presentation/widgets/vehicle_search_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/my_car/application/car_data_provider.dart';

class VehicleSearchWidget extends ConsumerStatefulWidget {
  final String? initialBrand;
  final String? initialModel;
  final int? initialYear;
  final Function(String brand, String model, int year) onVehicleSelected;

  const VehicleSearchWidget({
    super.key,
    this.initialBrand,
    this.initialModel,
    this.initialYear,
    required this.onVehicleSelected,
  });

  @override
  ConsumerState<VehicleSearchWidget> createState() =>
      _VehicleSearchWidgetState();
}

class _VehicleSearchWidgetState extends ConsumerState<VehicleSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  String? selectedBrand;
  String? selectedModel;
  int? selectedYear;

  // Dropdown filter queries
  String _brandQuery = '';
  String _modelQuery = '';

  // Main search results
  List<String> searchResults = [];
  bool isSearchMode = false;

  // Dropdown visibility toggles
  bool showBrandDropdown = false;
  bool showModelDropdown = false;
  bool showYearDropdown = false;

  Timer? _debounceTimer;
  late final List<int> yearsList;

  @override
  void initState() {
    super.initState();
    selectedBrand = widget.initialBrand;
    selectedModel = widget.initialModel;
    selectedYear = widget.initialYear;

    final currentYear = DateTime.now().year;
    yearsList = List.generate(
      currentYear - 1984,
      (index) => currentYear - index,
    );

    // Ensure models are loaded if brand is pre-selected
    if (selectedBrand != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(carModelsProvider(selectedBrand!));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleGlobalSearch(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = <String>[];
      final queryLower = query.toLowerCase();

      // 1. Search Brands (Always available)
      final allBrands = await ref.read(carBrandsProvider.future);
      for (final b in allBrands) {
        if (b.toLowerCase().contains(queryLower)) results.add(b);
      }

      // 2. Search Models (Only if brand is selected, or rudimentary check if no brand)
      // Note: Searching models across ALL brands is handled via a different provider in
      // CarSelector. Here we keep it simple or strictly robust to selected brand.
      if (selectedBrand != null) {
        final models = await ref.read(carModelsProvider(selectedBrand!).future);
        for (final m in models) {
          if (m.toLowerCase().contains(queryLower)) {
            // Display as "Brand - Model" to be clear
            results.add("$selectedBrand - $m");
          }
        }
      }

      if (mounted) {
        setState(() {
          searchResults = results.take(15).toList();
        });
      }
    });
  }

  void _notifySelection() {
    if (selectedBrand != null &&
        selectedModel != null &&
        selectedYear != null) {
      widget.onVehicleSelected(selectedBrand!, selectedModel!, selectedYear!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(carBrandsProvider);
    final modelsAsync = selectedBrand != null
        ? ref.watch(carModelsProvider(selectedBrand!))
        : null;

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        boxShadow: AppShadows.cardShadow,
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Vehicle', style: AppTextStyles.h4),
              // Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      isSearchMode = !isSearchMode;
                      _resetUIState();
                    });
                  },
                  icon: Icon(
                    isSearchMode ? Icons.list_alt : Icons.search,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  tooltip: isSearchMode ? 'Use List' : 'Search',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Area
          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isSearchMode
                ? _buildGlobalSearchField(theme)
                : _buildDropdownsFlow(brandsAsync, modelsAsync, theme),
          ),

          // Selection Summary
          if (selectedBrand != null &&
              selectedModel != null &&
              selectedYear != null)
            _buildSelectionSummary(),
        ],
      ),
    );
  }

  void _resetUIState() {
    _searchController.clear();
    searchResults = [];
    showBrandDropdown = false;
    showModelDropdown = false;
    showYearDropdown = false;
  }

  // --- Search Mode ---

  Widget _buildGlobalSearchField(ThemeData theme) {
    final hintText = selectedBrand == null
        ? 'Search Brand (e.g. Toyota)'
        : 'Search Model for $selectedBrand';

    return Column(
      children: [
        TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _handleGlobalSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _handleGlobalSearch,
        ),
        if (selectedBrand == null) ...[
          const SizedBox(height: 8),
          Text(
            'Tip: Select a brand first to search for models.',
            style: AppTextStyles.bodySmall.copyWith(color: theme.hintColor),
          ),
        ],
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = searchResults[index];
                final isModel = result.contains(' - ');
                return ListTile(
                  title: Text(result, style: AppTextStyles.bodyMedium),
                  leading: Icon(
                    isModel ? Icons.commute : Icons.directions_car,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onTap: () => _handleSearchResultTap(result, isModel),
                );
              },
            ),
          ),
      ],
    );
  }

  void _handleSearchResultTap(String result, bool isModel) {
    if (isModel) {
      final parts = result.split(' - ');
      setState(() {
        selectedBrand = parts[0];
        selectedModel = parts[1];
        isSearchMode = false;
        _resetUIState();
        showYearDropdown = true; // Auto-open year
      });
    } else {
      setState(() {
        selectedBrand = result;
        selectedModel = null;
        _searchController.clear();
        searchResults = [];
        // Keep search mode active to search models immediately
        // But update UI to reflect brand selection
      });
      // Ensure models load for the brand
      ref.read(carModelsProvider(selectedBrand!));
    }
  }

  // --- Dropdown Flow ---

  Widget _buildDropdownsFlow(
    AsyncValue<List<String>> brandsAsync,
    AsyncValue<List<String>>? modelsAsync,
    ThemeData theme,
  ) {
    return Column(
      children: [
        _buildDropdownItem(
          label: selectedBrand ?? 'Select Brand',
          icon: Icons.directions_car_outlined,
          isOpen: showBrandDropdown,
          onTap: () => setState(() {
            showBrandDropdown = !showBrandDropdown;
            showModelDropdown = false;
            showYearDropdown = false;
          }),
          child: _buildBrandList(brandsAsync),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: selectedBrand == null ? 0.5 : 1.0,
          child: _buildDropdownItem(
            label: modelsAsync?.isLoading == true
                ? 'Loading...'
                : selectedModel ?? 'Select Model',
            icon: Icons.commute_outlined,
            isOpen: showModelDropdown,
            onTap: selectedBrand == null
                ? null
                : () => setState(() {
                    showModelDropdown = !showModelDropdown;
                    showBrandDropdown = false;
                    showYearDropdown = false;
                  }),
            child: _buildModelList(modelsAsync),
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: selectedModel == null ? 0.5 : 1.0,
          child: _buildDropdownItem(
            label: selectedYear?.toString() ?? 'Select Year',
            icon: Icons.calendar_today_outlined,
            isOpen: showYearDropdown,
            onTap: selectedModel == null
                ? null
                : () => setState(() {
                    showYearDropdown = !showYearDropdown;
                    showBrandDropdown = false;
                    showModelDropdown = false;
                  }),
            child: _buildYearList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownItem({
    required String label,
    required IconData icon,
    required bool isOpen,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isSelected =
        label != 'Select Brand' &&
        label != 'Select Model' &&
        label != 'Select Year' &&
        label != 'Loading...';

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOpen
                    ? AppColors.primary
                    : (isSelected
                          ? AppColors.primary.withOpacity(0.5)
                          : theme.dividerColor),
                width: isOpen || isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isOpen || isSelected
                      ? AppColors.primary
                      : theme.disabledColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isOpen || isSelected
                          ? theme.textTheme.bodyLarge?.color
                          : theme.hintColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: theme.hintColor,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.floatingShadow,
              border: Border.all(color: theme.dividerColor),
            ),
            child: child,
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
      ],
    );
  }

  Widget _buildBrandList(AsyncValue<List<String>> brandsAsync) {
    return brandsAsync.when(
      data: (brands) {
        final filtered = _brandQuery.isEmpty
            ? brands
            : brands
                  .where(
                    (b) => b.toLowerCase().contains(_brandQuery.toLowerCase()),
                  )
                  .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Filter brands...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _brandQuery = v),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final brand = filtered[index];
                  final isSelected = selectedBrand == brand;
                  return ListTile(
                    title: Text(brand, style: AppTextStyles.bodyMedium),
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        selectedBrand = brand;
                        selectedModel = null;
                        showBrandDropdown = false;
                        showModelDropdown = true;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const Center(child: Text("Failed to load")),
    );
  }

  Widget _buildModelList(AsyncValue<List<String>>? modelsAsync) {
    if (modelsAsync == null) return const SizedBox.shrink();

    return modelsAsync.when(
      data: (models) {
        final filtered = _modelQuery.isEmpty
            ? models
            : models
                  .where(
                    (m) => m.toLowerCase().contains(_modelQuery.toLowerCase()),
                  )
                  .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Filter models...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _modelQuery = v),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final model = filtered[index];
                  return ListTile(
                    title: Text(model, style: AppTextStyles.bodyMedium),
                    selected: selectedModel == model,
                    selectedTileColor: AppColors.primary.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        selectedModel = model;
                        showModelDropdown = false;
                        showYearDropdown = true;
                      });
                      _notifySelection();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const Center(child: Text("Failed to load")),
    );
  }

  Widget _buildYearList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: yearsList.length,
      itemBuilder: (context, index) {
        final year = yearsList[index];
        return ListTile(
          title: Text('$year', style: AppTextStyles.bodyMedium),
          selected: selectedYear == year,
          selectedTileColor: AppColors.primary.withOpacity(0.1),
          onTap: () {
            setState(() {
              selectedYear = year;
              showYearDropdown = false;
            });
            _notifySelection();
          },
        );
      },
    );
  }

  Widget _buildSelectionSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.success, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Selected',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '$selectedYear $selectedBrand $selectedModel',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
