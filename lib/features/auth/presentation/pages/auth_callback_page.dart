import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_provider.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_brand_panel.dart';

class AuthCallbackPage extends ConsumerStatefulWidget {
  const AuthCallbackPage({super.key});

  @override
  ConsumerState<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends ConsumerState<AuthCallbackPage> {
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _timeoutTimer;
  bool _navigationStarted = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _handleCallback() {
    // 1. Immediately check currentSession/currentUser
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    if (kDebugMode) {
      print('DEBUG: [AuthCallbackPage] Initial check: user = ${user?.id}, session exists = ${session != null}');
    }

    if (user != null && session != null) {
      _processVerification(user, session);
      return;
    }

    // 2. Subscribe to onAuthStateChange as fallback
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final s = data.session;
      final u = s?.user;
      
      if (kDebugMode) {
        print('DEBUG: [AuthCallbackPage] Auth event received: ${data.event}');
      }

      if (u != null && s != null) {
        _processVerification(u, s);
      }
    });

    // 3. Set a maximum timeout (8 seconds)
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 8), _onTimeout);
  }

  void _onTimeout() {
    if (!mounted || _navigationStarted) return;
    if (kDebugMode) {
      print('DEBUG: [AuthCallbackPage] Verification timed out.');
    }
    _authSubscription?.cancel();
    setState(() {
      _hasError = true;
      _errorMessage = 'Verification completed, but setup is taking longer than expected.';
    });
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

  Future<void> _processVerification(User user, Session session) async {
    if (_navigationStarted) return;
    _navigationStarted = true;
    _timeoutTimer?.cancel();
    _authSubscription?.cancel();

    if (kDebugMode) {
      print('DEBUG: [AuthCallbackPage] Verification link recognized. Starting profile resolution.');
    }

    try {
      // Force refresh auth providers to ensure states are aligned
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);

      // Await profile validation/recovery with a bounded timeout (5 seconds)
      final profile = await ref.read(currentProfileProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Profile resolution timed out.'),
      );

      if (!mounted) return;

      if (profile != null) {
        final path = _getDashboardPath(profile.role);
        if (kDebugMode) {
          print('DEBUG: [AuthCallbackPage] Direct navigation path resolved: $path');
        }
        context.go(path);
      } else {
        throw Exception('Profile row not found or recovered.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: [AuthCallbackPage] Profile resolution error: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e is TimeoutException
              ? 'Verification completed, but setup is taking longer than expected.'
              : 'Unable to retrieve your profile. Please try signing in again.';
        });
      }
    }
  }

  void _retryCallback() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _navigationStarted = false;
    });
    _handleCallback();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    if (_hasError) {
      final cardContent = AuthCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Verification completed, but setup is taking longer than expected',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'Please sign in to continue. Your email verification may already be complete.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go('/auth/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Continue to Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _retryCallback,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}
