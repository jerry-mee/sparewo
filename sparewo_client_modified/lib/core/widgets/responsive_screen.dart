import 'package:flutter/material.dart';

class ResponsiveScreen extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final double breakpoint;

  const ResponsiveScreen({
    super.key,
    required this.mobile,
    required this.desktop,
    this.breakpoint = 1000,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpoint ? desktop : mobile;
  }
}
