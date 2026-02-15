// lib/features/auth/presentation/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    final compactAuthLayout =
        theme.platform == TargetPlatform.iOS && mediaQuery.size.height <= 860;
    ref.listen(authNotifierProvider, (_, state) {
      if (state.isLoading) {
        EasyLoading.show(status: 'Creating account...');
      } else {
        EasyLoading.dismiss();
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    });

    final content = SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: compactAuthLayout ? 20 : 32,
          vertical: compactAuthLayout ? 14 : 24,
        ),
        child: _SignUpForm(returnTo: returnTo, compact: compactAuthLayout),
      ),
    );

    return ResponsiveScreen(
      mobile: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (returnTo != null) {
                context.go(returnTo);
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Center(child: content),
      ),
      desktop: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (returnTo != null) {
                context.go(returnTo);
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _SignUpForm extends ConsumerStatefulWidget {
  final String? returnTo;
  final bool compact;

  const _SignUpForm({this.returnTo, required this.compact});

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _agreedToTerms = false;

  Future<void> _openTermsAndConditions() async {
    final uri = Uri.parse('https://www.sparewo.ug/terms-of-service');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Terms & Conditions')),
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authNotifierProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
          );
      if (mounted) {
        final returnParam = widget.returnTo != null
            ? '&returnTo=${Uri.encodeComponent(widget.returnTo!)}'
            : '';
        context.go(
          '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}$returnParam',
        );
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions first'),
        ),
      );
      return;
    }
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  void _continueAsGuest() {
    ref.read(hasSeenWelcomeProvider.notifier).completeWelcome();
    if (widget.returnTo != null) {
      context.go(widget.returnTo!);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: const Text(
              'Start your journey with SpareWo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ).animate().fadeIn(delay: 100.ms),
          ),

          SizedBox(height: widget.compact ? 18 : 32),
          TextButton(
            onPressed: _continueAsGuest,
            child: Text(
              'Continue as Guest',
              style: TextStyle(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: widget.compact ? 10 : 16),

          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 2 ? 'Name too short' : null,
          ),
          SizedBox(height: widget.compact ? 14 : 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
          ),
          SizedBox(height: widget.compact ? 14 : 20),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
          ),

          SizedBox(height: widget.compact ? 16 : 24),

          Row(
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Text(
                        'I agree to the ',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openTermsAndConditions,
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: widget.compact ? 20 : 28),

          SizedBox(
            width: double.infinity,
            height: widget.compact ? 52 : 56,
            child: FilledButton(
              onPressed: _handleSignUp,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: widget.compact ? 16 : 24),

          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or sign up with',
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
              Expanded(child: Divider(color: theme.dividerColor)),
            ],
          ),

          SizedBox(height: widget.compact ? 16 : 24),

          SizedBox(
            width: double.infinity,
            height: widget.compact ? 52 : 56,
            child: OutlinedButton.icon(
              onPressed: _handleGoogleSignUp,
              icon: Image.asset('assets/icons/Google Logo Icon.png', width: 24),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textTheme.bodyLarge?.color,
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          SizedBox(height: widget.compact ? 20 : 32),

          Center(
            child: GestureDetector(
              onTap: () {
                final route = widget.returnTo != null
                    ? '/login?returnTo=${Uri.encodeComponent(widget.returnTo!)}'
                    : '/login';
                context.go(route);
              },
              child: RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(color: theme.hintColor, fontSize: 15),
                  children: const [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {
                ref.read(hasSeenWelcomeProvider.notifier).completeWelcome();
                if (widget.returnTo != null) {
                  context.go(widget.returnTo!);
                } else {
                  context.go('/home');
                }
              },
              child: Text(
                'Continue as Guest',
                style: TextStyle(
                  color: theme.hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
