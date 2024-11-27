import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/providers/service_providers.dart';
import '../../models/vendor.dart'; // Fix: Import Vendor model
import '../../theme.dart';
import '../../services/feedback_service.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _feedbackService = FeedbackService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsService = ref.read(settingsServiceProvider);
    final settings = await settingsService.getSettings();
    setState(() {
      _notificationsEnabled = settings.notificationsEnabled;
    });
  }

  Widget _buildProfileSection(Vendor vendor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: VendorColors.primary,
            backgroundImage: vendor.profileImage != null
                ? NetworkImage(vendor.profileImage!)
                : null,
            child: vendor.profileImage == null
                ? Text(
                    vendor.name[0].toUpperCase(),
                    style: VendorTextStyles.heading1.copyWith(
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            vendor.businessName,
            style: VendorTextStyles.heading2,
          ),
          Text(
            vendor.email,
            style: VendorTextStyles.body1,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/editProfile');
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(currentVendorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          if (vendor != null) _buildProfileSection(vendor),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
          ),
          const ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
