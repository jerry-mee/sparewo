// lib/features/home/presentation/home_screen.dart
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/home/presentation/widgets/app_guide_modal.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';

// Provider for active orders count
final activeOrdersCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return Stream.value(0);
  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: user.id)
      .where(
        'status',
        whereIn: ['pending', 'confirmed', 'processing', 'shipped'],
      )
      .snapshots()
      .map((s) => s.docs.length);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AppLogger.ui('HomeScreen', 'Dashboard loaded');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAppGuide();
    });
  }

  Future<void> _checkAndShowAppGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGuide = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenGuide && mounted) {
      AppLogger.info('HomeScreen', 'Showing Guide Modal');
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) => const AppGuideModal(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final cartAsync = ref.watch(cartNotifierProvider);
    final carsAsync = ref.watch(carsProvider);
    final activeOrdersAsync = ref.watch(activeOrdersCountProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logoAsset = isDark
        ? 'assets/logo/branding.png'
        : 'assets/logo/branding_dark.png';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header (Centered Logo)
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.95),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 70,
            centerTitle: true,
            title: Image.asset(logoAsset, height: 28, fit: BoxFit.contain),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildGlassCartIcon(context, cartAsync),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Greeting
                const SizedBox(height: 8),
                currentUserAsync.when(
                  data: (user) => Text(
                    '${_getGreeting()}, ${user?.name.split(' ')[0] ?? 'Guest'}',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(height: 30),
                  error: (_, __) => Text(
                    '${_getGreeting()}, Guest',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Home Banner
                AspectRatio(
                  aspectRatio: 16 / 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.cardShadow,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/banner_home.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 3. Top Brands (Moved Up & Renamed)
                Text(
                  'Top Brands. Top Parts.',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    'assets/images/Car Brands.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),

                const SizedBox(height: 32),

                // 4. Categories
                _buildSectionHeading(
                  'Categories',
                  onSeeAll: () {
                    context.push('/catalog');
                  },
                ),
                const SizedBox(height: 16),
                _buildCategoriesGrid(context),

                const SizedBox(height: 32),

                // 5. AutoHub Section
                Text(
                  'SpareWo AutoHub',
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                _buildAutoHubCard(context),

                const SizedBox(height: 32),

                // 6. My Garage Updates (Moved to bottom)
                Text(
                  'My Garage Updates',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildGarageUpdates(context, carsAsync, activeOrdersAsync),

                // Bottom Padding (Increased for safety)
                const SizedBox(height: 140),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCartIcon(
    BuildContext context,
    AsyncValue<dynamic> cartAsync,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: IconButton(
            onPressed: () => context.push('/cart'),
            padding: EdgeInsets.zero,
            icon: Badge(
              isLabelVisible: (cartAsync.asData?.value.totalItems ?? 0) > 0,
              label: Text('${cartAsync.asData?.value.totalItems ?? 0}'),
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.shopping_bag_outlined,
                color: theme.iconTheme.color,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final categories = [
      {'name': 'Tyres', 'img': 'assets/images/tyrecat.png'},
      {'name': 'Body', 'img': 'assets/images/body_kit.png'},
      {'name': 'Engine', 'img': 'assets/images/Engine Category Icon.png'},
      {'name': 'Electrical', 'img': 'assets/images/Electricals.png'},
      {'name': 'Chassis', 'img': 'assets/images/Chasis Icon.png'},
      {'name': 'More', 'img': 'assets/images/Accessories Icon.png'},
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return GestureDetector(
          onTap: () => context.push('/catalog?category=${cat['name']}'),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBC05),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBC05).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(cat['img']!, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cat['name']!,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeading(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('View All')),
      ],
    );
  }

  Widget _buildAutoHubCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.asset(
                'assets/images/Request Service.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional mechanics at your doorstep',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push('/autohub'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageUpdates(
    BuildContext context,
    AsyncValue<List<CarModel>> carsAsync,
    AsyncValue<int> activeOrdersAsync,
  ) {
    return SizedBox(
      height: 170,
      child: carsAsync.when(
        data: (cars) {
          final defaultCar = cars.isNotEmpty
              ? (cars.firstWhere((c) => c.isDefault, orElse: () => cars.first))
              : null;
          final orderCount = activeOrdersAsync.asData?.value ?? 0;

          return PageView(
            controller: PageController(viewportFraction: 0.92),
            padEnds: false,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildUpdateCard(
                  context,
                  title: 'Active Orders',
                  value: orderCount > 0 ? '$orderCount Active' : 'No Orders',
                  desc: orderCount > 0
                      ? 'Track your deliveries'
                      : 'Start shopping today',
                  color: const Color(0xFF0F1235),
                  icon: Icons.local_shipping_outlined,
                  onTap: () => context.push('/orders'),
                ),
              ),
              if (defaultCar != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildServiceUpdateCard(context, defaultCar),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildInsuranceUpdateCard(context, defaultCar),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildUpdateCard(
                    context,
                    title: 'My Garage',
                    value: 'Add Car',
                    desc: 'Track service & insurance',
                    color: AppColors.primary,
                    icon: Icons.directions_car,
                    onTap: () => context.push('/my-cars'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildServiceUpdateCard(BuildContext context, CarModel car) {
    if (car.lastServiceDate == null) {
      return _buildUpdateCard(
        context,
        title: 'Service',
        value: 'No Record',
        desc: 'Tap to add service history',
        color: AppColors.primary,
        icon: Icons.build_circle_outlined,
        onTap: () => context.push('/my-cars/detail/${car.id}'),
      );
    }

    final diff = DateTime.now().difference(car.lastServiceDate!);
    final days = diff.inDays;
    final dateStr = DateFormat('d MMM y').format(car.lastServiceDate!);

    return _buildUpdateCard(
      context,
      title: 'Last Service',
      value: '$days days ago',
      desc: dateStr,
      color: AppColors.primary,
      icon: Icons.verified_outlined,
      onTap: () => context.push('/autohub'),
    );
  }

  Widget _buildInsuranceUpdateCard(BuildContext context, CarModel car) {
    if (car.insuranceExpiryDate == null) {
      return _buildUpdateCard(
        context,
        title: 'Insurance',
        value: 'Not Set',
        desc: 'Tap to set expiry date',
        color: const Color(0xFF1E293B),
        icon: Icons.security,
        onTap: () => context.push('/my-cars/detail/${car.id}'),
      );
    }

    final expiry = car.insuranceExpiryDate!;
    final diff = expiry.difference(DateTime.now());
    final daysLeft = diff.inDays;
    final dateStr = DateFormat('d MMM y').format(expiry);

    Color cardColor = const Color(0xFF1E293B);
    String valueText = '$daysLeft days left';
    String descText = 'Expires $dateStr';

    if (daysLeft < 7 && daysLeft >= 0) {
      cardColor = const Color(0xFFC2410C);
      valueText = '$daysLeft days left!';
    } else if (daysLeft < 0) {
      cardColor = AppColors.error;
      valueText = '${daysLeft.abs()} days PAST';
      descText = 'Expired on $dateStr';
    }

    return _buildUpdateCard(
      context,
      title: 'Insurance',
      value: valueText,
      desc: descText,
      color: cardColor,
      icon: Icons.shield_outlined,
      onTap: () => context.push('/my-cars/detail/${car.id}'),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context, {
    required String title,
    required String value,
    required String desc,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
