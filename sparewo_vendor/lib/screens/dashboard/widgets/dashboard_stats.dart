// lib/screens/dashboard/widgets/dashboard_stats.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../../../models/dashboard_stats.dart' as models;
import '../../../providers/stats_provider.dart';

class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsAsyncProvider);

    return statsAsync.when(
      data: (models.DashboardStats stats) => StatsGrid(stats: stats),
      loading: () => const LoadingStats(),
      error: (error, stackTrace) =>
          ErrorStats(error: error.toString(), ref: ref),
    );
  }
}

class StatsGrid extends StatelessWidget {
  final models.DashboardStats stats;

  const StatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          StatCard(
            title: 'Total Sales',
            value: 'UGX ${stats.totalSales.toStringAsFixed(2)}',
            icon: Icons.monetization_on,
            color: VendorColors.primary,
          ),
          StatCard(
            title: 'Today\'s Sales',
            value: 'UGX ${stats.todaySales.toStringAsFixed(2)}',
            icon: Icons.today,
            color: VendorColors.success,
          ),
          StatCard(
            title: 'Active Orders',
            value: stats.activeOrders.toString(),
            icon: Icons.pending_actions,
            color: VendorColors.pending,
          ),
          StatCard(
            title: 'Completed Orders',
            value: stats.completedOrders.toString(),
            icon: Icons.check_circle,
            color: VendorColors.approved,
          ),
          StatCard(
            title: 'Total Products',
            value: stats.totalProducts.toString(),
            icon: Icons.inventory,
            color: VendorColors.primary,
          ),
          StatCard(
            title: 'Out of Stock',
            value: stats.outOfStockProducts.toString(),
            icon: Icons.warning,
            color: VendorColors.error,
            isWarning: true,
          ),
          StatCard(
            title: 'Average Rating',
            value: '${stats.averageRating.toStringAsFixed(1)} ⭐',
            icon: Icons.star,
            color: Colors.amber,
          ),
          StatCard(
            title: 'Total Reviews',
            value: stats.totalReviews.toString(),
            icon: Icons.rate_review,
            color: VendorColors.secondary,
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWarning;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (isWarning &&
                    int.tryParse(value) != null &&
                    int.parse(value) > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: VendorColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Alert',
                      style: VendorTextStyles.caption.copyWith(
                        color: VendorColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: VendorTextStyles.body2.copyWith(
                color: VendorColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: VendorTextStyles.heading3.copyWith(
                color: VendorColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingStats extends StatelessWidget {
  const LoadingStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: List.generate(
          8,
          (index) => Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
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
}

class ErrorStats extends ConsumerWidget {
  final String error;
  final WidgetRef ref;

  const ErrorStats({
    super.key,
    required this.error,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: VendorColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load statistics',
            style: VendorTextStyles.heading3.copyWith(
              color: VendorColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: VendorTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(statsProvider.notifier).loadStats(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
