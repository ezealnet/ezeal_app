import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo & App Name
                Row(
                  children: [
                    Image.asset(
                      'assets/images/ezeal_logo.webp',
                      height: 48,
                      width: 48,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt, color: AppColors.accent, size: 28),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Ezeal',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Headline
                Text(
                  'Discover Your True Potential',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Subheading
                Text(
                  'AI-powered Human Potential Intelligence Platform helping students understand their strengths, personality, career direction and future opportunities.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Three premium feature cards
                _buildFeatureCard(
                  Icons.assignment_outlined,
                  'Career Assessments',
                  'Discover where your interests align.',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureCard(
                  Icons.psychology_outlined,
                  'Personality Intelligence',
                  'Understand how you learn and grow.',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureCard(
                  Icons.explore_outlined,
                  'Future Career Guidance',
                  'Build your roadmap with confidence.',
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Trusted by section
                const Divider(color: Colors.white24),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'TRUSTED BY',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTrustedLabel('Students'),
                    _buildTrustedLabel('Schools'),
                    _buildTrustedLabel('Career Counsellors'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: Colors.white70,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
