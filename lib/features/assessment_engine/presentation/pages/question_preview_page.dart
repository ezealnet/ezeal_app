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
import '../../../assessments/presentation/controllers/assessments_providers.dart';
import '../../../assessment_access/presentation/controllers/assessment_access_providers.dart';
import '../controllers/assessment_engine_providers.dart';
import 'package:flutter/foundation.dart';

class QuestionPreviewPage extends ConsumerStatefulWidget {
  final String slug;

  const QuestionPreviewPage({
    super.key,
    required this.slug,
  });

  @override
  ConsumerState<QuestionPreviewPage> createState() => _QuestionPreviewPageState();
}

class _QuestionPreviewPageState extends ConsumerState<QuestionPreviewPage> {
  bool _isRedirecting = false;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      final currentRoute = GoRouterState.of(context).uri.toString();
      print('--- DEBUG BUILD: Question Preview Page ---');
      print('Route: $currentRoute');
      print('Slug: ${widget.slug}');
      print('------------------------------------------');
    }

    final assessmentAsync = ref.watch(assessmentDetailProvider(widget.slug));
    final accessesAsync = ref.watch(assessmentAccessProvider);

    return assessmentAsync.when(
      data: (assessment) {
        if (assessment == null) {
          return const AppScaffold(
            title: 'Question Preview',
            body: Center(child: Text('Assessment not found.')),
          );
        }

        // Validate access
        return accessesAsync.when(
          data: (accesses) {
            final hasAccess = accesses.any((a) => a.assessmentId == assessment.id && (a.status == 'unlocked' || a.status == 'completed'));
            if (!hasAccess) {
              if (!_isRedirecting) {
                _isRedirecting = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  context.go('/student/assessments/${widget.slug}');
                });
              }
              return const AppScaffold(
                title: 'Question Preview',
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final questionsAsync = ref.watch(assessmentQuestionsProvider(assessment.id));
            final configAsync = ref.watch(assessmentEngineConfigProvider(assessment.id));
            final readinessAsync = ref.watch(assessmentReadinessProvider(assessment.id));

            return AppScaffold(
              title: 'Question Preview',
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      TextButton.icon(
                        onPressed: () => context.go('/student/access'),
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                        label: Text(
                          'Back to My Assessments',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Header Card
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    assessment.title,
                                    style: AppTextStyles.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                // Readiness Badge in debug mode
                                if (kDebugMode)
                                  readinessAsync.when(
                                    data: (readiness) {
                                      Color color;
                                      String label;
                                      switch (readiness) {
                                        case AssessmentReadinessState.ready:
                                          color = AppColors.success;
                                          label = 'READY';
                                          break;
                                        case AssessmentReadinessState.questionsMissing:
                                          color = AppColors.error;
                                          label = 'QUESTIONS MISSING';
                                          break;
                                        case AssessmentReadinessState.optionsMissing:
                                          color = AppColors.warning;
                                          label = 'OPTIONS MISSING';
                                          break;
                                        case AssessmentReadinessState.configMissing:
                                          color = AppColors.error;
                                          label = 'CONFIG MISSING';
                                          break;
                                      }
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          border: Border.all(color: color.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'DEBUG: $label',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const SizedBox(),
                                    error: (err, _) => const SizedBox(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              assessment.description,
                              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const Divider(),
                            const SizedBox(height: AppSpacing.md),

                            // Meta row
                            configAsync.when(
                              data: (config) {
                                final duration = config?.durationMinutes ?? assessment.durationMinutes;
                                return Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Duration: $duration minutes',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: AppSpacing.xl),
                                    const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
                                    const SizedBox(width: AppSpacing.xs),
                                    questionsAsync.when(
                                      data: (questions) => Text(
                                        'Questions: ${questions.length} active',
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      loading: () => const Text('Loading questions...'),
                                      error: (err, _) => const Text('Error loading questions'),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (err, _) => const Text('Error loading config'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Message banner
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
                            const Icon(Icons.info_outline, color: AppColors.info, size: 28),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'This is a question preview. Full assessment runner will be added in the next phase.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Questions Title
                      Text(
                        'Sample Question Preview',
                        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // First few questions preview list
                      questionsAsync.when(
                        data: (questions) {
                          if (questions.isEmpty) {
                            return const AppCard(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: Center(child: Text('No active questions found for preview.')),
                              ),
                            );
                          }

                          // Limit to first 3 questions for preview
                          final previewQuestions = questions.take(3).toList();

                          return Column(
                            children: previewQuestions.map((q) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: AppCard(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Question ${q.questionOrder}: ${q.questionText}',
                                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      ...q.options.map((opt) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: AppColors.primary),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    opt.optionValue,
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.md),
                                              Expanded(
                                                child: Text(
                                                  opt.optionText,
                                                  style: AppTextStyles.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error loading preview questions: $err')),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Actions Row
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Back to Access',
                              onPressed: () {
                                if (!context.mounted) return;
                                context.go('/student/access');
                              },
                              style: AppButtonStyle.outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton(
                              text: 'Start Test',
                              onPressed: () {
                                if (!context.mounted) return;
                                // TODO: Runner comes in Phase 7.
                                SnackbarHelper.showInfo(context, 'Assessment runner will be added in Phase 7.');
                              },
                              style: AppButtonStyle.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const AppScaffold(
            title: 'Question Preview',
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => AppScaffold(
            title: 'Question Preview',
            body: Center(child: Text('Error loading access: $err')),
          ),
        );
      },
      loading: () => const AppScaffold(
        title: 'Question Preview',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => AppScaffold(
        title: 'Question Preview',
        body: Center(child: Text('Error loading assessment details: $err')),
      ),
    );
  }
}
