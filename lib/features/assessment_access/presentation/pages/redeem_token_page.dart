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
import '../controllers/assessment_access_providers.dart';

class RedeemTokenPage extends ConsumerStatefulWidget {
  const RedeemTokenPage({super.key});

  @override
  ConsumerState<RedeemTokenPage> createState() => _RedeemTokenPageState();
}

class _RedeemTokenPageState extends ConsumerState<RedeemTokenPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitRedeem() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(tokenRedeemControllerProvider.notifier);
    final success = await controller.redeemToken(_tokenController.text.trim());

    if (mounted) {
      if (success) {
        SnackbarHelper.showSuccess(context, 'Token redeemed successfully! Assessment unlocked.');
        context.go('/student/access');
      } else {
        final error = ref.read(tokenRedeemControllerProvider).errorMessage ?? 'Invalid or expired token.';
        SnackbarHelper.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tokenRedeemControllerProvider);

    return AppScaffold(
      title: 'Redeem Token',
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
                        const Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 36),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Redeem Token',
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
                      'If your school or counsellor has purchased assessments for you, enter the token code below to unlock them.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      labelText: 'Token Code',
                      hintText: 'e.g. MOCK-TOKEN-RIASEC',
                      controller: _tokenController,
                      prefixIcon: Icons.confirmation_number_outlined,
                      enabled: !state.isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a token code.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Redeem Token & Unlock',
                        isLoading: state.isLoading,
                        onPressed: state.isLoading ? null : _submitRedeem,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        'Note: Tokens can only be redeemed once per student.',
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
