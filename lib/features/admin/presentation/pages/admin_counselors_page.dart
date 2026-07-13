import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminCounselorsPage extends ConsumerWidget {
  const AdminCounselorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counselorsAsync = ref.watch(adminCounselorsProvider);

    return AppScaffold(
      title: 'Counselor Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/counselors'),
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
                    'Counselor Operations Console',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  counselorsAsync.when(
                    data: (counselors) {
                      if (counselors.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.support_agent_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No registered counselors found.'),
                              ],
                            ),
                          ),
                        );
                      }

                      final bool isMobile = MediaQuery.of(context).size.width < 700;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: counselors.length,
                        itemBuilder: (context, index) {
                          final c = counselors[index];
                          final profile = c['profiles'] as Map<String, dynamic>? ?? {};
                          final name = profile['full_name'] ?? 'Unknown Counselor';
                          final email = profile['email'] ?? '';
                          final specialization = c['specialization'] ?? 'General Guidance';
                          final experience = c['experience_years'] ?? 0;
                          final status = profile['status'] ?? 'pending';

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(email, style: AppTextStyles.bodyMedium),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Specialty: $specialization', style: AppTextStyles.bodySmall),
                                    Text('Experience: $experience years', style: AppTextStyles.bodySmall),
                                    Text('Status: ${status.toUpperCase()}', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            text: 'Assign Student',
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Student Assignment will lock in Phase 2.')),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: AppButton(
                                            text: 'Toggle Status',
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Status Toggle triggers in Phase 2.')),
                                              );
                                            },
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
                                          name,
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(email, style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(specialization, style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text('$experience Years', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(status.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        AppButton(
                                          text: 'Assign',
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Assignment locks in Phase 2.')),
                                            );
                                          },
                                          width: 90,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        AppButton(
                                          text: 'Activate',
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Activation activates in Phase 2.')),
                                            );
                                          },
                                          width: 90,
                                        ),
                                      ],
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
                        'Admin RLS policy required for this counselors view.',
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
