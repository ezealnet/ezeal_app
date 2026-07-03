import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_brand_panel.dart';
import '../widgets/auth_segmented_control.dart';
import '../widgets/auth_progress_indicator.dart';
import '../widgets/responsive_auth_button_wrapper.dart';

class AuthSignupPage extends ConsumerStatefulWidget {
  const AuthSignupPage({super.key});

  @override
  ConsumerState<AuthSignupPage> createState() => _AuthSignupPageState();
}

class _AuthSignupPageState extends ConsumerState<AuthSignupPage> {
  int _selectedRoleIndex = 0; // 0 for Student, 1 for Institution
  int _currentStep = 0; // Steps 0, 1, 2

  // Form Keys for Student Steps
  final _studentStep1Key = GlobalKey<FormState>();
  final _studentStep2Key = GlobalKey<FormState>();
  final _studentStep3Key = GlobalKey<FormState>();

  // Form Keys for Institution Steps
  final _institutionStep1Key = GlobalKey<FormState>();
  final _institutionStep2Key = GlobalKey<FormState>();
  final _institutionStep3Key = GlobalKey<FormState>();

  // Student Controllers
  final _studentFirstNameController = TextEditingController();
  final _studentLastNameController = TextEditingController();
  final _studentDobController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedEducationStage = 'Undergraduate';

  final _studentEmailController = TextEditingController();
  final _studentPhoneController = TextEditingController();
  final _studentCityController = TextEditingController();
  final _studentStateController = TextEditingController();

  final _studentPasswordController = TextEditingController();
  final _studentConfirmPasswordController = TextEditingController();

  // Institution Controllers
  final _institutionNameController = TextEditingController();
  String _selectedInstitutionType = 'College';
  final _institutionBoardController = TextEditingController();

  final _institutionContactController = TextEditingController();
  final _institutionEmailController = TextEditingController();
  final _institutionPhoneController = TextEditingController();
  final _institutionCityController = TextEditingController();
  final _institutionStateController = TextEditingController();

  final _institutionPasswordController = TextEditingController();
  final _institutionConfirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _studentFirstNameController.dispose();
    _studentLastNameController.dispose();
    _studentDobController.dispose();
    _studentEmailController.dispose();
    _studentPhoneController.dispose();
    _studentCityController.dispose();
    _studentStateController.dispose();
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();

    _institutionNameController.dispose();
    _institutionBoardController.dispose();
    _institutionContactController.dispose();
    _institutionEmailController.dispose();
    _institutionPhoneController.dispose();
    _institutionCityController.dispose();
    _institutionStateController.dispose();
    _institutionPasswordController.dispose();
    _institutionConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleStudentSignUp() async {
    if (_studentStep3Key.currentState!.validate()) {
      if (_studentPasswordController.text != _studentConfirmPasswordController.text) {
        SnackbarHelper.showError(context, 'Passwords do not match.');
        return;
      }

      final firstName = _studentFirstNameController.text.trim();
      final lastName = _studentLastNameController.text.trim();
      final fullName = '$firstName $lastName';

      // Save value to backend: Convert selected DD-MM-YYYY to YYYY-MM-DD
      final dobParts = _studentDobController.text.split('-');
      final isoDob = dobParts.length == 3 
          ? '${dobParts[2]}-${dobParts[1]}-${dobParts[0]}' 
          : _studentDobController.text;

      if (kDebugMode) {
        print('Selected DOB for profile save: $isoDob');
      }

      final success = await ref.read(authControllerProvider.notifier).signUpStudent(
            email: _studentEmailController.text.trim(),
            password: _studentPasswordController.text,
            fullName: fullName,
            phone: _studentPhoneController.text.trim(),
            educationStage: _selectedEducationStage,
            city: _studentCityController.text.trim(),
            stateName: _studentStateController.text.trim(),
          );

      if (!mounted) return;
      if (success) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          SnackbarHelper.showSuccess(context, 'Account created successfully.');
          context.go('/dashboard');
        } else {
          SnackbarHelper.showSuccess(context, 'Account created. Please check your email to verify and sign in.');
          context.go('/auth/login');
        }
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    }
  }

  Future<void> _handleInstitutionSignUp() async {
    if (_institutionStep3Key.currentState!.validate()) {
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
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          SnackbarHelper.showSuccess(context, 'Institution account created. Pending approval.');
          context.go('/dashboard');
        } else {
          SnackbarHelper.showSuccess(context, 'Institution account created. Please check your email to verify and sign in.');
          context.go('/auth/login');
        }
      } else {
        final err = ref.read(authControllerProvider).errorMessage ?? 'Something went wrong. Please try again.';
        SnackbarHelper.showError(context, err);
      }
    }
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final cardContent = AuthCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wizard step indicator
          AuthProgressIndicator(
            currentStep: _currentStep,
            stepLabels: const ['Basic', 'Contact', 'Security'],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Role selection segmented control (only editable on Step 1)
          if (_currentStep == 0) ...[
            AuthSegmentedControl(
              selectedIndex: _selectedRoleIndex,
              labels: const ['Student', 'Institution'],
              onSelected: (index) {
                setState(() {
                  _selectedRoleIndex = index;
                  _currentStep = 0; // Reset wizard step on role index switch
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Animated Switcher for premium fade transition between steps
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _selectedRoleIndex == 0
                ? _buildStudentWizardContent(state.isLoading)
                : _buildInstitutionWizardContent(state.isLoading),
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Already have an account?'),
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: isDesktop
          ? Row(
              children: [
                const Expanded(
                  flex: 42,
                  child: AuthBrandPanel(),
                ),
                Expanded(
                  flex: 58,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: cardContent,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                child: Column(
                  children: [
                    // Mobile Branding Above Card
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Image.asset(
                        'assets/images/ezeal_logo.webp',
                        height: 52,
                        width: 52,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bolt, color: AppColors.primary, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ezeal',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Create Your Account',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'AI-powered Human Potential Intelligence Platform helping students understand their strengths, personality, and career direction.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    cardContent,
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Student Wizard Forms ---
  Widget _buildStudentWizardContent(bool isLoading) {
    switch (_currentStep) {
      case 0:
        return _buildStudentStep1(isLoading);
      case 1:
        return _buildStudentStep2(isLoading);
      case 2:
        return _buildStudentStep3(isLoading);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStudentStep1(bool isLoading) {
    return Container(
      key: const ValueKey('student_step1'),
      child: Form(
        key: _studentStep1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Basic Details',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'First Name',
              controller: _studentFirstNameController,
              prefixIcon: Icons.person_outline,
              validator: (val) => AppValidators.requiredText(val, 'First name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Last Name',
              controller: _studentLastNameController,
              prefixIcon: Icons.person_outline,
              validator: (val) => AppValidators.requiredText(val, 'Last name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Date of Birth',
              controller: _studentDobController,
              prefixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () async {
                final now = DateTime.now();
                final initialDate = DateTime(now.year - 15);
                final firstDate = DateTime(now.year - 80);
                final lastDate = DateTime(now.year - 5);

                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );

                if (selectedDate != null) {
                  final day = selectedDate.day.toString().padLeft(2, '0');
                  final month = selectedDate.month.toString().padLeft(2, '0');
                  final year = selectedDate.year.toString();
                  _studentDobController.text = '$day-$month-$year';
                }
              },
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Date of birth is required';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.transgender_outlined),
              ),
              items: ['Male', 'Female', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedGender = val ?? 'Male'),
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
            const SizedBox(height: AppSpacing.xl),
            ResponsiveAuthButtonWrapper(
              child: _buildPrimaryButton(
                text: 'Continue',
                onPressed: () {
                  if (_studentStep1Key.currentState!.validate()) {
                    setState(() => _currentStep = 1);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentStep2(bool isLoading) {
    return Container(
      key: const ValueKey('student_step2'),
      child: Form(
        key: _studentStep2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contact Details',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Email Address',
              controller: _studentEmailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Phone Number',
              controller: _studentPhoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: AppValidators.phoneIndia,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AuthTextField(
                    labelText: 'City',
                    controller: _studentCityController,
                    validator: (val) => AppValidators.requiredText(val, 'City'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AuthTextField(
                    labelText: 'State',
                    controller: _studentStateController,
                    validator: (val) => AppValidators.requiredText(val, 'State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSecondaryButton(
                        text: 'Back',
                        onPressed: () => setState(() => _currentStep = 0),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPrimaryButton(
                        text: 'Continue',
                        onPressed: () {
                          if (_studentStep2Key.currentState!.validate()) {
                            setState(() => _currentStep = 2);
                          }
                        },
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              text: 'Back',
                              onPressed: () => setState(() => _currentStep = 0),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPrimaryButton(
                              text: 'Continue',
                              onPressed: () {
                                if (_studentStep2Key.currentState!.validate()) {
                                  setState(() => _currentStep = 2);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentStep3(bool isLoading) {
    return Container(
      key: const ValueKey('student_step3'),
      child: Form(
        key: _studentStep3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account Security',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Password',
              controller: _studentPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: AppValidators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Confirm Password',
              controller: _studentConfirmPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: (val) => AppValidators.confirmPassword(val, _studentPasswordController.text),
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSecondaryButton(
                        text: 'Back',
                        onPressed: () => setState(() => _currentStep = 1),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPrimaryButton(
                        text: 'Create Account',
                        isLoading: isLoading,
                        onPressed: _handleStudentSignUp,
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              text: 'Back',
                              onPressed: () => setState(() => _currentStep = 1),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPrimaryButton(
                              text: 'Create Account',
                              isLoading: isLoading,
                              onPressed: _handleStudentSignUp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Institution Wizard Forms ---
  Widget _buildInstitutionWizardContent(bool isLoading) {
    switch (_currentStep) {
      case 0:
        return _buildInstitutionStep1(isLoading);
      case 1:
        return _buildInstitutionStep2(isLoading);
      case 2:
        return _buildInstitutionStep3(isLoading);
      default:
        return const SizedBox();
    }
  }

  Widget _buildInstitutionStep1(bool isLoading) {
    return Container(
      key: const ValueKey('institution_step1'),
      child: Form(
        key: _institutionStep1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Institution Details',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
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
            AuthTextField(
              labelText: 'Affiliated Board / Council',
              controller: _institutionBoardController,
              prefixIcon: Icons.gavel_outlined,
              validator: (val) => AppValidators.requiredText(val, 'Board affiliation'),
            ),
            const SizedBox(height: AppSpacing.xl),
            ResponsiveAuthButtonWrapper(
              child: _buildPrimaryButton(
                text: 'Continue',
                onPressed: () {
                  if (_institutionStep1Key.currentState!.validate()) {
                    setState(() => _currentStep = 1);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionStep2(bool isLoading) {
    return Container(
      key: const ValueKey('institution_step2'),
      child: Form(
        key: _institutionStep2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contact Details',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Contact Person Name',
              controller: _institutionContactController,
              prefixIcon: Icons.person_outline,
              validator: (val) => AppValidators.requiredText(val, 'Contact person name'),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Email Address',
              controller: _institutionEmailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: AppValidators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
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
                  child: AuthTextField(
                    labelText: 'City',
                    controller: _institutionCityController,
                    validator: (val) => AppValidators.requiredText(val, 'City'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AuthTextField(
                    labelText: 'State',
                    controller: _institutionStateController,
                    validator: (val) => AppValidators.requiredText(val, 'State'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSecondaryButton(
                        text: 'Back',
                        onPressed: () => setState(() => _currentStep = 0),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPrimaryButton(
                        text: 'Continue',
                        onPressed: () {
                          if (_institutionStep2Key.currentState!.validate()) {
                            setState(() => _currentStep = 2);
                          }
                        },
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              text: 'Back',
                              onPressed: () => setState(() => _currentStep = 0),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPrimaryButton(
                              text: 'Continue',
                              onPressed: () {
                                if (_institutionStep2Key.currentState!.validate()) {
                                  setState(() => _currentStep = 2);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionStep3(bool isLoading) {
    return Container(
      key: const ValueKey('institution_step3'),
      child: Form(
        key: _institutionStep3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Admin Account Security',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Password',
              controller: _institutionPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: AppValidators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            AuthTextField(
              labelText: 'Confirm Password',
              controller: _institutionConfirmPasswordController,
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: (val) => AppValidators.confirmPassword(val, _institutionPasswordController.text),
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSecondaryButton(
                        text: 'Back',
                        onPressed: () => setState(() => _currentStep = 1),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildPrimaryButton(
                        text: 'Create Institution',
                        isLoading: isLoading,
                        onPressed: _handleInstitutionSignUp,
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              text: 'Back',
                              onPressed: () => setState(() => _currentStep = 1),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildPrimaryButton(
                              text: 'Create Institution',
                              isLoading: isLoading,
                              onPressed: _handleInstitutionSignUp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
