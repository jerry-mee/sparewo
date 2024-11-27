import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../autohub/autohub_screen.dart';
import '../catalog/catalog_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/feedback_service.dart';
import 'widgets/banner_section.dart';
import 'widgets/autohub_cta.dart';
import 'widgets/categories_section.dart';
import 'widgets/my_car_section.dart';
import '../../constants/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> fadeAnimation;
  late final Animation<double> scaleAnimation;
  int _selectedIndex = 0;
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTabSelection(int index) async {
    await _feedbackService.bottomNavTap();

    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });

    if (!mounted) return;

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CatalogScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AutoHubScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  Future<void> _handleAutoHubTap() async {
    await _feedbackService.buttonTap();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AutoHubScreen()),
    );
  }

  Future<void> _handleCategoryTap(String category) async {
    await _feedbackService.buttonTap();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogScreen(category: category),
      ),
    );
  }

  Future<void> _handleCarDetailsTap() async {
    await _feedbackService.buttonTap();
    // TODO: Implement car details navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 720;
        final isVeryLargeScreen = constraints.maxWidth > 1200;

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24.0.w : 16.0.w,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BannerSection(
                      isLargeScreen: isLargeScreen,
                      isVeryLargeScreen: isVeryLargeScreen,
                    ),
                    AutoHubCTA(
                      isLargeScreen: isLargeScreen,
                      onTap: _handleAutoHubTap,
                    ),
                    CategoriesSection(
                      isLargeScreen: isLargeScreen,
                      isVeryLargeScreen: isVeryLargeScreen,
                      onCategoryTap: _handleCategoryTap,
                    ),
                    MyCarSection(
                      isLargeScreen: isLargeScreen,
                      onTap: _handleCarDetailsTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        onTap: _handleTabSelection,
        tabs: [
          Tab(
            icon: Icon(
              Icons.home,
              color: _selectedIndex == 0 ? AppColors.primary : Colors.grey,
              size: 22.r,
            ),
            text: 'Home',
          ),
          Tab(
            icon: Icon(
              Icons.menu_book,
              color: _selectedIndex == 1 ? AppColors.primary : Colors.grey,
              size: 22.r,
            ),
            text: 'Catalogue',
          ),
          Tab(
            icon: Icon(
              Icons.auto_awesome,
              color: _selectedIndex == 2 ? AppColors.primary : Colors.grey,
              size: 22.r,
            ),
            text: 'AutoHub',
          ),
          Tab(
            icon: Icon(
              Icons.settings,
              color: _selectedIndex == 3 ? AppColors.primary : Colors.grey,
              size: 22.r,
            ),
            text: 'Settings',
          ),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }
}
