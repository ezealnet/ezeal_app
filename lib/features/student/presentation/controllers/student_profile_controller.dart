import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../data/models/student_profile_model.dart';

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
  int calculateCompletion({
    required String fullName,
    required String phone,
    required DateTime? dateOfBirth,
    required String? gender,
    required String? educationStage,
    required String? city,
    required String? state,
    required Map<String, dynamic> metadata,
  }) {
    int filledFields = 0;
    int totalFields = 8; // 7 core + 1 qualifications list

    if (fullName.trim().isNotEmpty) filledFields++;
    if (phone.trim().isNotEmpty) filledFields++;
    if (dateOfBirth != null) filledFields++;
    if (gender != null && gender.trim().isNotEmpty) filledFields++;
    if (city != null && city.trim().isNotEmpty) filledFields++;
    if (state != null && state.trim().isNotEmpty) filledFields++;
    if (educationStage != null && educationStage.trim().isNotEmpty) filledFields++;

    final quals = metadata['qualifications'];
    if (quals is List && quals.isNotEmpty) {
      filledFields++;
    }

    // Optional field checks inside metadata if present
    final guardianName = metadata['guardian_name']?.toString() ?? '';
    final preferences = metadata['preferences']?.toString() ?? '';
    if (guardianName.isNotEmpty) {
      totalFields++;
      filledFields++;
    }
    if (preferences.isNotEmpty) {
      totalFields++;
      filledFields++;
    }

    return (filledFields / totalFields * 100).round();
  }

  // Update both profiles and student_profiles tables
  Future<bool> saveProfile(StudentProfileModel updatedProfile) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // 1. Calculate the dynamic completion percentage
      final completion = calculateCompletion(
        fullName: updatedProfile.fullName,
        phone: updatedProfile.phone,
        dateOfBirth: updatedProfile.dateOfBirth,
        gender: updatedProfile.gender,
        educationStage: updatedProfile.educationStage,
        city: updatedProfile.city,
        state: updatedProfile.state,
        metadata: updatedProfile.educationMetadata,
      );

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
