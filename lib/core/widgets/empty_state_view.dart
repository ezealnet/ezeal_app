import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSpacing.iconXl,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: actionLabel!,
                onPressed: onActionPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
