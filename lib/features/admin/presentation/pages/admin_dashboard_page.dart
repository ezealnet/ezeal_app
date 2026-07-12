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
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(adminStatsProvider);

    return AppScaffold(
      title: 'Admin Dashboard',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/dashboard'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: profileAsync.when(
                          data: (profile) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${profile?.fullName ?? user?.email ?? 'Administrator'}!',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
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
                                    'System Administrator Console',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (err, _) => Text('Error loading profile: $err'),
                        ),
                      ),
                      // Top actions placeholder
                      Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: AppColors.primary),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 12 KPI Metrics Grid
                  statsAsync.when(
                    data: (stats) => LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        int cols = 1;
                        if (width > 900) {
                          cols = 4;
                        } else if (width > 600) {
                          cols = 2;
                        }
                        final double spacing = AppSpacing.md.toDouble();
                        final double cardWidth = (width - (spacing * (cols - 1))) / cols;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _buildKpiCard(cardWidth, 'Total Users', '${stats['totalUsers']}', Icons.people_outline, AppColors.primary),
                            _buildKpiCard(cardWidth, 'Total Students', '${stats['totalStudents']}', Icons.school_outlined, AppColors.primary),
                            _buildKpiCard(cardWidth, 'Total Institutions', '${stats['totalInstitutions']}', Icons.business_outlined, AppColors.primary),
                            _buildKpiCard(cardWidth, 'Total Counselors', '${stats['totalCounselors']}', Icons.support_agent_outlined, AppColors.primary),
                            _buildKpiCard(cardWidth, 'Verified Ezeal IDs', '${stats['verifiedEzealIds']}', Icons.verified_user_outlined, AppColors.success),
                            _buildKpiCard(cardWidth, 'Pending KYC Checks', '${stats['pendingVerifications']}', Icons.fingerprint_outlined, AppColors.warning),
                            _buildKpiCard(cardWidth, 'Assessments Published', '${stats['assessmentsPublished']}', Icons.assessment_outlined, AppColors.info),
                            _buildKpiCard(cardWidth, 'Access Grants', '${stats['assessmentAccessGranted']}', Icons.vpn_key_outlined, AppColors.info),
                            _buildKpiCard(cardWidth, 'Tokens Available', '${stats['tokensAvailable']}', Icons.local_offer_outlined, AppColors.success),
                            _buildKpiCard(cardWidth, 'Tokens Redeemed', '${stats['tokensUsed']}', Icons.check_circle_outline, AppColors.success),
                            _buildKpiCard(cardWidth, 'Payments Received', '${stats['paymentsCount']}', Icons.payment_outlined, AppColors.accentDark),
                            _buildKpiCard(cardWidth, 'Completed Tests', '${stats['completedAssessments']}', Icons.task_alt_outlined, AppColors.success),
                          ],
                        );
                      },
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: Text(
                        'Admin RLS policy required for this management view.',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Quick Action Cards Section Header
                  Text(
                    'Quick Operations',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Action Shortcuts grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      int cols = 1;
                      if (width > 800) {
                        cols = 2;
                      }
                      final double spacing = AppSpacing.md.toDouble();
                      final double cardWidth = (width - (spacing * (cols - 1))) / cols;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          _buildActionCard(context, cardWidth, 'User Directory', 'Activate or suspend console accounts.', '/admin/users', Icons.people_outline),
                          _buildActionCard(context, cardWidth, 'Student Roster', 'Check profile completions and student results.', '/admin/students', Icons.school_outlined),
                          _buildActionCard(context, cardWidth, 'Partner Institutions', 'Issue school assessments tokens.', '/admin/institutions', Icons.business_outlined),
                          _buildActionCard(context, cardWidth, 'Token Registry', 'Generate, assign, or expire token codes.', '/admin/tokens', Icons.local_offer_outlined),
                          _buildActionCard(context, cardWidth, 'Order Payments Logs', 'Monitor payment status lists and refunds.', '/admin/payments', Icons.payment_outlined),
                          _buildActionCard(context, cardWidth, 'Audit Logs Console', 'Browse database logs and debug telemetry.', '/admin/audit', Icons.history_toggle_off_outlined),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(double width, String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, double width, String title, String desc, String path, IconData icon) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              desc,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Open Control Panel',
              onPressed: () => context.go(path),
            ),
          ],
        ),
      ),
    );
  }
}
