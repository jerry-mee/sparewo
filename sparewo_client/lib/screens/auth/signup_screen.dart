import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/theme.dart';
import '../../services/feedback_service.dart';
import '../../exceptions/auth_exceptions.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _feedbackService = FeedbackService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .signInWithGoogle();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await _feedbackService.buttonTap();
      await authProvider.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
    } on GoogleAccountException catch (e) {
      final shouldUseGoogle = await _showGoogleAccountDialog(e.message);
      if (shouldUseGoogle) {
        await _handleGoogleSignIn();
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  Future<bool> _showGoogleAccountDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Google Account Detected'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                _buildLogo(),
                const SizedBox(height: 48),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                _buildSignUpButton(),
                const SizedBox(height: 16),
                _buildGoogleButton(),
                const SizedBox(height: 16),
                _buildLoginLink(),
                const SizedBox(height: 16),
                _buildSkipButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/logo/logo.png',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: const TextStyle(color: AppColors.textLight),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.textLight),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon:
            const Icon(Icons.person_outline, color: AppColors.textLight),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Full name is required';
        if (value!.trim().length < 2) return 'Name is too short';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(color: AppColors.textLight),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.textLight),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon:
            const Icon(Icons.email_outlined, color: AppColors.textLight),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Email is required';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: AppColors.textLight),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.textLight),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textLight,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Password is required';
        if (value!.length < 6) return 'Password must be at least 6 characters';
        if (!value.contains(RegExp(r'[0-9]'))) {
          return 'Password must contain at least one number';
        }
        return null;
      },
    );
  }

  Widget _buildSignUpButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return ElevatedButton(
          onPressed: authProvider.isLoading ? null : _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
          child: authProvider.isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Sign Up'),
        );
      },
    );
  }

  Widget _buildGoogleButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return OutlinedButton.icon(
          onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.textLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: Image.asset(
            'assets/icons/google.png',
            height: 24,
          ),
          label: const Text(
            'Continue with Google',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/login'),
      child: const Text(
        'Already have an account? Log In',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
      child: Text(
        'Skip for now',
        style: TextStyle(color: AppColors.textLight.withOpacity(0.7)),
      ),
    );
  }
}
