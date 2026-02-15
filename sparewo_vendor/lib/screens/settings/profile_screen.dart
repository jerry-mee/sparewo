// lib/screens/settings/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/routes/app_router.dart';
import '../../services/ui_notification_service.dart';
import '../../theme.dart';
import '../../constants/enums.dart';
import '../../models/vendor.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _uiNotificationService = UINotificationService();

  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFields();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _populateFields() {
    final vendor = ref.read(currentVendorProvider);
    if (vendor != null) {
      _nameController.text = vendor.name;
      _emailController.text = vendor.email;
      _phoneController.text = vendor.phone;
      _businessNameController.text = vendor.businessName;
      _businessAddressController.text = vendor.businessAddress;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _uiNotificationService.showError('Please fix the errors in the form.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vendor = ref.read(currentVendorProvider);
      if (vendor == null) {
        throw Exception('No vendor profile found');
      }

      final updatedVendor = vendor.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(authNotifierProvider.notifier)
          .updateVendorProfile(updatedVendor);

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _isLoading = false;
        });
        _uiNotificationService.showSuccess('Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _uiNotificationService.showError('Failed to update profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(currentVendorProvider);
    final textTheme = Theme.of(context).textTheme;

    if (vendor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
            ),
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditMode = false);
                _populateFields();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(context, vendor),
              const SizedBox(height: 32),
              _buildProfileFields(),
              const SizedBox(height: 32),
              if (_isEditMode) _buildSaveButton(),
              const SizedBox(height: 16),
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Vendor vendor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          vendor.name,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(vendor.status),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            vendor.status.displayName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Information',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
          ),
          enabled: _isEditMode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
          enabled: false,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone),
          ),
          enabled: _isEditMode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Text('Business Information',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Business Name',
            prefixIcon: Icon(Icons.business),
          ),
          enabled: _isEditMode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your business name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _businessAddressController,
          decoration: const InputDecoration(
            labelText: 'Business Address',
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          enabled: _isEditMode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your business address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Save Changes'),
    );
  }

  Widget _buildSignOutButton() {
    return OutlinedButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text(
                'Are you sure you want to sign out of your account?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await ref.read(authNotifierProvider.notifier).signOut();
          if (mounted) {
            // FIX: Navigate to the named route for the splash screen.
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRouter.splash, (route) => false);
          }
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Sign Out'),
    );
  }

  Color _getStatusColor(VendorStatus status) {
    switch (status) {
      case VendorStatus.pending:
        return Theme.of(context).extension<AppColorsExtension>()!.pending;
      case VendorStatus.approved:
        return Theme.of(context).extension<AppColorsExtension>()!.approved;
      case VendorStatus.suspended:
        return Theme.of(context).colorScheme.error;
      case VendorStatus.rejected:
        return Theme.of(context).extension<AppColorsExtension>()!.rejected;
    }
  }
}
