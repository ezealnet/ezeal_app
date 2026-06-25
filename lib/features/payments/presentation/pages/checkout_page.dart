import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../cart/presentation/controllers/cart_providers.dart';
import '../../../cart/domain/assessment_pricing_service.dart';
import '../../../ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';
import '../controllers/checkout_controller.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemsAsync = ref.watch(cartItemsProvider);
    final identityAsync = ref.watch(ezealIdentityProvider);
    final checkoutState = ref.watch(checkoutControllerProvider);
    final isMobile = ResponsiveBuilder.isMobile(context);

    return AppScaffold(
      title: 'Checkout',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: identityAsync.when(
            data: (identity) {
              if (identity == null || !identity.aadhaarVerified || identity.verificationStatus != 'verified') {
                return Center(
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text('Verification Required', style: AppTextStyles.titleLarge),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        text: 'Verify Identity Now',
                        onPressed: () => context.go('/student/verify-identity'),
                      ),
                    ],
                  ),
                );
              }

              return cartItemsAsync.when(
                data: (cartItems) {
                  if (cartItems.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondaryLight),
                          const SizedBox(height: AppSpacing.md),
                          Text('Your cart is empty.', style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: 'Back to Marketplace',
                            onPressed: () => context.go('/student/assessments'),
                          ),
                        ],
                      ),
                    );
                  }

                  final int itemCount = cartItems.length;
                  final int finalTotal = AssessmentPricingService.calculateCartTotal(itemCount);

                  final itemsWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Assessments',
                        style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...cartItems.map((item) {
                        final assessment = item.assessment;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assessment?.title ?? 'Assessment',
                                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        assessment?.assessmentType ?? '',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${assessment?.basePrice ?? 299}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );

                  final summaryCardWidget = AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ezeal ID', style: AppTextStyles.bodyMedium),
                            Text(
                              identity.ezealId,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '₹$finalTotal',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Mock Payment Simulation',
                          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'Simulate Success (Pay Now)',
                            isLoading: checkoutState.isLoading,
                            onPressed: checkoutState.isLoading
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(checkoutControllerProvider.notifier)
                                        .processMockPayment(
                                          amount: finalTotal,
                                          assessmentIds: cartItems
                                              .map((e) => e.assessmentId)
                                              .toList(),
                                          simulateSuccess: true,
                                        );
                                    if (context.mounted) {
                                      if (success) {
                                        SnackbarHelper.showSuccess(context, 'Mock payment succeeded. Assessments unlocked!');
                                        context.go('/student/access');
                                      } else {
                                        final error = ref.read(checkoutControllerProvider).errorMessage ?? 'Payment failed';
                                        SnackbarHelper.showError(context, error);
                                      }
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            text: 'Simulate Failure',
                            isLoading: checkoutState.isLoading,
                            style: AppButtonStyle.outlined,
                            onPressed: checkoutState.isLoading
                                ? null
                                : () async {
                                    final success = await ref
                                        .read(checkoutControllerProvider.notifier)
                                        .processMockPayment(
                                          amount: finalTotal,
                                          assessmentIds: cartItems
                                              .map((e) => e.assessmentId)
                                              .toList(),
                                          simulateSuccess: false,
                                        );
                                    if (context.mounted) {
                                      if (!success) {
                                        final error = ref.read(checkoutControllerProvider).errorMessage ?? 'Mock payment failed.';
                                        SnackbarHelper.showError(context, error);
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        itemsWidget,
                        const SizedBox(height: AppSpacing.lg),
                        summaryCardWidget,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: itemsWidget,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 1,
                        child: summaryCardWidget,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading cart details: $err'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading identity: $err'),
          ),
        ),
      ),
    );
  }
}
