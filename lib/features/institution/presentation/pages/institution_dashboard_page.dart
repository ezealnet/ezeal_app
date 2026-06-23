import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/auth_provider.dart';

class InstitutionDashboardPage extends ConsumerWidget {
  const InstitutionDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Institution Dashboard',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning banner if pending approval
                    if (profile?.status == 'pending') ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Your registration is currently pending administrator approval. Certain dashboard features will remain locked until approved.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      'Welcome, ${profile?.fullName ?? user?.email ?? 'Institution'}!',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: profile?.status == 'pending' ? AppColors.warning : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          profile?.status == 'pending'
                              ? 'Pending Approval - Institution Portal'
                              : 'Active Account - Institution Portal',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error loading profile: $err'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.corporate_fare, color: AppColors.info, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text('Classes Registered', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Clasrooms configuration will display here in Phase 3.', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.show_chart, color: AppColors.success, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text('Average Grade Score', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Overall grade index will be calculated in Phase 3.', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'View Academic Roster',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Academic roster will load in Phase 3')),
                  );
                },
                width: 250,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
