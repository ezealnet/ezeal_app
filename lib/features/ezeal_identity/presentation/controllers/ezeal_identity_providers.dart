import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../data/models/ezeal_identity_model.dart';

class EzealIdentityState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const EzealIdentityState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  EzealIdentityState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return EzealIdentityState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final ezealIdentityProvider = FutureProvider<EzealIdentity?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('ezeal_identities')
        .select()
        .eq('user_id', user.id)
        .eq('role_type', 'student')
        .maybeSingle();

    if (response == null) return null;
    return EzealIdentity.fromJson(response);
  } catch (e) {
    if (kDebugMode) {
      print('ezealIdentityProvider: Error fetching identity: $e');
    }
    return null;
  }
});

class EzealIdentityController extends Notifier<EzealIdentityState> {
  @override
  EzealIdentityState build() {
    return const EzealIdentityState();
  }

  Future<String> generateStudentEzealId() async {
    try {
      // TODO: Replace with production-safe database sequence / RPC before production.
      final countResponse = await Supabase.instance.client
          .from('ezeal_identities')
          .select('id')
          .eq('role_type', 'student');
      final count = (countResponse as List).length;
      final sequence = count + 1;
      final paddedSequence = sequence.toString().padLeft(6, '0');
      final year = DateTime.now().year;
      return 'EZL-$year-STU-$paddedSequence';
    } catch (e) {
      if (kDebugMode) {
        print('EzealIdentityController.generateStudentEzealId error: $e');
      }
      return 'EZL-2026-STU-000001';
    }
  }

  Future<bool> verifyMockAadhaarAndCreateId({
    required String aadhaar,
    required String otp,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    // Validation
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'\s+'), '');
    if (cleanAadhaar.length != 12 || int.tryParse(cleanAadhaar) == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 12-digit Aadhaar number.',
      );
      return false;
    }

    if (otp != '123456') {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP. Use 123456 for mock verification.',
      );
      return false;
    }

    try {
      final ezealId = await generateStudentEzealId();

      // Store only verification details, do not store Aadhaar number or OTP
      // TODO: Replace mock Aadhaar with real KYC provider via Supabase Edge Function.
      await Supabase.instance.client.from('ezeal_identities').insert({
        'user_id': user.id,
        'ezeal_id': ezealId,
        'role_type': 'student',
        'aadhaar_verified': true,
        'verification_status': 'verified',
        'verification_provider': 'mock',
        'verification_reference': 'mock_verified',
        'verified_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(ezealIdentityProvider);
      await ref.read(ezealIdentityProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('EzealIdentityController.verifyMockAadhaarAndCreateId error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to verify identity. Please try again.',
      );
      return false;
    }
  }
}

final ezealIdentityControllerProvider =
    NotifierProvider<EzealIdentityController, EzealIdentityState>(() {
  return EzealIdentityController();
});
