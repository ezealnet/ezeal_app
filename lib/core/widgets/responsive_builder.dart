import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobileBuilder;
  final Widget Function(BuildContext context)? tabletBuilder;
  final Widget Function(BuildContext context) desktopBuilder;

  const ResponsiveBuilder({
    super.key,
    required this.mobileBuilder,
    this.tabletBuilder,
    required this.desktopBuilder,
  });

  static DeviceType getDeviceType(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    if (width < AppSpacing.breakpointMobile) {
      return DeviceType.mobile;
    } else if (width < AppSpacing.breakpointTablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSpacing.breakpointMobile) {
          return mobileBuilder(context);
        } else if (constraints.maxWidth < AppSpacing.breakpointTablet) {
          return (tabletBuilder ?? mobileBuilder)(context);
        } else {
          return desktopBuilder(context);
        }
      },
    );
  }
}
