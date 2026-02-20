import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/shared/widgets/legal_modal.dart';

/// A modal that politely asks the user to login/signup.
class AuthGuardModal extends ConsumerStatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onLoginSuccess;
  final String? returnTo;

  const AuthGuardModal({
    super.key,
    this.title = 'Join SpareWo',
    this.message =
        'Sign in to access this feature, track your orders, and manage your garage.',
    this.onLoginSuccess,
    this.returnTo,
  });

  /// Static helper to guard actions
  static void check({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onAuthenticated,
    String? title,
    String? message,
  }) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    final profileState = ref.read(currentUserProvider);
    final profile = profileState.asData?.value;
    final hasCompletedProfile = profile != null && profile.isEmailVerified;
    final isAuthenticated =
        user != null &&
        (profileState.isLoading ||
            profileState.hasError ||
            hasCompletedProfile);

    if (isAuthenticated) {
      onAuthenticated();
    } else {
      String? returnTo;
      try {
        returnTo = GoRouter.of(
          context,
        ).routeInformationProvider.value.uri.toString();
      } catch (_) {
        returnTo = null;
      }
      // Not authenticated, show modal
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6), // Dark dim
        builder: (context) => AuthGuardModal(
          title: title ?? 'Sign in Required',
          message: message ?? 'Please sign in to continue with this action.',
          onLoginSuccess: onAuthenticated,
          returnTo: returnTo,
        ),
      );
    }
  }

  @override
  ConsumerState<AuthGuardModal> createState() => _AuthGuardModalState();
}

enum _AuthMode { login, signup }

class _AuthGuardModalState extends ConsumerState<AuthGuardModal> {
  _AuthMode _mode = _AuthMode.login;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();
  bool _signupObscure = true;
  bool _loginObscure = true;
  bool _agreedToTerms = false;
  bool _isBusy = false;
  String _busyLabel = '';

  void _goSafely(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isBusy) return;
    TextInput.finishAutofillContext();
    if (_loginFormKey.currentState?.validate() ?? false) {
      await _withBusy('Signing you in...', () async {
        try {
          await ref
              .read(authNotifierProvider.notifier)
              .signIn(_loginEmail.text.trim(), _loginPassword.text.trim());
          _completeAuthSuccess();
        } catch (e) {
          if (!mounted) return;
          final message = e.toString().replaceAll('Exception: ', '');
          if (message.contains('__INCOMPLETE_SETUP__') ||
              message.toLowerCase().contains('setup incomplete')) {
            await _resumeIncompleteSetup(
              message.replaceAll('__INCOMPLETE_SETUP__', '').trim(),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<void> _handleSignup() async {
    if (_isBusy) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }
    if (_signupFormKey.currentState?.validate() ?? false) {
      await _withBusy('Creating your account...', () async {
        try {
          await ref
              .read(authNotifierProvider.notifier)
              .signUp(
                email: _signupEmail.text.trim(),
                password: _signupPassword.text.trim(),
                name: _signupName.text.trim(),
              );
          if (!mounted) return;
          final normalizedEmail = _signupEmail.text.trim().toLowerCase();
          final wasPartial = ref
              .read(authRepositoryProvider)
              .takeLastRegistrationWasPartial();
          final returnTo = widget.returnTo;
          Navigator.of(context).pop();
          final encodedEmail = Uri.encodeComponent(normalizedEmail);
          final partialParam = wasPartial ? '&partial=1' : '';
          final returnParam = returnTo != null
              ? '&returnTo=${Uri.encodeComponent(returnTo)}'
              : '';
          _goSafely(
            '/verify-email?email=$encodedEmail$partialParam$returnParam',
          );
        } catch (e) {
          if (!mounted) return;
          final message = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<void> _resumeIncompleteSetup(String message) async {
    final cleanMessage = message.isEmpty
        ? 'Your account setup is incomplete. Verify your email to continue.'
        : message;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finish your setup'),
          content: Text(cleanMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = _loginEmail.text.trim().toLowerCase();
                final password = _loginPassword.text.trim();
                if (email.isEmpty || password.isEmpty) return;
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .resumeIncompleteOnboarding(
                        email: email,
                        password: password,
                      );
                  if (!mounted) return;
                  final returnTo = widget.returnTo;
                  final returnParam = returnTo != null
                      ? '&returnTo=${Uri.encodeComponent(returnTo)}'
                      : '';
                  Navigator.of(context).pop();
                  _goSafely(
                    '/verify-email?email=${Uri.encodeComponent(email)}&partial=1$returnParam',
                  );
                } catch (e) {
                  if (!mounted) return;
                  final error = e.toString().replaceAll('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Resume Verification'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGoogle() async {
    if (_isBusy) return;
    await _withBusy('Connecting to Google...', () async {
      try {
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();
        _completeAuthSuccess();
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _withBusy(String label, Future<void> Function() action) async {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _busyLabel = label;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _busyLabel = '';
        });
      }
    }
  }

  void _completeAuthSuccess() {
    if (!mounted) return;
    final onLoginSuccess = widget.onLoginSuccess;
    final returnTo = widget.returnTo;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onLoginSuccess?.call();
      if (onLoginSuccess == null && returnTo != null) {
        router.go(returnTo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.floatingShadow,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _AuthToggle(
                          label: 'Sign In',
                          active: _mode == _AuthMode.login,
                          onTap: () {
                            if (_isBusy) return;
                            setState(() => _mode = _AuthMode.login);
                          },
                        ),
                        _AuthToggle(
                          label: 'Create Account',
                          active: _mode == _AuthMode.signup,
                          onTap: () {
                            if (_isBusy) return;
                            setState(() => _mode = _AuthMode.signup);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_mode == _AuthMode.login) _buildLoginForm(theme),
                  if (_mode == _AuthMode.signup) _buildSignupForm(theme),
                  if (_isBusy) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _busyLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _handleGoogle,
                      icon: Image.asset(
                        'assets/icons/Google Logo Icon.png',
                        width: 20,
                      ),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Maybe later',
                      style: TextStyle(
                        color: theme.hintColor,
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
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmail,
            enabled: !_isBusy,
            autofillHints: const [AutofillHints.email],
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPassword,
            enabled: !_isBusy,
            obscureText: _loginObscure,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _loginObscure = !_loginObscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            validator: (v) =>
                (v?.length ?? 0) < 6 ? 'Password too short' : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isBusy ? null : _handleLogin,
              child: const Text('Sign In'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSignupForm(ThemeData theme) {
    return Form(
      key: _signupFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _signupName,
            enabled: !_isBusy,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 2 ? 'Name too short' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signupEmail,
            enabled: !_isBusy,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signupPassword,
            enabled: !_isBusy,
            obscureText: _signupObscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _signupObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _signupObscure = !_signupObscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: _isBusy
                    ? null
                    : (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _isBusy
                      ? null
                      : () => LegalModal.showTermsAndConditions(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: TextStyle(
                        color: theme.hintColor,
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isBusy ? null : _handleSignup,
              child: const Text('Create Account'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _AuthToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _AuthToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
