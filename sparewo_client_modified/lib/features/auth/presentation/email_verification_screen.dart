// lib/features/auth/presentation/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:async';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String? returnTo;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.returnTo,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isVerifying = false;
  Timer? _clipboardTimer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupAutoFill();
    _startClipboardMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clipboardTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startClipboardMonitoring() {
    // Check clipboard every second for verification code
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isVerifying) return;

      try {
        final clipboardData = await Clipboard.getData('text/plain');
        if (clipboardData != null && clipboardData.text != null) {
          final text = clipboardData.text!.trim();
          final code = text.replaceAll(RegExp(r'[^0-9]'), '');

          // Check if it's a 6-digit code
          if (code.length == 6 && _controllers[0].text.isEmpty) {
            setState(() {
              for (int i = 0; i < 6; i++) {
                _controllers[i].text = code[i];
              }
            });
            // Clear clipboard after use
            Clipboard.setData(const ClipboardData(text: ''));
            // Auto-verify
            Future.delayed(const Duration(milliseconds: 300), _verifyCode);
          }
        }
      } catch (_) {
        // Ignore clipboard errors
      }
    });
  }

  void _setupAutoFill() {
    // Handle manual paste in first field
    _controllers[0].addListener(() {
      final text = _controllers[0].text;
      if (text.length > 1) {
        // User pasted multiple characters
        final code = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (code.length >= 6) {
          setState(() {
            for (int i = 0; i < 6; i++) {
              _controllers[i].text = code[i];
            }
          });
          // Clear focus and verify
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 100), _verifyCode);
        }
      }
    });
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    try {
      EasyLoading.show(status: 'Resending code...');
      await ref
          .read(authNotifierProvider.notifier)
          .resendVerificationCode(email: widget.email);
      EasyLoading.showSuccess('Code sent!');
      _startTimer();
      // Clear fields
      for (var controller in _controllers) {
        controller.clear();
      }
    } catch (e) {
      EasyLoading.showError(
        e.toString().replaceAll('Exception: ', ''),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (_isVerifying) return;

    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      EasyLoading.showError('Please enter the complete code');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      EasyLoading.show(status: 'Verifying...');

      final success = await ref
          .read(authNotifierProvider.notifier)
          .verifyEmail(email: widget.email, code: code);

      if (success) {
        EasyLoading.showSuccess('Account created successfully!');
        // Stop clipboard monitoring
        _clipboardTimer?.cancel();
        // Navigate after a brief delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          if (widget.returnTo != null) {
            context.go(widget.returnTo!);
          } else {
            context.go('/home');
          }
        }
      }
    } catch (e) {
      EasyLoading.showError(
        e.toString().replaceAll('Exception: ', ''),
        duration: const Duration(seconds: 3),
      );
      // Clear the code fields on error
      if (mounted) {
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildScaffold({required bool isDesktop}) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.go('/signup'),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 640 : 9999),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn().scale(),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Verify Your Email',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Enter the 6-digit code sent to',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 8),

                    Text(
                      widget.email,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),

                    // Code Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 50,
                          height: 60,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            enabled: !_isVerifying,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.05,
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else {
                                  // Last field filled - auto verify
                                  final code = _controllers
                                      .map((c) => c.text)
                                      .join();
                                  if (code.length == 6) {
                                    FocusScope.of(context).unfocus();
                                    _verifyCode();
                                  }
                                }
                              } else if (value.isEmpty && index > 0) {
                                // Handle backspace
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 40),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isVerifying ? null : _verifyCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Verify Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).scale(),

                    const SizedBox(height: 32),

                    // Resend Code
                    if (!_canResend)
                      Text(
                        'Resend code in $_secondsRemaining seconds',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ).animate().fadeIn(delay: 350.ms)
                    else
                      TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 32),

                    // Helper Text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Check your spam folder if you don\'t see the email in your inbox',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Code will auto-paste from your clipboard',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ResponsiveScreen(
      mobile: buildScaffold(isDesktop: false),
      desktop: buildScaffold(isDesktop: true),
    );
  }
}
