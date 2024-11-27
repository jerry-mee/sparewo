import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../constants/theme.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.loadPastOrders();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      if (!mounted) return;

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Execute operations sequentially
      await dataProvider.loadPastOrders();
      await dataProvider.loadCart();
      await authProvider.refreshUserProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: AppTextStyles.heading3),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, DataProvider>(
        builder: (context, authProvider, dataProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return _buildUnauthenticatedView();
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, dataProvider),
                  const SizedBox(height: 24),
                  _buildOrdersSection(dataProvider),
                  const SizedBox(height: 24),
                  _buildMenuSection(context),
                  const SizedBox(height: 24),
                  _buildSignOutButton(context, authProvider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Please sign in to view your profile',
            style: AppTextStyles.body1,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage:
                user.profileImg != null ? NetworkImage(user.profileImg!) : null,
            child: user.profileImg == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: AppTextStyles.heading2,
          ),
          Text(
            user.email,
            style: AppTextStyles.body2,
          ),
          if (user.phone != null) ...[
            const SizedBox(height: 4),
            Text(
              user.phone!,
              style: AppTextStyles.body2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DataProvider dataProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionItem(
            context: context,
            icon: Icons.shopping_cart,
            label: 'Cart (${dataProvider.cartItems.length})',
            onTap: () => Navigator.pushNamed(context, '/cart'),
            badgeCount: dataProvider.cartItems.length,
          ),
          _buildQuickActionItem(
            context: context,
            icon: Icons.history,
            label: 'Orders (${dataProvider.pastOrders.length})',
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),
          _buildQuickActionItem(
            context: context,
            icon: Icons.favorite,
            label: 'Wishlist',
            onTap: () => Navigator.pushNamed(context, '/wishlist'),
          ),
          _buildQuickActionItem(
            context: context,
            icon: Icons.directions_car,
            label: 'My Cars',
            onTap: () => Navigator.pushNamed(context, '/cars'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersSection(DataProvider dataProvider) {
    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: AppTextStyles.heading3),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/orders'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dataProvider.pastOrders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No orders yet',
                  style: AppTextStyles.body2,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataProvider.pastOrders.take(3).length,
              itemBuilder: (context, index) {
                final order = dataProvider.pastOrders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      'Order #${order['id']}',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Status: ${order['status']}',
                      style: AppTextStyles.body2,
                    ),
                    trailing: Text(
                      'UGX ${order['total_amount']}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/order-details',
                        arguments: order,
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Account Settings',
            style: AppTextStyles.heading3,
          ),
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          icon: Icons.person,
          title: 'Edit Profile',
          onTap: () => Navigator.pushNamed(context, '/edit-profile'),
        ),
        _buildMenuItem(
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () => Navigator.pushNamed(context, '/notifications'),
        ),
        _buildMenuItem(
          icon: Icons.security,
          title: 'Security',
          onTap: () => Navigator.pushNamed(context, '/security'),
        ),
        _buildMenuItem(
          icon: Icons.help,
          title: 'Help & Support',
          onTap: () => Navigator.pushNamed(context, '/support'),
        ),
        _buildMenuItem(
          icon: Icons.description,
          title: 'Terms & Conditions',
          onTap: () => Navigator.pushNamed(context, '/terms'),
        ),
        _buildMenuItem(
          icon: Icons.privacy_tip,
          title: 'Privacy Policy',
          onTap: () => Navigator.pushNamed(context, '/privacy'),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.body1),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => _handleSignOut(context, authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Sign Out',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleSignOut(
      BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        if (!mounted) return;

        await authProvider.signOut();

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }
}
