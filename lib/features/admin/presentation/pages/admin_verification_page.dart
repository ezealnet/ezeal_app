import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminVerificationPage extends ConsumerWidget {
  const AdminVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(adminVerificationProvider);

    return AppScaffold(
      title: 'Identity Verification',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/verification'),
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
                    'Identity Verification Overview',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  verificationsAsync.when(
                    data: (verifications) {
                      if (verifications.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.fingerprint_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No identity verifications registered yet.'),
                              ],
                            ),
                          ),
                        );
                      }

                      final bool isMobile = MediaQuery.of(context).size.width < 700;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: verifications.length,
                        itemBuilder: (context, index) {
                          final v = verifications[index];
                          final profile = v['profiles'] as Map<String, dynamic>? ?? {};
                          final name = profile['full_name'] ?? 'Unknown Student';
                          final email = profile['email'] ?? '';
                          final ezealId = v['ezeal_id'] ?? 'None';
                          final verified = v['aadhaar_verified'] as bool? ?? false;
                          final status = v['verification_status'] as String? ?? 'pending';
                          final date = v['verified_at'] != null ? v['verified_at'].toString().split('T').first : '';

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
                                    Text('Ezeal ID: $ezealId', style: AppTextStyles.bodySmall),
                                    Text('Aadhaar Verified: ${verified ? "YES" : "NO"}  |  Date: $date', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: status == 'verified' ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'verified' ? AppColors.success : AppColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                    flex: 2,
                                    child: Text(ezealId, style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(verified ? 'YES' : 'NO', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(status.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(date, style: AppTextStyles.bodyMedium),
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
                        'Admin RLS policy required for this verification view.',
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
