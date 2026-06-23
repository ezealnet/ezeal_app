import 'package:flutter/material.dart';

class AppSpacing {
  // Margins & Paddings
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 999.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Standard Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // Responsive Breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 1024.0;

  // Edge Insets helper utilities
  static const EdgeInsets pAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets pAllXs = EdgeInsets.all(xs);
  static const EdgeInsets pAllSm = EdgeInsets.all(sm);
  static const EdgeInsets pAllMd = EdgeInsets.all(md);
  static const EdgeInsets pAllLg = EdgeInsets.all(lg);
  static const EdgeInsets pAllXl = EdgeInsets.all(xl);

  static const EdgeInsets pHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets pHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets pHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pHorizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets pVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets pVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets pVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets pVerticalLg = EdgeInsets.symmetric(vertical: lg);
}
