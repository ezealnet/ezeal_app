import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  final bool expand;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('--- DEBUG APP BUTTON BUILD ---');
      print('Text: $text');
      print('Style: $style');
      print('Expand state: $expand');
      print('Configured Width: $width');
      print('------------------------------');
    }

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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeightMd),
            ),
            child: buttonContent,
          );
        case AppButtonStyle.secondary:
          return ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimaryLight,
              minimumSize: const Size(0, AppSpacing.buttonHeightMd),
            ),
            child: buttonContent,
          );
        case AppButtonStyle.outlined:
          return OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.buttonHeightMd),
            ),
            child: buttonContent,
          );
      }
    }

    Widget result = buildButton();
    if (width != null) {
      result = SizedBox(
        width: width,
        child: result,
      );
    } else if (expand) {
      result = SizedBox(
        width: double.infinity,
        child: result,
      );
    }

    return result;
  }
}
