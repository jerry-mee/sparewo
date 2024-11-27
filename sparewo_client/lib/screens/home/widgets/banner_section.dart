import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BannerSection extends StatelessWidget {
  final bool isLargeScreen;
  final bool isVeryLargeScreen;

  const BannerSection({
    super.key,
    required this.isLargeScreen,
    required this.isVeryLargeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.0.h, bottom: 24.0.h),
      child: Hero(
        tag: 'home_banner',
        child: Container(
          height: isVeryLargeScreen
              ? 300.h
              : isLargeScreen
                  ? 250.h
                  : 160.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(
                isVeryLargeScreen
                    ? 'assets/images/banner_home@3x.png'
                    : isLargeScreen
                        ? 'assets/images/banner_home@2x.png'
                        : 'assets/images/banner_home.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
