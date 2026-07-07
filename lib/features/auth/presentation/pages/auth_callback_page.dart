import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_brand_panel.dart';

class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    // 8. Add debug logs under kDebugMode
    if (kDebugMode) {
      final currentRoute = GoRouterState.of(context).uri.toString();
      final currentSession = Supabase.instance.client.auth.currentSession;
      final currentUser = Supabase.instance.client.auth.currentUser;

      print('DEBUG: Callback route reached: /auth/callback');
      print('DEBUG: current route: $currentRoute');
      print('DEBUG: Supabase currentSession exists: ${currentSession != null}');
      print('DEBUG: currentUser emailConfirmedAt: ${currentUser?.emailConfirmedAt}');
      print('DEBUG: active themeMode: ThemeMode.light');
    }

    // Give supabase_flutter a moment to parse the incoming deep link and restore session
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    if (kDebugMode) {
      print('DEBUG: Post-delay callback check.');
      print('DEBUG: Supabase currentSession exists: ${session != null}');
      print('DEBUG: currentUser emailConfirmedAt: ${user?.emailConfirmedAt}');
    }

    if (user != null && session != null) {
      // User/session exists
      SnackbarHelper.showSuccess(context, 'Email verified successfully.');
      
      // Invalidate providers to force auth state update
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);
      
      context.go('/dashboard');
    } else {
      // No session
      SnackbarHelper.showInfo(context, 'Email verified. Please sign in.');
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final cardContent = AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Verifying your email...',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please wait while we complete the verification process.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: isDesktop
          ? Row(
              children: [
                const Expanded(
                  flex: 42,
                  child: AuthBrandPanel(),
                ),
                Expanded(
                  flex: 58,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: cardContent,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    // Mobile Branding Above Card
                    Center(
                      child: Image.asset(
                        'assets/images/ezeal_logo.webp',
                        height: 52,
                        width: 52,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt, color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ezeal',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    cardContent,
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }
}
