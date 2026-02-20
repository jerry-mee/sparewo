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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/orders');
              }
            },
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
    final summary = _resolveSummary(orderData, items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusCard(context, orderData['status'] ?? 'pending'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _refreshOrderStatus(context),
            icon: const Icon(Icons.sync),
            label: const Text('Update Status'),
          ),
        ),
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
                context,
                Icons.person_outline,
                'Recipient',
                orderData['userName'] ?? 'N/A',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                context,
                Icons.location_on_outlined,
                'Address',
                orderData['deliveryAddress'] ?? 'N/A',
              ),
              const Divider(height: 24),
              _buildDetailRow(
                context,
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.34 : 0.7,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              _buildSummaryRow(context, 'Subtotal', summary.subtotal),
              const SizedBox(height: 8),
              _buildSummaryRow(context, 'Delivery Fee', summary.deliveryFee),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.h3),
                  Text(
                    'UGX ${_formatCurrency(summary.total)}',
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
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

    final foregroundColor = isDarkMode
        ? Colors.white
        : const Color(0xFF111827); // Dark text in light mode.

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDarkMode ? 0.4 : 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  color: foregroundColor,
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

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final hintColor = theme.hintColor;
    final textColor = theme.colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: hintColor)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItemsList(BuildContext context, List items) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.5 : 0.8,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.settings, color: theme.hintColor),
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
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              'UGX ${_formatCurrency(_itemLineTotal(item))}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSummaryRow(BuildContext context, String label, double amount) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.hintColor)),
        Text(
          'UGX ${_formatCurrency(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
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

  Future<void> _refreshOrderStatus(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final status = (doc.data()?['status'] as String?) ?? 'pending';
      scaffold.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Latest status: ${status.toUpperCase()}'),
        ),
      );
    } catch (error) {
      scaffold.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not refresh status: $error'),
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }

  double _toAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  double _itemLineTotal(dynamic rawItem) {
    if (rawItem is! Map) return 0.0;
    final item = Map<String, dynamic>.from(
      rawItem.map((k, v) => MapEntry(k.toString(), v)),
    );
    final lineTotal = _toAmount(item['lineTotal']);
    if (lineTotal > 0) return lineTotal;
    final unitPrice = _toAmount(item['unitPrice']);
    final quantity = _toAmount(item['quantity']);
    return unitPrice * quantity;
  }

  _OrderSummary _resolveSummary(Map<String, dynamic> orderData, List items) {
    final deliveryFee = _toAmount(orderData['deliveryFee']);
    final declaredSubtotal = _toAmount(orderData['subtotal']);
    final declaredTotal = _toAmount(orderData['totalAmount']);

    var computedSubtotal = 0.0;
    for (final item in items) {
      computedSubtotal += _itemLineTotal(item);
    }

    final subtotal = declaredSubtotal > 0 ? declaredSubtotal : computedSubtotal;
    var total = declaredTotal;
    if (total <= 0 || total == deliveryFee) {
      total = subtotal + deliveryFee;
    }
    return _OrderSummary(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
    );
  }
}

class _OrderSummary {
  final double subtotal;
  final double deliveryFee;
  final double total;

  _OrderSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });
}
