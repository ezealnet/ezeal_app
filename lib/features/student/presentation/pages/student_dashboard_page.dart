import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/auth_provider.dart';
import '../controllers/student_profile_controller.dart';
import '../widgets/profile_completion_widget.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentProfileAsync = ref.watch(studentProfileProvider);
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Student Dashboard',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              studentProfileAsync.when(
                data: (profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${profile?.fullName ?? user?.email ?? 'Student'}!',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Active Account - Student Portal',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error loading greeting: $err'),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Interactive Profile Completion Summary Card
              studentProfileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox();
                  return Column(
                    children: [
                      AppCard(
                        child: ProfileCompletionWidget(
                          completionPercentage: profile.profileCompletion,
                          showButton: true,
                          onActionButtonPressed: () => context.go('/student/profile'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
                loading: () => const SizedBox(),
                error: (err, _) => const SizedBox(),
              ),

              // Enrollment and Assessments Status Rows
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school, color: AppColors.primary, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text('My Class Enrollment', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Your enrollment status will be updated here.', style: AppTextStyles.bodyMedium),
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
                          const Icon(Icons.assessment, color: AppColors.accentDark, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text('Active Assessments', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Pending exams will display here.', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'View My Assessments',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assessments will load in a later phase.')),
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
