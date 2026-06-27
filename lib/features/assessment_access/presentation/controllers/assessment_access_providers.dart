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

// To verify access rows manually in Supabase SQL editor:
// select * from assessment_access where user_id = '<current-user-id>';
final assessmentAccessProvider = FutureProvider<List<AssessmentAccess>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    if (kDebugMode) {
      print('assessmentAccessProvider: No user logged in.');
    }
    return const [];
  }

  if (kDebugMode) {
    print('assessmentAccessProvider: Fetching for user ID: ${user.id}');
  }

  try {
    // 1. Fetch raw assessment_access rows first
    final List<dynamic> rows = await Supabase.instance.client
        .from('assessment_access')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (kDebugMode) {
      print('assessmentAccessProvider: Raw access rows fetched. Count: ${rows.length}');
      print('assessmentAccessProvider: Raw data: $rows');
    }

    if (rows.isEmpty) {
      return const [];
    }

    // 2. Fetch assessments by IDs separately
    final assessmentIds = rows.map((r) => r['assessment_id'] as String).toSet().toList();
    if (kDebugMode) {
      print('assessmentAccessProvider: Unique assessment IDs to fetch: $assessmentIds');
    }

    final assessmentsResponse = await Supabase.instance.client
        .from('assessments')
        .select('*')
        .inFilter('id', assessmentIds);

    final assessmentsList = assessmentsResponse as List;
    final assessmentsMap = {
      for (final a in assessmentsList) a['id'] as String: a
    };

    if (kDebugMode) {
      print('assessmentAccessProvider: Fetched assessments count: ${assessmentsList.length}');
    }

    // 3. Client-side merge
    final response = rows.map((row) {
      final Map<String, dynamic> rowMap = Map<String, dynamic>.from(row);
      final aId = rowMap['assessment_id'] as String;
      rowMap['assessments'] = assessmentsMap[aId];
      return rowMap;
    }).toList();

    final accessList = response.map((json) => AssessmentAccess.fromJson(json)).toList();
    return accessList;
  } catch (e) {
    if (kDebugMode) {
      print('assessmentAccessProvider: Error fetching access rows: $e');
    }
    return const [];
  }
});

class TokenRedeemState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool isSuccess;

  const TokenRedeemState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isSuccess = false,
  });

  TokenRedeemState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isSuccess,
  }) {
    return TokenRedeemState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
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
      if (kDebugMode) {
        print('--- DEBUG REDEEM TOKEN ---');
        print('Token Code entered: $tokenCode');
        print('User: null (Unauthorized)');
        print('---------------------------');
      }
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null, isSuccess: false);

    bool tokenFound = false;
    String tokenStatus = 'unknown';
    String assessmentId = 'unknown';
    bool existingAccessFound = false;
    String accessInsertStatus = 'not_attempted';
    String tokenUpdateStatus = 'not_attempted';

    try {
      // 1. Verify student has a verified Ezeal ID
      final identityAsync = ref.read(ezealIdentityProvider);
      final identity = identityAsync.asData?.value;
      if (identity == null || !identity.aadhaarVerified || identity.verificationStatus != 'verified') {
        if (kDebugMode) {
          print('--- DEBUG REDEEM TOKEN ---');
          print('Token Code entered: $tokenCode');
          print('User ID: ${user.id}');
          print('Identity Status: Unverified');
          print('---------------------------');
        }
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

      tokenFound = tokenData != null;
      if (tokenData != null) {
        tokenStatus = tokenData['status'] as String? ?? '';
        assessmentId = tokenData['assessment_id'] as String? ?? '';
      }

      if (tokenData == null || assessmentId.isEmpty) {
        if (kDebugMode) {
          print('--- DEBUG REDEEM TOKEN ---');
          print('Token Code entered: $tokenCode');
          print('User ID: ${user.id}');
          print('Token Found: ${tokenData != null ? 'Yes' : 'No'}');
          print('Assessment ID exists: ${assessmentId.isNotEmpty}');
          print('---------------------------');
        }
        state = state.copyWith(isLoading: false, errorMessage: 'Invalid or expired token.');
        return false;
      }

      final String status = tokenStatus;
      final String? assignedStudentId = tokenData['assigned_student_id'] as String?;

      // 3. Validate status & assignment logic
      final isAvailable = status == 'available';
      final isAssignedToMe = status == 'assigned' && assignedStudentId == user.id;

      if (!isAvailable && !isAssignedToMe) {
        if (kDebugMode) {
          print('--- DEBUG REDEEM TOKEN ---');
          print('Token Code entered: $tokenCode');
          print('User ID: ${user.id}');
          print('Token Found: Yes');
          print('Token Status: $status');
          print('Assigned Student ID: $assignedStudentId');
          print('Validation: Invalid/Expired/Assigned to other student');
          print('---------------------------');
        }
        state = state.copyWith(isLoading: false, errorMessage: 'Invalid or expired token.');
        return false;
      }

      // 4. Check if assessment_access already exists for this user and assessment
      final existingAccess = await Supabase.instance.client
          .from('assessment_access')
          .select()
          .eq('user_id', user.id)
          .eq('assessment_id', assessmentId)
          .maybeSingle();

      existingAccessFound = existingAccess != null;

      if (existingAccess != null) {
        // Access already exists! Mark token as used if not already.
        if (status != 'used') {
          try {
            await Supabase.instance.client.from('institution_assessment_tokens').update({
              'status': 'used',
              'assigned_student_id': user.id,
              'used_at': DateTime.now().toIso8601String(),
            }).eq('id', tokenData['id'] as String);
            tokenUpdateStatus = 'success';
          } catch (e) {
            tokenUpdateStatus = 'failed ($e)';
          }
        } else {
          tokenUpdateStatus = 'already_used';
        }

        ref.invalidate(assessmentAccessProvider);
        await ref.read(assessmentAccessProvider.future);

        if (kDebugMode) {
          print('--- DEBUG REDEEM TOKEN ---');
          print('Token Code entered: $tokenCode');
          print('User ID: ${user.id}');
          print('Token Found: Yes');
          print('Token Status: $status');
          print('Assessment ID: $assessmentId');
          print('Existing Access Found: Yes');
          print('Access Insert Status: ignored_duplicate');
          print('Token Update Status: $tokenUpdateStatus');
          print('---------------------------');
        }

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          successMessage: 'Access already unlocked.',
        );
        return true;
      }

      // Mark token used
      try {
        await Supabase.instance.client.from('institution_assessment_tokens').update({
          'status': 'used',
          'assigned_student_id': user.id,
          'used_at': DateTime.now().toIso8601String(),
        }).eq('id', tokenData['id'] as String);
        tokenUpdateStatus = 'success';
      } catch (e) {
        tokenUpdateStatus = 'failed ($e)';
        rethrow;
      }

      // Create assessment_access record with conflict safety
      try {
        await Supabase.instance.client.from('assessment_access').insert({
          'user_id': user.id,
          'assessment_id': assessmentId,
          'ezeal_identity_id': identity.id,
          'access_source': 'institution',
          'status': 'unlocked',
        });
        accessInsertStatus = 'success';
      } on PostgrestException catch (pe) {
        if (pe.code == '23505') {
          accessInsertStatus = 'success_duplicate_catch';
          if (kDebugMode) {
            print('TokenRedeemController: duplicate key error 23505 caught. Access already exists, ignoring insert.');
          }
        } else {
          accessInsertStatus = 'failed_postgrest ($pe)';
          rethrow;
        }
      } catch (e) {
        accessInsertStatus = 'failed ($e)';
        rethrow;
      }

      ref.invalidate(assessmentAccessProvider);
      await ref.read(assessmentAccessProvider.future);

      if (kDebugMode) {
        print('--- DEBUG REDEEM TOKEN ---');
        print('Token Code entered: $tokenCode');
        print('User ID: ${user.id}');
        print('Token Found: Yes');
        print('Token Status: $status');
        print('Assessment ID: $assessmentId');
        print('Existing Access Found: No');
        print('Access Insert Status: $accessInsertStatus');
        print('Token Update Status: $tokenUpdateStatus');
        print('---------------------------');
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'Token redeemed successfully! Assessment unlocked.',
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('TokenRedeemController.redeemToken error: $e');
        print('--- DEBUG REDEEM TOKEN (ERROR) ---');
        print('Token Code entered: $tokenCode');
        print('User ID: ${user.id}');
        print('Token Found: $tokenFound');
        print('Token Status: $tokenStatus');
        print('Assessment ID: $assessmentId');
        print('Existing Access Found: $existingAccessFound');
        print('Access Insert Status: $accessInsertStatus');
        print('Token Update Status: $tokenUpdateStatus');
        print('Error Details: $e');
        print('---------------------------');
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
