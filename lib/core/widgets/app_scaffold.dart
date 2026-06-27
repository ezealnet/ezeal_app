import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../enums/user_role.dart';
import '../services/auth_provider.dart';
import 'responsive_builder.dart';
import '../../features/cart/presentation/controllers/cart_providers.dart';
import 'package:flutter/foundation.dart';

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveBuilder.isMobile(context);
    final currentRoute = GoRouterState.of(context).uri.toString();
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.asData?.value;

    if (kDebugMode) {
      print('--- DEBUG APP SCAFFOLD ---');
      print('Current Route: $currentRoute');
      print('Page Title Being Built: $title');
      print('---------------------------');
    }

    // Side navigation items definition
    final navItems = <_NavItem>[
      const _NavItem(title: 'Home / Landing', icon: Icons.home_outlined, route: '/'),
    ];

    if (user == null) {
      navItems.add(const _NavItem(title: 'Auth Portal', icon: Icons.lock_outline, route: '/auth'));
    } else if (profile != null) {
      switch (profile.role) {
        case UserRole.student:
          navItems.add(const _NavItem(title: 'Student space', icon: Icons.school_outlined, route: '/student/dashboard'));
          navItems.add(const _NavItem(title: 'Assessments', icon: Icons.assignment_outlined, route: '/student/assessments'));
          navItems.add(const _NavItem(title: 'My Cart', icon: Icons.shopping_cart_outlined, route: '/student/cart'));
          navItems.add(const _NavItem(title: 'Redeem Token', icon: Icons.vpn_key_outlined, route: '/student/redeem-token'));
          navItems.add(const _NavItem(title: 'My Access', icon: Icons.lock_open_outlined, route: '/student/access'));
          break;
        case UserRole.admin:
          navItems.add(const _NavItem(title: 'Admin panel', icon: Icons.admin_panel_settings_outlined, route: '/admin/dashboard'));
          break;
        case UserRole.institution:
          navItems.add(const _NavItem(title: 'Institution panel', icon: Icons.business_outlined, route: '/institution/dashboard'));
          break;
        case UserRole.counsellor:
          navItems.add(const _NavItem(title: 'Counsellor space', icon: Icons.psychology_outlined, route: '/counsellor/dashboard'));
          break;
        default:
          break;
      }
    }

    Widget buildNavList(bool inDrawer) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/ezeal_logo.webp',
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback container when asset is missing or loading
                        return Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Ezeal',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'MVP Foundation',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Nav items list
          ...navItems.map((item) {
            final isSelected = currentRoute == item.route;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              child: ListTile(
                leading: Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                ),
                title: Text(
                  item.title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: AppColors.primaryLight,
                hoverColor: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                onTap: () {
                  if (inDrawer) {
                    Navigator.pop(context); // Close drawer on mobile
                  }
                  if (currentRoute != item.route) {
                    context.go(item.route);
                  }
                },
              ),
            );
          }),
          if (user != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Sign Out',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                ),
                hoverColor: AppColors.error.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                onTap: () {
                  ref.read(authControllerProvider.notifier).logout();
                  if (inDrawer) {
                    Navigator.pop(context);
                  }
                  context.go('/');
                },
              ),
            ),
          ],
        ],
      );
    }

    // Determine actions to display
    final List<Widget> finalActions = [];
    if (actions != null) {
      finalActions.addAll(actions!);
    }
    
    // Add cart badge icon if student is logged in
    if (user != null && profile?.role == UserRole.student) {
      final cartItemsAsync = ref.watch(cartItemsProvider);
      final cartCount = cartItemsAsync.asData?.value.length ?? 0;
      
      finalActions.add(
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: currentRoute == '/student/cart'
                      ? null
                      : () {
                          context.go('/student/cart');
                        },
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Visibility(
                    visible: cartCount > 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title, style: AppTextStyles.titleLarge),
          actions: finalActions,
        ),
        drawer: Drawer(
          child: Material(
            color: Colors.white,
            child: buildNavList(true),
          ),
        ),
        body: SafeArea(child: body),
      );
    }

    // Tablet/Desktop Layout: sidebar + content area
    return Scaffold(
      body: Row(
        children: [
          // Persistent sidebar
          SizedBox(
            width: 280,
            child: Material(
              color: Colors.white,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: buildNavList(false),
              ),
            ),
          ),
          // Main content area
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title, style: AppTextStyles.titleLarge),
                actions: finalActions,
              ),
              body: SafeArea(child: body),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String route;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
