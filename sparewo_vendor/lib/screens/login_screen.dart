// lib/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/feedback_service.dart';
import '../../theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../exceptions/auth_exceptions.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _feedbackService = FeedbackService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      await _feedbackService.error();
      return;
    }

    setState(() => _isLoading = true);
    await _feedbackService.buttonTap();

    try {
      await ref.read(authStateNotifierProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

      final authState = ref.read(authStateNotifierProvider);
      if (authState.hasError) {
        throw AuthException(
            message: authState.error ?? 'Authentication failed');
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

  Future<void> _handleSkipForNow() async {
    setState(() => _isLoading = true);
    await _feedbackService.buttonTap();

    try {
      // Directly navigate to the dashboard without altering auth state
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      await _feedbackService.error();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to skip login: ${e.toString()}'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: VendorTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to manage your inventory',
                  style: VendorTextStyles.body1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
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
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
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
                LoadingButton(
                  onPressed: _handleLogin,
                  isLoading: _isLoading || isAuthLoading,
                  label: 'Login',
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isAuthLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('New Vendor? Create Account'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isAuthLoading
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password reset functionality coming soon',
                              ),
                            ),
                          );
                        },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: 24),
                Divider(
                  color: VendorColors.textLight,
                  thickness: 1,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: isAuthLoading
                      ? null
                      : _handleSkipForNow, // New "Skip for now" button handler
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: VendorColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
