import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../data/models/cart_item_model.dart';

class CartState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const CartState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  CartState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final cartItemsProvider = FutureProvider<List<CartItem>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }

  try {
    final response = await Supabase.instance.client
        .from('assessment_cart_items')
        .select('*, assessments(*)')
        .order('created_at', ascending: true);

    return (response as List).map((json) => CartItem.fromJson(json as Map<String, dynamic>)).toList();
  } catch (e) {
    if (kDebugMode) {
      print('cartItemsProvider: Error fetching cart items: $e');
    }
    rethrow;
  }
});

class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  Future<bool> addToCart(String assessmentId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in to add items to the cart.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // Fetch current cart items to validate limit and duplicates
      final currentItems = await ref.read(cartItemsProvider.future);
      
      // Check duplicate
      if (currentItems.any((item) => item.assessmentId == assessmentId)) {
        state = state.copyWith(isLoading: false, errorMessage: 'Assessment is already in your cart.');
        return false;
      }

      // Check limit
      if (currentItems.length >= 5) {
        state = state.copyWith(isLoading: false, errorMessage: 'Your cart cannot hold more than 5 assessments.');
        return false;
      }

      await Supabase.instance.client.from('assessment_cart_items').insert({
        'user_id': user.id,
        'assessment_id': assessmentId,
      });

      ref.invalidate(cartItemsProvider);
      await ref.read(cartItemsProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CartController.addToCart: Error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to add item to cart. Please try again.',
      );
      return false;
    }
  }

  Future<bool> removeFromCart(String assessmentId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in to modify the cart.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      await Supabase.instance.client
          .from('assessment_cart_items')
          .delete()
          .eq('user_id', user.id)
          .eq('assessment_id', assessmentId);

      ref.invalidate(cartItemsProvider);
      await ref.read(cartItemsProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CartController.removeFromCart: Error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to remove item from cart. Please try again.',
      );
      return false;
    }
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(() {
  return CartController();
});
