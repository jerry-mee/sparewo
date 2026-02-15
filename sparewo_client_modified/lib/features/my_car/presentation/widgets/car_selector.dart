// lib/features/my_car/presentation/widgets/car_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/my_car/application/car_data_provider.dart';
import 'package:sparewo_client/features/my_car/data/car_data_repository.dart';

class CarSelector extends ConsumerStatefulWidget {
  final void Function(String make, String model, int year) onCarSelected;
  final String? initialMake;
  final String? initialModel;
  final int? initialYear;

  const CarSelector({
    super.key,
    required this.onCarSelected,
    this.initialMake,
    this.initialModel,
    this.initialYear,
  });

  @override
  ConsumerState<CarSelector> createState() => _CarSelectorState();
}

class _CarSelectorState extends ConsumerState<CarSelector> {
  final _searchController = TextEditingController();

  List<String> _brands = [];
  List<String> _modelsForBrand = [];
  List<CarSearchResult> _searchResults = [];

  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedYear;

  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedBrand = widget.initialMake;
    _selectedModel = widget.initialModel;
    _selectedYear = widget.initialYear;
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    final repo = ref.read(carDataRepositoryProvider);
    setState(() => _isLoadingBrands = true);
    try {
      _brands = await repo.getCarBrands();
      if (_selectedBrand != null) {
        await _loadModelsForBrand(_selectedBrand!);
      }
    } finally {
      if (mounted) setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _loadModelsForBrand(String brand) async {
    final repo = ref.read(carDataRepositoryProvider);
    setState(() {
      _isLoadingModels = true;
      _modelsForBrand = [];
    });
    try {
      final models = await repo.getCarModels(brand);
      if (!mounted) return;
      setState(() => _modelsForBrand = models);
    } finally {
      if (mounted) setState(() => _isLoadingModels = false);
    }
  }

  Future<void> _runGlobalSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final repo = ref.read(carDataRepositoryProvider);
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await repo.searchModelsGlobally(trimmed);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _applySearchResult(CarSearchResult result) {
    setState(() {
      _selectedBrand = result.brand;
      _selectedModel = result.model;
      _searchController.text = result.displayName;
      _searchResults = [];
    });
    _loadModelsForBrand(result.brand);
  }

  List<int> _availableYears() {
    final current = DateTime.now().year;
    return List<int>.generate(40, (i) => current - i);
  }

  void _onConfirm() {
    if (_selectedBrand == null ||
        _selectedModel == null ||
        _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select brand, model and year.')),
      );
      return;
    }
    widget.onCarSelected(_selectedBrand!, _selectedModel!, _selectedYear!);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Select your vehicle',
                style: AppTextStyles.h2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),

              // -------- SEARCH BAR --------
              TextField(
                controller: _searchController,
                onChanged: _runGlobalSearch,
                decoration: InputDecoration(
                  hintText: 'Search by model (e.g. Vitz)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_isSearching)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else if (_searchResults.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = _searchResults[i];
                      return ListTile(
                        title: Text(item.displayName),
                        onTap: () => _applySearchResult(item),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // -------- BRAND DROPDOWN --------
              _buildDropdown<String>(
                label: 'Brand',
                value: _selectedBrand,
                items: _brands,
                isLoading: _isLoadingBrands,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedBrand = value;
                    _selectedModel = null;
                  });
                  _loadModelsForBrand(value);
                },
              ),
              const SizedBox(height: 12),

              // -------- MODEL DROPDOWN --------
              _buildDropdown<String>(
                label: 'Model',
                value: _selectedModel,
                items: _modelsForBrand,
                isLoading: _isLoadingModels,
                onChanged: (value) => setState(() => _selectedModel = value),
              ),
              const SizedBox(height: 12),

              // -------- YEAR DROPDOWN --------
              _buildDropdown<int>(
                label: 'Year',
                value: _selectedYear,
                items: _availableYears(),
                isLoading: false,
                onChanged: (value) => setState(() => _selectedYear = value),
              ),
              const SizedBox(height: 20),

              // -------- SUMMARY --------
              if (_selectedBrand != null && _selectedModel != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary),
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    '${_selectedBrand!} ${_selectedModel!}'
                    '${_selectedYear != null ? ' (${_selectedYear!})' : ''}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirm Vehicle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required bool isLoading,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    isExpanded: true,
                    value: value,
                    hint: Text('Select ${label.toLowerCase()}'),
                    items: items
                        .map(
                          (item) => DropdownMenuItem<T>(
                            value: item,
                            child: Text(
                              item.toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
        ),
      ],
    );
  }
}
