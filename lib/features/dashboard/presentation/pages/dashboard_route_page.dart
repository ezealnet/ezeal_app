import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/enums/user_role.dart';

class DashboardRoutePage extends ConsumerStatefulWidget {
  const DashboardRoutePage({super.key});

  @override
  ConsumerState<DashboardRoutePage> createState() => _DashboardRoutePageState();
}

class _DashboardRoutePageState extends ConsumerState<DashboardRoutePage> {
  @override
  void initState() {
    super.initState();
    _checkRedirect();
  }

  void _checkRedirect() {
    final profileAsync = ref.read(currentProfileProvider);
    final profile = profileAsync.asData?.value;
    if (profile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _performRedirect(profile.role);
      });
    }
  }

  void _performRedirect(UserRole role) {
    final path = _getDashboardPath(role);
    if (kDebugMode) {
      print('DEBUG: resolved role: $role');
      print('DEBUG: final redirect path: $path');
    }
    context.go(path);
  }

  String _getDashboardPath(UserRole role) {
    switch (role) {
      case UserRole.student:
        return '/student/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.institution:
        return '/institution/dashboard';
      case UserRole.counsellor:
        return '/counsellor/dashboard';
      default:
        return '/auth/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    ref.listen<AsyncValue<UserProfile?>>(currentProfileProvider, (previous, next) {
      final profile = next.asData?.value;
      if (profile != null) {
        _performRedirect(profile.role);
      }
    });

    final isLoading = profileAsync.isLoading || (profileAsync.asData?.value == null);

    if (kDebugMode) {
      print('DEBUG: dashboard resolver loading: $isLoading');
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ezeal_logo.webp',
                height: 64,
                width: 64,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Preparing your Ezeal dashboard...',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Please wait while we resolve your session role.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
