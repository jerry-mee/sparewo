import 'package:flutter/material.dart';
import '../../theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 0,
        title: const Text('Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSupportCard(
            context: context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Browse frequently asked questions',
            onTap: () {},
          ),
          _buildSupportCard(
            context: context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@sparewo.ug',
            onTap: () {},
          ),
          _buildSupportCard(
            context: context,
            icon: Icons.phone_outlined,
            title: 'Call Support',
            subtitle: '+256 700 123 456',
            onTap: () {},
          ),
          _buildSupportCard(
            context: context,
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
