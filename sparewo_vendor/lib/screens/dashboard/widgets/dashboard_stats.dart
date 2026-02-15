// File: lib/screens/dashboard/widgets/dashboard_stats.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparewo_vendor/routes/app_router.dart';
import '../../../providers/stats_provider.dart';
import '../../../theme.dart';
import '../../../models/dashboard_stats.dart' as models;

class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsStreamProvider);

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 220),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildEmptyState(context),
          data: (stats) {
            if (stats.totalProducts == 0 && stats.totalSales == 0) {
              return _buildEmptyState(context);
            }
            return _buildStatsGrid(context, stats);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(height: 16),
        Text('Your Store Stats Appear Here',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
            'Add your first product to start selling and see your performance grow!',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.addEditProduct),
          icon: const Icon(Icons.add_shopping_cart_rounded),
          label: const Text('Add Your First Product'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
        )
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, models.DashboardStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.inventory_2_outlined,
                label: 'Total Products',
                value: stats.totalProducts.toString(),
                color: Theme.of(context).colorScheme.primary,
                subLabel: '${stats.activeProducts} active',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.shopping_bag_outlined,
                label: 'Total Orders',
                value: stats.totalOrders.toString(),
                color: Theme.of(context).colorScheme.secondary,
                subLabel: '${stats.activeOrders} active',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.monetization_on_outlined,
                label: 'Total Sales',
                value: 'UGX ${stats.totalSales.toStringAsFixed(0)}',
                color:
                    Theme.of(context).extension<AppColorsExtension>()!.success,
                subLabel: 'Today: ${stats.todaySales.toStringAsFixed(0)}',
                isRevenue: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.star_outline,
                label: 'Avg Rating',
                value: stats.averageRating.toStringAsFixed(1),
                color:
                    Theme.of(context).extension<AppColorsExtension>()!.pending,
                subLabel: '${stats.totalReviews} reviews',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subLabel,
    bool isRevenue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Icon(icon, color: color, size: 24)],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: color,
                  fontSize: isRevenue ? 16 : 20,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .color!
                        .withOpacity(0.8),
                    fontSize: 10,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
