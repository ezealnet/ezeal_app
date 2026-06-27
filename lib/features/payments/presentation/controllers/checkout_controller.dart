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
        final paymentRes = await Supabase.instance.client.from('payments').insert({
          'order_id': orderId,
          'provider': 'mock',
          'provider_payment_id': 'mock_pay_id_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'status': 'success',
        }).select().maybeSingle();
        final paymentId = paymentRes?['id'] as String? ?? 'mock_payment_id';

        // Unlock assessment_access records
        final accessRecords = assessmentIds.map((assessmentId) => {
          'user_id': user.id,
          'assessment_id': assessmentId,
          'ezeal_identity_id': identity.id,
          'order_id': orderId,
          'access_source': 'individual',
          'status': 'unlocked',
        }).toList();

        int insertedCount = 0;
        try {
          final insertResult = await Supabase.instance.client
              .from('assessment_access')
              .insert(accessRecords)
              .select();
          insertedCount = (insertResult as List).length;
        } on PostgrestException catch (pe) {
          if (pe.code == '23505') {
            if (kDebugMode) {
              print('checkout_controller: duplicate key error 23505 caught. Access already exists, ignoring.');
            }
            final existingRows = await Supabase.instance.client
                .from('assessment_access')
                .select()
                .eq('user_id', user.id)
                .inFilter('assessment_id', assessmentIds);
            insertedCount = (existingRows as List).length;
          } else {
            rethrow;
          }
        } catch (e) {
          if (kDebugMode) {
            print('checkout_controller: Error inserting assessment_access: $e');
          }
          rethrow;
        }

        if (kDebugMode) {
          print('--- DEBUG CHECKOUT SUCCESS ---');
          print('Current User ID: ${user.id}');
          print('Selected Cart Item Count: ${assessmentIds.length}');
          print('Created Order ID: $orderId');
          print('Created Payment ID: $paymentId');
          print('Assessment Access Insert Payload: $accessRecords');
          print('Inserted/Updated Assessment Access Row Count: $insertedCount');
          print('------------------------------');
        }

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
