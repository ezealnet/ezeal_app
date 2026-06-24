import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../controllers/ezeal_identity_providers.dart';

class VerifyIdentityPage extends ConsumerStatefulWidget {
  const VerifyIdentityPage({super.key});

  @override
  ConsumerState<VerifyIdentityPage> createState() => _VerifyIdentityPageState();
}

class _VerifyIdentityPageState extends ConsumerState<VerifyIdentityPage> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(ezealIdentityControllerProvider.notifier);
    final success = await controller.verifyMockAadhaarAndCreateId(
      aadhaar: _aadhaarController.text.trim(),
      otp: _otpController.text.trim(),
    );

    if (mounted) {
      if (success) {
        SnackbarHelper.showSuccess(context, 'Identity verified successfully. Your Ezeal ID has been created.');
        context.go('/student/assessments');
      } else {
        final errorMsg = ref.read(ezealIdentityControllerProvider).errorMessage ?? 'Unable to verify identity. Please try again.';
        SnackbarHelper.showError(context, errorMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ezealIdentityControllerProvider);

    return AppScaffold(
      title: 'Identity Verification',
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 36),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Verify Your Identity',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Verification is required before taking official Ezeal assessments.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      labelText: 'Aadhaar Number',
                      hintText: 'Enter 12-digit Aadhaar number',
                      controller: _aadhaarController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.credit_card,
                      enabled: !state.isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your Aadhaar number.';
                        }
                        final clean = value.replaceAll(RegExp(r'\s+'), '');
                        if (clean.length != 12 || int.tryParse(clean) == null) {
                          return 'Please enter a valid 12-digit Aadhaar number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      labelText: 'OTP Verification',
                      hintText: 'Use 123456 for mock verification',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.lock_outline,
                      enabled: !state.isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the OTP sent to your Aadhaar-linked mobile.';
                        }
                        if (value.trim() != '123456') {
                          return 'Invalid OTP. Use 123456 for mock verification.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Verify & Generate Ezeal ID',
                        isLoading: state.isLoading,
                        onPressed: state.isLoading ? null : _submitVerification,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        'Note: We do not store your Aadhaar details.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
