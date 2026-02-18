// lib/features/orders/presentation/orders_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/autohub/domain/service_booking_model.dart';
import 'package:sparewo_client/core/widgets/desktop_scaffold.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';

// --- Parts Orders Provider ---
final myOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          AppLogger.debug(
            'OrdersScreen',
            'Fetched ${snapshot.docs.length} orders',
          );
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  },
);

// --- Garage Bookings Provider (Fixed Error Handling) ---
final myBookingsProvider = StreamProvider.autoDispose<List<ServiceBooking>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('service_bookings')
      .where('userId', isEqualTo: user.id)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        AppLogger.debug(
          'OrdersScreen',
          'Fetched ${snapshot.docs.length} bookings',
        );
        final bookings = <ServiceBooking>[];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            // Create booking and inject ID
            final booking = ServiceBooking.fromJson(data).copyWith(id: doc.id);
            bookings.add(booking);
          } catch (e, st) {
            // Log error but skip this specific corrupted item so the list still loads
            AppLogger.error(
              'OrdersScreen',
              'Failed to parse booking ${doc.id}',
              error: e,
              stackTrace: st,
            );
          }
        }
        return bookings;
      });
});

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AppLogger.ui('OrdersScreen', 'Opened Orders Screen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScreen(
      mobile: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('My Activity'),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: theme.iconTheme.color,
            ),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: theme.hintColor,
            labelStyle: AppTextStyles.labelLarge,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Parts Orders'),
              Tab(text: 'Garage Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPartsOrdersList(context, ref, isDesktop: false),
            _buildGarageBookingsList(context, ref, isDesktop: false),
          ],
        ),
      ),
      desktop: DesktopScaffold(
        widthTier: DesktopWidthTier.standard,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DesktopSection(
                title: 'My Activity',
                subtitle: 'Track orders and garage bookings',
                padding: const EdgeInsets.only(top: 28, bottom: 12),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: theme.hintColor,
                  labelStyle: AppTextStyles.labelLarge,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Parts Orders'),
                    Tab(text: 'Garage Bookings'),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 220,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPartsOrdersList(context, ref, isDesktop: true),
                    _buildGarageBookingsList(context, ref, isDesktop: true),
                  ],
                ),
              ),
              const SiteFooter(),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartsOrdersList(
    BuildContext context,
    WidgetRef ref, {
    required bool isDesktop,
  }) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final ordersAsync = ref.watch(myOrdersProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return _buildGuestState(context, ref);
    }

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            'No part orders yet',
            Icons.shopping_bag_outlined,
          );
        }

        return ListView.separated(
          padding: isDesktop
              ? const EdgeInsets.fromLTRB(0, 8, 0, 120)
              : const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            final date = (order['createdAt'] as Timestamp?)?.toDate();
            final status = (order['status'] as String?) ?? 'pending';

            // FIX: Robust Price Calculation
            double total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
            final items = (order['items'] as List?) ?? [];

            // If total is 0 but items exist, calculate manually
            if (total == 0.0 && items.isNotEmpty) {
              for (var item in items) {
                total += (item['lineTotal'] as num?)?.toDouble() ?? 0.0;
              }
            }

            final firstItemName = items.isNotEmpty ? items[0]['name'] : 'Parts';

            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.cardShadow,
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    context.push('/order/${order['id']}', extra: order),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            date != null
                                ? DateFormat('dd MMM yyyy').format(date)
                                : 'Recent',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$firstItemName ${items.length > 1 ? '+ ${items.length - 1} more' : ''}',
                        style: AppTextStyles.h4.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${order['id'].toString().substring(0, 8).toUpperCase()}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          Text(
                            'UGX ${_formatCurrency(total)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        AppLogger.error(
          'OrdersScreen',
          'Error loading orders',
          error: e,
          stackTrace: s,
        );
        return Center(child: Text('Error: $e'));
      },
    );
  }

  Widget _buildGarageBookingsList(
    BuildContext context,
    WidgetRef ref, {
    required bool isDesktop,
  }) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final bookingsAsync = ref.watch(myBookingsProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return _buildGuestState(context, ref);
    }

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return _buildEmptyState('No garage bookings', Icons.car_repair);
        }

        return ListView.separated(
          padding: isDesktop
              ? const EdgeInsets.fromLTRB(0, 8, 0, 120)
              : const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final dateStr = booking.createdAt != null
                ? DateFormat('dd MMM yyyy').format(booking.createdAt!)
                : 'Recent';
            final status = booking.status;

            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.cardShadow,
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  context.push('/booking/${booking.id}', extra: booking);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$dateStr • ${booking.pickupTime}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${booking.vehicleYear} ${booking.vehicleBrand} ${booking.vehicleModel}',
                                  style: AppTextStyles.h4.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.services.join(', '),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: theme.hintColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.pickupLocation,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) {
        AppLogger.error(
          'OrdersScreen',
          'Error loading bookings',
          error: e,
          stackTrace: s,
        );
        return Center(child: Text('Error: $e'));
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              'Sign in to view your activity',
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Track your orders and garage bookings in one place.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.6),
                  builder: (context) => AuthGuardModal(
                    title: 'Sign in to view activity',
                    message:
                        'Create an account to track orders and garage bookings.',
                    returnTo: GoRouterState.of(context).uri.toString(),
                  ),
                );
              },
              child: const Text('Sign In / Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    Color color;
    IconData icon = Icons.access_time;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'confirmed':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'mechanic_assigned':
      case 'in_progress':
        color = Colors.blue;
        icon = Icons.build;
        label = "IN PROGRESS";
        break;
      case 'completed':
      case 'delivered':
        color = AppColors.success;
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning;
        icon = Icons.access_time;
        label = "PENDING";
    }

    final foregroundColor = isDarkMode
        ? Colors.white
        : const Color(0xFF111827); // Dark text for readability in light mode.

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.26 : 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDarkMode ? 0.45 : 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}
