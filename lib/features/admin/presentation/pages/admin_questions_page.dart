import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminQuestionsPage extends ConsumerStatefulWidget {
  const AdminQuestionsPage({super.key});

  @override
  ConsumerState<AdminQuestionsPage> createState() => _AdminQuestionsPageState();
}

class _AdminQuestionsPageState extends ConsumerState<AdminQuestionsPage> {
  String? _selectedAssessmentId;

  @override
  Widget build(BuildContext context) {
    final assessmentsAsync = ref.watch(adminAssessmentsProvider);
    final questionsAsync = ref.watch(adminQuestionsProvider);

    final assessments = assessmentsAsync.asData?.value ?? [];

    return AppScaffold(
      title: 'Question Bank',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/questions'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question Bank Repository',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filter selector
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Filter by Assessment'),
                      value: _selectedAssessmentId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Assessments')),
                        ...assessments.map((a) => DropdownMenuItem(
                              value: a['id'] as String,
                              child: Text(a['title'] as String? ?? 'Assessment'),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedAssessmentId = val),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Questions list
                  questionsAsync.when(
                    data: (questions) {
                      final filtered = questions.where((q) {
                        return _selectedAssessmentId == null || q['assessment_id'] == _selectedAssessmentId;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.quiz_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No questions matched the filter.'),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final q = filtered[index];
                          final text = q['question_text'] ?? 'Question Text Missing';
                          final type = q['question_type'] ?? 'multiple_choice';
                          final active = q['is_active'] as bool? ?? true;
                          final order = q['question_order'] ?? 0;
                          final scoreKey = q['scoring_key'] ?? 'None';
                          final parentAssessment = q['assessments'] as Map<String, dynamic>? ?? {};
                          final parentTitle = parentAssessment['title'] ?? 'Global';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          parentTitle.toString().toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Order Index: $order',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    text,
                                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Type: ${type.toString().toUpperCase()}', style: AppTextStyles.bodySmall),
                                      Text(
                                        active ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          color: active ? AppColors.success : AppColors.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (scoreKey != 'None') ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Scoring Weight Key: $scoreKey',
                                      style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: const Text(
                        'Admin RLS policy required for this question repository view.',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
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
