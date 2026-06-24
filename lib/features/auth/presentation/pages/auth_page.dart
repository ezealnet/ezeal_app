import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/config/auth_config.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  // Page mode: login_signup or forgot_password
  bool _isForgotPasswordMode = false;

  Timer? _forgotPasswordTimer;
  int _forgotPasswordCooldown = 0;
  Timer? _resendVerificationTimer;
  int _resendVerificationCooldown = 0;

  void _startForgotPasswordCooldown() {
    setState(() {
      _forgotPasswordCooldown = 60;
    });
    _forgotPasswordTimer?.cancel();
    _forgotPasswordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_forgotPasswordCooldown > 1) {
        setState(() {
          _forgotPasswordCooldown--;
        });
      } else {
        setState(() {
          _forgotPasswordCooldown = 0;
        });
        timer.cancel();
      }
    });
  }

  void _startResendVerificationCooldown() {
    setState(() {
      _resendVerificationCooldown = 60;
    });
    _resendVerificationTimer?.cancel();
    _resendVerificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendVerificationCooldown > 1) {
        setState(() {
          _resendVerificationCooldown--;
        });
      } else {
        setState(() {
          _resendVerificationCooldown = 0;
        });
        timer.cancel();
      }
    });
  }

  // Sign In controllers
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Student Sign Up controllers
  final _studentFormKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentEmailController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();
  final _studentCityController = TextEditingController();
  final _studentStateController = TextEditingController();
  String _selectedEducationStage = 'Undergraduate';

  // Institution Sign Up controllers
  final _institutionFormKey = GlobalKey<FormState>();
  final _institutionNameController = TextEditingController();
  final _institutionContactController = TextEditingController();
  final _institutionEmailController = TextEditingController();
  final _institutionPhoneController = TextEditingController();
  final _institutionPasswordController = TextEditingController();
  final _institutionConfirmPasswordController = TextEditingController();
  final _institutionCityController = TextEditingController();
  final _institutionStateController = TextEditingController();
  String _selectedInstitutionType = 'College';

  // Counsellor Sign Up controllers
  final _counsellorFormKey = GlobalKey<FormState>();
  final _counsellorNameController = TextEditingController();
  final _counsellorSpecializationController = TextEditingController();
  final _counsellorExpController = TextEditingController();
  final _counsellorEmailController = TextEditingController();
  final _counsellorPhoneController = TextEditingController();
  final _counsellorPasswordController = TextEditingController();
  final _counsellorConfirmPasswordController = TextEditingController();
  final _counsellorCityController = TextEditingController();
  final _counsellorStateController = TextEditingController();

  // Forgot Password controllers
  final _forgotFormKey = GlobalKey<FormState>();
  final _forgotEmailController = TextEditingController();

  @override
  void dispose() {
    _forgotPasswordTimer?.cancel();
    _resendVerificationTimer?.cancel();
    
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _studentPhoneController.dispose();
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();
    _studentCityController.dispose();
    _studentStateController.dispose();
    
    _institutionNameController.dispose();
    _institutionContactController.dispose();
    _institutionEmailController.dispose();
    _institutionPhoneController.dispose();
    _institutionPasswordController.dispose();
    _institutionConfirmPasswordController.dispose();
    _institutionCityController.dispose();
    _institutionStateController.dispose();
    
    _counsellorNameController.dispose();
    _counsellorSpecializationController.dispose();
    _counsellorExpController.dispose();
    _counsellorEmailController.dispose();
    _counsellorPhoneController.dispose();
    _counsellorPasswordController.dispose();
    _counsellorConfirmPasswordController.dispose();
    _counsellorCityController.dispose();
    _counsellorStateController.dispose();
    
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_signInFormKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).login(
            email: _signInEmailController.text.trim(),
            password: _signInPasswordController.text,
          );
      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Welcome back to Ezeal.');
        context.go('/dashboard');
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Unable to sign in. Please check your email and password.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  Future<void> _handleResendVerification() async {
    final emailErr = AppValidators.email(_signInEmailController.text.trim());
    if (emailErr != null) {
      SnackbarHelper.showError(context, emailErr);
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).resendVerificationEmail(
          email: _signInEmailController.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      SnackbarHelper.showSuccess(context, 'Account verification link sent. Please check your inbox.');
      _startResendVerificationCooldown();
    } else {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
      SnackbarHelper.showError(context, err);
    }
  }

  Future<void> _handleStudentSignUp() async {
    if (_studentFormKey.currentState!.validate()) {
      if (_studentPasswordController.text != _studentConfirmPasswordController.text) {
        SnackbarHelper.showError(context, 'Passwords do not match.');
        return;
      }

      final success = await ref.read(authControllerProvider.notifier).signUpStudent(
            email: _studentEmailController.text.trim(),
            password: _studentPasswordController.text,
            fullName: _studentNameController.text.trim(),
            phone: _studentPhoneController.text.trim(),
            educationStage: _selectedEducationStage,
            city: _studentCityController.text.trim(),
            stateName: _studentStateController.text.trim(),
          );

      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Account created successfully. Welcome to Ezeal.');
        context.go('/student/dashboard');
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  Future<void> _handleInstitutionSignUp() async {
    if (_institutionFormKey.currentState!.validate()) {
      if (_institutionPasswordController.text != _institutionConfirmPasswordController.text) {
        SnackbarHelper.showError(context, 'Passwords do not match.');
        return;
      }

      final success = await ref.read(authControllerProvider.notifier).signUpInstitution(
            email: _institutionEmailController.text.trim(),
            password: _institutionPasswordController.text,
            institutionName: _institutionNameController.text.trim(),
            institutionType: _selectedInstitutionType,
            contactPerson: _institutionContactController.text.trim(),
            phone: _institutionPhoneController.text.trim(),
            city: _institutionCityController.text.trim(),
            stateName: _institutionStateController.text.trim(),
          );

      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Institution account created. Your account is pending approval.');
        context.go('/institution/dashboard');
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  Future<void> _handleCounsellorSignUp() async {
    if (_counsellorFormKey.currentState!.validate()) {
      if (_counsellorPasswordController.text != _counsellorConfirmPasswordController.text) {
        SnackbarHelper.showError(context, 'Passwords do not match.');
        return;
      }

      final exp = int.tryParse(_counsellorExpController.text.trim()) ?? 0;

      final success = await ref.read(authControllerProvider.notifier).signUpCounsellor(
            email: _counsellorEmailController.text.trim(),
            password: _counsellorPasswordController.text,
            fullName: _counsellorNameController.text.trim(),
            specialization: _counsellorSpecializationController.text.trim(),
            experienceYears: exp,
            phone: _counsellorPhoneController.text.trim(),
            city: _counsellorCityController.text.trim(),
            stateName: _counsellorStateController.text.trim(),
          );

      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Counsellor account created. Your account is pending approval.');
        context.go('/counsellor/dashboard');
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_forgotFormKey.currentState!.validate()) {
      final success = await ref.read(authControllerProvider.notifier).forgotPassword(
            email: _forgotEmailController.text.trim(),
          );
      if (!mounted) return;
      if (success) {
        SnackbarHelper.showSuccess(context, 'Password reset email sent. Please check your inbox.');
        _startForgotPasswordCooldown();
        setState(() {
          _isForgotPasswordMode = false;
        });
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return AppScaffold(
      title: _isForgotPasswordMode ? 'Reset Password' : 'Ezeal Portal',
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _isForgotPasswordMode ? 450 : 600),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header branding
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/ezeal_logo.webp',
                          height: 48,
                          width: 48,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 48,
                            width: 48,
                            color: AppColors.accent,
                            child: const Icon(Icons.bolt, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Ezeal Portal',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    if (_isForgotPasswordMode) ...[
                      // Forgot password mode
                      _buildForgotPasswordForm(state.isLoading),
                    ] else ...[
                      // Normal Login / Signups Tabbed view
                      DefaultTabController(
                        length: 4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TabBar(
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textSecondaryLight,
                              indicatorColor: AppColors.accent,
                              isScrollable: true,
                              tabs: const [
                                Tab(text: 'Sign In'),
                                Tab(text: 'Student Signup'),
                                Tab(text: 'Institution Signup'),
                                Tab(text: 'Counsellor Signup'),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              height: 520,
                              child: TabBarView(
                                children: [
                                  _buildSignInTab(state.isLoading),
                                  _buildStudentSignupTab(state.isLoading),
                                  _buildInstitutionSignupTab(state.isLoading),
                                  _buildCounsellorSignupTab(state.isLoading),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Developer Quick Login - Debug Mode Only
                    if (kDebugMode) ...[
                      const Divider(height: AppSpacing.xl),
                      Text(
                        'Developer Quick Login - Debug Only',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.surfaceDark 
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.borderDark 
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auth User: ${ref.watch(currentUserProvider) != null ? "Yes" : "No"}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Current Session: ${Supabase.instance.client.auth.currentSession != null ? "Active" : "None"}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Current User ID: ${ref.watch(currentUserProvider)?.id ?? "None"}',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Current Email: ${ref.watch(currentUserProvider)?.email ?? "None"}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppButton(
                            text: 'As Student',
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).devLogin(UserRole.student);
                              context.go('/student/dashboard');
                            },
                            width: 130,
                            style: AppButtonStyle.outlined,
                          ),
                          AppButton(
                            text: 'As Admin',
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).devLogin(UserRole.admin);
                              context.go('/admin/dashboard');
                            },
                            width: 130,
                            style: AppButtonStyle.outlined,
                          ),
                          AppButton(
                            text: 'As Institution',
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).devLogin(UserRole.institution);
                              context.go('/institution/dashboard');
                            },
                            width: 130,
                            style: AppButtonStyle.outlined,
                          ),
                          AppButton(
                            text: 'As Counsellor',
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).devLogin(UserRole.counsellor);
                              context.go('/counsellor/dashboard');
                            },
                            width: 130,
                            style: AppButtonStyle.outlined,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SIGN IN VIEW
  Widget _buildSignInTab(bool isLoading) {
    return Form(
      key: _signInFormKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            labelText: 'Email Address',
            controller: _signInEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Password',
            controller: _signInPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _isForgotPasswordMode = true),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Sign In',
            isLoading: isLoading,
            onPressed: _handleSignIn,
          ),
          if (AuthConfig.emailConfirmationEnabled) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: (_resendVerificationCooldown > 0 || isLoading)
                    ? null
                    : _handleResendVerification,
                child: Text(
                  _resendVerificationCooldown > 0
                      ? 'Resend Verification Email (Wait ${_resendVerificationCooldown}s)'
                      : 'Resend Verification Email',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // STUDENT SIGNUP VIEW
  Widget _buildStudentSignupTab(bool isLoading) {
    return Form(
      key: _studentFormKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            labelText: 'Full Name',
            controller: _studentNameController,
            prefixIcon: Icons.person_outline,
            validator: (val) => AppValidators.minLength(val, 'Full name', 2),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Email Address',
            controller: _studentEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Phone Number',
            controller: _studentPhoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: AppValidators.phoneIndia,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedEducationStage,
            decoration: const InputDecoration(
              labelText: 'Education Stage',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: ['High School', 'Undergraduate', 'Postgraduate', 'Other']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _selectedEducationStage = val ?? 'Undergraduate'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  labelText: 'City',
                  controller: _studentCityController,
                  validator: (val) => AppValidators.requiredText(val, 'City'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  labelText: 'State',
                  controller: _studentStateController,
                  validator: (val) => AppValidators.requiredText(val, 'State'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Password',
            controller: _studentPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Confirm Password',
            controller: _studentConfirmPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) => AppValidators.confirmPassword(val, _studentPasswordController.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Sign Up',
            isLoading: isLoading,
            onPressed: _handleStudentSignUp,
          ),
        ],
      ),
    );
  }

  // INSTITUTION SIGNUP VIEW
  Widget _buildInstitutionSignupTab(bool isLoading) {
    return Form(
      key: _institutionFormKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            labelText: 'Institution Name',
            controller: _institutionNameController,
            prefixIcon: Icons.business_outlined,
            validator: (val) => AppValidators.requiredText(val, 'Institution name'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedInstitutionType,
            decoration: const InputDecoration(
              labelText: 'Institution Type',
              prefixIcon: Icon(Icons.corporate_fare_outlined),
            ),
            items: ['School', 'College', 'University', 'Training Center']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => setState(() => _selectedInstitutionType = val ?? 'College'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Contact Person Name',
            controller: _institutionContactController,
            prefixIcon: Icons.person_outline,
            validator: (val) => AppValidators.requiredText(val, 'Contact person'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Email Address',
            controller: _institutionEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Phone Number',
            controller: _institutionPhoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: AppValidators.phoneIndia,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  labelText: 'City',
                  controller: _institutionCityController,
                  validator: (val) => AppValidators.requiredText(val, 'City'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  labelText: 'State',
                  controller: _institutionStateController,
                  validator: (val) => AppValidators.requiredText(val, 'State'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Password',
            controller: _institutionPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Confirm Password',
            controller: _institutionConfirmPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) => AppValidators.confirmPassword(val, _institutionPasswordController.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Request Registration',
            isLoading: isLoading,
            onPressed: _handleInstitutionSignUp,
          ),
        ],
      ),
    );
  }

  // COUNSELLOR SIGNUP VIEW
  Widget _buildCounsellorSignupTab(bool isLoading) {
    return Form(
      key: _counsellorFormKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            labelText: 'Full Name',
            controller: _counsellorNameController,
            prefixIcon: Icons.person_outline,
            validator: (val) => AppValidators.minLength(val, 'Full name', 2),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Specialization',
            controller: _counsellorSpecializationController,
            prefixIcon: Icons.psychology_outlined,
            validator: (val) => AppValidators.requiredText(val, 'Specialization'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Experience (Years)',
            controller: _counsellorExpController,
            prefixIcon: Icons.work_history_outlined,
            keyboardType: TextInputType.number,
            validator: (val) => AppValidators.numberRequired(val, 'Experience years'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Email Address',
            controller: _counsellorEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Phone Number',
            controller: _counsellorPhoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: AppValidators.phoneIndia,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  labelText: 'City',
                  controller: _counsellorCityController,
                  validator: (val) => AppValidators.requiredText(val, 'City'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  labelText: 'State',
                  controller: _counsellorStateController,
                  validator: (val) => AppValidators.requiredText(val, 'State'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Password',
            controller: _counsellorPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: AppValidators.password,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Confirm Password',
            controller: _counsellorConfirmPasswordController,
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (val) => AppValidators.confirmPassword(val, _counsellorPasswordController.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Request Registration',
            isLoading: isLoading,
            onPressed: _handleCounsellorSignUp,
          ),
        ],
      ),
    );
  }

  // FORGOT PASSWORD VIEW
  Widget _buildForgotPasswordForm(bool isLoading) {
    return Form(
      key: _forgotFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Trouble Logging In?',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter your email and we will send you a password reset link.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            labelText: 'Email Address',
            controller: _forgotEmailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: AppValidators.email,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: _forgotPasswordCooldown > 0
                ? 'Send Reset Link (Wait ${_forgotPasswordCooldown}s)'
                : 'Send Reset Link',
            isLoading: isLoading,
            onPressed: (_forgotPasswordCooldown > 0 || isLoading)
                ? null
                : _handleForgotPassword,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() => _isForgotPasswordMode = false),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}
