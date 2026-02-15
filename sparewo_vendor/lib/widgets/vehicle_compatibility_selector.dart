// lib/widgets/vehicle_compatibility_selector.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_compatibility.dart';
import '../services/firebase_service.dart';
import '../widgets/expandable_year_selector.dart';
import '../services/logger_service.dart';
import '../providers/firebase_providers.dart';

enum SearchResultType { brand, model }

class SearchResult {
  final String text;
  final SearchResultType type;
  final String? parentBrand;
  SearchResult(this.text, this.type, {this.parentBrand});
}

class VehicleCompatibilitySelector extends ConsumerStatefulWidget {
  final List<VehicleCompatibility>? initialCompatibilities;
  final Function(List<VehicleCompatibility>) onChanged;
  final Function(String?)? onValidationError;
  final Function(String, String)? onModelSelected;

  const VehicleCompatibilitySelector({
    Key? key,
    this.initialCompatibilities,
    required this.onChanged,
    this.onValidationError,
    this.onModelSelected,
  }) : super(key: key);

  @override
  ConsumerState<VehicleCompatibilitySelector> createState() =>
      _VehicleCompatibilitySelectorState();
}

class _VehicleCompatibilitySelectorState
    extends ConsumerState<VehicleCompatibilitySelector> {
  final LoggerService _logger = LoggerService.instance;
  late final FirebaseService _firebaseService;

  String? selectedBrand;
  String? selectedModel;
  List<int> selectedYears = [];
  List<VehicleCompatibility> compatibilities = [];
  bool isLoading = false;
  String? error;
  bool isBrandsLoaded = false;
  List<SearchResult> searchResults = [];
  bool isSearching = false;
  bool isSearchLoading = false;
  bool isEditing = false;
  int? editingIndex;
  bool isMultiSelectMode = false;
  Set<int> selectedIndices = {};
  List<String> availableBrands = [];
  List<String> availableModels = [];

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  Timer? cacheTimer;
  static const Duration cacheExpiration = Duration(minutes: 30);
  final Map<String, List<String>> cache = {};
  final Map<String, List<SearchResult>> searchCache = {};

  @override
  void initState() {
    super.initState();
    _firebaseService = ref.read(firebaseServiceProvider);

    compatibilities = widget.initialCompatibilities?.toList() ?? [];
    searchController.addListener(_handleSearch);
    searchFocusNode.addListener(_onSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBrands();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    cacheTimer?.cancel();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (!searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted &&
            !searchFocusNode.hasFocus &&
            selectedBrand == null &&
            selectedModel == null) {
          _resetSearch();
        }
      });
    }
  }

  Future<void> _loadBrands() async {
    if (!mounted || isBrandsLoaded) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      availableBrands = cache.containsKey('brands')
          ? cache['brands']!
          : await _firebaseService.getVehicleBrands();
      if (!cache.containsKey('brands')) {
        cache['brands'] = availableBrands;
        _startCacheTimer();
      }
      isBrandsLoaded = true;
      setState(() {
        isLoading = false;
      });
      _logger.info('Loaded ${availableBrands.length} brands');
    } catch (e) {
      _setError('Failed to load vehicle brands: ${e.toString()}');
      _logger.error('Failed to load vehicle brands', error: e);
    }
  }

  Future<void> _loadModels(String brand) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final cacheKey = 'models_$brand';
      availableModels = cache.containsKey(cacheKey)
          ? cache[cacheKey]!
          : await _firebaseService.getVehicleModels(brand);
      if (!cache.containsKey(cacheKey)) {
        cache[cacheKey] = availableModels;
        _startCacheTimer();
      }
      setState(() {
        isLoading = false;
      });
      _logger.info('Loaded ${availableModels.length} models for brand $brand');
    } catch (e) {
      _setError('Failed to load vehicle models: ${e.toString()}');
      _logger.error('Failed to load vehicle models', error: e);
    }
  }

  Future<List<SearchResult>> _loadModelsForSearch(String query) async {
    _logger.info('Searching for models containing: $query');
    List<SearchResult> results = [];
    final cacheKey = 'search_$query';

    if (searchCache.containsKey(cacheKey)) {
      return searchCache[cacheKey]!;
    }

    if (availableBrands.isEmpty) return results;

    try {
      final queryLower = query.toLowerCase();

      // Search matching brands
      List<String> matchingBrands = availableBrands
          .where((brand) => brand.toLowerCase().contains(queryLower))
          .toList();

      for (final brand in matchingBrands) {
        results.add(SearchResult(brand, SearchResultType.brand));
      }

      // Search all models across all brands
      List<Future<void>> modelSearchTasks = [];

      for (final brand in availableBrands) {
        modelSearchTasks.add(() async {
          try {
            final modelCacheKey = 'models_$brand';
            List<String> models;

            if (cache.containsKey(modelCacheKey)) {
              models = cache[modelCacheKey]!;
            } else {
              models = await _firebaseService.getVehicleModels(brand);
              cache[modelCacheKey] = models;
            }

            // Filter models that match the query
            final matchingModels = models
                .where((model) => model.toLowerCase().contains(queryLower))
                .toList();

            for (final model in matchingModels) {
              results.add(SearchResult(model, SearchResultType.model,
                  parentBrand: brand));
            }
          } catch (e) {
            _logger.error('Error loading models for brand $brand', error: e);
          }
        }());
      }

      // Wait for all model searches to complete
      await Future.wait(modelSearchTasks);

      // Limit results to prevent UI overflow
      if (results.length > 50) {
        results = results.take(50).toList();
      }

      searchCache[cacheKey] = results;
      return results;
    } catch (e) {
      _logger.error('Error searching for models', error: e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  void _startCacheTimer() {
    cacheTimer?.cancel();
    cacheTimer = Timer(cacheExpiration, _clearCache);
  }

  void _clearCache() {
    setState(() {
      cache.clear();
      searchCache.clear();
    });
  }

  void _handleSearch() async {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      isSearchLoading = query.isNotEmpty;
      searchResults = [];
    });

    if (query.isEmpty) return;

    try {
      if (!isBrandsLoaded) {
        await _loadBrands();
      }

      final results = await _loadModelsForSearch(query);

      if (mounted) {
        setState(() {
          searchResults = results;
          isSearchLoading = false;
        });
        _logger.info('Search completed with ${searchResults.length} results');
      }
    } catch (e) {
      _logger.error('Error during search', error: e);
      if (mounted) {
        setState(() {
          isSearchLoading = false;
          searchResults = [];
        });
      }
    }
  }

  void _resetSearch() {
    if (!mounted) return;
    setState(() {
      isSearching = false;
      isSearchLoading = false;
      searchResults = [];
      searchController.clear();
    });
  }

  void _selectSearchResult(SearchResult result) {
    _logger.info('Selected search result: ${result.text} (${result.type})');
    setState(() {
      if (result.type == SearchResultType.brand) {
        selectedBrand = result.text;
        selectedModel = null;
        selectedYears = [];
        availableModels = [];
        _loadModels(result.text);
      } else {
        if (result.parentBrand != null && selectedBrand != result.parentBrand) {
          selectedBrand = result.parentBrand;
          _loadModels(result.parentBrand!);
        }

        selectedModel = result.text;

        if (selectedYears.isEmpty) {
          _initDefaultYears();
        }
        widget.onModelSelected?.call(selectedBrand!, selectedModel!);
      }
      _resetSearch();
    });
  }

  void _initDefaultYears() {
    final currentYear = DateTime.now().year;
    selectedYears = List.generate(5, (index) => currentYear - (index + 1));
  }

  void _selectBrand(String? brand) async {
    setState(() {
      selectedBrand = brand;
      selectedModel = null;
      selectedYears = [];
      availableModels = [];
    });

    if (brand != null) {
      await _loadModels(brand);
    }
  }

  void _selectModel(String? model) {
    setState(() {
      selectedModel = model;
      if (selectedYears.isEmpty && model != null) {
        _initDefaultYears();
      }
    });
  }

  void _validateAndNotify() {
    final errorMessage = (selectedBrand == null ||
            selectedModel == null ||
            selectedYears.isEmpty)
        ? 'Please select brand, model and at least one year'
        : null;
    widget.onValidationError?.call(errorMessage);
  }

  void _handleCompatibility() {
    if (!_validateSelection()) return;

    if (editingIndex != null) {
      _updateCompatibility(editingIndex!);
    } else {
      _addCompatibility();
    }
  }

  bool _validateSelection() {
    if (selectedBrand == null ||
        selectedModel == null ||
        selectedYears.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // FIX: Removed const
            content: Text('Please select brand, model and at least one year'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _addCompatibility() {
    final newCompatibility = VehicleCompatibility(
      brand: selectedBrand!,
      model: selectedModel!,
      compatibleYears: List.from(selectedYears)..sort(),
    );

    final isDuplicate = compatibilities.any(
      (comp) =>
          comp.brand == selectedBrand &&
          comp.model == selectedModel &&
          comp.compatibleYears.toSet().containsAll(selectedYears.toSet()),
    );

    if (isDuplicate && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // FIX: Removed const
          content: Text('This vehicle compatibility already exists'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      compatibilities.add(newCompatibility);
      _resetForm();
    });

    widget.onChanged(compatibilities);
    widget.onValidationError?.call(null);
    _logger.info('Added compatibility: $newCompatibility');
  }

  void _updateCompatibility(int index) {
    final updatedCompatibility = VehicleCompatibility(
      brand: selectedBrand!,
      model: selectedModel!,
      compatibleYears: List.from(selectedYears)..sort(),
    );

    setState(() {
      compatibilities[index] = updatedCompatibility;
      _resetForm();
    });

    widget.onChanged(compatibilities);
    widget.onValidationError?.call(null);
    _logger
        .info('Updated compatibility at index $index: $updatedCompatibility');
  }

  void _editCompatibility(int index) {
    final compatibility = compatibilities[index];
    setState(() {
      selectedBrand = compatibility.brand;
      selectedModel = compatibility.model;
      selectedYears = List.from(compatibility.compatibleYears);
      editingIndex = index;
      isEditing = true;
    });

    _loadModels(compatibility.brand);
    _logger.info('Editing compatibility at index $index: $compatibility');
  }

  void _removeCompatibility(int index) {
    final removed = compatibilities[index];
    setState(() {
      compatibilities.removeAt(index);
      selectedIndices.remove(index);
    });
    widget.onChanged(compatibilities);
    _logger.info('Removed compatibility at index $index: $removed');
  }

  void _enterMultiSelectMode() {
    setState(() {
      isMultiSelectMode = true;
      selectedIndices.clear();
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      isMultiSelectMode = false;
      selectedIndices.clear();
    });
  }

  void _toggleIndexSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void _bulkRemoveCompatibilities() {
    final indicesToDelete = selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      compatibilities.removeWhere((element) =>
          indicesToDelete.contains(compatibilities.indexOf(element)));
      _exitMultiSelectMode();
    });

    widget.onChanged(compatibilities);
    _logger.info('Bulk removed ${indicesToDelete.length} compatibilities');
  }

  void _resetForm() {
    setState(() {
      selectedBrand = null;
      selectedModel = null;
      selectedYears = [];
      editingIndex = null;
      isEditing = false;
      searchController.clear();
      _resetSearch();
    });
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          error ?? 'An error occurred',
          style: Theme.of(context)
              .textTheme
              .bodyLarge! // FIX: Added !
              .copyWith(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadBrands,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vehicle Compatibility',
              style: textTheme.titleLarge,
            ),
            if (compatibilities.isNotEmpty && !isMultiSelectMode)
              _buildMultiSelectButton(),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          _buildErrorUI()
        else
          _buildSelectionCard(),
        if (compatibilities.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildCompatibilitiesList(),
          if (isMultiSelectMode) _buildMultiSelectActions(),
        ],
      ],
    );
  }

  Widget _buildSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _buildErrorUI()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchField(),
                      if (isSearching &&
                          (isSearchLoading || searchResults.isNotEmpty))
                        _buildSearchResults()
                      else ...[
                        const SizedBox(height: 16),
                        _buildBrandDropdown(),
                        const SizedBox(height: 16),
                        _buildModelDropdown(),
                        const SizedBox(height: 16),
                        _buildYearSelector(),
                        const SizedBox(height: 16),
                        _buildActionButton(),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorUI() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          error!,
          style: textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadBrands,
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      focusNode: searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search brands or models (e.g. "Toyota" or "Corolla")',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: isSearching
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  _resetSearch();
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onSubmitted: (value) {
        if (searchResults.isNotEmpty) {
          _selectSearchResult(searchResults.first);
        }
      },
    );
  }

  Widget _buildSearchResults() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: isSearchLoading
            ? const ListTile(
                title: Text('Searching...'),
                leading: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : searchResults.isEmpty
                ? const ListTile(
                    title: Text('No results found'),
                    leading: Icon(Icons.search_off),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      return ListTile(
                        title: Text(result.text),
                        subtitle: Text(result.type == SearchResultType.brand
                            ? 'Brand'
                            : 'Model (${result.parentBrand})'),
                        leading: Icon(
                          result.type == SearchResultType.brand
                              ? Icons.directions_car_filled
                              : Icons.commute,
                          color: result.type == SearchResultType.brand
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                        onTap: () => _selectSearchResult(result),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selectedBrand,
      decoration: const InputDecoration(
        labelText: 'Brand',
        prefixIcon: Icon(Icons.directions_car),
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Brand')),
        ...availableBrands.map((brand) => DropdownMenuItem(
              value: brand,
              child: Text(brand),
            )),
      ],
      onChanged: _selectBrand,
    );
  }

  Widget _buildModelDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selectedModel,
      decoration: const InputDecoration(
        labelText: 'Model',
        prefixIcon: Icon(Icons.car_repair),
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Model')),
        ...availableModels.map((model) => DropdownMenuItem(
              value: model,
              child: Text(model),
            )),
      ],
      onChanged: selectedBrand != null ? _selectModel : null,
      hint: isLoading && selectedBrand != null
          ? Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading models...'),
              ],
            )
          : null,
    );
  }

  Widget _buildYearSelector() {
    return selectedBrand != null && selectedModel != null
        ? ExpandableYearSelector(
            selectedYears: selectedYears,
            onYearsChanged: (years) => setState(() {
              selectedYears = years;
              _validateAndNotify();
            }),
            excludeCurrentYear: true,
          )
        : const SizedBox.shrink();
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: _handleCompatibility,
      icon: Icon(isEditing ? Icons.save : Icons.add),
      label: Text(isEditing ? 'Update Compatibility' : 'Add Compatibility'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCompatibilitiesList() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Added Compatibilities',
              style: textTheme.titleMedium,
            ),
            if (!isMultiSelectMode) _buildMultiSelectButton(),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: compatibilities.length,
          itemBuilder: (context, index) => _buildCompatibilityCard(index),
        ),
      ],
    );
  }

  Widget _buildCompatibilityCard(int index) {
    final compatibility = compatibilities[index];
    final isSelected = selectedIndices.contains(index);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isMultiSelectMode && isSelected ? Colors.grey[300] : null,
      child: ListTile(
        onTap: isMultiSelectMode ? () => _toggleIndexSelection(index) : null,
        title: Text(
          '${compatibility.brand} ${compatibility.model}',
          style: textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Years: ${_formatYears(compatibility.compatibleYears)}',
          style: textTheme.bodyMedium,
        ),
        leading: isMultiSelectMode
            ? Checkbox(
                value: isSelected,
                onChanged: (bool? value) => _toggleIndexSelection(index),
              )
            : null,
        trailing: isMultiSelectMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: () => _editCompatibility(index),
                    tooltip: 'Edit Compatibility',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: () => _removeCompatibility(index),
                    tooltip: 'Remove Compatibility',
                  ),
                ],
              ),
      ),
    );
  }

  String _formatYears(List<int> years) {
    if (years.isEmpty) return 'No years selected';

    final sortedYears = List<int>.from(years)..sort();
    List<String> ranges = [];
    int start = sortedYears.first;
    int prev = start;

    for (int i = 1; i < sortedYears.length; i++) {
      if (sortedYears[i] != prev + 1) {
        ranges.add(start == prev ? '$start' : '$start-$prev');
        start = sortedYears[i];
      }
      prev = sortedYears[i];
    }
    ranges.add(start == prev ? '$start' : '$start-$prev');

    return ranges.join(', ');
  }

  Widget _buildMultiSelectButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _enterMultiSelectMode,
        icon: const Icon(Icons.checklist),
        label: const Text('Select'),
      ),
    );
  }

  Widget _buildMultiSelectActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _exitMultiSelectMode,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed:
                selectedIndices.isNotEmpty ? _bulkRemoveCompatibilities : null,
            icon: const Icon(Icons.delete_sweep),
            label: Text('Delete (${selectedIndices.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  void _setError(String? errorMessage) {
    if (!mounted) return;
    setState(() {
      error = errorMessage;
      isLoading = false;
    });
  }
}
