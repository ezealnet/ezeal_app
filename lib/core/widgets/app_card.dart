import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool hasShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.pAllMd,
    this.onTap,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? AppColors.borderLight
              : AppColors.borderDark,
          width: 1,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppColors.shadowLight
                      : AppColors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
