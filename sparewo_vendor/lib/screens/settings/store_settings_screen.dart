// lib/screens/settings/store_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vendor.dart';
import '../../providers/providers.dart';
import '../../services/ui_notification_service.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uiNotificationService = UINotificationService();
  bool _isLoading = false;

  late final TextEditingController _businessNameController;
  late final TextEditingController _businessAddressController;
  late final TextEditingController _phoneController;
  final List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    final vendor = ref.read(currentVendorProvider);
    _initializeControllers(vendor);
  }

  void _initializeControllers(Vendor? vendor) {
    _businessNameController =
        TextEditingController(text: vendor?.businessName ?? '');
    _businessAddressController =
        TextEditingController(text: vendor?.businessAddress ?? '');
    _phoneController = TextEditingController(text: vendor?.phone ?? '');
    if (vendor?.categories != null) {
      _selectedCategories.addAll(vendor!.categories);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _uiNotificationService.showError('Please fix the errors in the form.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final vendor = ref.read(currentVendorProvider);
      if (vendor == null) throw Exception("User not signed in.");

      final updatedVendor = vendor.copyWith(
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        phone: _phoneController.text.trim(),
        categories: _selectedCategories,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(authNotifierProvider.notifier)
          .updateVendorProfile(updatedVendor);
      _uiNotificationService.showSuccess('Store settings updated successfully');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        _uiNotificationService.showError('Failed to update store settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCategoriesSection(BuildContext context) {
    const categories = [
      'Body Parts',
      'Engine Parts',
      'Electrical Parts',
      'Suspension',
      'Brakes',
      'Transmission',
      'Interior',
      'Exterior',
      'Accessories',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                _selectedCategories.remove(category);
              }
            });
          },
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentVendorProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Store Details', style: textTheme.headlineSmall),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _businessNameController,
                  label: 'Business Name',
                  hintText: 'Enter your business name',
                  // FIX: Pass IconData, not an Icon widget
                  prefixIcon: Icons.business,
                  validator: (value) =>
                      Validators.notEmpty(value, 'Business Name'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _businessAddressController,
                  label: 'Business Address',
                  hintText: 'Enter your business address',
                  // FIX: Pass IconData, not an Icon widget
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                  validator: (value) =>
                      Validators.notEmpty(value, 'Business Address'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Contact Phone',
                  hintText: 'Enter your store phone number',
                  // FIX: Pass IconData, not an Icon widget
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      Validators.notEmpty(value, 'Phone Number'),
                ),
                const SizedBox(height: 24),
                Text('Store Categories', style: textTheme.headlineSmall),
                const SizedBox(height: 16),
                _buildCategoriesSection(context),
                const SizedBox(height: 32),
                LoadingButton(
                  onPressed: _saveChanges,
                  isLoading: _isLoading,
                  // FIX: Use the correct parameter 'label' instead of 'text'
                  label: 'Save Changes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
