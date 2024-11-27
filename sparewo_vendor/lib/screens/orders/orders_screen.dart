import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/enums.dart';
import '../../providers/order_provider.dart';
import '../../theme.dart';
import '../../utils/string_extensions.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderStatus? _selectedStatus;
  String _searchQuery = '';

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersAsyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterOrders,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusFilterChip(
                    label: 'All',
                    isSelected: _selectedStatus == null,
                    onSelected: () => setState(() => _selectedStatus = null),
                  ),
                  const SizedBox(width: 8),
                  _StatusFilterChip(
                    label: 'Pending',
                    isSelected: _selectedStatus == OrderStatus.pending,
                    onSelected: () =>
                        setState(() => _selectedStatus = OrderStatus.pending),
                  ),
                  const SizedBox(width: 8),
                  _StatusFilterChip(
                    label: 'Processing',
                    isSelected: _selectedStatus == OrderStatus.processing,
                    onSelected: () => setState(
                        () => _selectedStatus = OrderStatus.processing),
                  ),
                  const SizedBox(width: 8),
                  _StatusFilterChip(
                    label: 'Delivered',
                    isSelected: _selectedStatus == OrderStatus.delivered,
                    onSelected: () =>
                        setState(() => _selectedStatus = OrderStatus.delivered),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          final filteredOrders = orders.where((order) {
            final matchesStatus =
                _selectedStatus == null || order.status == _selectedStatus;
            final matchesSearch =
                order.customerName.toLowerCase().contains(_searchQuery) ||
                    order.id.toLowerCase().contains(_searchQuery);
            return matchesStatus && matchesSearch;
          }).toList();

          if (filteredOrders.isEmpty) {
            return const Center(
              child: Text('No orders found.', style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return ListTile(
                title: Text(order.customerName),
                subtitle: Text('UGX ${order.totalAmount.toStringAsFixed(2)}'),
                trailing: Text(order.status.name.capitalize()),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/orders/detail',
                    arguments: order,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading orders: $error',
            style: TextStyle(color: VendorColors.error, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: VendorColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? VendorColors.primary : VendorColors.text,
      ),
    );
  }
}
