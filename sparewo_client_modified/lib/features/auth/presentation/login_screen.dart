// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    final compactAuthLayout =
        theme.platform == TargetPlatform.iOS && mediaQuery.size.height <= 860;

    // Listen to auth state for global loading/error handling
    ref.listen(authNotifierProvider, (_, state) {
      if (state.isLoading) {
        EasyLoading.show(status: 'Signing in...');
      } else {
        EasyLoading.dismiss();
        if (state.hasError) {
          final error = state.error.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),

            const SizedBox(height: 12),

            Text(
              'Enter your credentials to continue.',
              style: TextStyle(color: theme.hintColor, fontSize: 16),
            ).animate().fadeIn(delay: 100.ms),

            SizedBox(height: compactAuthLayout ? 24 : 48),

            _LoginForm(returnTo: returnTo, compact: compactAuthLayout),
          ],
        ),
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
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
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
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.go('/welcome');
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

class _LoginForm extends ConsumerStatefulWidget {
  final String? returnTo;
  final bool compact;

  const _LoginForm({this.returnTo, required this.compact});

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  Future<void> _handleLogin() async {
    TextInput.finishAutofillContext();
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authNotifierProvider.notifier)
          .signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      await _routeAfterAuth();
    }
  }

  Future<void> _handleGoogleLogin() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    await _routeAfterAuth();
  }

  Future<void> _routeAfterAuth() async {
    if (!mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final perUserKey = 'hasSeenOnboarding_$uid';
      final hasSeenOnboarding =
          (prefs.getBool(perUserKey) ?? false) ||
          (prefs.getBool('hasSeenOnboarding') ?? false);

      if (!hasSeenOnboarding) {
        await prefs.setBool(perUserKey, true);
        await prefs.setBool('hasSeenOnboarding', true);
        if (mounted) {
          context.go('/add-car?nudge=true');
        }
        return;
      }
    }

    if (widget.returnTo != null) {
      context.go(widget.returnTo!);
    } else {
      context.go('/home');
    }
  }

  void _continueAsGuest() {
    ref.read(hasSeenWelcomeProvider.notifier).completeWelcome();
    if (widget.returnTo != null) {
      context.go(widget.returnTo!);
    } else {
      context.go('/home');
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address to receive a password reset link.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v?.contains('@') == true ? null : 'Invalid email',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                try {
                  EasyLoading.show(status: 'Sending...');
                  await ref
                      .read(authNotifierProvider.notifier)
                      .sendPasswordResetEmail(
                        email: emailController.text.trim(),
                      );
                  EasyLoading.showSuccess('Reset link sent!');
                } catch (e) {
                  EasyLoading.showError(
                    e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
          ),
          SizedBox(height: widget.compact ? 14 : 24),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
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
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            validator: (v) =>
                (v?.length ?? 0) < 6 ? 'Password too short' : null,
          ),

          SizedBox(height: widget.compact ? 10 : 16),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              child: const Text('Forgot Password?'),
            ),
          ),

          SizedBox(height: widget.compact ? 20 : 32),

          SizedBox(
            width: double.infinity,
            height: widget.compact ? 52 : 56,
            child: FilledButton(
              onPressed: _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          SizedBox(height: widget.compact ? 8 : 12),
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

          SizedBox(height: widget.compact ? 16 : 24),

          Row(
            children: [
              Expanded(child: Divider(color: theme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
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
              onPressed: _handleGoogleLogin,
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

          GestureDetector(
            onTap: () {
              final route = widget.returnTo != null
                  ? '/signup?returnTo=${Uri.encodeComponent(widget.returnTo!)}'
                  : '/signup';
              context.push(route);
            },
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: theme.hintColor, fontSize: 15),
                children: const [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
