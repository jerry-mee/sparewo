import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:garage@sparewo.ug');
    await launchUrl(uri);
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+256773276096');
    await launchUrl(uri);
  }

  void _showModal(BuildContext context, Widget child, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.desktopH3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = DateFormat('yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.32)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help or want to reach us?',
            style: AppTextStyles.desktopH3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Email or call our team. We respond within business hours (7am–9pm).',
            style: AppTextStyles.bodyMedium.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FooterButton(
                label: 'garage@sparewo.ug',
                icon: Icons.email_outlined,
                onTap: _launchEmail,
              ),
              _FooterButton(
                label: '+256 773 276 096',
                icon: Icons.phone_outlined,
                onTap: _launchPhone,
              ),
              _FooterButton(
                label: 'FAQs',
                icon: Icons.help_outline,
                onTap: () => _showModal(context, const _FaqContent(), 'FAQs'),
              ),
              _FooterButton(
                label: 'Terms',
                icon: Icons.article_outlined,
                onTap: () => _showModal(
                  context,
                  const _TermsContent(),
                  'Terms and Conditions',
                ),
              ),
              _FooterButton(
                label: 'Privacy',
                icon: Icons.privacy_tip_outlined,
                onTap: () => _showModal(
                  context,
                  const _PrivacyContent(),
                  'Privacy Policy',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '© $year SpareWo (U) Ltd. All rights reserved.',
            style: AppTextStyles.bodyMedium.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FooterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textTheme.bodyMedium?.color,
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.28)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FaqContent extends StatelessWidget {
  const _FaqContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = [
      {
        'q': 'Are the spare parts genuine?',
        'a':
            'Yes. All parts are sourced from vetted suppliers and checked before delivery.',
      },
      {
        'q': 'Do you provide part fitting?',
        'a': 'Yes. Part fitting is offered alongside spare part purchases.',
      },
      {
        'q': 'Is part fitting done through AutoHub?',
        'a': 'No. AutoHub is for other car care services only.',
      },
      {
        'q': 'What services does AutoHub cover?',
        'a':
            'Diagnostics, servicing, maintenance, inspections, and other non-part services.',
      },
      {
        'q': 'What extra benefits do I get from the app?',
        'a':
            'You can track your car’s health, service history, and important dates in one place.',
      },
    ];

    return Column(
      children: questions
          .map(
            (item) => _FaqTile(
              question: item['q']!,
              answer: item['a']!,
              textColor: theme.textTheme.bodyMedium?.color,
              hintColor: theme.hintColor,
            ),
          )
          .toList(),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  final Color? textColor;
  final Color? hintColor;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.textColor,
    required this.hintColor,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.question,
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              _isOpen ? Icons.expand_less : Icons.expand_more,
              color: widget.hintColor,
            ),
            onTap: () => setState(() => _isOpen = !_isOpen),
          ),
          if (_isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _LegalContent(
      sections: const [
        _LegalSection(
          title: '1. About SpareWo',
          body:
              'SpareWo (U) Ltd provides genuine auto spare parts, fitting services alongside spare part purchases, and additional car care services such as diagnostics and maintenance. Some services may be carried out by approved third-party service providers.',
        ),
        _LegalSection(
          title: '2. Spare Parts and Services',
          body:
              'All spare parts are supplied based on the information provided by the customer. Services are provided as agreed at the time of booking or purchase. SpareWo takes reasonable care to ensure quality parts and workmanship.',
        ),
        _LegalSection(
          title: '3. Payments',
          body:
              'Prices are communicated before payment is made. Payment may be made using Mobile Money, cards, or other approved methods. Some services may require partial or full payment before work begins.',
        ),
        _LegalSection(
          title: '4. Warranty',
          body:
              'Spare parts supplied by SpareWo are covered by a 90-day warranty from the date of delivery or fitting. The warranty covers defects related to the part supplied or fitting provided by SpareWo. The warranty does not cover damage caused by misuse, accidents, neglect, or normal wear and tear.',
        ),
        _LegalSection(
          title: '5. Replacements and Free Fitting',
          body:
              'If a spare part is found to be defective within the warranty period, SpareWo will replace it where applicable. Fitting for approved replacements is provided free of charge. Replacement is subject to inspection and confirmation by SpareWo.',
        ),
        _LegalSection(
          title: '6. Refunds',
          body:
              'Refunds may be requested within 30 days of purchase. Refunds are subject to the condition that the part has not been misused or damaged. Where applicable, refunds may be processed after inspection and verification.',
        ),
        _LegalSection(
          title: '7. Customer Responsibilities',
          body:
              'Customers are responsible for providing accurate information about their vehicle, disclosing relevant service or repair history, making the vehicle available at the agreed time, and following reasonable care and maintenance guidance.',
        ),
        _LegalSection(
          title: '8. Limitation of Liability',
          body:
              'SpareWo’s liability is limited to the value of the parts or services provided. SpareWo is not liable for indirect or consequential losses. SpareWo is not responsible for pre-existing vehicle conditions or faults outside the agreed scope of work.',
        ),
        _LegalSection(
          title: '9. Delays and Risk',
          body:
              'While SpareWo aims to deliver services on time, delays may occur due to availability of parts or other factors beyond reasonable control. Vehicles and components are handled with reasonable care, but remain at the customer’s risk unless loss or damage is caused by SpareWo’s negligence.',
        ),
        _LegalSection(
          title: '10. Disputes',
          body:
              'Any disputes will first be addressed in good faith. If unresolved, disputes may be referred to arbitration in accordance with the laws of Uganda.',
        ),
        _LegalSection(
          title: '11. Governing Law',
          body:
              'These Terms and Conditions are governed by the laws of the Republic of Uganda.',
        ),
        _LegalSection(
          title: '12. Privacy',
          body:
              'Customer information is handled with reasonable care and confidentiality. Information may be used to provide services, support, and relevant communication in line with SpareWo’s Privacy Policy.',
        ),
        _LegalSection(
          title: '13. Changes to These Terms',
          body:
              'SpareWo may update these Terms and Conditions from time to time. Continued use of the platform means you accept the updated terms.',
        ),
      ],
      footer:
          'If you have questions about these terms, please contact us at garage@sparewo.ug.',
      textColor: theme.textTheme.bodyMedium?.color,
      hintColor: theme.hintColor,
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _LegalContent(
      sections: const [
        _LegalSection(
          title: 'Information we collect',
          body:
              'We collect information you provide directly to us, such as when you create an account, make a purchase, or contact support. This may include your name, email address, phone number, vehicle information, and payment details. We also collect usage data automatically when you interact with our services.',
        ),
        _LegalSection(
          title: 'How we use it',
          body:
              'We use your information to facilitate order processing, deliver spare parts, arrange fitting services, and manage your account. We also use data to improve our platform, communicate with you regarding your orders or account status, and for internal analytics.',
        ),
        _LegalSection(
          title: 'Payments and security',
          body:
              'Payment processing is handled by secure third-party payment providers. We do not store your full credit card details on our servers. We implement industry-standard security measures to protect your personal information from unauthorized access or disclosure.',
        ),
        _LegalSection(
          title: 'Third-party services',
          body:
              'We may share your information with third-party service providers who assist us in our operations, such as logistics partners for delivery, mechanics for fitting services, and cloud hosting providers. These parties are authorized to use your data only as necessary to provide these services to us.',
        ),
        _LegalSection(
          title: 'Your rights',
          body:
              'You have the right to access, correct, or delete your personal information held by us. You may also object to the processing of your data or request data portability. To exercise these rights, please contact us.',
        ),
      ],
      footer:
          'If you have any questions about this Privacy Policy, please contact us at garage@sparewo.ug.',
      textColor: theme.textTheme.bodyMedium?.color,
      hintColor: theme.hintColor,
    );
  }
}

class _LegalContent extends StatelessWidget {
  final List<_LegalSection> sections;
  final String footer;
  final Color? textColor;
  final Color? hintColor;

  const _LegalContent({
    required this.sections,
    required this.footer,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Text(
            section.title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: AppTextStyles.bodyMedium.copyWith(color: hintColor),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          footer,
          style: AppTextStyles.bodyMedium.copyWith(color: hintColor),
        ),
      ],
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});
}
