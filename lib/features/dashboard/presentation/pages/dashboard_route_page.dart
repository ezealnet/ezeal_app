import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class DashboardRoutePage extends StatelessWidget {
  const DashboardRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Dashboard Selector',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Dashboard Selector',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please select a role dashboard to test the GoRouter setup.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 900 ? 1 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: MediaQuery.sizeOf(context).width < 900 ? 3.0 : 1.6,
                    children: [
                      _RoleCard(
                        title: 'Student space',
                        description: 'View courses, start exam assessments, and check progress.',
                        icon: Icons.school_outlined,
                        color: AppColors.primary,
                        onTap: () => context.go('/student/dashboard'),
                      ),
                      _RoleCard(
                        title: 'Admin panel',
                        description: 'Configure overall application, manage payments, audit logs.',
                        icon: Icons.admin_panel_settings_outlined,
                        color: AppColors.error,
                        onTap: () => context.go('/admin/dashboard'),
                      ),
                      _RoleCard(
                        title: 'Institution panel',
                        description: 'Enroll classes, track student results, monitor staff.',
                        icon: Icons.business_outlined,
                        color: AppColors.info,
                        onTap: () => context.go('/institution/dashboard'),
                      ),
                      _RoleCard(
                        title: 'Counsellor space',
                        description: 'Review psychological assessments, manage sessions.',
                        icon: Icons.psychology_outlined,
                        color: AppColors.warning,
                        onTap: () => context.go('/counsellor/dashboard'),
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}
