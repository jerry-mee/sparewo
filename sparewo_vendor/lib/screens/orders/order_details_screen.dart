import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../constants/enums.dart';
import '../../theme.dart';
import '../../providers/order_provider.dart';
import '../../services/feedback_service.dart';

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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return VendorColors.pending;
      case OrderStatus.accepted:
        return VendorColors.primary;
      case OrderStatus.processing:
        return VendorColors.primary;
      case OrderStatus.readyForDelivery:
        return VendorColors.approved;
      case OrderStatus.delivered:
        return VendorColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return VendorColors.error;
    }
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(orderProvider.notifier).updateOrderStatus(
            widget.order.id,
            newStatus,
          );
      await _feedbackService.success();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      await _feedbackService.error();
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
                  _buildOrderHeader(),
                  const SizedBox(height: 24),
                  _buildCustomerDetails(),
                  const SizedBox(height: 24),
                  _buildProductDetails(),
                  const SizedBox(height: 24),
                  _buildOrderStatus(),
                  const SizedBox(height: 24),
                  _buildDeliveryDetails(),
                  const SizedBox(height: 24),
                  _buildPaymentDetails(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderHeader() {
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
                  'Order #${widget.order.id}',
                  style: VendorTextStyles.heading3,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.order.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.order.status.name.toUpperCase(),
                    style: VendorTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered on ${_dateFormatter.format(widget.order.createdAt)}',
              style: VendorTextStyles.body2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: VendorTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.person,
              label: 'Name',
              value: widget.order.customerName,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.email,
              label: 'Email',
              value: widget.order.customerEmail,
            ),
            if (widget.order.customerPhone != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.phone,
                label: 'Phone',
                value: widget.order.customerPhone!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Details',
              style: VendorTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            if (widget.order.productImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.order.productImage!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.order.productName,
              style: VendorTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.attach_money,
              label: 'Price',
              value: 'UGX ${widget.order.price.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.shopping_cart,
              label: 'Quantity',
              value: widget.order.quantity.toString(),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.receipt,
              label: 'Total',
              value: 'UGX ${widget.order.totalAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: VendorTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _TimelineItem(
              title: 'Order Placed',
              date: widget.order.createdAt,
              isCompleted: true,
            ),
            if (widget.order.acceptedAt != null)
              _TimelineItem(
                title: 'Order Accepted',
                date: widget.order.acceptedAt!,
                isCompleted: true,
              ),
            if (widget.order.processedAt != null)
              _TimelineItem(
                title: 'Processing',
                date: widget.order.processedAt!,
                isCompleted: true,
              ),
            if (widget.order.readyAt != null)
              _TimelineItem(
                title: 'Ready for Delivery',
                date: widget.order.readyAt!,
                isCompleted: true,
              ),
            if (widget.order.deliveredAt != null)
              _TimelineItem(
                title: 'Delivered',
                date: widget.order.deliveredAt!,
                isCompleted: true,
              ),
            if (widget.order.cancelledAt != null)
              _TimelineItem(
                title: 'Cancelled',
                date: widget.order.cancelledAt!,
                isCompleted: true,
                isError: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    if (widget.order.deliveryAddress == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Details',
              style: VendorTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Address',
              value: widget.order.deliveryAddress!,
            ),
            if (widget.order.deliveryFee != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.local_shipping,
                label: 'Delivery Fee',
                value: 'UGX ${widget.order.deliveryFee!.toStringAsFixed(2)}',
              ),
            ],
            if (widget.order.expectedDeliveryDate != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.event,
                label: 'Expected Delivery',
                value:
                    _dateFormatter.format(widget.order.expectedDeliveryDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: VendorTextStyles.heading3,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.payment,
              label: 'Status',
              value: widget.order.isPaid ? 'Paid' : 'Pending',
              valueColor: widget.order.isPaid
                  ? VendorColors.success
                  : VendorColors.pending,
            ),
            if (widget.order.paymentMethod != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.account_balance_wallet,
                label: 'Payment Method',
                value: widget.order.paymentMethod!,
              ),
            ],
            if (widget.order.paymentId != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.receipt_long,
                label: 'Payment ID',
                value: widget.order.paymentId!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.order.status == OrderStatus.cancelled ||
        widget.order.status == OrderStatus.delivered ||
        widget.order.status == OrderStatus.rejected) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (widget.order.status == OrderStatus.pending) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _updateOrderStatus(OrderStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VendorColors.error,
                  ),
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
          const SizedBox(height: 16),
        ],
        if (widget.order.status == OrderStatus.accepted)
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _updateOrderStatus(OrderStatus.processing),
            child: const Text('Start Processing'),
          ),
        if (widget.order.status == OrderStatus.processing)
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _updateOrderStatus(OrderStatus.readyForDelivery),
            child: const Text('Mark as Ready'),
          ),
        if (widget.order.status == OrderStatus.readyForDelivery)
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

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: VendorColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: VendorTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: VendorTextStyles.body2.copyWith(
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isError;

  const _TimelineItem({
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isError = false,
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
                  ? VendorColors.error
                  : isCompleted
                      ? VendorColors.success
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
                Text(
                  title,
                  style: VendorTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(date),
                  style: VendorTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
