import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class ProfileCompletionWidget extends StatelessWidget {
  final int completionPercentage;
  final VoidCallback? onActionButtonPressed;
  final bool showButton;

  const ProfileCompletionWidget({
    super.key,
    required this.completionPercentage,
    this.onActionButtonPressed,
    this.showButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = completionPercentage >= 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profile Completion',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.textPrimaryDark 
                    : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              '$completionPercentage%',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: completionPercentage / 100.0,
            minHeight: 12,
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.surfaceDark 
                : AppColors.primaryLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        if (showButton) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: isComplete ? 'View Profile' : 'Complete Profile',
            style: isComplete ? AppButtonStyle.outlined : AppButtonStyle.primary,
            onPressed: onActionButtonPressed,
          ),
        ],
      ],
    );
  }
}
