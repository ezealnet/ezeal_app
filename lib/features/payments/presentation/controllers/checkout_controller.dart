import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../cart/presentation/controllers/cart_providers.dart';
import '../../../ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';
import '../../../assessment_access/presentation/controllers/assessment_access_providers.dart';
import '../../../assessments/presentation/controllers/assessments_providers.dart';

class CheckoutState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const CheckoutState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    return const CheckoutState();
  }

  Future<bool> processMockPayment({
    required int amount,
    required List<String> assessmentIds,
    required bool simulateSuccess,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // Verify student has a verified Ezeal ID
      final identityAsync = ref.read(ezealIdentityProvider);
      final identity = identityAsync.asData?.value;
      if (identity == null || !identity.aadhaarVerified || identity.verificationStatus != 'verified') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You must have a verified Ezeal ID before purchase.',
        );
        return false;
      }

      if (simulateSuccess) {
        // TODO: Move payment logic to Supabase Edge Functions before production
        // TODO: Replace mock payment with Cashfree/Zoho gateway adapter

        // Create paid order
        final orderResponse = await Supabase.instance.client.from('orders').insert({
          'user_id': user.id,
          'ezeal_identity_id': identity.id,
          'amount': amount,
          'status': 'paid',
          'access_source': 'individual',
        }).select().single();

        final orderId = orderResponse['id'] as String;

        // Create payment record
        await Supabase.instance.client.from('payments').insert({
          'order_id': orderId,
          'provider': 'mock',
          'provider_payment_id': 'mock_pay_id_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'status': 'success',
        });

        // Unlock assessment_access records
        final accessRecords = assessmentIds.map((assessmentId) => {
          'user_id': user.id,
          'assessment_id': assessmentId,
          'ezeal_identity_id': identity.id,
          'order_id': orderId,
          'access_source': 'individual',
          'status': 'unlocked',
        }).toList();

        await Supabase.instance.client.from('assessment_access').insert(accessRecords);

        // Clear cart items in Supabase
        await Supabase.instance.client
            .from('assessment_cart_items')
            .delete()
            .eq('user_id', user.id);

        ref.invalidate(cartItemsProvider);
        ref.invalidate(assessmentAccessProvider);
        ref.invalidate(assessmentListProvider);
        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      } else {
        // Create failed order
        await Supabase.instance.client.from('orders').insert({
          'user_id': user.id,
          'ezeal_identity_id': identity.id,
          'amount': amount,
          'status': 'failed',
          'access_source': 'individual',
        });

        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Mock payment failed. Access was not unlocked.',
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('CheckoutController.processMockPayment error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred during checkout. Please try again.',
      );
      return false;
    }
  }
}

final checkoutControllerProvider = NotifierProvider<CheckoutController, CheckoutState>(() {
  return CheckoutController();
});
