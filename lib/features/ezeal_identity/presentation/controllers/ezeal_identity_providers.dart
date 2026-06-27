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

  static int parseStudentSequence(String ezealId, int year) {
    try {
      final prefix = 'EZL-$year-STU-';
      if (ezealId.startsWith(prefix)) {
        final seqStr = ezealId.substring(prefix.length);
        return int.tryParse(seqStr) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<String> generateStudentEzealId({int? customYear}) async {
    final year = customYear ?? DateTime.now().year;
    try {
      // TODO: Replace this with Supabase RPC/database sequence before production.
      final response = await Supabase.instance.client
          .from('ezeal_identities')
          .select('ezeal_id')
          .eq('role_type', 'student');

      final list = response as List;
      int maxSeq = 0;
      for (final item in list) {
        final String ezealId = item['ezeal_id'] as String? ?? '';
        final seq = parseStudentSequence(ezealId, year);
        if (seq > maxSeq) {
          maxSeq = seq;
        }
      }
      final nextSeq = maxSeq + 1;
      final paddedSequence = nextSeq.toString().padLeft(6, '0');
      return 'EZL-$year-STU-$paddedSequence';
    } catch (e) {
      if (kDebugMode) {
        print('EzealIdentityController.generateStudentEzealId error: $e');
      }
      return 'EZL-$year-STU-000001';
    }
  }

  Future<EzealIdentity?> verifyMockAadhaarAndCreateId({
    required String aadhaar,
    required String otp,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    // 1. Idempotency Check: Before creating a new identity, check if the current user already has a verified student identity.
    try {
      final existing = await Supabase.instance.client
          .from('ezeal_identities')
          .select()
          .eq('user_id', user.id)
          .eq('role_type', 'student')
          .maybeSingle();

      if (existing != null) {
        ref.invalidate(ezealIdentityProvider);
        await ref.read(ezealIdentityProvider.future);
        state = state.copyWith(isLoading: false, isSuccess: true);
        return EzealIdentity.fromJson(existing);
      }
    } catch (e) {
      if (kDebugMode) {
        print('EzealIdentityController idempotency check error: $e');
      }
    }

    // Validation
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'\s+'), '');
    if (cleanAadhaar.length != 12 || int.tryParse(cleanAadhaar) == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid 12-digit Aadhaar number.',
      );
      return null;
    }

    if (otp != '123456') {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP. Use 123456 for mock verification.',
      );
      return null;
    }

    // 2. Retry-safe insert logic
    int attempt = 0;
    bool insertSuccess = false;
    String generatedEzealId = '';
    final int year = DateTime.now().year;
    Map<String, dynamic>? insertedRow;

    try {
      // Find initial maximum sequence
      final response = await Supabase.instance.client
          .from('ezeal_identities')
          .select('ezeal_id')
          .eq('role_type', 'student');

      final list = response as List;
      int maxSeq = 0;
      for (final item in list) {
        final String ezealId = item['ezeal_id'] as String? ?? '';
        final seq = parseStudentSequence(ezealId, year);
        if (seq > maxSeq) {
          maxSeq = seq;
        }
      }

      int nextSeq = maxSeq + 1;

      while (attempt < 5 && !insertSuccess) {
        generatedEzealId = 'EZL-$year-STU-${nextSeq.toString().padLeft(6, '0')}';

        try {
          // TODO: Replace this with Supabase RPC/database sequence before production.
          insertedRow = await Supabase.instance.client.from('ezeal_identities').insert({
            'user_id': user.id,
            'ezeal_id': generatedEzealId,
            'role_type': 'student',
            'aadhaar_verified': true,
            'verification_status': 'verified',
            'verification_provider': 'mock',
            'verification_reference': 'mock_verified',
            'verified_at': DateTime.now().toIso8601String(),
          }).select().single();
          insertSuccess = true;
        } catch (e) {
          if (e is PostgrestException && e.code == '23505') {
            // Unique key violation
            attempt++;
            nextSeq++;
            if (kDebugMode) {
              print('Duplicate key violation ($generatedEzealId). Retrying... Attempt $attempt/5');
            }
          } else {
            rethrow;
          }
        }
      }

      if (!insertSuccess || insertedRow == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to generate Ezeal ID. Please try again.',
        );
        return null;
      }

      ref.invalidate(ezealIdentityProvider);
      await ref.read(ezealIdentityProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return EzealIdentity.fromJson(insertedRow);
    } catch (e) {
      if (kDebugMode) {
        print('EzealIdentityController.verifyMockAadhaarAndCreateId error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to generate Ezeal ID. Please try again.',
      );
      return null;
    }
  }
}

final ezealIdentityControllerProvider =
    NotifierProvider<EzealIdentityController, EzealIdentityState>(() {
  return EzealIdentityController();
});
