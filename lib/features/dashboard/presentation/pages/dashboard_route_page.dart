import 'dart:async';
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
import '../../../auth/presentation/widgets/auth_card.dart';
import '../../../auth/presentation/widgets/auth_brand_panel.dart';

class DashboardRoutePage extends ConsumerStatefulWidget {
  const DashboardRoutePage({super.key});

  @override
  ConsumerState<DashboardRoutePage> createState() => _DashboardRoutePageState();
}

class _DashboardRoutePageState extends ConsumerState<DashboardRoutePage> {
  Timer? _timeoutTimer;
  bool _navigationStarted = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('DEBUG: [DashboardRoutePage] dashboard resolver initialized');
    }
    
    // Start resolver timeout (9 seconds)
    _timeoutTimer = Timer(const Duration(seconds: 9), _onTimeout);

    // Initial state check in case provider is already resolved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialState();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _onTimeout() {
    if (!mounted || _navigationStarted) return;
    if (kDebugMode) {
      print('DEBUG: [DashboardRoutePage] timeout reached');
    }
    setState(() {
      _hasError = true;
      _errorMessage = 'We could not finish setting up your profile (Timeout).';
    });
  }

  void _checkInitialState() {
    if (!mounted || _navigationStarted) return;
    
    final profileAsync = ref.read(currentProfileProvider);
    
    if (kDebugMode) {
      print('DEBUG: [DashboardRoutePage] Checking initial state: isLoading = ${profileAsync.isLoading}, hasValue = ${profileAsync.hasValue}');
    }

    if (profileAsync.hasValue && !profileAsync.isLoading) {
      final profile = profileAsync.value;
      if (profile != null) {
        _performRedirect(profile.role);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'We could not find or recover a profile for this user.';
        });
      }
    } else if (profileAsync.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = profileAsync.error.toString();
      });
    }
  }

  void _performRedirect(UserRole role) {
    if (_navigationStarted) return;
    _navigationStarted = true;
    _timeoutTimer?.cancel();
    
    final path = _getDashboardPath(role);
    if (kDebugMode) {
      print('DEBUG: [DashboardRoutePage] resolved role: $role');
      print('DEBUG: [DashboardRoutePage] final route: $path');
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

  Future<void> _retrySetup() async {
    if (!mounted) return;
    setState(() {
      _isRetrying = true;
      _hasError = false;
      _errorMessage = null;
    });

    if (kDebugMode) {
      print('DEBUG: [DashboardRoutePage] Retrying setup, invalidating currentProfileProvider');
    }

    // Reset timeout timer
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 9), _onTimeout);

    ref.invalidate(currentProfileProvider);

    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (kDebugMode) {
        print('DEBUG: [DashboardRoutePage] Retry complete. Profile resolves: ${profile?.email}');
      }
      if (profile != null) {
        _performRedirect(profile.role);
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'We could not find or recover a profile for this user.';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: [DashboardRoutePage] Retry recovery failed: $e');
      }
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unable to resolve profile. Please contact support or retry.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    _timeoutTimer?.cancel();
    if (kDebugMode) {
      print('DEBUG: [DashboardRoutePage] Sign out triggered');
    }
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic state listener
    ref.listen<AsyncValue<UserProfile?>>(currentProfileProvider, (previous, next) {
      if (kDebugMode) {
        print('DEBUG: [DashboardRoutePage] provider updated. isLoading = ${next.isLoading}, hasError = ${next.hasError}, hasValue = ${next.hasValue}');
      }

      if (_navigationStarted || _hasError) return;

      next.when(
        data: (profile) {
          if (profile != null) {
            _performRedirect(profile.role);
          } else {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = 'We could not find or recover a profile for this user.';
              });
            }
          }
        },
        loading: () {},
        error: (err, stack) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Profile setup error. Please contact administrator.';
            });
          }
        },
      );
    });

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final cardContent = AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasError) ...[
            const Center(
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'We could not finish setting up your profile',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'An unexpected error occurred resolving your user details.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _retrySetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Retry Setup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
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
              'Preparing your Ezeal dashboard...',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isRetrying ? 'Retrying profile setup...' : 'Please wait while we resolve your session role.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
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
