import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminAuditPage extends StatelessWidget {
  const AdminAuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Audit Logs',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/audit'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Security Audit Logging',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppCard(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_outlined, size: 64, color: AppColors.textSecondaryLight),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Audit logs console is currently disabled.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Security transaction logging will be activated in a subsequent release phase.',
                        style: TextStyle(color: AppColors.textSecondaryLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
