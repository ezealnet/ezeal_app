import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonStyle { primary, secondary, outlined }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                style == AppButtonStyle.outlined ? AppColors.primary : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    Widget buildButton() {
      switch (style) {
        case AppButtonStyle.primary:
          return ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: buttonContent,
          );
        case AppButtonStyle.secondary:
          return ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimaryLight,
            ),
            child: buttonContent,
          );
        case AppButtonStyle.outlined:
          return OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: buttonContent,
          );
      }
    }

    if (width != null) {
      return SizedBox(
        width: width,
        child: buildButton(),
      );
    }

    return buildButton();
  }
}
