import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/auth_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Admin Dashboard',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${profile?.fullName ?? user?.email ?? 'Administrator'}!',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.error,
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
                            color: AppColors.error,
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
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.people, color: AppColors.error, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text('System Accounts', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Total registered system accounts will display in later phases.', style: AppTextStyles.bodyMedium),
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
                          const Icon(Icons.security, color: Colors.blueGrey, size: 36),
                          const SizedBox(height: AppSpacing.md),
                          Text('Security Audit Logs', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('No issues detected in last 24h.', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Launch System Settings',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings will load in Phase 3')),
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
