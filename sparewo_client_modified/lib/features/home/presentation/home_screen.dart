// lib/features/home/presentation/home_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';
import 'package:sparewo_client/core/theme/app_theme.dart';
import 'package:sparewo_client/features/auth/application/auth_provider.dart';
import 'package:sparewo_client/features/cart/application/cart_provider.dart';
import 'package:sparewo_client/features/home/presentation/widgets/app_guide_modal.dart';
import 'package:sparewo_client/features/auth/presentation/widgets/auth_guard_modal.dart';
import 'package:sparewo_client/features/my_car/application/car_provider.dart';
import 'package:sparewo_client/features/my_car/domain/car_model.dart';
import 'package:sparewo_client/core/widgets/desktop_layout.dart';
import 'package:sparewo_client/core/widgets/desktop_section.dart';
import 'package:sparewo_client/core/widgets/responsive_screen.dart';
import 'package:sparewo_client/core/widgets/site_footer.dart';

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

class CarFuluTip {
  final String headline;
  final String explainer;

  const CarFuluTip({required this.headline, required this.explainer});
}

const _carFuluTips = <CarFuluTip>[
  CarFuluTip(
    headline: 'Change engine oil every 5,000 to 8,000 km.',
    explainer:
        'Frequent stop-and-go traffic needs faster oil changes to keep your engine healthy.',
  ),
  CarFuluTip(
    headline: 'Check tyre pressure every week.',
    explainer:
        'Correct pressure improves fuel economy, grip, and tyre lifespan.',
  ),
  CarFuluTip(
    headline: 'Rotate tyres every 8,000 to 10,000 km.',
    explainer: 'Rotation evens out wear and improves braking stability.',
  ),
  CarFuluTip(
    headline: 'Replace air filter every 15,000 km.',
    explainer:
        'A clean air filter helps the engine breathe and improves performance.',
  ),
  CarFuluTip(
    headline: 'Inspect brake pads every service.',
    explainer:
        'Don’t wait for squeaking sounds; worn pads can damage brake discs.',
  ),
  CarFuluTip(
    headline: 'Top up coolant before long trips.',
    explainer:
        'Low coolant can cause overheating and expensive engine repairs.',
  ),
  CarFuluTip(
    headline: 'Battery terminals should stay clean.',
    explainer:
        'Corrosion causes weak starts and charging issues. Clean and tighten monthly.',
  ),
  CarFuluTip(
    headline: 'Align wheels if steering pulls.',
    explainer:
        'Poor alignment increases tyre wear and makes driving less safe.',
  ),
  CarFuluTip(
    headline: 'Replace wiper blades every 6 to 12 months.',
    explainer:
        'Fresh blades improve visibility in rain and reduce windshield scratching.',
  ),
  CarFuluTip(
    headline: 'Check transmission fluid at service intervals.',
    explainer:
        'Healthy transmission fluid keeps shifting smooth and prevents heat damage.',
  ),
  CarFuluTip(
    headline: 'Use matching tyre sizes on all wheels.',
    explainer:
        'Mixed sizes can affect ABS behavior, handling, and fuel consumption.',
  ),
  CarFuluTip(
    headline: 'Listen for suspension knocks early.',
    explainer:
        'Small bush or link issues are cheaper to fix before they affect other parts.',
  ),
  CarFuluTip(
    headline: 'Clean your throttle body periodically.',
    explainer:
        'Carbon buildup can cause rough idle and sluggish throttle response.',
  ),
  CarFuluTip(
    headline: 'Inspect drive belts for cracks.',
    explainer:
        'A failed belt can disable charging, cooling, and power steering suddenly.',
  ),
];

final carFuluTipProvider = Provider<CarFuluTip>((ref) {
  // TODO: Replace with Firestore/Admin-managed daily tips when dashboard endpoint is ready.
  final now = DateTime.now();
  final anchor = DateTime(2026, 1, 1);
  final days = now.difference(anchor).inDays.abs();
  return _carFuluTips[days % _carFuluTips.length];
});

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveScreen(
      mobile: MobileHomeScreen(),
      desktop: DesktopHomeScreen(),
    );
  }
}

class MobileHomeScreen extends ConsumerStatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  ConsumerState<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends ConsumerState<MobileHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AppLogger.ui('HomeScreen', 'Dashboard loaded');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        _checkAndShowAppGuide();
      }
    });
  }

  Future<void> _checkAndShowAppGuide() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final perUserKey = 'hasSeenOnboarding_${user.id}';
    final legacySeen = prefs.getBool('hasSeenOnboarding') ?? false;
    var hasSeenGuide = prefs.getBool(perUserKey);

    // Migration: if the user had already seen the legacy onboarding flag,
    // preserve that behavior and avoid showing onboarding again.
    if (hasSeenGuide == null && legacySeen) {
      hasSeenGuide = true;
      await prefs.setBool(perUserKey, true);
    }

    if (!(hasSeenGuide ?? false) && mounted) {
      AppLogger.info('HomeScreen', 'Showing Guide Modal');
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
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
    final tip = ref.watch(carFuluTipProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logoAsset = isDark
        ? 'assets/logo/branding.png'
        : 'assets/logo/branding_dark.png';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor.withValues(
              alpha: 0.95,
            ),
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
                AspectRatio(
                  aspectRatio: 16 / 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.cardShadow,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/banner_home.webp'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionHeading('Top Brands. Top Parts.'),
                const SizedBox(height: 12),
                _buildTopBrandsStrip(isDark),
                const SizedBox(height: AppSpacing.xl),
                _buildSectionHeading(
                  'Categories',
                  onSeeAll: () {
                    context.push('/catalog');
                  },
                ),
                const SizedBox(height: 16),
                _buildCategoriesGrid(context),
                const SizedBox(height: 32),
                Text(
                  'SpareWo AutoHub',
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                _buildAutoHubCard(context),
                const SizedBox(height: 32),
                Text(
                  'My Garage Updates',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildGarageUpdates(context, carsAsync, activeOrdersAsync, ref),
                const SizedBox(height: 24),
                _buildCarFuluCard(context, tip),
                const SizedBox(height: 140),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarFuluCard(BuildContext context, CarFuluTip tip) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = isDark
        ? const [Color(0xFF113D3A), Color(0xFF0B5A51)]
        : const [Color(0xFFEAF8F0), Color(0xFFD4F1E1)];
    final textColor = isDark ? Colors.white : const Color(0xFF10322D);
    final subtleText = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF2F5B52);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0B5A51,
            ).withValues(alpha: isDark ? 0.35 : 0.2),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.wrench(),
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF0B5A51),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'CarFulu the car expert',
                style: AppTextStyles.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip.headline,
            style: AppTextStyles.h4.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip.explainer,
            style: AppTextStyles.bodySmall.copyWith(color: subtleText),
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
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
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
      {'name': 'Body', 'img': 'assets/images/body_kit_hi_def.png'},
      {
        'name': 'Engine',
        'img': 'assets/images/Engine Category Icon_hi_def.png',
      },
      {'name': 'Electrical', 'img': 'assets/images/Electricals_hi_def.png'},
      {'name': 'Chassis', 'img': 'assets/images/Chasis Icon_hi_def.png'},
      {'name': 'More', 'img': 'assets/images/Accessories Icon_hi_def.png'},
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140, // Responsive sizing!
        crossAxisSpacing: 16,
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
                        color: const Color(0xFFFBBC05).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 104,
                      height: 104,
                      child: Image.asset(
                        cat['img']!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
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

  Widget _buildTopBrandsStrip(bool isDark) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWidePhone = screenWidth >= 400;

    final gradientColors = isDark
        ? const [Color(0xFFF59E0B), Color(0xFFF97316)]
        : const [Color(0xFFFFD166), Color(0xFFFFA12F)];

    final stripHeight = isWidePhone ? 62.0 : 56.0;
    final imageHeightFactor = isWidePhone ? 0.66 : 0.56;
    final imageAlignmentY = isWidePhone ? 0.18 : 0.25;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFF97316,
            ).withValues(alpha: isDark ? 0.28 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: stripHeight,
        width: double.infinity,
        child: ClipRect(
          child: Align(
            alignment: Alignment(0, imageAlignmentY),
            heightFactor: imageHeightFactor,
            child: Image.asset(
              'assets/images/car_brands_final.webp',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGarageUpdates(
    BuildContext context,
    AsyncValue<List<CarModel>> carsAsync,
    AsyncValue<int> activeOrdersAsync,
    WidgetRef ref,
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
                  onTap: () {
                    AuthGuardModal.check(
                      context: context,
                      ref: ref,
                      title: 'View Your Orders',
                      message: 'Sign in to track your orders.',
                      onAuthenticated: () => context.push('/orders'),
                    );
                  },
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
                    onTap: () {
                      AuthGuardModal.check(
                        context: context,
                        ref: ref,
                        title: 'My Garage',
                        message: 'Sign in to add and manage your vehicles.',
                        onAuthenticated: () => context.push('/my-cars'),
                      );
                    },
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
              color: color.withValues(alpha: 0.4),
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

Widget _buildAutoHubCard(BuildContext context, {bool isCompact = false}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      boxShadow: AppShadows.cardShadow,
    ),
    child: isCompact
        ? InkWell(
            onTap: () => context.push('/autohub'),
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/Request Service.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book a service',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
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

class DesktopHomeScreen extends ConsumerWidget {
  const DesktopHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final carsAsync = ref.watch(carsProvider);
    final activeOrdersAsync = ref.watch(activeOrdersCountProvider);
    final tip = ref.watch(carFuluTipProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundTop = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFFFF6E8);
    final backgroundBottom = isDark
        ? const Color(0xFF141B26)
        : const Color(0xFFFFFBF2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundTop, backgroundBottom],
        ),
      ),
      child: Stack(
        children: [
          if (isDark)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [Color(0x221F2937), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopLayout(
                  tier: DesktopWidthTier.wide,
                  child: DesktopSection(
                    title: currentUserAsync.when(
                      data: (user) =>
                          '${_getGreeting()}, ${user?.name.split(' ')[0] ?? 'Guest'}',
                      loading: () => 'Welcome',
                      error: (_, __) => 'Welcome',
                    ),
                    subtitle: 'Premium parts, curated for your vehicle.',
                    padding: const EdgeInsets.only(top: 34, bottom: 20),
                    child: const SizedBox.shrink(),
                  ),
                ),
                DesktopLayout(
                  tier: DesktopWidthTier.wide,
                  child: _buildHeroWithBrands(context),
                ),
                const SizedBox(height: 36),
                DesktopLayout(
                  tier: DesktopWidthTier.wide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesktopSection(
                        title: 'Categories',
                        subtitle: 'Browse by system or component',
                        child: _buildDesktopCategoriesGrid(context),
                      ),
                      DesktopSection(
                        title: 'SpareWo AutoHub',
                        subtitle: 'Request a service from trusted mechanics',
                        child: SizedBox(
                          height: 260,
                          child: _buildAutoHubDesktopCard(context),
                        ),
                      ),
                      DesktopSection(
                        title: 'My Garage Updates',
                        subtitle:
                            'Active orders, service, and insurance at a glance',
                        child: _buildDesktopGarageGrid(
                          context,
                          carsAsync,
                          activeOrdersAsync,
                          ref,
                        ),
                      ),
                      DesktopSection(
                        title: 'CarFulu the car expert',
                        subtitle:
                            'Daily care tips. Admin-managed tips coming next.',
                        child: _buildDesktopCarFuluCard(context, tip),
                      ),
                      const SiteFooter(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroWithBrands(BuildContext context) {
    const dividerWidth = 1.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final heroWidth = constraints.maxWidth;
        final height = math.max(320.0, heroWidth / 2.55);

        return SizedBox(
          width: heroWidth,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: theme.dividerColor.withValues(
                  alpha: isDark ? 0.2 : 0.08,
                ),
                width: 1,
              ),
              boxShadow: AppShadows.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox.expand(
                      child: Image.asset(
                        'assets/images/banner_home.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  Container(
                    width: dividerWidth,
                    height: height,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox.expand(
                      child: Image.asset(
                        'assets/images/Car Brands Vertical.webp',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAutoHubDesktopCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(36),
              ),
              child: Image.asset(
                'assets/images/Request Service.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book a service',
                    style: AppTextStyles.desktopH2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional mechanics at your doorstep.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => context.push('/autohub'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        'Book a service',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCategoriesGrid(BuildContext context) {
    final categories = [
      {
        'name': 'Tyres',
        'icon': Icons.tire_repair_rounded,
        'img': 'assets/images/tyrecat.png',
      },
      {
        'name': 'Body',
        'icon': Icons.directions_car_filled_rounded,
        'img': 'assets/images/body_kit_hi_def.png',
      },
      {
        'name': 'Engine',
        'icon': Icons.precision_manufacturing_rounded,
        'img': 'assets/images/Engine Category Icon_hi_def.png',
      },
      {
        'name': 'Electrical',
        'icon': Icons.battery_charging_full_rounded,
        'img': 'assets/images/Electricals_hi_def.png',
      },
      {
        'name': 'Chassis',
        'icon': Icons.car_repair_rounded,
        'img': 'assets/images/Chasis Icon_hi_def.png',
      },
      {
        'name': 'More',
        'icon': Icons.apps_rounded,
        'img': 'assets/images/Accessories Icon_hi_def.png',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxTileWidth = width >= 1550
            ? 252.0
            : (width >= 1280 ? 236.0 : 220.0);
        final tileHeight = width >= 1550 ? 196.0 : 188.0;

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileWidth,
            mainAxisExtent: tileHeight,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return GestureDetector(
              onTap: () => context.push('/catalog?category=${cat['name']}'),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBC05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1A0F1235)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.11),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: kIsWeb ? 124 : 98,
                        height: kIsWeb ? 124 : 98,
                        decoration: BoxDecoration(
                          color: kIsWeb
                              ? Colors.transparent
                              : const Color(0xFFE3AA00),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: kIsWeb
                            ? Padding(
                                padding: const EdgeInsets.all(2),
                                child: Image.asset(
                                  cat['img']! as String,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              )
                            : Icon(
                                cat['icon']! as IconData,
                                size: 52,
                                color: const Color(0xFF0F1235),
                              ),
                      ),
                      Text(
                        cat['name']! as String,
                        style: AppTextStyles.desktopH3.copyWith(
                          fontSize: 44 / 2,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1235),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopGarageGrid(
    BuildContext context,
    AsyncValue<List<CarModel>> carsAsync,
    AsyncValue<int> activeOrdersAsync,
    WidgetRef ref,
  ) {
    return carsAsync.when(
      data: (cars) {
        final defaultCar = cars.isNotEmpty
            ? (cars.firstWhere((c) => c.isDefault, orElse: () => cars.first))
            : null;
        final orderCount = activeOrdersAsync.asData?.value ?? 0;

        final cards = <Widget>[
          _buildUpdateCard(
            context,
            title: 'Active Orders',
            value: orderCount > 0 ? '$orderCount Active' : 'No Orders',
            desc: orderCount > 0 ? 'Track your deliveries' : 'Start shopping',
            color: const Color(0xFF0F1235),
            icon: Icons.local_shipping_outlined,
            onTap: () {
              AuthGuardModal.check(
                context: context,
                ref: ref,
                title: 'View Your Orders',
                message: 'Sign in to track your orders.',
                onAuthenticated: () => context.push('/orders'),
              );
            },
          ),
        ];

        if (defaultCar != null) {
          cards.addAll([
            _buildServiceUpdateCard(context, defaultCar),
            _buildInsuranceUpdateCard(context, defaultCar),
          ]);
        } else {
          cards.add(
            _buildUpdateCard(
              context,
              title: 'My Garage',
              value: 'Add Car',
              desc: 'Track service & insurance',
              color: AppColors.primary,
              icon: Icons.directions_car,
              onTap: () {
                AuthGuardModal.check(
                  context: context,
                  ref: ref,
                  title: 'My Garage',
                  message: 'Sign in to add and manage your vehicles.',
                  onAuthenticated: () => context.push('/my-cars'),
                );
              },
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxColumns = constraints.maxWidth >= 1280 ? 3 : 2;
            final crossAxisCount = math.min(cards.length, maxColumns);
            final ratio = crossAxisCount == 1
                ? 2.5
                : (crossAxisCount == 2 ? 1.95 : 1.35);

            return GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: ratio,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
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
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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

  Widget _buildDesktopCarFuluCard(BuildContext context, CarFuluTip tip) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = isDark
        ? const [Color(0xFF113D3A), Color(0xFF0B5A51)]
        : const [Color(0xFFEAF8F0), Color(0xFFD4F1E1)];
    final textColor = isDark ? Colors.white : const Color(0xFF10322D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFB6E2CF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.wrench(),
                size: 26,
                color: isDark ? Colors.white : const Color(0xFF0B5A51),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CarFulu the car expert',
                  style: AppTextStyles.desktopH3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tip.headline,
                  style: AppTextStyles.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.explainer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.82)
                        : const Color(0xFF2F5B52),
                  ),
                ),
              ],
            ),
          ),
        ],
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
