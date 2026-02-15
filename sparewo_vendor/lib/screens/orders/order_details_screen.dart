// / File: lib/screens/orders/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../constants/enums.dart';
import '../../theme.dart';
import '../../services/feedback_service.dart';
import '../../providers/providers.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final VendorOrder order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  final _feedbackService = FeedbackService();
  bool _isLoading = false;
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  // FIXED: Pass context to helper method
  Color _getStatusColor(BuildContext context, OrderStatus status) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    switch (status) {
      case OrderStatus.pending:
        return colors.pending;
      case OrderStatus.accepted:
      case OrderStatus.processing:
        return Theme.of(context).colorScheme.primary;
      case OrderStatus.readyForDelivery:
        return colors.approved;
      case OrderStatus.delivered:
        return colors.success;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Theme.of(context).colorScheme.error;
    }
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(orderNotifierProvider.notifier).updateOrderStatus(
            widget.order.id,
            newStatus,
          );
      _feedbackService.success();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _feedbackService.error();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderNotifierProvider).orders;
    final currentOrder = ordersState.asData?.value.firstWhere(
          (o) => o.id == widget.order.id,
          orElse: () => widget.order,
        ) ??
        widget.order;

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(context, currentOrder, textTheme),
                  const SizedBox(height: 24),
                  _buildCustomerDetails(currentOrder, textTheme),
                  const SizedBox(height: 24),
                  _buildProductDetails(currentOrder, textTheme),
                  const SizedBox(height: 24),
                  _buildOrderStatus(context, currentOrder, textTheme),
                  const SizedBox(height: 24),
                  _buildDeliveryDetails(currentOrder, textTheme),
                  const SizedBox(height: 24),
                  _buildPaymentDetails(context, currentOrder, textTheme),
                  const SizedBox(height: 32),
                  _buildActionButtons(currentOrder),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHeader(
      BuildContext context, VendorOrder order, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: textTheme.headlineSmall,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(context, order.status), // Pass context
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.status.name.toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered on ${_dateFormatter.format(order.createdAt)}',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ... (No changes needed for most build methods below, just pass textTheme)

  Widget _buildCustomerDetails(VendorOrder order, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Details', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            _DetailRow(
                icon: Icons.person,
                label: 'Name',
                value: order.customerName,
                textTheme: textTheme),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.email,
                label: 'Email',
                value: order.customerEmail,
                textTheme: textTheme),
            if (order.customerPhone != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: order.customerPhone!,
                  textTheme: textTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(VendorOrder order, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product Details', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (order.productImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order.productImage!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(order.productName,
                style:
                    textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.attach_money,
                label: 'Price',
                value: 'UGX ${order.price.toStringAsFixed(0)}',
                textTheme: textTheme),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.shopping_cart,
                label: 'Quantity',
                value: order.quantity.toString(),
                textTheme: textTheme),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.receipt,
                label: 'Total',
                value: 'UGX ${order.totalAmount.toStringAsFixed(0)}',
                textTheme: textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus(
      BuildContext context, VendorOrder order, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Timeline', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            _TimelineItem(
                context: context,
                title: 'Order Placed',
                date: order.createdAt,
                isCompleted: true,
                textTheme: textTheme),
            if (order.acceptedAt != null)
              _TimelineItem(
                  context: context,
                  title: 'Order Accepted',
                  date: order.acceptedAt!,
                  isCompleted: true,
                  textTheme: textTheme),
            if (order.processedAt != null)
              _TimelineItem(
                  context: context,
                  title: 'Processing',
                  date: order.processedAt!,
                  isCompleted: true,
                  textTheme: textTheme),
            if (order.readyAt != null)
              _TimelineItem(
                  context: context,
                  title: 'Ready for Delivery',
                  date: order.readyAt!,
                  isCompleted: true,
                  textTheme: textTheme),
            if (order.deliveredAt != null)
              _TimelineItem(
                  context: context,
                  title: 'Delivered',
                  date: order.deliveredAt!,
                  isCompleted: true,
                  textTheme: textTheme),
            if (order.cancelledAt != null)
              _TimelineItem(
                  context: context,
                  title: 'Cancelled',
                  date: order.cancelledAt!,
                  isCompleted: true,
                  isError: true,
                  textTheme: textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails(VendorOrder order, TextTheme textTheme) {
    if (order.deliveryAddress == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Details', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            _DetailRow(
                icon: Icons.location_on,
                label: 'Address',
                value: order.deliveryAddress!,
                textTheme: textTheme),
            if (order.deliveryFee != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                  icon: Icons.local_shipping,
                  label: 'Delivery Fee',
                  value: 'UGX ${order.deliveryFee!.toStringAsFixed(0)}',
                  textTheme: textTheme),
            ],
            if (order.expectedDeliveryDate != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                  icon: Icons.event,
                  label: 'Expected Delivery',
                  value: _dateFormatter.format(order.expectedDeliveryDate!),
                  textTheme: textTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(
      BuildContext context, VendorOrder order, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Details', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            _DetailRow(
                icon: Icons.payment,
                label: 'Status',
                value: order.isPaid ? 'Paid' : 'Pending',
                valueColor: order.isPaid
                    ? Theme.of(context).extension<AppColorsExtension>()!.success
                    : Theme.of(context)
                        .extension<AppColorsExtension>()!
                        .pending,
                textTheme: textTheme),
            if (order.paymentMethod != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                  icon: Icons.account_balance_wallet,
                  label: 'Payment Method',
                  value: order.paymentMethod!,
                  textTheme: textTheme),
            ],
            if (order.paymentId != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                  icon: Icons.receipt_long,
                  label: 'Payment ID',
                  value: order.paymentId!,
                  textTheme: textTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(VendorOrder order) {
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.rejected) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.status == OrderStatus.pending) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _updateOrderStatus(OrderStatus.rejected),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error)),
                  child: const Text('Reject Order'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _updateOrderStatus(OrderStatus.accepted),
                  child: const Text('Accept Order'),
                ),
              ),
            ],
          ),
        ],
        if (order.status == OrderStatus.accepted)
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _updateOrderStatus(OrderStatus.processing),
            child: const Text('Start Processing'),
          ),
        if (order.status == OrderStatus.processing)
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _updateOrderStatus(OrderStatus.readyForDelivery),
            child: const Text('Mark as Ready'),
          ),
        if (order.status == OrderStatus.readyForDelivery)
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _updateOrderStatus(OrderStatus.delivered),
            child: const Text('Mark as Delivered'),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final TextTheme textTheme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text('$label: ',
            style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Expanded(
            child: Text(value,
                style: textTheme.bodyMedium!.copyWith(color: valueColor))),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BuildContext context; // FIXED
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isError;
  final TextTheme textTheme;

  const _TimelineItem({
    required this.context, // FIXED
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isError = false,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError
                  ? Theme.of(context).colorScheme.error
                  : isCompleted
                      ? Theme.of(context)
                          .extension<AppColorsExtension>()!
                          .success
                      : Colors.grey,
            ),
            child: Icon(
              isError
                  ? Icons.close
                  : isCompleted
                      ? Icons.check
                      : Icons.circle,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: textTheme.bodyLarge!
                        .copyWith(fontWeight: FontWeight.bold)),
                Text(DateFormat('dd MMM yyyy, HH:mm').format(date),
                    style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
