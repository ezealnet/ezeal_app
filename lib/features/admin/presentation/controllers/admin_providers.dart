import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/auth_provider.dart';

// 1. Admin Stats Provider
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final profilesRes = await supabase.from('profiles').select('id, role');
    final profiles = profilesRes as List;
    final totalUsers = profiles.length;
    final students = profiles.where((p) => p['role'] == 'student').length;
    final institutions = profiles.where((p) => p['role'] == 'institution').length;
    final counselors = profiles.where((p) => p['role'] == 'counsellor').length;

    final identitiesRes = await supabase.from('ezeal_identities').select('id, verification_status');
    final identities = identitiesRes as List;
    final verifiedIds = identities.where((i) => i['verification_status'] == 'verified').length;
    final pendingVerifications = identities.where((i) => i['verification_status'] == 'pending').length;

    final assessmentsRes = await supabase.from('assessments').select('id, is_published');
    final assessments = assessmentsRes as List;
    final publishedAssessments = assessments.where((a) => a['is_published'] == true).length;

    final accessRes = await supabase.from('assessment_access').select('id, status');
    final accesses = accessRes as List;
    final totalAccess = accesses.length;
    final completedAssessments = accesses.where((a) => a['status'] == 'completed').length;

    final tokensRes = await supabase.from('institution_assessment_tokens').select('id, status');
    final tokens = tokensRes as List;
    final tokensAvailable = tokens.where((t) => t['status'] == 'available').length;
    final tokensUsed = tokens.where((t) => t['status'] == 'used').length;

    final paymentsRes = await supabase.from('payments').select('id, status');
    final payments = paymentsRes as List;
    final paymentsCount = payments.where((p) => p['status'] == 'success').length;

    return {
      'totalUsers': totalUsers,
      'totalStudents': students,
      'totalInstitutions': institutions,
      'totalCounselors': counselors,
      'verifiedEzealIds': verifiedIds,
      'pendingVerifications': pendingVerifications,
      'assessmentsPublished': publishedAssessments,
      'assessmentAccessGranted': totalAccess,
      'tokensAvailable': tokensAvailable,
      'tokensUsed': tokensUsed,
      'paymentsCount': paymentsCount,
      'completedAssessments': completedAssessments,
    };
  } catch (e) {
    if (kDebugMode) {
      print('adminStatsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return {
      'totalUsers': 0,
      'totalStudents': 0,
      'totalInstitutions': 0,
      'totalCounselors': 0,
      'verifiedEzealIds': 0,
      'pendingVerifications': 0,
      'assessmentsPublished': 0,
      'assessmentAccessGranted': 0,
      'tokensAvailable': 0,
      'tokensUsed': 0,
      'paymentsCount': 0,
      'completedAssessments': 0,
    };
  }
});

// 2. Admin Users Provider
final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase.from('profiles').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminUsersProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 3. Admin Students Provider
final adminStudentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('student_profiles')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminStudentsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 4. Admin Institutions Provider
final adminInstitutionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('institution_profiles')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminInstitutionsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 5. Admin Counselors Provider
final adminCounselorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('counsellor_profiles')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminCounselorsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 6. Admin Assessments Provider
final adminAssessmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase.from('assessments').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminAssessmentsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 7. Admin Questions Provider
final adminQuestionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('assessment_questions')
        .select('*, assessments(*)')
        .order('question_order', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminQuestionsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 8. Admin Access Provider
final adminAccessProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('assessment_access')
        .select('*, profiles(*), assessments(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminAccessProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 9. Admin Tokens Provider
final adminTokensProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('institution_assessment_tokens')
        .select('*, assessments(*), institution:profiles!institution_id(*), student:profiles!assigned_student_id(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminTokensProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 10. Admin Results Provider
final adminResultsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('assessment_attempts')
        .select('*, profiles(*), assessments(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminResultsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 11. Admin Verification Provider
final adminVerificationProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('ezeal_identities')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminVerificationProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});

// 12. Admin Payments Provider
final adminPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = SupabaseService.client;
  try {
    final response = await supabase
        .from('payments')
        .select('*, orders(*, profiles(*))')
        .order('paid_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  } catch (e) {
    if (kDebugMode) {
      print('adminPaymentsProvider error: $e. Admin RLS policy required for this management view.');
    }
    return const [];
  }
});
