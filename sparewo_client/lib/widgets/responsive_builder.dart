// lib/widgets/responsive_builder.dart
import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    SizingInformation sizingInformation,
  ) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      var sizingInformation = SizingInformation(
        deviceScreenType: _getDeviceType(mediaQuery),
        screenSize: mediaQuery.size,
        localWidgetSize: Size(constraints.maxWidth, constraints.maxHeight),
      );
      return builder(context, sizingInformation);
    });
  }

  DeviceScreenType _getDeviceType(MediaQueryData mediaQuery) {
    double deviceWidth = mediaQuery.size.width;

    if (deviceWidth >= 1200) {
      return DeviceScreenType.desktop;
    }
    if (deviceWidth >= 600) {
      return DeviceScreenType.tablet;
    }
    return DeviceScreenType.mobile;
  }
}

class SizingInformation {
  final DeviceScreenType deviceScreenType;
  final Size screenSize;
  final Size localWidgetSize;

  SizingInformation({
    required this.deviceScreenType,
    required this.screenSize,
    required this.localWidgetSize,
  });

  bool get isDesktop => deviceScreenType == DeviceScreenType.desktop;
  bool get isTablet => deviceScreenType == DeviceScreenType.tablet;
  bool get isMobile => deviceScreenType == DeviceScreenType.mobile;
}

enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}
