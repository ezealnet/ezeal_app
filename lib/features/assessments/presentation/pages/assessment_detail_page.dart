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
import '../../presentation/controllers/assessments_providers.dart';
import '../../../cart/presentation/controllers/cart_providers.dart';
import '../../../assessment_access/presentation/controllers/assessment_access_providers.dart';

class AssessmentDetailPage extends ConsumerWidget {
  final String slug;

  const AssessmentDetailPage({
    super.key,
    required this.slug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentAsync = ref.watch(assessmentDetailProvider(slug));
    final cartItemsAsync = ref.watch(cartItemsProvider);
    final cartState = ref.watch(cartControllerProvider);
    final accessesAsync = ref.watch(assessmentAccessProvider);

    return AppScaffold(
      title: 'Assessment Details',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Row
              TextButton.icon(
                onPressed: () => context.go('/student/assessments'),
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                label: Text(
                  'Back to Marketplace',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              assessmentAsync.when(
                data: (assessment) {
                  if (assessment == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 64, color: AppColors.textSecondaryLight),
                          const SizedBox(height: AppSpacing.md),
                          Text('Assessment not found.', style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: 'Back to Marketplace',
                            onPressed: () => context.go('/student/assessments'),
                          ),
                        ],
                      ),
                    );
                  }

                  final isInCart = cartItemsAsync.asData?.value.any((item) => item.assessmentId == assessment.id) ?? false;

                  final accesses = accessesAsync.asData?.value ?? [];
                  final matches = accesses.where((a) => a.assessmentId == assessment.id).toList();
                  final access = matches.isNotEmpty ? matches.first : null;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left/Main Info Card
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppCard(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    assessment.title,
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    assessment.description,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  const Divider(),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'What this assessment evaluates:',
                                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _buildInfoRow(Icons.psychology, 'Core traits and cognitive strengths suitable for career matches.'),
                                  const SizedBox(height: AppSpacing.sm),
                                  _buildInfoRow(Icons.track_changes, 'Standardized results aligned with industry-standard benchmarks.'),
                                  const SizedBox(height: AppSpacing.sm),
                                  _buildInfoRow(Icons.description_outlined, 'Personalized 20-page career report detailing recommended streams.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Notice Banner based on access
                            if (access == null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.accentDark.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_outline, color: AppColors.accentDark, size: 32),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'Test access will unlock after verification and payment in the next phase.',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (access.status == 'unlocked') ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_open_outlined, color: AppColors.success, size: 32),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'Access Unlocked! You can start the assessment whenever you are ready.',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (access.status == 'completed') ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_outlined, color: AppColors.info, size: 32),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'Assessment Completed! Your career insights report is ready.',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),

                      // Right Summary / Access status or Cart Action Card
                      Expanded(
                        flex: 1,
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: access != null
                                ? [
                                    Text(
                                      'Access Status',
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Access Method', style: AppTextStyles.bodyMedium),
                                        Text(
                                          access.accessSource == 'institution' ? 'Institution Token' : 'Individual Purchase',
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    const Divider(),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Status', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                        Text(
                                          access.status == 'completed' ? 'Completed' : 'Unlocked',
                                          style: AppTextStyles.titleMedium.copyWith(
                                            color: access.status == 'completed' ? AppColors.info : AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 20, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text('${assessment.durationMinutes} Minutes Duration', style: AppTextStyles.bodyMedium),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        const Icon(Icons.quiz_outlined, size: 20, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text('${assessment.questionCount} Questions', style: AppTextStyles.bodyMedium),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    SizedBox(
                                      width: double.infinity,
                                      child: access.status == 'completed'
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
                                            ),
                                    ),
                                  ]
                                : [
                                    Text(
                                      'Pricing Details',
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Base Price', style: AppTextStyles.bodyMedium),
                                        Text(
                                          '₹${assessment.basePrice}',
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    const Divider(),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Price', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
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
                                      '* Add more assessments to your cart to unlock tiered package discounts!',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondaryLight,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 20, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text('${assessment.durationMinutes} Minutes Duration', style: AppTextStyles.bodyMedium),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        const Icon(Icons.quiz_outlined, size: 20, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text('${assessment.questionCount} Questions', style: AppTextStyles.bodyMedium),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    SizedBox(
                                      width: double.infinity,
                                      child: isInCart
                                          ? AppButton(
                                              text: 'Remove from Cart',
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
                                                          final error = ref.read(cartControllerProvider).errorMessage ?? 'Error';
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
                                                          final error = ref.read(cartControllerProvider).errorMessage ?? 'Error';
                                                          SnackbarHelper.showError(context, error);
                                                        }
                                                      }
                                                    },
                                              style: AppButtonStyle.primary,
                                            ),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ],
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
                    child: Text('Error loading assessment details: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}
