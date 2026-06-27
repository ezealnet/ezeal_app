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
import '../../../../core/services/auth_provider.dart';
import 'package:flutter/foundation.dart';

class AssessmentAccessPage extends ConsumerWidget {
  const AssessmentAccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessesAsync = ref.watch(assessmentAccessProvider);
    final user = ref.watch(currentUserProvider);

    if (kDebugMode) {
      final currentRoute = GoRouterState.of(context).uri.toString();
      print('--- DEBUG BUILD: /student/access ---');
      print('Route: $currentRoute');
      print('User ID: ${user?.id}');
      print('Provider state: $accessesAsync');
      if (accessesAsync.hasValue) {
        print('Access row count: ${accessesAsync.value!.length}');
        for (final item in accessesAsync.value!) {
          print('Access row: id=${item.id}, assessmentId=${item.assessmentId}, status=${item.status}, source=${item.accessSource}, assessmentTitle=${item.assessment?.title}');
        }
      }
      print('-----------------------------------------');
    }

    return AppScaffold(
      title: 'My Assessment Access',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Assessment Access',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              accessesAsync.when(
                data: (accesses) {
                  if (accesses.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No unlocked assessments yet',
                          style: AppTextStyles.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          text: 'Browse Marketplace',
                          onPressed: () {
                            if (!context.mounted) return;
                            context.go('/student/assessments');
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          text: 'Redeem Token',
                          style: AppButtonStyle.outlined,
                          onPressed: () {
                            if (!context.mounted) return;
                            context.go('/student/redeem-token');
                          },
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: accesses.map((item) {
                      final assessment = item.assessment;
                      final isInstitution = item.accessSource == 'institution';
                      final isCompleted = item.status == 'completed';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assessment?.title ?? 'Assessment (ID: ${item.assessmentId})',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Source: ${isInstitution ? "Institution Token" : "Individual Purchase"}',
                                style: AppTextStyles.bodySmall,
                              ),
                              Text(
                                'Status: ${isCompleted ? "Completed" : "Unlocked"}',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (isCompleted)
                                AppButton(
                                  text: 'View Result',
                                  onPressed: () {
                                    if (!context.mounted) return;
                                    SnackbarHelper.showInfo(context, 'Assessment report will be added in the next phase.');
                                  },
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppButton(
                                      text: 'Start Test',
                                      onPressed: () {
                                        if (!context.mounted) return;
                                        SnackbarHelper.showInfo(context, 'Assessment runner will be added in the next phase.');
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Assessment runner will be added in the next phase.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondaryLight,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Text(
                  'Error loading accesses: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
