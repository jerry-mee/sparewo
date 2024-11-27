import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/feedback_service.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../exceptions/auth_exceptions.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _feedbackService = FeedbackService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  final List<String> _selectedCategories = [];

  final _categories = [
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      await _feedbackService.error();
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: VendorColors.error,
        ),
      );
      await _feedbackService.error();
      return;
    }

    setState(() => _isLoading = true);
    await _feedbackService.buttonTap();

    try {
      final vendorData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'businessAddress': _businessAddressController.text.trim(),
        'categories': _selectedCategories,
      };

      await ref.read(authStateNotifierProvider.notifier).signUp(
            vendorData,
            _passwordController.text,
          );

      final authState = ref.read(authStateNotifierProvider);
      if (authState.hasError) {
        throw AuthException(message: authState.error ?? 'Registration failed');
      }

      await _feedbackService.success();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      await _feedbackService.error();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: VendorColors.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthLoading = ref.watch(authLoadingProvider);
    final authError = ref.watch(authErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Vendor Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (authError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VendorColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authError,
                      style: VendorTextStyles.body2.copyWith(
                        color: VendorColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person,
                  validator: (value) => Validators.required(value, 'Full Name'),
                  enabled: !isAuthLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  enabled: !isAuthLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  enabled: !isAuthLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _businessNameController,
                  label: 'Business Name',
                  prefixIcon: Icons.business,
                  validator: (value) =>
                      Validators.required(value, 'Business Name'),
                  enabled: !isAuthLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _businessAddressController,
                  label: 'Business Address',
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                  validator: (value) =>
                      Validators.required(value, 'Business Address'),
                  enabled: !isAuthLoading,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  enabled: !isAuthLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select Categories',
                  style: VendorTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: isAuthLoading
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  onPressed: _handleSignup,
                  isLoading: _isLoading || isAuthLoading,
                  label: 'Create Account',
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      isAuthLoading ? null : () => Navigator.pop(context),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
