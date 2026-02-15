// File: lib/screens/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../theme.dart';
import '../providers/providers.dart';
import '../widgets/loading_button.dart';
import '../services/ui_notification_service.dart';
import '../constants/enums.dart';
import '../routes/app_router.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  Timer? _clipboardTimer;
  String? _lastClipboardContent;
  final UINotificationService _uiNotificationService = UINotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startClipboardMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clipboardTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  void _startClipboardMonitoring() {
    _checkClipboard();
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkClipboard();
    });
  }

  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final content = clipboardData?.text?.trim();
      if (content != null &&
          content != _lastClipboardContent &&
          _isValidVerificationCode(content) &&
          _codeController.text.isEmpty) {
        setState(() {
          _codeController.text = content;
          _lastClipboardContent = content;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verification code pasted automatically'),
              duration: const Duration(seconds: 2),
              backgroundColor:
                  Theme.of(context).extension<AppColorsExtension>()!.success,
            ),
          );
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  bool _isValidVerificationCode(String code) {
    return code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code);
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      _uiNotificationService.showError('Please enter the verification code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final email = ref.read(authNotifierProvider).verificationEmail ?? '';
      await ref.read(authNotifierProvider.notifier).verifyEmail(
            email,
            _codeController.text.trim(),
          );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState.status == AuthStatus.authenticated) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      }
    } catch (e) {
      if (!mounted) return;
      _uiNotificationService
          .showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.email_outlined,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Check your email',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a verification code to\n${authState.verificationEmail ?? 'your email'}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Copy the code from your email and it will be pasted automatically',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium,
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _codeController.clear());
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length == 6 && _isValidVerificationCode(value)) {
                  _verifyCode();
                }
              },
            ),
            const SizedBox(height: 24),
            LoadingButton(
              onPressed: _verifyCode,
              isLoading: _isLoading,
              label: 'Verify',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .sendVerificationEmail(
                              authState.verificationEmail ?? '',
                            );
                        if (!mounted) return;
                        _uiNotificationService
                            .showSuccess('Verification code resent');
                      } catch (e) {
                        if (!mounted) return;
                        _uiNotificationService.showError(e.toString());
                      }
                    },
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
