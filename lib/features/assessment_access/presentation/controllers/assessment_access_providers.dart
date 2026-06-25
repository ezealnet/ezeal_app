import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../assessments/data/models/assessment_model.dart';
import '../../../ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';

class AssessmentAccess {
  final String id;
  final String userId;
  final String assessmentId;
  final String? ezealIdentityId;
  final String? orderId;
  final String accessSource;
  final String status;
  final DateTime? createdAt;
  final Assessment? assessment;

  const AssessmentAccess({
    required this.id,
    required this.userId,
    required this.assessmentId,
    this.ezealIdentityId,
    this.orderId,
    required this.accessSource,
    required this.status,
    this.createdAt,
    this.assessment,
  });

  factory AssessmentAccess.fromJson(Map<String, dynamic> json) {
    return AssessmentAccess(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      ezealIdentityId: json['ezeal_identity_id'] as String?,
      orderId: json['order_id'] as String?,
      accessSource: json['access_source'] as String? ?? 'individual',
      status: json['status'] as String? ?? 'unlocked',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      assessment: json['assessments'] != null
          ? Assessment.fromJson(json['assessments'] as Map<String, dynamic>)
          : null,
    );
  }
}

final assessmentAccessProvider = FutureProvider<List<AssessmentAccess>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  try {
    final response = await Supabase.instance.client
        .from('assessment_access')
        .select('*, assessments(*)')
        .order('created_at', ascending: false);

    return (response as List).map((json) => AssessmentAccess.fromJson(json as Map<String, dynamic>)).toList();
  } catch (e) {
    if (kDebugMode) {
      print('assessmentAccessProvider: Error fetching assessment access: $e');
    }
    return const [];
  }
});

class TokenRedeemState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const TokenRedeemState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  TokenRedeemState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return TokenRedeemState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TokenRedeemController extends Notifier<TokenRedeemState> {
  @override
  TokenRedeemState build() {
    return const TokenRedeemState();
  }

  Future<bool> redeemToken(String tokenCode) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // 1. Verify student has a verified Ezeal ID
      final identityAsync = ref.read(ezealIdentityProvider);
      final identity = identityAsync.asData?.value;
      if (identity == null || !identity.aadhaarVerified || identity.verificationStatus != 'verified') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'You must have a verified Ezeal ID before redeeming a token.',
        );
        return false;
      }

      // 2. Fetch token from database
      final tokenData = await Supabase.instance.client
          .from('institution_assessment_tokens')
          .select()
          .eq('token_code', tokenCode.trim())
          .maybeSingle();

      if (tokenData == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Invalid or expired token.');
        return false;
      }

      final String status = tokenData['status'] as String? ?? '';
      final String? assignedStudentId = tokenData['assigned_student_id'] as String?;
      final String assessmentId = tokenData['assessment_id'] as String;

      // 3. Validate status
      final isAvailable = status == 'available';
      final isAssignedToMe = status == 'assigned' && assignedStudentId == user.id;

      if (!isAvailable && !isAssignedToMe) {
        state = state.copyWith(isLoading: false, errorMessage: 'Invalid or expired token.');
        return false;
      }

      // TODO: Harden institution token rules before production
      // Mark token used
      await Supabase.instance.client.from('institution_assessment_tokens').update({
        'status': 'used',
        'assigned_student_id': user.id,
        'used_at': DateTime.now().toIso8601String(),
      }).eq('id', tokenData['id'] as String);

      // Create assessment_access record
      await Supabase.instance.client.from('assessment_access').insert({
        'user_id': user.id,
        'assessment_id': assessmentId,
        'ezeal_identity_id': identity.id,
        'access_source': 'institution',
        'status': 'unlocked',
      });

      ref.invalidate(assessmentAccessProvider);
      await ref.read(assessmentAccessProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('TokenRedeemController.redeemToken error: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid or expired token.',
      );
      return false;
    }
  }
}

final tokenRedeemControllerProvider =
    NotifierProvider<TokenRedeemController, TokenRedeemState>(() {
  return TokenRedeemController();
});
