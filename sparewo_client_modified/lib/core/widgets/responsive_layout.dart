import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    required this.desktopBody,
  });

  static const int mobileBreakpoint = 600;
  static const int tabletBreakpoint = 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobileBody;
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return tabletBody ?? desktopBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
