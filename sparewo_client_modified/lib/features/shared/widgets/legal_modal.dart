import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';

class LegalModal extends StatelessWidget {
  final String title;
  final String content;

  const LegalModal({super.key, required this.title, required this.content});

  static Future<void> showTermsAndConditions(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LegalModal(
            title: 'Terms & Conditions',
            content: _dummyTerms,
          ).animate().slideY(
            begin: 1.0,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  static Future<void> showPrivacyPolicy(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LegalModal(
            title: 'Privacy Policy',
            content: _dummyPrivacy,
          ).animate().slideY(
            begin: 1.0,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.transparent,
            color: AppColors.primary.withValues(alpha: 0.2),
            minHeight: 1,
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(28),
              child: Text(
                content,
                style: AppTextStyles.bodyMedium.copyWith(
                  height: 1.8,
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),
            ),
          ),

          // Action (Floating/Gradient Effect)
          Container(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0)
                      : Colors.white.withValues(alpha: 0),
                  isDark ? const Color(0xFF0F172A) : Colors.white,
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child:
                  FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        child: const Text(
                          'I Understand',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .shimmer(
                        delay: 3000.ms,
                        duration: 1500.ms,
                        color: Colors.white24,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

const _dummyTerms = '''
TERMS AND CONDITIONS

Welcome to SpareWo. These terms and conditions outline the rules and regulations for the use of SpareWo's Website and Mobile Application.

1. Agreement to Terms
By accessing this app, we assume you accept these terms and conditions. Do not continue to use SpareWo if you do not agree to take all of the terms and conditions stated on this page.

2. Intellectual Property
Unless otherwise stated, SpareWo and/or its licensors own the intellectual property rights for all material on SpareWo. All intellectual property rights are reserved.

3. User Responsibilities
Users must provide accurate information when creating an account and placing orders. Users are responsible for maintaining the confidentiality of their account credentials.

4. Orders and Payments
All orders are subject to availability and confirmation of the order price. SpareWo reserves the right to refuse any order.

5. Delivery
SpareWo aims to provide timely delivery of spare parts. However, delivery times are estimates and not guaranteed.

6. Limitation of Liability
SpareWo shall not be held liable for any indirect, consequential, or special liability arising out of or in any way related to your use of this app.

7. Governing Law
These terms will be governed by and interpreted in accordance with the laws of Uganda.
''';

const _dummyPrivacy = '''
PRIVACY POLICY

Your privacy is important to us. It is SpareWo's policy to respect your privacy regarding any information we may collect from you across our website and mobile application.

1. Information We Collect
We only ask for personal information when we truly need it to provide a service to you. We collect it by fair and lawful means, with your knowledge and consent.

2. How We Use Information
We use your information to provide our services, process orders, and communicate with you about your account or SpareWo updates.

3. Data Retention
We only retain collected information for as long as necessary to provide you with your requested service.

4. Data Sharing
We do not share any personally identifying information publicly or with third-parties, except when required by law or to complete your service (e.g., delivery partners).

5. Security
We use commercially acceptable means to protect your personal data from loss and theft, as well as unauthorized access, disclosure, copying, use or modification.

6. Your Rights
You are free to refuse our request for your personal information, with the understanding that we may be unable to provide you with some of your desired services.
''';
