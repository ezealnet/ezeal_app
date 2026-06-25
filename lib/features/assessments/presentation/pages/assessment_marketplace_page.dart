import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../student/presentation/controllers/student_profile_controller.dart';
import '../../presentation/controllers/assessments_providers.dart';
import '../../../cart/presentation/controllers/cart_providers.dart';
import '../../../assessment_access/presentation/controllers/assessment_access_providers.dart';

class AssessmentMarketplacePage extends ConsumerWidget {
  const AssessmentMarketplacePage({super.key});

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentsAsync = ref.watch(assessmentListProvider);
    final profileAsync = ref.watch(studentProfileProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);
    final cartState = ref.watch(cartControllerProvider);
    final accessesAsync = ref.watch(assessmentAccessProvider);

    return AppScaffold(
      title: 'Assessment Marketplace',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Completion Banner
              profileAsync.when(
                data: (profile) {
                  if (profile == null || profile.profileCompletion >= 100) {
                    return const SizedBox();
                  }
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.accentDark.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.accentDark, size: 28),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete Your Profile (${profile.profileCompletion}%)',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    'Finish filling in your details to receive personalized career mapping recommendations.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            AppButton(
                              text: 'Complete Now',
                              onPressed: () => context.go('/student/profile'),
                              width: 140,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (err, _) => const SizedBox(),
              ),

              // Marketplace Intro
              Text(
                'Explore Career Assessments',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Enroll in standardized tests to identify your strengths, personality traits, and stream recommendations.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Assessments Grid/List
              assessmentsAsync.when(
                data: (assessments) {
                  if (assessments.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: Text('No assessments available in the marketplace.'),
                      ),
                    );
                  }

                  // Responsive grid layout logic
                  final width = MediaQuery.of(context).size.width;
                  final crossAxisCount = width > 1100 ? 3 : (width > 750 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: assessments.length,
                    itemBuilder: (context, index) {
                      final assessment = assessments[index];
                      final isInCart = cartItemsAsync.asData?.value.any((item) => item.assessmentId == assessment.id) ?? false;

                      final accesses = accessesAsync.asData?.value ?? [];
                      final matches = accesses.where((a) => a.assessmentId == assessment.id).toList();
                      final access = matches.isNotEmpty ? matches.first : null;

                      Widget? statusBadge;
                      if (access != null) {
                        if (access.status == 'unlocked') {
                          statusBadge = _buildStatusBadge('Access Unlocked', AppColors.success);
                        } else if (access.status == 'completed') {
                          statusBadge = _buildStatusBadge('Completed', AppColors.info);
                        }
                      } else if (isInCart) {
                        statusBadge = _buildStatusBadge('In Cart', AppColors.warning);
                      }

                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        assessment.assessmentType,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (statusBadge != null) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      statusBadge,
                                    ],
                                  ],
                                ),
                                Text(
                                  '₹${assessment.basePrice}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              assessment.title,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                assessment.description,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondaryLight),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  '${assessment.durationMinutes} mins',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                const Icon(Icons.quiz_outlined, size: 16, color: AppColors.textSecondaryLight),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  '${assessment.questionCount} questions',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    text: 'View Details',
                                    onPressed: () => context.go('/student/assessments/${assessment.slug}'),
                                    style: AppButtonStyle.outlined,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: access != null
                                      ? (access.status == 'completed'
                                          ? AppButton(
                                              text: 'View Result',
                                              onPressed: () {
                                                SnackbarHelper.showInfo(context, 'Assessment report will be added in the next phase.');
                                              },
                                              style: AppButtonStyle.primary,
                                            )
                                          : AppButton(
                                              text: 'Start Test',
                                              onPressed: () {
                                                SnackbarHelper.showInfo(context, 'Assessment runner will be added in the next phase.');
                                              },
                                              style: AppButtonStyle.primary,
                                            ))
                                      : (isInCart
                                          ? AppButton(
                                              text: 'Remove',
                                              onPressed: cartState.isLoading
                                                  ? null
                                                  : () async {
                                                      final success = await ref
                                                          .read(cartControllerProvider.notifier)
                                                          .removeFromCart(assessment.id);
                                                      if (context.mounted) {
                                                        if (success) {
                                                          SnackbarHelper.showInfo(context, 'Removed ${assessment.title} from cart.');
                                                        } else {
                                                          final error = ref.read(cartControllerProvider).errorMessage ?? 'Error removing item';
                                                          SnackbarHelper.showError(context, error);
                                                        }
                                                      }
                                                    },
                                              style: AppButtonStyle.secondary,
                                            )
                                          : AppButton(
                                              text: 'Add to Cart',
                                              onPressed: cartState.isLoading
                                                  ? null
                                                  : () async {
                                                      final success = await ref
                                                          .read(cartControllerProvider.notifier)
                                                          .addToCart(assessment.id);
                                                      if (context.mounted) {
                                                        if (success) {
                                                          SnackbarHelper.showSuccess(context, 'Added ${assessment.title} to cart.');
                                                        } else {
                                                          final error = ref.read(cartControllerProvider).errorMessage ?? 'Error adding item';
                                                          SnackbarHelper.showError(context, error);
                                                        }
                                                      }
                                                    },
                                              style: AppButtonStyle.primary,
                                            )),
                                ),
                              ],
                            ),
                          ],
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
                    child: Text('Error loading assessments: $err', style: const TextStyle(color: AppColors.error)),
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
