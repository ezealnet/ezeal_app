import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ezeal Home',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero section
                  Image.asset(
                    'assets/images/ezeal_logo.webp',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt, size: 50, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Welcome to Ezeal',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'The ultimate responsive assessment, identity verification, and counselling ecosystem built for students, administrators, institutions, and counsellors.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Call to actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppButton(
                        text: 'Get Started (Auth)',
                        onPressed: () => context.go('/auth'),
                        width: 200,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(
                        text: 'Role Dashboards',
                        style: AppButtonStyle.secondary,
                        onPressed: () => context.go('/dashboard'),
                        width: 200,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Features grid
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 900 ? 1 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: MediaQuery.sizeOf(context).width < 900 ? 3.0 : 1.5,
                    children: const [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 32),
                            SizedBox(height: AppSpacing.sm),
                            Text('Ezeal Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: AppSpacing.xxs),
                            Text('Integrated identity verification framework for reliable onboarding.', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                          ],
                        ),
                      ),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, color: AppColors.primary, size: 32),
                            SizedBox(height: AppSpacing.sm),
                            Text('Assessment Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: AppSpacing.xxs),
                            Text('Robust exam runner, test scoring, and verification controls.', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
