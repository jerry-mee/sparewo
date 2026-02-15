// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/feedback_service.dart';
import '../theme.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import '../exceptions/auth_exceptions.dart';
import '../widgets/error_message_widget.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      _feedbackService.error();
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one category'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _feedbackService.error();
      return;
    }

    setState(() => _isLoading = true);
    _feedbackService.buttonTap();

    try {
      final vendorData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'businessAddress': _businessAddressController.text.trim(),
        'categories': _selectedCategories,
      };

      await ref.read(authNotifierProvider.notifier).signUp(
            vendorData,
            _passwordController.text,
          );

      _feedbackService.success();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/email-verification');
    } on AuthException catch (e) {
      _feedbackService.error();
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (e) {
      _feedbackService.error();
      if (!mounted) return;
      String errorMessage = e.toString();
      if (errorMessage.contains('PigeonUserDetails')) {
        errorMessage = 'Authentication service error. Please try again.';
      }
      showErrorSnackBar(context, errorMessage.replaceAll('Exception: ', ''));
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.95),
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Create Vendor Account',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            if (authError != null && !_isLoading) ...[
                              ErrorMessageWidget(
                                message: authError,
                                isInline: true,
                              ),
                            ],
                            // Personal Information Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Personal Information',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall!
                                            .copyWith(
                                              fontSize: 18,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    prefixIcon: Icons.person,
                                    validator: (value) =>
                                        Validators.notEmpty(value, 'Full Name'),
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Business Information Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.business_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Business Details',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall!
                                            .copyWith(
                                              fontSize: 18,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _businessNameController,
                                    label: 'Business Name',
                                    prefixIcon: Icons.business,
                                    validator: (value) => Validators.notEmpty(
                                        value, 'Business Name'),
                                    enabled: !isAuthLoading,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _businessAddressController,
                                    label: 'Business Address',
                                    prefixIcon: Icons.location_on,
                                    maxLines: 2,
                                    validator: (value) => Validators.notEmpty(
                                        value, 'Business Address'),
                                    enabled: !isAuthLoading,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Security Section
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .extension<AppColorsExtension>()!
                                              .success
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.lock_outline,
                                          color: Theme.of(context)
                                              .extension<AppColorsExtension>()!
                                              .success,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Security',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall!
                                            .copyWith(
                                              fontSize: 18,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Categories Section
                            Text(
                              'Select Categories',
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((category) {
                                final isSelected =
                                    _selectedCategories.contains(category);
                                return FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  selectedColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  checkmarkColor:
                                      Theme.of(context).colorScheme.primary,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  side: BorderSide(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).dividerColor,
                                  ),
                                  onSelected: isAuthLoading
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedCategories.add(category);
                                            } else {
                                              _selectedCategories
                                                  .remove(category);
                                            }
                                          });
                                        },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: LoadingButton(
                                onPressed: _handleSignup,
                                isLoading: _isLoading || isAuthLoading,
                                label: 'Create Account',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: isAuthLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: Text(
                                'Already have an account? Login',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
