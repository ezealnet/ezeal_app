import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SnackbarHelper {
  /// Shows a green success snackbar.
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  /// Shows a red error snackbar.
  static void showError(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  /// Shows a blue informational snackbar.
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline,
    );
  }

  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // Clear any active snackbars first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
