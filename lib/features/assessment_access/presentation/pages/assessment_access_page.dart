import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/assessment_access_providers.dart';
import '../../../../core/utils/snackbar_helper.dart';

class AssessmentAccessPage extends ConsumerWidget {
  const AssessmentAccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessesAsync = ref.watch(assessmentAccessProvider);

    return AppScaffold(
      title: 'My Assessments',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Unlocked Assessments',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Here are the tests you have unlocked. You can begin them once testing session runners are provisioned.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              accessesAsync.when(
                data: (accesses) {
                  if (accesses.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: Column(
                          children: [
                            const Icon(Icons.assignment_outlined, size: 72, color: AppColors.textSecondaryLight),
                            const SizedBox(height: AppSpacing.md),
                            Text('No unlocked assessments found', style: AppTextStyles.titleLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Buy career tests from the marketplace or redeem a school token to get access.',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppButton(
                                  text: 'Browse Marketplace',
                                  onPressed: () => context.go('/student/assessments'),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AppButton(
                                  text: 'Redeem Token',
                                  style: AppButtonStyle.outlined,
                                  onPressed: () => context.go('/student/redeem-token'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accesses.length,
                    itemBuilder: (context, index) {
                      final access = accesses[index];
                      final assessment = access.assessment;
                      final isInstitution = access.accessSource == 'institution';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          ),
                                          child: Text(
                                            assessment?.assessmentType ?? 'Test',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                          decoration: BoxDecoration(
                                            color: isInstitution
                                                ? AppColors.info.withValues(alpha: 0.1)
                                                : AppColors.success.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          ),
                                          child: Text(
                                            isInstitution ? 'Institution Credit' : 'Individual Purchase',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: isInstitution ? AppColors.info : AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      assessment?.title ?? 'Assessment',
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      assessment?.description ?? '',
                                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                    decoration: BoxDecoration(
                                      color: access.status == 'completed'
                                          ? AppColors.info.withValues(alpha: 0.1)
                                          : AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    ),
                                    child: Text(
                                      access.status == 'completed' ? 'Status: Completed' : 'Status: Unlocked',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: access.status == 'completed' ? AppColors.info : AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  if (access.status == 'completed') ...[
                                    AppButton(
                                      text: 'View Result',
                                      onPressed: () {
                                        SnackbarHelper.showInfo(context, 'Assessment report will be added in the next phase.');
                                      },
                                    ),
                                  ] else ...[
                                    AppButton(
                                      text: 'Start Test',
                                      onPressed: () {
                                        SnackbarHelper.showInfo(context, 'Assessment runner will be added in the next phase.');
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Assessment runner will be added in the next phase.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondaryLight,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Text('Error loading accesses: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
