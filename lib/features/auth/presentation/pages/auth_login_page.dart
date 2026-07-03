import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/config/auth_config.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_brand_panel.dart';
import '../widgets/responsive_auth_button_wrapper.dart';

class AuthLoginPage extends ConsumerStatefulWidget {
  const AuthLoginPage({super.key});

  @override
  ConsumerState<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends ConsumerState<AuthLoginPage> {
  bool _isForgotPasswordMode = false;
  Timer? _forgotPasswordTimer;
  int _forgotPasswordCooldown = 0;
  Timer? _resendVerificationTimer;
  int _resendVerificationCooldown = 0;

  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _forgotFormKey = GlobalKey<FormState>();
  final _forgotEmailController = TextEditingController();

  @override
  void dispose() {
    _forgotPasswordTimer?.cancel();
    _resendVerificationTimer?.cancel();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  void _startForgotPasswordCooldown() {
    setState(() {
      _forgotPasswordCooldown = 60;
    });
    _forgotPasswordTimer?.cancel();
    _forgotPasswordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_forgotPasswordCooldown > 1) {
        setState(() {
          _forgotPasswordCooldown--;
        });
      } else {
        setState(() {
          _forgotPasswordCooldown = 0;
        });
        timer.cancel();
      }
    });
  }

  void _startResendVerificationCooldown() {
    setState(() {
      _resendVerificationCooldown = 60;
    });
    _resendVerificationTimer?.cancel();
    _resendVerificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendVerificationCooldown > 1) {
        setState(() {
          _resendVerificationCooldown--;
        });
      } else {
        setState(() {
          _resendVerificationCooldown = 0;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _handleSignIn() async {
    if (_signInFormKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).login(
            email: _signInEmailController.text.trim(),
            password: _signInPasswordController.text,
          );
      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Welcome back to Ezeal.');
        context.go('/dashboard');
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Unable to sign in. Please check your email and password.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  Future<void> _handleResendVerification() async {
    final emailErr = AppValidators.email(_signInEmailController.text.trim());
    if (emailErr != null) {
      SnackbarHelper.showError(context, emailErr);
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).resendVerificationEmail(
          email: _signInEmailController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      SnackbarHelper.showSuccess(context, 'Account verification link sent. Please check your inbox.');
      _startResendVerificationCooldown();
    } else {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
      SnackbarHelper.showError(context, err);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_forgotFormKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).forgotPassword(
            email: _forgotEmailController.text.trim(),
          );
      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Password reset email sent. Please check your inbox.');
        _startForgotPasswordCooldown();
        setState(() {
          _isForgotPasswordMode = false;
        });
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
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
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isForgotPasswordMode) ...[
            _buildForgotPasswordForm(state.isLoading),
          ] else ...[
            _buildSignInForm(state.isLoading),
          ],

          // Developer Quick Login - Debug Mode Only
          if (kDebugMode && AuthConfig.showDeveloperTools) ...[
            const Divider(height: AppSpacing.xl),
            Text(
              'Developer Quick Login - Debug Only',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).devLogin(UserRole.student);
                      context.go('/student/dashboard');
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Student', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).devLogin(UserRole.admin);
                      context.go('/admin/dashboard');
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Admin', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).devLogin(UserRole.institution);
                      context.go('/institution/dashboard');
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Institution', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],

          // Footer Terms and Privacy links
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const Text('•', style: TextStyle(color: AppColors.textSecondaryLight)),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
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
                    // Mobile Branding Above Card
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Discover Your True Potential',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'AI-powered Human Potential Intelligence Platform helping students understand their strengths, personality, and career direction.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildSignInForm(bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Sign in to continue your journey.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthTextField(
            labelText: 'Email Address',
            controller: _signInEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthTextField(
            labelText: 'Password',
            controller: _signInPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _isForgotPasswordMode = true),
              child: Text(
                'Forgot password?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ResponsiveAuthButtonWrapper(
            child: _buildPrimaryButton(
              text: 'Sign In',
              isLoading: isLoading,
              onPressed: _handleSignIn,
            ),
          ),
          if (AuthConfig.emailConfirmationEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: (_resendVerificationCooldown > 0 || isLoading)
                    ? null
                    : _handleResendVerification,
                child: Text(
                  _resendVerificationCooldown > 0
                      ? 'Resend Verification Email (Wait ${_resendVerificationCooldown}s)'
                      : 'Resend Verification Email',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ResponsiveAuthButtonWrapper(
            child: _buildSecondaryButton(
              text: 'Create Account',
              onPressed: () => context.go('/auth/signup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm(bool isLoading) {
    return Form(
      key: _forgotFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Trouble Logging In?',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter your email and we will send you a password reset link.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthTextField(
            labelText: 'Email Address',
            controller: _forgotEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.lg),
          ResponsiveAuthButtonWrapper(
            child: _buildPrimaryButton(
              text: _forgotPasswordCooldown > 0
                  ? 'Send Reset Link (Wait ${_forgotPasswordCooldown}s)'
                  : 'Send Reset Link',
              isLoading: isLoading,
              onPressed: (_forgotPasswordCooldown > 0 || isLoading)
                  ? null
                  : _handleForgotPassword,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() => _isForgotPasswordMode = false),
            child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
