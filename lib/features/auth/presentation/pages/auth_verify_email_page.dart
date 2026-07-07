import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_brand_panel.dart';
import '../widgets/responsive_auth_button_wrapper.dart';

class AuthVerifyEmailPage extends ConsumerStatefulWidget {
  final String email;

  const AuthVerifyEmailPage({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<AuthVerifyEmailPage> createState() => _AuthVerifyEmailPageState();
}

class _AuthVerifyEmailPageState extends ConsumerState<AuthVerifyEmailPage> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Automatically start cooldown on page load to prevent instant spamming
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 1) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        setState(() {
          _cooldownSeconds = 0;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    final success = await ref.read(authControllerProvider.notifier).resendVerificationEmail(
          email: widget.email.trim(),
        );

    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'Verification email sent. Please check your inbox.');
      _startCooldown();
    } else {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
      SnackbarHelper.showError(context, err);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final cardContent = AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Email Verification Icon
          const Center(
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Verify your email',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Display target email safely
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.email,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            "We've sent a verification link to your email. Please verify your email before signing in.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          ResponsiveAuthButtonWrapper(
            child: _buildPrimaryButton(
              text: _cooldownSeconds > 0
                  ? 'Resend Verification (Wait ${_cooldownSeconds}s)'
                  : 'Resend Verification Email',
              isLoading: state.isLoading,
              onPressed: _cooldownSeconds > 0 ? null : _handleResend,
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
