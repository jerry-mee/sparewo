import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/feedback_service.dart';
import '../../../widgets/category_card.dart'; // Fixed import path

class CategoriesSection extends StatefulWidget {
  final bool isLargeScreen;
  final bool isVeryLargeScreen;
  final Function(String) onCategoryTap;

  static const List<Map<String, dynamic>> categories = [
    {
      'icon': Icons.car_repair,
      'label': 'Body Kits',
      'description': 'Exterior body parts and styling kits'
    },
    {
      'icon': Icons.tire_repair,
      'label': 'Tyres',
      'description': 'High quality tyres for all vehicles'
    },
    {
      'icon': Icons.electrical_services,
      'label': 'Electricals',
      'description': 'Complete electrical parts and systems'
    },
    {
      'icon': Icons.build,
      'label': 'Accessories',
      'description': 'Essential car accessories and add-ons'
    },
    {
      'icon': Icons.settings,
      'label': 'Chassis',
      'description': 'Structural components and chassis parts'
    },
    {
      'icon': Icons.engineering,
      'label': 'Engine',
      'description': 'Engine parts and components'
    },
  ];

  const CategoriesSection({
    super.key,
    required this.isLargeScreen,
    required this.isVeryLargeScreen,
    required this.onCategoryTap,
  });

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<Animation<double>> _scaleAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    for (int i = 0; i < CategoriesSection.categories.length; i++) {
      final delay = i * 0.2;

      _scaleAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay,
              delay + 0.5,
              curve: Curves.easeOut,
            ),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay,
              delay + 0.5,
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
    }

    _animationController.forward();
  }

  Future<void> _handleCategoryTap(String category) async {
    await _feedbackService.buttonTap();
    widget.onCategoryTap(category);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: GoogleFonts.poppins(
              fontSize: (widget.isLargeScreen ? 22 : 18).sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.isVeryLargeScreen
                  ? 5
                  : widget.isLargeScreen
                      ? 4
                      : 2,
              childAspectRatio: widget.isLargeScreen ? 1.2 : 1.0,
              crossAxisSpacing: (widget.isLargeScreen ? 16 : 12).w,
              mainAxisSpacing: (widget.isLargeScreen ? 16 : 12).h,
            ),
            itemCount: CategoriesSection.categories.length,
            itemBuilder: (context, index) {
              final category = CategoriesSection.categories[index];
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: Opacity(
                      opacity: _fadeAnimations[index].value,
                      child: CategoryCard(
                        icon: category['icon'],
                        label: category['label'],
                        description: category['description'],
                        onTap: () => _handleCategoryTap(category['label']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
