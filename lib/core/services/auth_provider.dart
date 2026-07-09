import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../enums/user_role.dart';
import 'auth_state.dart';
import '../config/app_config.dart';

// Simulated dev profile state (only used in kDebugMode)
class SimulatedProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  void updateProfile(UserProfile? profile) {
    state = profile;
  }
}

final simulatedProfileProvider = NotifierProvider<SimulatedProfileNotifier, UserProfile?>(() {
  return SimulatedProfileNotifier();
});

// Stream of Supabase Auth state changes
final supabaseAuthProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Resolves current active Supabase Auth User
final currentUserProvider = Provider<User?>((ref) {
  // If simulated profile exists in debug mode, return a dummy user
  if (kDebugMode && ref.watch(simulatedProfileProvider) != null) {
    return User(
      id: ref.watch(simulatedProfileProvider)!.id,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  // Watch the auth state stream to ensure this provider updates when auth state changes
  ref.watch(supabaseAuthProvider);

  // Otherwise return real Supabase user
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
});

// Helper method to perform profile recovery in development mode
// TODO: Production Hardening. Recovery is for development only.
// TODO: Production: move signup profile provisioning to secure database trigger or Edge Function.
Future<UserProfile?> _recoverProfile(User user) async {
  if (kDebugMode) {
    print('Profile recovery: Profile row not found for id: ${user.id}. Attempting profile recovery...');
  }

  final meta = user.userMetadata ?? {};

  // 1. Determine role from userMetadata or appMetadata
  final userMetaRole = meta['role'];
  final appMetaRole = user.appMetadata['role'];
  final metaRole = userMetaRole ?? appMetaRole;

  String? targetRole;
  String? targetStatus;

  if (metaRole != null) {
    final rStr = metaRole.toString().toLowerCase().trim();
    if (rStr == 'student') {
      targetRole = 'student';
      targetStatus = 'active';
    } else if (rStr == 'institution') {
      targetRole = 'institution';
      targetStatus = 'pending';
    } else if (rStr == 'counsellor' || rStr == 'admin') {
      // Do not recover admin/counsellor users automatically. They must be manually provisioned.
      if (kDebugMode) {
        print('Profile recovery aborted: Admin/Counsellor profile auto-recovery is forbidden.');
      }
      return null;
    }
  }

  // 2. If no role metadata exists, fallback to student role with active status
  if (targetRole == null) {
    targetRole = 'student';
    targetStatus = 'active';
  }

  // Fallback and metadata-based fields
  final email = user.email ?? meta['email']?.toString() ?? 'unknown@ezeal.com';
  final fullName = meta['full_name']?.toString() ?? (email.contains('@') ? email.split('@').first : 'User');
  final phone = meta['phone']?.toString();

  // Student specific fields
  final dateOfBirth = meta['date_of_birth']?.toString();
  final gender = meta['gender']?.toString();
  final educationStage = meta['education_stage']?.toString() ?? 'Other';
  final city = meta['city']?.toString();
  final state = meta['state']?.toString();

  // Institution specific fields
  final institutionName = meta['institution_name']?.toString() ?? fullName;
  final institutionType = meta['institution_type']?.toString() ?? 'Other';
  final contactPerson = meta['contact_person']?.toString();

  if (kDebugMode) {
    print('Profile recovery: Role derived as: $targetRole, Status: $targetStatus, FullName: $fullName');
    print('Profile recovery metadata keys: ${meta.keys.toList()}');
  }

  // 3. Perform recovery transactionally
  try {
    final profilesPayload = {
      'id': user.id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': targetRole,
      'status': targetStatus,
    };

    if (kDebugMode) {
      print('Profile recovery payload profiles: $profilesPayload');
    }

    // Insert profiles row
    await Supabase.instance.client.from('profiles').insert(profilesPayload);

    // Insert role-specific profile subtype
    if (targetRole == 'student') {
      // 1. Calculate the dynamic completion percentage based on recovery data
      int filledFields = 0;
      const int totalFields = 8; // 7 core + 1 qualifications list

      if (fullName.isNotEmpty) filledFields++;
      if (phone != null && phone.isNotEmpty) filledFields++;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) filledFields++;
      if (gender != null && gender.isNotEmpty) filledFields++;
      if (city != null && city.isNotEmpty) filledFields++;
      if (state != null && state.isNotEmpty) filledFields++;
      if (educationStage.isNotEmpty && educationStage != 'Other') filledFields++;

      // 2. Provision initial qualifications array if educationStage exists
      final educationMetadata = educationStage.isNotEmpty && educationStage != 'Other'
          ? {
              'qualifications': [
                {
                  'id': 'initial_1',
                  'type': educationStage == 'School Student'
                      ? 'School'
                      : educationStage == 'PUC / Intermediate'
                          ? 'PUC'
                          : educationStage == 'Diploma'
                              ? 'Diploma'
                              : educationStage == 'Undergraduate'
                                  ? 'Undergraduate'
                                  : educationStage == 'Postgraduate'
                                      ? 'Postgraduate'
                                      : educationStage == 'Working Professional'
                                          ? 'Work Experience'
                                          : 'School',
                  'institution_name': '',
                  'board_or_university': '',
                  'course_or_stream': '',
                  'grade_or_year': '',
                  'start_year': '',
                  'end_year': '',
                  'is_current': true,
                  'city': city ?? '',
                  'state': state ?? '',
                }
              ]
            }
          : null;

      if (educationMetadata != null) {
        filledFields++; // qualifications list counts as filled
      }

      final completion = (filledFields / totalFields * 100).round();

      final studentProfilesPayload = {
        'user_id': user.id,
        'education_stage': educationStage,
        'city': city,
        'state': state,
        'profile_completion': completion,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'education_metadata': educationMetadata,
      };

      if (kDebugMode) {
        print('Profile recovery payload student_profiles: $studentProfilesPayload');
      }

      await Supabase.instance.client.from('student_profiles').insert(studentProfilesPayload);
    } else if (targetRole == 'institution') {
      await Supabase.instance.client.from('institution_profiles').insert({
        'user_id': user.id,
        'institution_name': institutionName,
        'institution_type': institutionType,
        'contact_person': contactPerson,
        'city': city,
        'state': state,
        'approval_status': 'pending',
      });
    }

    if (kDebugMode) {
      print('Profile recovery: Profile recovered successfully for id: ${user.id}');
    }

    // Re-fetch the newly created profile
    final recoveredData = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(recoveredData);
  } catch (dbError) {
    if (kDebugMode) {
      print('Profile recovery Failed: $dbError');
    }
    return null;
  }
}

// Fetches the active profile data (either simulated or from Supabase Postgres)
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    if (kDebugMode) {
      print('currentProfileProvider: No active Supabase Auth user found.');
    }
    return null;
  }

  // Ensure Supabase currentUser is not null (for real/non-simulated auth)
  final simulated = ref.read(simulatedProfileProvider) != null;
  if (!simulated && Supabase.instance.client.auth.currentUser == null) {
    if (kDebugMode) {
      print('currentProfileProvider: Supabase currentUser is null, skipping profile lookup.');
    }
    return null;
  }

  // In debug mode, check if we have a simulated user profile
  if (kDebugMode) {
    final simProfile = ref.watch(simulatedProfileProvider);
    if (simProfile != null) {
      print('currentProfileProvider: Returning simulated debug profile for id: ${simProfile.id}');
      return simProfile;
    }
  }

  if (kDebugMode) {
    print('currentProfileProvider: Fetching profile for auth user id: ${user.id}, email: ${user.email}');
  }

  try {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) {
      if (kDebugMode) {
        print('currentProfileProvider: Profile found successfully for id: ${user.id}');
      }
      return UserProfile.fromJson(data);
    }

    // Profiles row is missing - Trigger Profile Auto-Recovery helper
    return await _recoverProfile(user);
  } catch (e) {
    if (kDebugMode) {
      print('Error inside currentProfileProvider: $e');
    }
    return null;
  }
});

// State structure for AuthController
class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// Controller managing login, signup, forgot password, and logout operations
class AuthController extends Notifier<AuthControllerState> {
  @override
  AuthControllerState build() {
    return const AuthControllerState();
  }

  // Developer simulated login (Debug Mode Only)
  void devLogin(UserRole role) {
    if (!kDebugMode) return;

    final mockId = '${role.name}_mock_id';
    final mockProfile = UserProfile(
      id: mockId,
      email: '${role.name}@ezeal.com',
      fullName: 'Dev ${role.displayName}',
      phone: '1234567890',
      role: role,
      status: (role == UserRole.institution || role == UserRole.counsellor) ? 'pending' : 'active',
    );

    ref.read(simulatedProfileProvider.notifier).updateProfile(mockProfile);
    state = const AuthControllerState(isSuccess: true);
  }

  // Private helper to map Supabase AuthException to user-friendly messages
  String _mapAuthException(AuthException e) {
    if (kDebugMode) {
      print('Supabase AuthException: message="${e.message}", code="${e.code}", status="${e.statusCode}"');
    }
    final code = e.code?.toLowerCase() ?? '';
    final message = e.message.toLowerCase();

    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Unable to sign in. Please check your email and password.';
    }
    
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        code == 'email_address_already_exists' ||
        code == 'identity_already_exists' ||
        message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('email_exists') ||
        message.contains('user already registered') ||
        message.contains('user already exists')) {
      return 'This email is already registered. Please sign in instead.';
    }

    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed') ||
        message.contains('verify your email')) {
      return 'Please verify your email before signing in.';
    }

    if (code == 'weak_password' ||
        message.contains('weak password') ||
        message.contains('should be at least 6 characters') ||
        message.contains('password should be at least')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }

    if (code == 'over_email_send_rate_limit' ||
        message.contains('over_email_send_rate_limit') ||
        message.contains('email rate limit') ||
        message.contains('rate limit exceeded') ||
        message.contains('too many email requests') ||
        e.statusCode == '429') {
      return 'Too many email requests. Please wait a few minutes before trying again.';
    }

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed to connect') ||
        message.contains('network_error') ||
        message.contains('timeout')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Something went wrong. Please try again.';
  }

  // Supabase Email & Password Login
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    
    // Clear simulated profile
    if (kDebugMode) {
      ref.read(simulatedProfileProvider.notifier).updateProfile(null);
      print('login debug before signIn: email = $email');
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (kDebugMode) {
        print('login debug after signIn: user.id = ${user?.id}, session != null = ${session != null}');
      }

      if (user == null || session == null) {
        throw Exception('Unable to sign in. Please check your email and password.');
      }

      // Fetch profile directly by response.user.id without relying on currentUser Provider timing
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      UserProfile? profile;
      bool recoveryAttempted = false;

      if (data != null) {
        profile = UserProfile.fromJson(data);
      } else {
        // Run the development recovery
        recoveryAttempted = true;
        profile = await _recoverProfile(user);
      }

      if (kDebugMode) {
        print('login debug: fetched profile role = ${profile?.role.name}, recovery attempted = $recoveryAttempted');
      }

      if (profile == null) {
        throw Exception('Login successful, but profile setup is incomplete.');
      }

      // Explicitly notify and invalidate providers so auth state updates
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);
      await ref.read(currentProfileProvider.future);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during login: $e');
      }
      String errorMsg = 'Something went wrong. Please try again.';
      final eStr = e.toString();
      if (eStr.contains('Login successful, but profile setup is incomplete.')) {
        errorMsg = 'Login successful, but profile setup is incomplete.';
      } else if (eStr.contains('Unable to sign in. Please check your email and password.')) {
        errorMsg = 'Unable to sign in. Please check your email and password.';
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  // Supabase Student Signup
  Future<bool> signUpStudent({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String dateOfBirth,
    required String gender,
    required String educationStage,
    required String city,
    required String stateName,
  }) async {
    state = state.copyWith(isLoading: true);
    final trimmedEmail = email.trim();

    // 1. Before student signup, validate email format locally
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmedEmail)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    try {
      // 1. Sign up user in Supabase Auth (saving metadata in userMetadata)
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'role': 'student',
          'full_name': fullName,
          'phone': phone,
          'date_of_birth': dateOfBirth,
          'gender': gender,
          'education_stage': educationStage,
          'city': city,
          'state': stateName,
          'pending_profile_setup': true,
        },
      );

      final user = authResponse.user;
      final session = authResponse.session;
      if (user == null) {
        throw const AuthException('Signup failed. User registration rejected.');
      }

      // Check if Supabase returned a fake-success unconfirmed user duplicate
      final identities = user.identities;
      if (identities != null && identities.isEmpty) {
        throw const AuthException(
          'This email is already registered. Please sign in instead.',
          code: 'user_already_exists',
        );
      }

      // 2. Insert into profiles and student_profiles only if session is NOT null
      if (session != null) {
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': user.id,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'role': 'student',
            'status': 'active',
          });

          await Supabase.instance.client.from('student_profiles').insert({
            'user_id': user.id,
            'education_stage': educationStage,
            'city': city,
            'state': stateName,
            'profile_completion': 0,
            'date_of_birth': dateOfBirth,
            'gender': gender,
          });
        } catch (dbError) {
          if (kDebugMode) {
            print('Immediate Database insertion failed after signup: $dbError');
          }
          // We don't crash if RLS or other insert failed but we have a session,
          // as the recovery/creation flow on dashboard redirect will handle it.
        }
      }

      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during student signup: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // Supabase Institution Signup
  Future<bool> signUpInstitution({
    required String email,
    required String password,
    required String institutionName,
    required String institutionType,
    required String contactPerson,
    required String phone,
    required String city,
    required String stateName,
  }) async {
    state = state.copyWith(isLoading: true);
    final trimmedEmail = email.trim();

    // 1. Before institution signup, validate email format locally
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmedEmail)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    try {
      // 1. Sign up user in Supabase Auth (saving metadata in userMetadata)
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'role': 'institution',
          'institution_name': institutionName,
          'institution_type': institutionType,
          'contact_person': contactPerson,
          'phone': phone,
          'city': city,
          'state': stateName,
          'pending_profile_setup': true,
        },
      );

      final user = authResponse.user;
      final session = authResponse.session;
      if (user == null) {
        throw const AuthException('Signup failed. User registration rejected.');
      }

      // Check if Supabase returned a fake-success unconfirmed user duplicate
      final identities = user.identities;
      if (identities != null && identities.isEmpty) {
        throw const AuthException(
          'This email is already registered. Please sign in instead.',
          code: 'user_already_exists',
        );
      }

      // 2. Insert into profiles and institution_profiles only if session is NOT null
      if (session != null) {
        try {
          await Supabase.instance.client.from('profiles').insert({
            'id': user.id,
            'email': email,
            'full_name': institutionName,
            'phone': phone,
            'role': 'institution',
            'status': 'pending',
          });

          await Supabase.instance.client.from('institution_profiles').insert({
            'user_id': user.id,
            'institution_name': institutionName,
            'institution_type': institutionType,
            'contact_person': contactPerson,
            'city': city,
            'state': stateName,
            'approval_status': 'pending',
          });
        } catch (dbError) {
          if (kDebugMode) {
            print('Immediate Database insertion failed after signup: $dbError');
          }
        }
      }

      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during institution signup: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // Supabase Counsellor Signup
  Future<bool> signUpCounsellor({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
    required int experienceYears,
    required String phone,
    required String city,
    required String stateName,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Sign up user in Supabase Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw const AuthException('Signup failed. User registration rejected.');
      }

      // 2. Insert into profiles and counsellor_profiles
      try {
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': 'counsellor',
          'status': 'pending',
        });

        await Supabase.instance.client.from('counsellor_profiles').insert({
          'user_id': user.id,
          'specialization': specialization,
          'experience_years': experienceYears,
          'city': city,
          'state': stateName,
          'approval_status': 'pending',
        });
      } catch (dbError) {
        if (kDebugMode) {
          print('Database insertion failed after signup: $dbError');
        }
        throw Exception('Account was created, but profile setup failed. Please contact support or try again.');
      }

      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during counsellor signup: $e');
      }
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      if (msg.contains('Account was created, but profile setup failed')) {
        state = state.copyWith(isLoading: false, errorMessage: msg);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Please try again.');
      }
      return false;
    }
  }

  // Supabase Forgot Password Request
  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true);
    final trimmedEmail = email.trim();

    // 1. Locally validate email first. Empty/malformed email -> "Please enter a valid email address."
    if (trimmedEmail.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmedEmail)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    try {
      // 2. If email format is valid, call Supabase resetPasswordForEmail with redirectTo.
      await Supabase.instance.client.auth.resetPasswordForEmail(
        trimmedEmail,
        redirectTo: '${AppConfig.appUrl}/auth/reset-password',
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      // 6. Log raw errors only under kDebugMode.
      if (kDebugMode) {
        print('Supabase AuthException during forgot password: message="${e.message}", code="${e.code}", status="${e.statusCode}"');
      }
      // For all Supabase AuthException cases, show the same safe generic response
      state = state.copyWith(
        isLoading: false,
        isSuccess: true, // Mark success to trigger the identical success UI flow
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during forgot password: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // Update password using Supabase recovery session
  Future<bool> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true);

    // Validation: minimum length
    if (newPassword.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password must be at least 6 characters.',
      );
      return false;
    }

    // Validation: passwords match
    if (newPassword != confirmPassword) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Passwords do not match.',
      );
      return false;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (kDebugMode) {
        print('DEBUG: [updatePassword] Password updated successfully.');
      }

      // Sign out recovery session and invalidate providers
      await Supabase.instance.client.auth.signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentProfileProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('DEBUG: [updatePassword] Supabase AuthException: message="${e.message}", code="${e.code}"');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update password. Link may be expired or invalid.',
      );
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: [updatePassword] General Exception: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // Update Profile (normal user, updates fullName and phone only)
  // Ensures role and status fields are NOT sent from the client.
  Future<bool> updateOwnProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      // We ONLY update full_name and phone. Role/status are never sent.
      await Supabase.instance.client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
      }).eq('id', user.id);

      ref.invalidate(currentProfileProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during profile update: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // Resend Supabase signup confirmation email
  Future<bool> resendVerificationEmail({required String email}) async {
    state = state.copyWith(isLoading: true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during verification resend: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Please try again.');
      return false;
    }
  }

  // Supabase & Simulated Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    // Clear simulated profile
    if (kDebugMode) {
      ref.read(simulatedProfileProvider.notifier).updateProfile(null);
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    
    ref.invalidate(currentUserProvider);
    ref.invalidate(currentProfileProvider);
    
    state = const AuthControllerState();
  }
}

// Global AuthControllerProvider
final authControllerProvider = NotifierProvider<AuthController, AuthControllerState>(() {
  return AuthController();
});
