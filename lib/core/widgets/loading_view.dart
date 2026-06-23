import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const LoadingView({
    super.key,
    this.message,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final spinner = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          backgroundColor: AppColors.primaryLight,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        body: Center(
          child: spinner,
        ),
      );
    }

    return Center(
      child: spinner,
    );
  }
}
