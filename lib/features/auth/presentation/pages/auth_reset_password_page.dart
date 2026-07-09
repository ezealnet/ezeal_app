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
import '../../../../core/validators/app_validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_brand_panel.dart';
import '../widgets/responsive_auth_button_wrapper.dart';

class AuthResetPasswordPage extends ConsumerStatefulWidget {
  const AuthResetPasswordPage({super.key});

  @override
  ConsumerState<AuthResetPasswordPage> createState() => _AuthResetPasswordPageState();
}

class _AuthResetPasswordPageState extends ConsumerState<AuthResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isReady = false;
  bool _isExpired = false;
  bool _isCodeVerifierError = false;

  StreamSubscription<AuthState>? _authSubscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();

    final uri = Uri.base;
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    final errorCode = uri.queryParameters['error_code'];
    final type = uri.queryParameters['type'];
    final fragment = uri.fragment;

    final currentSession = Supabase.instance.client.auth.currentSession;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (kDebugMode) {
      print('DEBUG: [ResetPassword] Recovery Started');
      print('DEBUG: [ResetPassword] Recovery URL:\n$uri\n');
      print('DEBUG: [ResetPassword] code exists:\n${code != null}\n');
      print('DEBUG: [ResetPassword] type:\n$type\n');
      print('DEBUG: [ResetPassword] error:\n$error\n');
      print('DEBUG: [ResetPassword] error_code:\n$errorCode\n');
      print('DEBUG: [ResetPassword] fragment:\n$fragment\n');
      print('DEBUG: [ResetPassword] currentSession:\n${currentSession != null}\n');
      print('DEBUG: [ResetPassword] currentUser:\n${currentUser != null}');
    }

    // 1. Expired Link check
    if (errorCode == 'otp_expired' || error == 'access_denied' || errorCode == 'access_denied') {
      if (kDebugMode) {
        print('DEBUG: [ResetPassword] Invalid recovery session.');
      }
      setState(() {
        _isLoading = false;
        _isReady = false;
        _isExpired = true;
      });
      return;
    }

    // 2. PKCE Exchange
    if (code != null && code.isNotEmpty) {
      if (kDebugMode) {
        print('DEBUG: [ResetPassword] PKCE Code Found');
      }
      _exchangePKCECode(code);
      return;
    }

    // 3. Synchronous restoration check fallback
    final isRecoveryFromUrl = fragment.contains('type=recovery') || fragment.contains('recovery') || type == 'recovery';
    if (currentSession != null && isRecoveryFromUrl) {
      if (kDebugMode) {
        print('DEBUG: [ResetPassword] Active recovery session detected synchronously on load.');
        print('DEBUG: [ResetPassword] Session Restored');
      }
      setState(() {
        _isReady = true;
        _isLoading = false;
        _isExpired = false;
      });
      return;
    }

    // 4. Fallback listener
    _startFallbackListener();
  }

  void _startFallbackListener() {
    _timeoutTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (!_isReady) {
        if (kDebugMode) {
          print('DEBUG: [ResetPassword] Recovery timeout.');
          print('DEBUG: [ResetPassword] Invalid recovery session.');
        }
        setState(() {
          _isLoading = false;
          _isReady = false;
          _isExpired = true;
        });
      }
    });

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (kDebugMode) {
        print('DEBUG: [ResetPassword] AuthStateChange: event=$event, session=${session != null}');
      }

      if (event == AuthChangeEvent.passwordRecovery && session != null) {
        if (kDebugMode) {
          print('DEBUG: [ResetPassword] Recovery event received: passwordRecovery');
          print('DEBUG: [ResetPassword] Session Restored');
        }
        _timeoutTimer?.cancel();
        setState(() {
          _isReady = true;
          _isLoading = false;
          _isExpired = false;
        });
      }
    });
  }

  Future<void> _exchangePKCECode(String code) async {
    if (kDebugMode) {
      print('DEBUG: [ResetPassword] Exchange Started');
    }
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
      
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (kDebugMode) {
        print('DEBUG: [ResetPassword] Exchange Success');
        print('DEBUG: [ResetPassword] Session Exists: ${session != null}');
        print('DEBUG: [ResetPassword] User Exists: ${user != null}');
      }

      if (session != null) {
        if (mounted) {
          setState(() {
            _isReady = true;
            _isLoading = false;
            _isExpired = false;
            _isCodeVerifierError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isReady = false;
            _isExpired = true;
            _isCodeVerifierError = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: [ResetPassword] Exchange Failed: $e');
      }
      final errStr = e.toString().toLowerCase();
      final isCodeVerifierMissing = errStr.contains('code verifier') ||
          errStr.contains('code_verifier') ||
          errStr.contains('verifier could not be found');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReady = false;
          _isExpired = true;
          _isCodeVerifierError = isCodeVerifierMissing;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _timeoutTimer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).updatePassword(
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (!mounted) return;

      if (success) {
        if (kDebugMode) {
          print('DEBUG: [ResetPassword] Password Updated');
          print('DEBUG: [ResetPassword] Recovery Finished');
          print('DEBUG: [ResetPassword] Redirect to login');
        }
        SnackbarHelper.showSuccess(
          context,
          'Password Updated Successfully',
        );
        context.go('/auth/login');
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    }
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
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
          'Restoring password reset session...',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExpiredState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _isCodeVerifierError ? 'Reset Link Invalid' : 'Reset Link Expired',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _isCodeVerifierError
              ? 'This password reset link could not be verified. Please request a new password reset email.'
              : 'This password reset link has expired or has already been used. Please request a new password reset email.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        ResponsiveAuthButtonWrapper(
          child: _buildPrimaryButton(
            text: 'Request New Reset Link',
            onPressed: () {
              context.go('/auth/login');
              // Let the UI open directly in Forgot Password mode where they can request a new link
              // By routing to /auth/login and prompting them.
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ResponsiveAuthButtonWrapper(
          child: _buildSecondaryButton(
            text: 'Back to Sign In',
            onPressed: () => context.go('/auth/login'),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyState(bool isUpdating) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(
              Icons.lock_reset_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Create New Password',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter a new password for your Ezeal account.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthTextField(
            labelText: 'New Password',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            labelText: 'Confirm Password',
            controller: _confirmPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) => AppValidators.confirmPassword(val, _passwordController.text),
          ),
          const SizedBox(height: AppSpacing.xl),
          ResponsiveAuthButtonWrapper(
            child: _buildPrimaryButton(
              text: 'Update Password',
              isLoading: isUpdating,
              onPressed: isUpdating ? null : _handleUpdatePassword,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => context.go('/auth/login'),
            child: const Text('Back to Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    Widget activeCardContent;
    if (_isLoading) {
      activeCardContent = _buildLoadingState();
    } else if (_isExpired) {
      activeCardContent = _buildExpiredState();
    } else {
      activeCardContent = _buildReadyState(state.isLoading);
    }

    final cardContent = AuthCard(child: activeCardContent);

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
