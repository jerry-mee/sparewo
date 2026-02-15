// lib/screens/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/enums.dart';
import '../../models/order.dart';
import '../../theme.dart';
import '../../utils/string_extensions.dart';
import '../../providers/providers.dart';
import '../../routes/app_router.dart';
import 'widgets/order_list_item.dart';

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
    final ordersAsync = ref.watch(orderNotifierProvider).orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Customer or Order ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  onChanged: _filterOrders,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _StatusFilterChip(
                      label: 'All',
                      isSelected: _selectedStatus == null,
                      onSelected: () => setState(() => _selectedStatus = null),
                    ),
                    ...OrderStatus.values.map((status) => _StatusFilterChip(
                          // FIX: Use the correct .name property, not .displayName
                          label: status.name.capitalize(),
                          isSelected: _selectedStatus == status,
                          onSelected: () =>
                              setState(() => _selectedStatus = status),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(orderNotifierProvider),
        child: ordersAsync.when(
          data: (orders) {
            final filteredOrders = orders.where((order) {
              final matchesStatus =
                  _selectedStatus == null || order.status == _selectedStatus;
              final matchesSearch = _searchQuery.isEmpty ||
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
              padding: const EdgeInsets.all(8),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return OrderListItem(
                  order: order,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.orderDetails,
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
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 16),
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
