// lib/features/auth/presentation/signup_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/features/shared/widgets/legal_modal.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/router/app_router.dart';
import 'package:sparewo_client/core/router/navigation_extensions.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';

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
      }
    });

    final content = SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: compactAuthLayout ? 20 : 32,
          vertical: compactAuthLayout ? 8 : 16,
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
                context.goBackOr('/welcome');
              }
            },
          ),
        ),
        body: content,
      ),
      desktop: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (returnTo != null) {
                context.go(returnTo);
              } else {
                context.goBackOr('/welcome');
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
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isEmailTaken = false;
  bool _isSubmitting = false;
  String? _emailInlineError;
  Timer? _emailCheckDebounce;
  int _emailCheckVersion = 0;
  final GlobalKey _passwordSectionKey = GlobalKey();
  bool _didFocusPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(_refreshUi);
    _confirmPasswordFocusNode.addListener(_refreshUi);
  }

  void _refreshUi() {
    if (!mounted) return;
    setState(() {});
    final isInPasswordSection =
        _passwordFocusNode.hasFocus || _confirmPasswordFocusNode.hasFocus;
    if (isInPasswordSection && !_didFocusPasswordSection) {
      _didFocusPasswordSection = true;
      _ensurePasswordSectionVisible();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _emailCheckDebounce?.cancel();
    super.dispose();
  }

  void _ensurePasswordSectionVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _passwordSectionKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
  }

  void _goSafely(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  void _goNow(String route) {
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    context.go(route);
  }

  int _passwordScore(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  Color _strengthColor(int score) {
    if (score <= 2) return AppColors.error;
    if (score <= 3) return AppColors.warning;
    return AppColors.success;
  }

  String _strengthLabel(int score) {
    if (score <= 2) return 'Weak password';
    if (score <= 3) return 'Good password';
    return 'Strong password';
  }

  bool _isValidEmailFormat(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  void _onEmailChanged(String rawValue) {
    final email = rawValue.trim().toLowerCase();
    _emailCheckDebounce?.cancel();
    final version = ++_emailCheckVersion;

    if (email.isEmpty || !_isValidEmailFormat(email)) {
      setState(() {
        _isEmailTaken = false;
        _emailInlineError = email.isEmpty
            ? null
            : 'Enter a valid email address';
      });
      return;
    }

    setState(() {
      _emailInlineError = null;
    });

    _emailCheckDebounce = Timer(const Duration(milliseconds: 450), () async {
      final exists = await _emailExists(email);
      if (!mounted || version != _emailCheckVersion) return;
      setState(() {
        _isEmailTaken = exists;
        _emailInlineError = exists
            ? 'This email already has an account.'
            : null;
      });
    });
  }

  Future<bool> _emailExists(String email) async {
    try {
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (users.docs.isNotEmpty) return true;

      final clients = await FirebaseFirestore.instance
          .collection('clients')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return clients.docs.isNotEmpty;
    } catch (_) {
      // If this lookup is blocked by rules/network, avoid false positives.
      return false;
    }
  }

  Future<void> _openTermsAndConditions() async {
    LegalModal.showTermsAndConditions(context);
  }

  Future<void> _openPrivacyPolicy() async {
    LegalModal.showPrivacyPolicy(context);
  }

  Future<void> _handleSignUp() async {
    if (_isSubmitting) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        if (_isEmailTaken) {
          AppLogger.info(
            'SignUpScreen',
            'Inline email check marked email as taken',
            extra: {'email': _emailController.text.trim().toLowerCase()},
          );
          await _showExistingAccountDialog(
            'This email already has an account. If the email is unverified, tap "Complete setup" to continue verification.',
            canResume: true,
          );
          return;
        }
        await ref
            .read(authNotifierProvider.notifier)
            .signUp(
              email: _emailController.text.trim().toLowerCase(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
            );
        if (mounted) {
          TextInput.finishAutofillContext(shouldSave: true);
          final normalizedEmail = _emailController.text.trim().toLowerCase();
          final wasPartial = ref
              .read(authRepositoryProvider)
              .takeLastRegistrationWasPartial();
          final partialParam = wasPartial ? '&partial=1' : '';
          final returnParam = widget.returnTo != null
              ? '&returnTo=${Uri.encodeComponent(widget.returnTo!)}'
              : '';
          _goSafely(
            '/verify-email?email=${Uri.encodeComponent(normalizedEmail)}$partialParam$returnParam',
          );
        }
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceAll('Exception: ', '');
        AppLogger.warn(
          'SignUpScreen',
          'Sign up failed',
          extra: {
            'email': _emailController.text.trim().toLowerCase(),
            'message': message,
          },
        );
        if (_looksLikeExistingAccountError(message)) {
          setState(() {
            _isEmailTaken = true;
            _emailInlineError = 'This email already has an account.';
          });
          await _showExistingAccountDialog(
            'This email already has an account. If the email is unverified, tap "Complete setup" to continue verification.',
            canResume: true,
          );
          return;
        }
        _showSignupFeedback(message, isFailure: true);
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  bool _looksLikeExistingAccountError(String message) {
    final value = message.toLowerCase();
    return value.contains('already registered') ||
        value.contains('already in use') ||
        value.contains('email-already-in-use') ||
        value.contains('already has an account') ||
        value.contains('partial setup') ||
        value.contains('continue setup');
  }

  Future<void> _showExistingAccountDialog(
    String message, {
    bool canResume = false,
  }) async {
    final route = widget.returnTo != null
        ? '/login?returnTo=${Uri.encodeComponent(widget.returnTo!)}'
        : '/login';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Account already exists'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Stay here'),
            ),
            if (canResume)
              FilledButton.tonal(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _resumePartialOnboardingFromSignUp();
                },
                child: const Text('Continue setup'),
              ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _goNow(route);
              },
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resumePartialOnboardingFromSignUp() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSignupFeedback(
        'Enter the same email and password you used before, then continue setup.',
        isFailure: true,
      );
      return;
    }
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resumeIncompleteOnboarding(
            email: email,
            password: password,
            name: _nameController.text.trim(),
          );
      final returnParam = widget.returnTo != null
          ? '&returnTo=${Uri.encodeComponent(widget.returnTo!)}'
          : '';
      _goSafely(
        '/verify-email?email=${Uri.encodeComponent(email)}&partial=1$returnParam',
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceAll('Exception: ', '');
      if (_looksLikeExistingAccountError(message)) {
        await _showExistingAccountDialog(
          'This account is already active. Please log in instead.',
          canResume: false,
        );
        return;
      }
      _showSignupFeedback(message, isFailure: true);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    TextInput.finishAutofillContext();
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions first'),
        ),
      );
      return;
    }
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      await _routeAfterAuth();
    } catch (e) {
      if (!mounted) return;
      _showSignupFeedback(
        e.toString().replaceAll('Exception: ', ''),
        isFailure: true,
      );
    }
  }

  void _showSignupFeedback(String message, {bool isFailure = false}) {
    final theme = Theme.of(context);
    final bg = isFailure
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;
    final fg = isFailure
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimaryContainer;
    final icon = isFailure ? Icons.info_outline : Icons.check_circle_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        content: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: fg, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
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
        _goSafely('/add-car?nudge=true');
        return;
      }
    }

    if (widget.returnTo != null) {
      _goNow(widget.returnTo!);
    } else {
      _goNow('/home');
    }
  }

  void _continueAsGuest() {
    ref.read(hasSeenWelcomeProvider.notifier).completeWelcome();
    if (widget.returnTo != null) {
      _goNow(widget.returnTo!);
    } else {
      _goNow('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final password = _passwordController.text;
    final strengthScore = _passwordScore(password);
    final isStrongPassword =
        password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    final shouldShowPasswordGuide =
        password.isNotEmpty &&
        (_passwordFocusNode.hasFocus ||
            _confirmPasswordFocusNode.hasFocus ||
            !isStrongPassword);

    return AutofillGroup(
      child: Form(
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
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Start your journey with SpareWo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.hintColor),
              ).animate().fadeIn(delay: 100.ms),
            ),

            SizedBox(height: widget.compact ? 12 : 20),

            TextFormField(
              controller: _nameController,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
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
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: _onEmailChanged,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              validator: (v) => !_isValidEmailFormat((v ?? '').trim())
                  ? 'Invalid email'
                  : (_isEmailTaken ? 'This email is already registered' : null),
            ),
            if (_emailInlineError != null) ...[
              const SizedBox(height: 8),
              _isEmailTaken
                  ? Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 130,
                          child: Text(
                            'This email already has an account. If setup is incomplete, continue registration.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _resumePartialOnboardingFromSignUp,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Complete setup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final route = widget.returnTo != null
                                ? '/login?returnTo=${Uri.encodeComponent(widget.returnTo!)}'
                                : '/login';
                            _goNow(route);
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _emailInlineError!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
            SizedBox(height: widget.compact ? 10 : 16),
            Container(
              key: _passwordSectionKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    focusNode: _passwordFocusNode,
                    autofillHints: const [AutofillHints.newPassword],
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.next,
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
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Add at least 1 uppercase letter and 1 number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: widget.compact ? 10 : 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    focusNode: _confirmPasswordFocusNode,
                    autofillHints: const [AutofillHints.newPassword],
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableInteractiveSelection: false,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_person_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) {
                        return 'Confirm your password';
                      }
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (_confirmPasswordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _confirmPasswordController.text ==
                                  _passwordController.text
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 14,
                          color:
                              _confirmPasswordController.text ==
                                  _passwordController.text
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _confirmPasswordController.text ==
                                  _passwordController.text
                              ? 'Passwords match'
                              : 'Passwords do not match',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _confirmPasswordController.text ==
                                    _passwordController.text
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (shouldShowPasswordGuide) ...[
                    SizedBox(height: widget.compact ? 10 : 14),
                    _PasswordGuide(
                      password: password,
                      score: strengthScore,
                      color: _strengthColor(strengthScore),
                      label: _strengthLabel(strengthScore),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: widget.compact ? 12 : 16),

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
                      Text(' and ', style: TextStyle(color: theme.hintColor)),
                      GestureDetector(
                        onTap: _openPrivacyPolicy,
                        child: const Text(
                          'Privacy Policy',
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

            SizedBox(height: widget.compact ? 12 : 16),

            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: SizedBox(
                  width: double.infinity,
                  height: widget.compact ? 46 : 50,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleSignUp,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.28),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            SizedBox(height: widget.compact ? 12 : 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  final route = widget.returnTo != null
                      ? '/login?returnTo=${Uri.encodeComponent(widget.returnTo!)}'
                      : '/login';
                  _goNow(route);
                },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            SizedBox(height: widget.compact ? 12 : 16),

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

            SizedBox(height: widget.compact ? 10 : 14),

            SizedBox(
              width: double.infinity,
              height: widget.compact ? 46 : 48,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _handleGoogleSignUp,
                icon: Image.asset(
                  'assets/icons/Google Logo Icon.png',
                  width: 22,
                ),
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
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _continueAsGuest,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
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
      ),
    );
  }
}

class _PasswordGuide extends StatelessWidget {
  const _PasswordGuide({
    required this.password,
    required this.score,
    required this.color,
    required this.label,
  });

  final String password;
  final int score;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final checks = <_PasswordCheck>[
      _PasswordCheck('8+ characters', password.length >= 8),
      _PasswordCheck('Uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      _PasswordCheck('Lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      _PasswordCheck('Number', RegExp(r'[0-9]').hasMatch(password)),
      _PasswordCheck(
        'Special character',
        RegExp(r'[^A-Za-z0-9]').hasMatch(password),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: (score / 5).clamp(0, 1),
                    color: color,
                    backgroundColor: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: checks
                .map(
                  (check) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: check.passed
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          check.passed
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 14,
                          color: check.passed
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          check.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PasswordCheck {
  const _PasswordCheck(this.label, this.passed);
  final String label;
  final bool passed;
}
