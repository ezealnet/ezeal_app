import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthProgressIndicator extends StatelessWidget {
  final int currentStep; // 0, 1, 2
  final List<String> stepLabels;

  const AuthProgressIndicator({
    super.key,
    required this.currentStep,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stepLabels.length, (index) {
            final isActive = index <= currentStep;
            final isCurrent = index == currentStep;
            
            return Row(
              children: [
                // Step Dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCurrent 
                        ? AppColors.accent 
                        : (isActive ? AppColors.primary : (isDark ? AppColors.surfaceDark : Colors.white)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: index < currentStep
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isActive 
                                  ? (isCurrent ? AppColors.primary : Colors.white) 
                                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                          ),
                  ),
                ),
                // Connector Line
                if (index < stepLabels.length - 1)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 2,
                    color: index < currentStep 
                        ? AppColors.primary 
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(stepLabels.length, (index) {
            final isCurrent = index == currentStep;
            final isActive = index <= currentStep;
            return Container(
              width: 98,
              alignment: Alignment.center,
              child: Text(
                stepLabels[index],
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent 
                      ? AppColors.primary 
                      : (isActive 
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      ],
    );
  }
}
