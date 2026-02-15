import 'package:flutter/material.dart';

enum DesktopWidthTier { compact, standard, wide }

class DesktopWebScale {
  static const double pageMaxWidth = 1800;
  static const double navHeight = 108;
  static const double sectionSpacing = 40;
  static const double cardRadius = 32;
  static const double panelRadius = 40;

  static EdgeInsets horizontalPadding(double width) {
    if (width >= 1900) return const EdgeInsets.symmetric(horizontal: 96);
    if (width >= 1600) return const EdgeInsets.symmetric(horizontal: 72);
    if (width >= 1280) return const EdgeInsets.symmetric(horizontal: 48);
    return const EdgeInsets.symmetric(horizontal: 32);
  }
}

class DesktopLayout extends StatelessWidget {
  final Widget child;
  final DesktopWidthTier tier;

  const DesktopLayout({
    super.key,
    required this.child,
    this.tier = DesktopWidthTier.standard,
  });

  double _maxWidthForTier() {
    switch (tier) {
      case DesktopWidthTier.compact:
        return 980;
      case DesktopWidthTier.standard:
        return 1320;
      case DesktopWidthTier.wide:
        return 1680;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _maxWidthForTier().clamp(0, DesktopWebScale.pageMaxWidth),
        ),
        child: Padding(
          padding: DesktopWebScale.horizontalPadding(width),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
