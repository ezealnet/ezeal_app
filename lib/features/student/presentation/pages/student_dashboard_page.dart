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
import '../../../cart/presentation/controllers/cart_providers.dart';

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go('/student/assessments'),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.explore_outlined, color: AppColors.primary, size: 36),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Assessment Marketplace',
                              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Discover and register for RIASEC, BigFive, VARK, and Aptitude tests.',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Text(
                                  'Explore Tests',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final cartItemsAsync = ref.watch(cartItemsProvider);
                        final cartCount = cartItemsAsync.asData?.value.length ?? 0;
                        return InkWell(
                          onTap: () => context.go('/student/cart'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.shopping_cart_outlined, color: AppColors.accentDark, size: 36),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'My Shopping Cart',
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  cartCount == 0
                                      ? 'Your shopping cart is currently empty.'
                                      : 'You have $cartCount assessment${cartCount > 1 ? 's' : ''} in your cart.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Text(
                                      'View Cart',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.accentDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.accentDark),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Browse Assessments',
                onPressed: () => context.go('/student/assessments'),
                width: 250,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
