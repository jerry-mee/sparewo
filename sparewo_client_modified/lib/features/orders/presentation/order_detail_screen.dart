// lib/features/orders/presentation/order_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';

// Provider to fetch a single order by ID
final orderByIdProvider = StreamProvider.family<DocumentSnapshot, String>((
  ref,
  id,
) {
  return FirebaseFirestore.instance.collection('orders').doc(id).snapshots();
});

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  final Map<String, dynamic>? initialOrder;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));
    final theme = Theme.of(context);

    // Use initial data if available, otherwise wait for stream
    final orderData =
        orderAsync.asData?.value.data() as Map<String, dynamic>? ??
        initialOrder;

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Order #${orderId.substring(0, 8).toUpperCase()}'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: orderData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: _buildContent(context, orderData, isDesktop: false),
              ),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: orderData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesktopSection(
                      title: 'Order #${orderId.substring(0, 8).toUpperCase()}',
                      subtitle: 'Details and order summary',
                      padding: const EdgeInsets.only(top: 28, bottom: 12),
                      child: const SizedBox.shrink(),
                    ),
                    _buildContent(context, orderData, isDesktop: true),
                    const SiteFooter(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> orderData, {
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);
    final items = orderData['items'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusCard(context, orderData['status'] ?? 'pending'),
        const SizedBox(height: 24),
        Text('Delivery Details', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.person_outline,
                'Recipient',
                orderData['userName'] ?? 'N/A',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                Icons.location_on_outlined,
                'Address',
                orderData['deliveryAddress'] ?? 'N/A',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                Icons.phone_outlined,
                'Phone',
                orderData['contactPhone'] ?? 'N/A',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Items Ordered', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        ..._buildItemsList(context, items),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                'Subtotal',
                (orderData['subtotal'] ?? 0).toDouble(),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Delivery Fee',
                (orderData['deliveryFee'] ?? 0).toDouble(),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.h3),
                  Text(
                    'UGX ${_formatCurrency((orderData['totalAmount'] ?? 0).toDouble())}',
                    style: AppTextStyles.price,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: isDesktop ? 260 : double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _contactSupport(),
            icon: const Icon(Icons.support_agent),
            label: const Text('Problem with this order?'),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String status) {
    Color color;
    IconData icon;
    String text;

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.thumb_up_alt_outlined;
        text = 'Order Confirmed';
        break;
      case 'processing':
        color = Colors.orange;
        icon = Icons.inventory_2_outlined;
        text = 'Processing';
        break;
      case 'shipped':
        color = Colors.purple;
        icon = Icons.local_shipping_outlined;
        text = 'Out for Delivery';
        break;
      case 'delivered':
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        text = 'Delivered';
        break;
      case 'cancelled':
        color = AppColors.error;
        icon = Icons.cancel_outlined;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        icon = Icons.access_time;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItemsList(BuildContext context, List items) {
    return items.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Part',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Qty: ${item['quantity']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              'UGX ${_formatCurrency((item['lineTotal'] ?? 0).toDouble())}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          'UGX ${_formatCurrency(amount)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _contactSupport() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '0773276096');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}
