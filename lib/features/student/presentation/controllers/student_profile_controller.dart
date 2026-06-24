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

  // Calculates the profile completion percentage dynamically from core and stage-specific fields
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
    int completedCount = 0;
    int totalCount = 7; // 4 Personal + 2 Location + 1 EducationStage

    if (fullName.trim().isNotEmpty) completedCount++;
    if (phone.trim().isNotEmpty) completedCount++;
    if (dateOfBirth != null) completedCount++;
    if (gender != null && gender.trim().isNotEmpty) completedCount++;
    if (city != null && city.trim().isNotEmpty) completedCount++;
    if (state != null && state.trim().isNotEmpty) completedCount++;
    if (educationStage != null && educationStage.trim().isNotEmpty) completedCount++;

    if (educationStage == 'School Student') {
      totalCount += 3;
      final valClass = metadata['class']?.toString() ?? '';
      final valBoard = metadata['board']?.toString() ?? '';
      final valSchool = metadata['school_name']?.toString() ?? '';

      if (valClass.trim().isNotEmpty) completedCount++;
      if (valBoard.trim().isNotEmpty) completedCount++;
      if (valSchool.trim().isNotEmpty) completedCount++;
    } else if (educationStage == 'PUC / Intermediate') {
      totalCount += 4;
      final valYear = metadata['year']?.toString() ?? '';
      final valStream = metadata['stream']?.toString() ?? '';
      final valCollege = metadata['college_name']?.toString() ?? '';
      final valBoard = metadata['board']?.toString() ?? '';

      if (valYear.trim().isNotEmpty) completedCount++;
      if (valStream.trim().isNotEmpty) completedCount++;
      if (valCollege.trim().isNotEmpty) completedCount++;
      if (valBoard.trim().isNotEmpty) completedCount++;
    } else if (educationStage == 'Diploma') {
      totalCount += 4;
      final valBranch = metadata['branch']?.toString() ?? '';
      final valSem = metadata['semester']?.toString() ?? '';
      final valInst = metadata['institution_name']?.toString() ?? '';
      final valBoard = metadata['board_or_university']?.toString() ?? '';

      if (valBranch.trim().isNotEmpty) completedCount++;
      if (valSem.trim().isNotEmpty) completedCount++;
      if (valInst.trim().isNotEmpty) completedCount++;
      if (valBoard.trim().isNotEmpty) completedCount++;
    } else if (educationStage == 'Undergraduate' || educationStage == 'Postgraduate') {
      totalCount += 5;
      final valDegree = metadata['degree']?.toString() ?? '';
      final valSpec = metadata['specialization']?.toString() ?? '';
      final valYearSem = metadata['year_or_semester']?.toString() ?? '';
      final valCollege = metadata['college_name']?.toString() ?? '';
      final valUniv = metadata['university']?.toString() ?? '';

      if (valDegree.trim().isNotEmpty) completedCount++;
      if (valSpec.trim().isNotEmpty) completedCount++;
      if (valYearSem.trim().isNotEmpty) completedCount++;
      if (valCollege.trim().isNotEmpty) completedCount++;
      if (valUniv.trim().isNotEmpty) completedCount++;
    } else if (educationStage == 'Working Professional') {
      totalCount += 5;
      final valJob = metadata['job_title']?.toString() ?? '';
      final valInd = metadata['industry']?.toString() ?? '';
      final valExp = metadata['experience_years']?.toString() ?? '';
      final valOrg = metadata['organization']?.toString() ?? '';
      final valQual = metadata['highest_qualification']?.toString() ?? '';

      if (valJob.trim().isNotEmpty) completedCount++;
      if (valInd.trim().isNotEmpty) completedCount++;
      if (valExp.trim().isNotEmpty) completedCount++;
      if (valOrg.trim().isNotEmpty) completedCount++;
      if (valQual.trim().isNotEmpty) completedCount++;
    }

    return (completedCount / totalCount * 100).round();
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

// Global provider for the controller
final studentProfileControllerProvider =
    NotifierProvider<StudentProfileController, StudentProfileControllerState>(() {
  return StudentProfileController();
});
