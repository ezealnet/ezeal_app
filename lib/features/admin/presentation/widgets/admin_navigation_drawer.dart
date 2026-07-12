import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminNavigationDrawer extends StatelessWidget {
  final String currentPath;
  const AdminNavigationDrawer({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                'Ezeal Admin',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(context, 'Dashboard', '/admin/dashboard', Icons.dashboard_outlined),
                _buildNavItem(context, 'Users', '/admin/users', Icons.people_outline),
                _buildNavItem(context, 'Students', '/admin/students', Icons.school_outlined),
                _buildNavItem(context, 'Institutions', '/admin/institutions', Icons.business_outlined),
                _buildNavItem(context, 'Counselors', '/admin/counselors', Icons.support_agent_outlined),
                _buildNavItem(context, 'Assessments', '/admin/assessments', Icons.assessment_outlined),
                _buildNavItem(context, 'Question Bank', '/admin/questions', Icons.quiz_outlined),
                _buildNavItem(context, 'Access control', '/admin/access', Icons.vpn_key_outlined),
                _buildNavItem(context, 'Tokens / Offers', '/admin/tokens', Icons.local_offer_outlined),
                _buildNavItem(context, 'Results Status', '/admin/results', Icons.bar_chart_outlined),
                _buildNavItem(context, 'Ezeal ID KYC', '/admin/verification', Icons.fingerprint_outlined),
                _buildNavItem(context, 'Payments Logs', '/admin/payments', Icons.payment_outlined),
                _buildNavItem(context, 'Audit Registry', '/admin/audit', Icons.history_toggle_off_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String path, IconData icon) {
    final isSelected = currentPath == path;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
        size: 20,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.5),
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.go(path);
      },
    );
  }
}
