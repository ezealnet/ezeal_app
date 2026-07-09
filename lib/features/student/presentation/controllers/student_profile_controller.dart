import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../data/models/student_profile_model.dart';
import '../../../ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';

// State structure for StudentProfileController
class StudentProfileControllerState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const StudentProfileControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  StudentProfileControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return StudentProfileControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// FutureProvider to fetch and monitor the student profile
final studentProfileProvider = FutureProvider<StudentProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    if (kDebugMode) {
      print('studentProfileProvider: No active user.');
    }
    return null;
  }

  if (kDebugMode) {
    print('studentProfileProvider: Loading profile for user ID: ${user.id}');
  }

  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('*, student_profiles(*)')
        .eq('id', user.id)
        .single();

    final profile = StudentProfileModel.fromJson(data);
    if (kDebugMode) {
      print('studentProfileProvider: Profile loaded. Completion: ${profile.profileCompletion}%');
      print('studentProfileProvider: Fetched student profile data: { userId: ${profile.userId}, email: ${profile.email}, fullName: ${profile.fullName}, phone: ${profile.phone}, city: ${profile.city}, state: ${profile.state}, qualifications: ${profile.qualifications.length} }');
      print('studentProfileProvider: Qualifications count: ${profile.qualifications.length}');
    }
    return profile;
  } catch (e) {
    if (kDebugMode) {
      print('studentProfileProvider: Error loading student profile: $e');
    }
    rethrow;
  }
});

// Controller to manage save operations
class StudentProfileController extends Notifier<StudentProfileControllerState> {
  @override
  StudentProfileControllerState build() {
    return const StudentProfileControllerState();
  }

  // Calculates the profile completion percentage dynamically from core fields + qualifications
  static int calculateLiveCompletion(StudentProfileModel profile, {bool isVerified = false}) {
    double personalScore = 0.0;
    if (profile.fullName.trim().isNotEmpty) personalScore += 7.5;
    if (profile.phone.trim().isNotEmpty) personalScore += 7.5;
    if (profile.dateOfBirth != null) personalScore += 7.5;
    if (profile.gender != null && profile.gender!.trim().isNotEmpty) personalScore += 7.5;

    double locationScore = 0.0;
    if (profile.city != null && profile.city!.trim().isNotEmpty) locationScore += 7.5;
    if (profile.state != null && profile.state!.trim().isNotEmpty) locationScore += 7.5;

    double qualificationScore = 0.0;
    if (profile.educationStage != null && profile.educationStage!.trim().isNotEmpty) {
      qualificationScore += 5.0;
    }
    if (profile.qualifications.isNotEmpty) {
      qualificationScore += 5.0;
      final firstQual = profile.qualifications.first;
      if (firstQual.type.trim().isNotEmpty) qualificationScore += 5.0;
      if (firstQual.institutionName.trim().isNotEmpty) qualificationScore += 5.0;
      if (firstQual.boardOrUniversity.trim().isNotEmpty) qualificationScore += 5.0;
      if (firstQual.courseOrStream.trim().isNotEmpty) qualificationScore += 5.0;
      if (firstQual.gradeOrYear.trim().isNotEmpty) qualificationScore += 5.0;
    }

    double guardianScore = 0.0;
    final meta = profile.educationMetadata;
    final guardianName = meta['guardian_name']?.toString() ?? '';
    final guardianPhone = meta['guardian_phone']?.toString() ?? '';
    final guardianRelation = meta['guardian_relation']?.toString() ?? '';

    if (guardianName.trim().isNotEmpty) guardianScore += 3.33;
    if (guardianPhone.trim().isNotEmpty) guardianScore += 3.33;
    if (guardianRelation.trim().isNotEmpty) guardianScore += 3.34;

    double verificationScore = isVerified ? 10.0 : 0.0;

    final double total = personalScore + locationScore + qualificationScore + guardianScore + verificationScore;
    final int finalCompletion = total.clamp(0.0, 100.0).round();

    if (kDebugMode) {
      print('DEBUG: [ProfileCompletion] Personal Score: $personalScore%');
      print('DEBUG: [ProfileCompletion] Location Score: $locationScore%');
      print('DEBUG: [ProfileCompletion] Qualification Score: $qualificationScore%');
      print('DEBUG: [ProfileCompletion] Guardian Score: $guardianScore%');
      print('DEBUG: [ProfileCompletion] Verification Score: $verificationScore%');
      print('DEBUG: [ProfileCompletion] Final Completion: $finalCompletion%');
    }

    return finalCompletion;
  }

  // Compatibility wrapper method for dynamic calculation
  int calculateCompletion({
    required String fullName,
    required String phone,
    required DateTime? dateOfBirth,
    required String? gender,
    required String? educationStage,
    required String? city,
    required String? state,
    required Map<String, dynamic> metadata,
    bool isVerified = false,
  }) {
    final List<StudentQualification> qualificationsList = [];
    final qualsRaw = metadata['qualifications'];
    if (qualsRaw is List) {
      for (final q in qualsRaw) {
        qualificationsList.add(StudentQualification.fromJson(Map<String, dynamic>.from(q as Map)));
      }
    }
    final dummy = StudentProfileModel(
      userId: '',
      email: '',
      fullName: fullName,
      phone: phone,
      educationStage: educationStage,
      city: city,
      state: state,
      dateOfBirth: dateOfBirth,
      gender: gender,
      educationMetadata: metadata,
      qualifications: qualificationsList,
    );
    return StudentProfileController.calculateLiveCompletion(dummy, isVerified: isVerified);
  }

  // Update both profiles and student_profiles tables
  Future<bool> saveProfile(StudentProfileModel updatedProfile) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // 1. Calculate the dynamic completion percentage
      // Try to check verified state from identity provider
      bool isVerified = false;
      try {
        final identity = ref.read(ezealIdentityProvider).asData?.value;
        isVerified = identity != null && identity.aadhaarVerified && identity.verificationStatus == 'verified';
      } catch (_) {}

      final completion = StudentProfileController.calculateLiveCompletion(updatedProfile, isVerified: isVerified);

      // 2. Perform Profiles updates
      await Supabase.instance.client.from('profiles').update({
        'full_name': updatedProfile.fullName,
        'phone': updatedProfile.phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', updatedProfile.userId);

      // 3. Keep education_stage inside education_metadata as well
      final Map<String, dynamic> finalMetadata = Map.of(updatedProfile.educationMetadata);
      if (updatedProfile.educationStage != null) {
        finalMetadata['education_stage'] = updatedProfile.educationStage;
      }

      // 4. Perform Student Profiles updates
      await Supabase.instance.client.from('student_profiles').update({
        'education_stage': updatedProfile.educationStage,
        'city': updatedProfile.city,
        'state': updatedProfile.state,
        'date_of_birth': updatedProfile.dateOfBirth?.toIso8601String().substring(0, 10), // yyyy-MM-dd format
        'gender': updatedProfile.gender,
        'profile_completion': completion,
        'education_metadata': finalMetadata,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', updatedProfile.userId);

      if (kDebugMode) {
        print('Profile saved successfully. New completion: $completion%');
      }

      // 5. Force invalidate and reload provider states
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(studentProfileProvider);

      // Wait briefly for hydration
      await ref.read(studentProfileProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving student profile: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save profile. Please try again.',
      );
      return false;
    }
  }
}

final studentProfileControllerProvider =
    NotifierProvider<StudentProfileController, StudentProfileControllerState>(() {
  return StudentProfileController();
});
