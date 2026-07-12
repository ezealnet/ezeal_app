import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/supabase_service.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminAssessmentsPage extends ConsumerStatefulWidget {
  const AdminAssessmentsPage({super.key});

  @override
  ConsumerState<AdminAssessmentsPage> createState() => _AdminAssessmentsPageState();
}

class _AdminAssessmentsPageState extends ConsumerState<AdminAssessmentsPage> {
  bool _isSaving = false;

  Future<void> _togglePublishStatus(String assessmentId, bool currentStatus) async {
    setState(() => _isSaving = true);
    final targetStatus = !currentStatus;
    try {
      await SupabaseService.client
          .from('assessments')
          .update({'is_published': targetStatus})
          .eq('id', assessmentId);
      ref.invalidate(adminAssessmentsProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assessment is now ${targetStatus ? "published" : "unpublished"}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status. RLS policies block.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assessmentsAsync = ref.watch(adminAssessmentsProvider);
    final accessAsync = ref.watch(adminAccessProvider);

    return AppScaffold(
      title: 'Assessment Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/assessments'),
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
                    'Assessment Catalog Operations',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  assessmentsAsync.when(
                    data: (assessments) {
                      final accesses = accessAsync.asData?.value ?? [];

                      if (assessments.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.assessment_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No assessments configured in database.'),
                              ],
                            ),
                          ),
                        );
                      }

                      final bool isMobile = MediaQuery.of(context).size.width < 700;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: assessments.length,
                        itemBuilder: (context, index) {
                          final a = assessments[index];
                          final id = a['id'] as String? ?? '';
                          final title = a['title'] ?? 'Assessment';
                          final type = a['assessment_type'] ?? 'RIASEC';
                          final duration = a['duration_minutes'] ?? 30;
                          final questionsCount = a['question_count'] ?? 20;
                          final basePrice = a['base_price'] ?? 299;
                          final isPublished = a['is_published'] as bool? ?? true;

                          final accessCount = accesses.where((access) => access['assessment_id'] == id).length;
                          final completedCount = accesses.where((access) => access['assessment_id'] == id && access['status'] == 'completed').length;

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text('Type: $type', style: AppTextStyles.bodyMedium),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Price: ₹$basePrice  |  Duration: $duration Min', style: AppTextStyles.bodySmall),
                                    Text('Questions: $questionsCount  |  Access: $accessCount ($completedCount completed)', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            text: isPublished ? 'Unpublish' : 'Publish',
                                            onPressed: _isSaving ? null : () => _togglePublishStatus(id, isPublished),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text('Type: $type  |  Questions: $questionsCount', style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text('₹$basePrice', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text('Access: $accessCount', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(isPublished ? 'PUBLISHED' : 'DRAFT', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: AppButton(
                                        text: isPublished ? 'Unpublish' : 'Publish',
                                        onPressed: _isSaving ? null : () => _togglePublishStatus(id, isPublished),
                                        width: 110,
                                      ),
                                    ),
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
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: const Text(
                        'Admin RLS policy required for this assessments view.',
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
