import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import '../controllers/assessment_runner_providers.dart';

class AssessmentRunnerPage extends ConsumerStatefulWidget {
  final String slug;
  const AssessmentRunnerPage({super.key, required this.slug});

  @override
  ConsumerState<AssessmentRunnerPage> createState() => _AssessmentRunnerPageState();
}

class _AssessmentRunnerPageState extends ConsumerState<AssessmentRunnerPage> {
  bool _initialized = false;

  void _showSubmitConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Submit Assessment'),
        content: const Text('Are you sure you want to submit this assessment? You cannot make any more changes after submission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(assessmentRunnerControllerProvider.notifier).submitAttempt();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Exit Test?'),
        content: const Text('Your answers are auto-saved. You can resume this test at any time from your My Access page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Resume Test'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.go('/student/access');
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assessmentAsync = ref.watch(assessmentDetailProvider(widget.slug));

    // Listen for submit success or errors
    ref.listen<AssessmentRunnerState>(assessmentRunnerControllerProvider, (prev, next) {
      if (next.submitSuccess && (prev == null || !prev.submitSuccess)) {
        if (kDebugMode) {
          print('--- Navigation Complete ---');
          print('Target: /student/access');
          print('---------------------------');
        }
        SnackbarHelper.showSuccess(context, 'Assessment submitted successfully.');
        context.go('/student/access');
      }

      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        SnackbarHelper.showError(context, next.errorMessage!);
      }
    });

    return assessmentAsync.when(
      data: (assessment) {
        if (assessment == null) {
          return AppScaffold(
            title: 'Assessment Runner',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Assessment not found.'),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: 'Back to Access',
                      onPressed: () => context.go('/student/access'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!_initialized) {
          _initialized = true;
          Future.microtask(() {
            ref.read(assessmentRunnerControllerProvider.notifier).startOrResumeAttempt(assessment.id);
          });
        }

        final runnerState = ref.watch(assessmentRunnerControllerProvider);

        if (runnerState.isLoading) {
          return AppScaffold(
            title: assessment.title,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isSubmitted = runnerState.attempt?.status == 'submitted' ||
            runnerState.errorMessage == 'This assessment has already been completed.';

        if (isSubmitted || runnerState.attempt == null) {
          final isCompletedMsg = isSubmitted ||
              (runnerState.errorMessage?.contains('completed') ?? false);
          return AppScaffold(
            title: assessment.title,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompletedMsg ? Icons.check_circle : Icons.error_outline,
                      size: 64,
                      color: isCompletedMsg ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isCompletedMsg
                          ? 'Assessment already completed.'
                          : (runnerState.errorMessage ?? 'Failed to load assessment attempt.'),
                      style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    if (isCompletedMsg) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'You cannot retake this assessment.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        text: 'View Result',
                        onPressed: () {
                          if (!context.mounted) return;
                          SnackbarHelper.showInfo(context, 'Assessment report will be added in the next phase.');
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go('/student/access'),
                      child: const Text('Back to My Access'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (runnerState.questions.isEmpty) {
          return AppScaffold(
            title: assessment.title,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No questions available in this test.'),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      text: 'Go to My Access',
                      onPressed: () => context.go('/student/access'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final question = runnerState.questions[runnerState.currentIndex];
        final totalQuestions = runnerState.questions.length;
        final progress = totalQuestions > 0 ? (runnerState.currentIndex + 1) / totalQuestions : 0.0;

        return AppScaffold(
          title: assessment.title,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Test',
              onPressed: () => _showExitConfirmation(context),
            ),
          ],
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessment.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${runnerState.currentIndex + 1} of $totalQuestions',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '${(runnerState.attempt?.completionPercentage ?? 0.0).toStringAsFixed(0)}% Completed',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.questionText,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ...question.options.map((option) {
                          final isSelected = runnerState.answers[question.id] == option.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: InkWell(
                              onTap: runnerState.isSubmitting || runnerState.isLoading
                                  ? null
                                  : () {
                                      ref.read(assessmentRunnerControllerProvider.notifier).saveAnswer(question.id, option.id);
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryLight : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        option.optionText,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (runnerState.isSaving) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Saving...',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                            ),
                          ] else ...[
                            const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Saved',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ],
                      ),
                      if (runnerState.errorMessage != null)
                        Expanded(
                          child: Text(
                            runnerState.errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppButton(
                        text: 'Previous',
                        style: AppButtonStyle.outlined,
                        onPressed: runnerState.currentIndex > 0 && !runnerState.isSubmitting
                            ? () => ref.read(assessmentRunnerControllerProvider.notifier).goToPreviousQuestion()
                            : null,
                      ),
                      if (runnerState.currentIndex + 1 < totalQuestions)
                        AppButton(
                          text: 'Next',
                          onPressed: !runnerState.isSubmitting
                              ? () => ref.read(assessmentRunnerControllerProvider.notifier).goToNextQuestion()
                              : null,
                        )
                      else
                        AppButton(
                          text: 'Submit Test',
                          isLoading: runnerState.isSubmitting,
                          onPressed: runnerState.answers.length < totalQuestions || runnerState.isSubmitting
                              ? null
                              : () => _showSubmitConfirmation(context, ref),
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
        title: 'Loading Assessment',
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => AppScaffold(
        title: 'Error',
        body: Center(
          child: Text('Error loading assessment details: $err'),
        ),
      ),
    );
  }
}
