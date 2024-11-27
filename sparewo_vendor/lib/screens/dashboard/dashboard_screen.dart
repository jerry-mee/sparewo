import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import 'widgets/dashboard_stats.dart';
import '../products/widgets/product_list.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/feedback_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts();
      ref.read(statsProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(currentVendorProvider);
    final productsAsync = ref.watch(productsAsyncProvider);
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.home_outlined, size: 28),
            const SizedBox(width: 8),
            Text(
              'Welcome, ${vendor?.businessName ?? "Vendor"}',
              style: VendorTextStyles.heading3,
            ),
          ],
        ),
        actions: [
          _buildNotificationIcon(unreadNotifications, context),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(productsProvider.notifier).loadProducts(),
            ref.read(statsProvider.notifier).loadStats(),
          ]);
          await _feedbackService.success();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardStats(),
              const SizedBox(height: 24),
              _buildYourProductsSection(context, productsAsync),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/products/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildNotificationIcon(int unreadNotifications, BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        if (unreadNotifications > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: VendorColors.error,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadNotifications.toString(),
                style: VendorTextStyles.caption.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYourProductsSection(
      BuildContext context, AsyncValue productsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Products', style: VendorTextStyles.heading2),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/products');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return _buildEmptyProductsState(context);
            }
            return ProductList(
              products: products.take(5).toList(),
              showStatus: true,
              showActions: true,
              onProductTap: (product) {
                Navigator.pushNamed(
                  context,
                  '/products/detail',
                  arguments: product,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: VendorColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: VendorTextStyles.body1.copyWith(
                    color: VendorColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(productsProvider.notifier).loadProducts();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProductsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products yet. Add your first product!',
            style: VendorTextStyles.body1.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/products/add');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}
