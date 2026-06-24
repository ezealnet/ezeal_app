import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../enums/user_role.dart';
import 'auth_state.dart';

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
Future<UserProfile?> _recoverProfile(User user) async {
  if (kDebugMode) {
    print('Profile recovery: Profile row not found for id: ${user.id}. Attempting profile recovery...');
  }

  // 1. Determine role from userMetadata or appMetadata
  final userMetaRole = user.userMetadata?['role'];
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
    } else if (rStr == 'counsellor') {
      targetRole = 'counsellor';
      targetStatus = 'pending';
    } else if (rStr == 'admin') {
      // Do not recover admin users automatically. Admin must be manually provisioned.
      if (kDebugMode) {
        print('Profile recovery aborted: Admin profile auto-recovery is forbidden.');
      }
      return null;
    }
  }

  // 2. If no role metadata exists, fallback to student role with active status
  if (targetRole == null) {
    targetRole = 'student';
    targetStatus = 'active';
  }

  // Fallback full name
  final email = user.email ?? '';
  final fallbackName = email.contains('@') ? email.split('@').first : 'User';

  if (kDebugMode) {
    print('Profile recovery: Role derived as: $targetRole, Status: $targetStatus, FullName fallback: $fallbackName');
  }

  // 3. Perform recovery transactionally
  try {
    // Insert profiles row
    await Supabase.instance.client.from('profiles').insert({
      'id': user.id,
      'email': email.isNotEmpty ? email : 'unknown@ezeal.com',
      'full_name': fallbackName,
      'phone': null,
      'role': targetRole,
      'status': targetStatus,
    });

    // Insert role-specific profile subtype
    if (targetRole == 'student') {
      await Supabase.instance.client.from('student_profiles').insert({
        'user_id': user.id,
        'education_stage': 'Other',
        'city': null,
        'state': null,
        'profile_completion': 0,
      });
    } else if (targetRole == 'institution') {
      await Supabase.instance.client.from('institution_profiles').insert({
        'user_id': user.id,
        'institution_name': fallbackName,
        'institution_type': 'Other',
        'contact_person': null,
        'city': null,
        'state': null,
        'approval_status': 'pending',
      });
    } else if (targetRole == 'counsellor') {
      await Supabase.instance.client.from('counsellor_profiles').insert({
        'user_id': user.id,
        'specialization': 'General',
        'experience_years': 0,
        'city': null,
        'state': null,
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
        message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('email_exists') ||
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
    required String educationStage,
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

      // 2. Insert into profiles and student_profiles
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
        print('General Exception during student signup: $e');
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

      // 2. Insert into profiles and institution_profiles
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
        print('General Exception during institution signup: $e');
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
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthException catch (e) {
      final friendlyMsg = _mapAuthException(e);
      state = state.copyWith(isLoading: false, errorMessage: friendlyMsg);
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General Exception during forgot password: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong. Please try again.');
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
