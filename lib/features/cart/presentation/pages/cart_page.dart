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
import '../../domain/assessment_pricing_service.dart';
import '../controllers/cart_providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemsAsync = ref.watch(cartItemsProvider);
    final cartState = ref.watch(cartControllerProvider);
    final isMobile = ResponsiveBuilder.isMobile(context);

    return AppScaffold(
      title: 'My Cart',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: cartItemsAsync.when(
            data: (cartItems) {
              if (cartItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 72,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Your cart is empty',
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Explore our assessments in the marketplace and add them to your cart.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          text: 'Browse Assessments',
                          onPressed: () => context.go('/student/assessments'),
                          width: 220,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Compute prices
              final int itemCount = cartItems.length;
              final List<int> basePrices = cartItems.map((item) => item.assessment?.basePrice ?? 299).toList();
              final int baseSubtotal = basePrices.fold(0, (sum, p) => sum + p);
              final int finalTotal = AssessmentPricingService.calculateCartTotal(itemCount);
              final int discount = AssessmentPricingService.calculateDiscount(itemCount, basePrices);

              // Layout widgets
              final itemsListWidget = Column(
                children: cartItems.map((item) {
                  final assessment = item.assessment;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assessment?.title ?? 'Career Assessment',
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  assessment?.description ?? '',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      ),
                                      child: Text(
                                        assessment?.assessmentType ?? '',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      '${assessment?.durationMinutes ?? 30} mins',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${assessment?.basePrice ?? 299}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                tooltip: 'Remove from cart',
                                onPressed: cartState.isLoading
                                    ? null
                                    : () async {
                                        final success = await ref
                                            .read(cartControllerProvider.notifier)
                                            .removeFromCart(item.assessmentId);
                                        if (context.mounted) {
                                          if (success) {
                                            SnackbarHelper.showInfo(context, 'Removed assessment from cart.');
                                          } else {
                                            final error = ref.read(cartControllerProvider).errorMessage ?? 'Error removing item';
                                            SnackbarHelper.showError(context, error);
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );

              final summaryCardWidget = AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Selected Tests ($itemCount)', style: AppTextStyles.bodyMedium),
                        Text('₹$baseSubtotal', style: AppTextStyles.bodyLarge),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Package Discount',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
                          ),
                          Text(
                            '-₹$discount',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable',
                          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹$finalTotal',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (discount > 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          '🎉 You save ₹$discount with package pricing!',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Continue to Verification',
                        onPressed: null, // Disabled in this phase
                        style: AppButtonStyle.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Aadhaar verification and payment processing will unlock in the next phase.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );

              if (isMobile) {
                return Column(
                  children: [
                    itemsListWidget,
                    const SizedBox(height: AppSpacing.lg),
                    summaryCardWidget,
                  ],
                );
              }

              // Desktop layout split column
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: itemsListWidget,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 1,
                    child: summaryCardWidget,
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Text('Error loading cart items: $err', style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
