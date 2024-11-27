import 'package:flutter/material.dart';

class HomeController extends ChangeNotifier {
  final TickerProvider vsync;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _selectedIndex = 0;

  // Getters
  int get selectedIndex => _selectedIndex;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;

  HomeController({required this.vsync});

  get navigateToCategory => null;

  void initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: vsync,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void onTabTapped(int index) {
    setSelectedIndex(index);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  navigateToAutoHub(BuildContext context) {}

  navigateToCarDetails(BuildContext context) {}
}
