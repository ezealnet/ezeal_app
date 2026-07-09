import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../controllers/student_profile_controller.dart';
import '../../data/models/student_profile_model.dart';
import '../../../student/presentation/widgets/profile_completion_widget.dart';
import '../../../ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _hasHydratedProfile = false;
  String? _hydratedUserId;

  // Personal & Location Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Guardian Details Controllers
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianRelationController = TextEditingController();

  // Selected Dropdown States
  DateTime? _dob;
  String? _gender;
  String? _educationStage;

  // Qualifications list state
  List<StudentQualification> _qualifications = [];

  // Local controller caches for qualifications
  final Map<String, Map<String, TextEditingController>> _qualificationControllers = {};

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _stateController.dispose();

    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianRelationController.dispose();

    for (final controllers in _qualificationControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // Triggers DatePicker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime initialDate = _dob ?? DateTime(2005, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: today,
    );

    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  TextEditingController _getQualController(String qualId, String field, String initialVal) {
    if (!_qualificationControllers.containsKey(qualId)) {
      _qualificationControllers[qualId] = {};
    }
    final fieldControllers = _qualificationControllers[qualId]!;
    if (!fieldControllers.containsKey(field)) {
      fieldControllers[field] = TextEditingController(text: initialVal);
    }
    return fieldControllers[field]!;
  }

  void _syncQualificationsControllers() {
    for (var i = 0; i < _qualifications.length; i++) {
      final q = _qualifications[i];
      final inst = _getQualController(q.id, 'institution', q.institutionName);
      final board = _getQualController(q.id, 'board', q.boardOrUniversity);
      final course = _getQualController(q.id, 'course', q.courseOrStream);
      final grade = _getQualController(q.id, 'grade', q.gradeOrYear);
      final start = _getQualController(q.id, 'start', q.startYear);
      final end = _getQualController(q.id, 'end', q.endYear);
      final city = _getQualController(q.id, 'city', q.city);
      final state = _getQualController(q.id, 'state', q.state);

      _qualifications[i] = q.copyWith(
        institutionName: inst.text.trim(),
        boardOrUniversity: board.text.trim(),
        courseOrStream: course.text.trim(),
        gradeOrYear: grade.text.trim(),
        startYear: start.text.trim(),
        endYear: end.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
      );
    }
  }

  Future<void> _handleSave(StudentProfileModel currentProfile) async {
    // Sync all text field modifications back to qualifications list model first
    _syncQualificationsControllers();

    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> metadata = Map.from(currentProfile.educationMetadata);

      // Save guardian details inside metadata
      metadata['guardian_name'] = _guardianNameController.text.trim();
      metadata['guardian_phone'] = _guardianPhoneController.text.trim();
      metadata['guardian_relation'] = _guardianRelationController.text.trim();

      // Ensure stage is present in metadata
      metadata['education_stage'] = _educationStage;

      final updatedProfile = currentProfile.copyWith(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        educationStage: _educationStage,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        qualifications: _qualifications,
        educationMetadata: metadata,
      );

      // Check change differentials
      final isSameName = currentProfile.fullName == updatedProfile.fullName;
      final isSamePhone = currentProfile.phone == updatedProfile.phone;
      final isSameStage = currentProfile.educationStage == updatedProfile.educationStage;
      final isSameCity = currentProfile.city == updatedProfile.city;
      final isSameState = currentProfile.state == updatedProfile.state;
      final isSameDob = currentProfile.dateOfBirth?.toIso8601String().substring(0, 10) == 
          updatedProfile.dateOfBirth?.toIso8601String().substring(0, 10);
      final isSameGender = currentProfile.gender == updatedProfile.gender;

      bool isSameQualifications = currentProfile.qualifications.length == _qualifications.length;
      if (isSameQualifications) {
        for (int i = 0; i < _qualifications.length; i++) {
          final q1 = currentProfile.qualifications[i];
          final q2 = _qualifications[i];
          if (q1.type != q2.type ||
              q1.institutionName != q2.institutionName ||
              q1.boardOrUniversity != q2.boardOrUniversity ||
              q1.courseOrStream != q2.courseOrStream ||
              q1.gradeOrYear != q2.gradeOrYear ||
              q1.startYear != q2.startYear ||
              q1.endYear != q2.endYear ||
              q1.isCurrent != q2.isCurrent ||
              q1.city != q2.city ||
              q1.state != q2.state) {
            isSameQualifications = false;
            break;
          }
        }
      }

      final oldMeta = currentProfile.educationMetadata;
      final isSameGuardian = oldMeta['guardian_name']?.toString() == _guardianNameController.text.trim() &&
          oldMeta['guardian_phone']?.toString() == _guardianPhoneController.text.trim() &&
          oldMeta['guardian_relation']?.toString() == _guardianRelationController.text.trim();

      if (isSameName &&
          isSamePhone &&
          isSameStage &&
          isSameCity &&
          isSameState &&
          isSameDob &&
          isSameGender &&
          isSameQualifications &&
          isSameGuardian) {
        SnackbarHelper.showInfo(context, 'No profile changes to save.');
        return;
      }

      final success = await ref
          .read(studentProfileControllerProvider.notifier)
          .saveProfile(updatedProfile);

      if (mounted) {
        if (success) {
          SnackbarHelper.showSuccess(context, 'Profile saved. Completion updated.');
        } else {
          final err = ref.read(studentProfileControllerProvider).errorMessage ?? 
              'Unable to save profile. Please try again.';
          SnackbarHelper.showError(context, err);
        }
      }
    } else {
      SnackbarHelper.showError(context, 'Please correct the highlighted fields.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(studentProfileProvider);
    final controllerState = ref.watch(studentProfileControllerProvider);
    final identityAsync = ref.watch(ezealIdentityProvider);
    final identity = identityAsync.asData?.value;
    final isVerified = identity != null && identity.aadhaarVerified && identity.verificationStatus == 'verified';

    // Dynamic one-time hydration
    final profile = profileAsync.asData?.value;
    if (profile != null) {
      if (!_hasHydratedProfile || _hydratedUserId != profile.userId) {
        _fullNameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phone;

        if (profile.dateOfBirth != null) {
          _dob = profile.dateOfBirth;
          _dobController.text = "${_dob!.day.toString().padLeft(2, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.year}";
        } else {
          _dob = null;
          _dobController.text = '';
        }

        final validGenders = ['Male', 'Female', 'Other', 'Prefer not to say'];
        _gender = validGenders.contains(profile.gender) ? profile.gender : null;

        final validStages = ['School Student', 'PUC / Intermediate', 'Diploma', 'Undergraduate', 'Postgraduate', 'Working Professional'];
        _educationStage = validStages.contains(profile.educationStage) ? profile.educationStage : null;

        _cityController.text = profile.city ?? '';
        _stateController.text = profile.state ?? '';

        final meta = profile.educationMetadata;
        _guardianNameController.text = meta['guardian_name']?.toString() ?? '';
        _guardianPhoneController.text = meta['guardian_phone']?.toString() ?? '';
        _guardianRelationController.text = meta['guardian_relation']?.toString() ?? '';

        _qualifications = List.from(profile.qualifications);
        
        // If qualifications is empty but educationStage exists, prefill a local qualification card
        if (_qualifications.isEmpty && _educationStage != null && _educationStage!.isNotEmpty && _educationStage != 'Other') {
          String type = 'School';
          if (_educationStage == 'School Student') {
            type = 'School';
          } else if (_educationStage == 'PUC / Intermediate') {
            type = 'PUC';
          } else if (_educationStage == 'Diploma') {
            type = 'Diploma';
          } else if (_educationStage == 'Undergraduate') {
            type = 'Undergraduate';
          } else if (_educationStage == 'Postgraduate') {
            type = 'Postgraduate';
          } else if (_educationStage == 'Working Professional') {
            type = 'Work Experience';
          }
          _qualifications.add(
            StudentQualification(
              id: 'initial_1',
              type: type,
              institutionName: '',
              boardOrUniversity: '',
              courseOrStream: '',
              gradeOrYear: '',
              isCurrent: true,
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
            ),
          );
        }

        _hasHydratedProfile = true;
        _hydratedUserId = profile.userId;

        if (kDebugMode) {
          print('DEBUG: [StudentProfilePage] Profile loaded: true');
          print('DEBUG: [StudentProfilePage] Loaded fullName: ${profile.fullName}');
          print('DEBUG: [StudentProfilePage] Loaded email: ${profile.email}');
          print('DEBUG: [StudentProfilePage] Loaded phone: ${profile.phone}');
          print('DEBUG: [StudentProfilePage] Loaded city/state: ${profile.city}/${profile.state}');
          print('DEBUG: [StudentProfilePage] Loaded educationStage: ${profile.educationStage}');
          print('DEBUG: [StudentProfilePage] Qualifications count: ${profile.qualifications.length}');
          print('DEBUG: [StudentProfilePage] Hydration executed: true');
        }
      }
    }

    return AppScaffold(
      title: 'Edit Profile',
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Completion Header Widget
                  AppCard(
                    child: ProfileCompletionWidget(
                      completionPercentage: StudentProfileController.calculateLiveCompletion(profile, isVerified: isVerified),
                      showButton: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _buildVerificationStatusSection(),
                  const SizedBox(height: AppSpacing.lg),

                  _buildPersonalDetailsSection(),
                  const SizedBox(height: AppSpacing.lg),

                  _buildContactLocationSection(),
                  const SizedBox(height: AppSpacing.lg),

                  _buildQualificationsSection(),
                  const SizedBox(height: AppSpacing.lg),

                  _buildGuardianSection(),
                  const SizedBox(height: AppSpacing.xl),

                  // Save Action Button
                  AppButton(
                    text: 'Save Profile Changes',
                    isLoading: controllerState.isLoading,
                    onPressed: () => _handleSave(profile),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Error loading profile: $err',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStatusSection() {
    final identityAsync = ref.watch(ezealIdentityProvider);
    final identity = identityAsync.asData?.value;
    final isVerified = identity != null && identity.aadhaarVerified && identity.verificationStatus == 'verified';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Status',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isVerified ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.warning_amber_rounded,
                  color: isVerified ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified ? 'Aadhaar Identity Verified' : 'Aadhaar Identity Not Verified',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isVerified ? Colors.green[800] : Colors.orange[850],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVerified 
                            ? 'Your official identity details are verified on-chain.' 
                            : 'Verify your Aadhaar on checkout to unlock official career guidance tests.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isVerified ? Colors.green[700] : Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Full Name *',
            controller: _fullNameController,
            prefixIcon: Icons.person,
            validator: (v) => AppValidators.requiredText(v, 'Full Name'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Email Address (Read-only)',
            controller: _emailController,
            prefixIcon: Icons.email,
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: AppTextField(
                labelText: 'Date of Birth',
                controller: _dobController,
                prefixIcon: Icons.calendar_today,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: InputDecoration(
              labelText: 'Gender',
              prefixIcon: const Icon(Icons.transgender, size: 20),
              labelStyle: AppTextStyles.bodyMedium,
            ),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
              DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
            ],
            onChanged: (val) => setState(() => _gender = val),
          ),
        ],
      ),
    );
  }

  Widget _buildContactLocationSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Location',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Mobile Number',
            controller: _phoneController,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return AppValidators.phoneIndia(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'City',
            controller: _cityController,
            prefixIcon: Icons.location_city,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'State',
            controller: _stateController,
            prefixIcon: Icons.map,
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qualifications',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _qualifications.add(
                      StudentQualification(
                        id: UniqueKey().toString(),
                        type: 'School',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Qualification'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _educationStage,
            decoration: InputDecoration(
              labelText: 'Current Education Stage',
              prefixIcon: const Icon(Icons.school, size: 20),
              labelStyle: AppTextStyles.bodyMedium,
            ),
            items: const [
              DropdownMenuItem(value: 'School Student', child: Text('School Student')),
              DropdownMenuItem(value: 'PUC / Intermediate', child: Text('PUC / Intermediate')),
              DropdownMenuItem(value: 'Diploma', child: Text('Diploma')),
              DropdownMenuItem(value: 'Undergraduate', child: Text('Undergraduate')),
              DropdownMenuItem(value: 'Postgraduate', child: Text('Postgraduate')),
              DropdownMenuItem(value: 'Working Professional', child: Text('Working Professional')),
            ],
            onChanged: (val) {
              setState(() {
                _educationStage = val;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_qualifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'No qualifications added yet.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _qualifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final q = _qualifications[index];
                return _buildQualificationCard(q, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQualificationCard(StudentQualification q, int index) {
    final typeOptions = [
      'School',
      'PUC',
      'Diploma',
      'Undergraduate',
      'Postgraduate',
      'Certification',
      'Work Experience'
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qualification #${index + 1}',
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _qualifications.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: typeOptions.contains(q.type) ? q.type : 'School',
              decoration: const InputDecoration(
                labelText: 'Qualification Type',
                prefixIcon: Icon(Icons.class_outlined, size: 20),
              ),
              items: typeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _qualifications[index] = q.copyWith(type: val);
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              labelText: 'Institution Name',
              controller: _getQualController(q.id, 'institution', q.institutionName),
              prefixIcon: Icons.account_balance,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              labelText: 'Board / University',
              controller: _getQualController(q.id, 'board', q.boardOrUniversity),
              prefixIcon: Icons.assignment,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              labelText: 'Course / Stream / Branch',
              controller: _getQualController(q.id, 'course', q.courseOrStream),
              prefixIcon: Icons.book,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    labelText: 'Grade / GPA / CGPA',
                    controller: _getQualController(q.id, 'grade', q.gradeOrYear),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    labelText: 'Start Year',
                    controller: _getQualController(q.id, 'start', q.startYear),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AbsorbPointer(
                    absorbing: q.isCurrent,
                    child: Opacity(
                      opacity: q.isCurrent ? 0.5 : 1.0,
                      child: AppTextField(
                        labelText: 'End Year',
                        controller: _getQualController(q.id, 'end', q.endYear),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Row(
                  children: [
                    Checkbox(
                      value: q.isCurrent,
                      onChanged: (val) {
                        setState(() {
                          final endCtrl = _getQualController(q.id, 'end', q.endYear);
                          if (val == true) {
                            endCtrl.text = '';
                          }
                          _qualifications[index] = q.copyWith(isCurrent: val ?? false, endYear: val == true ? '' : endCtrl.text);
                        });
                      },
                    ),
                    const Text('Current'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    labelText: 'City',
                    controller: _getQualController(q.id, 'city', q.city),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    labelText: 'State',
                    controller: _getQualController(q.id, 'state', q.state),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guardian / Parent Details',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Guardian Name',
            controller: _guardianNameController,
            prefixIcon: Icons.family_restroom,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Guardian Contact Number',
            controller: _guardianPhoneController,
            prefixIcon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              return AppValidators.phoneIndia(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            labelText: 'Relationship to Student',
            controller: _guardianRelationController,
            prefixIcon: Icons.connect_without_contact,
          ),
        ],
      ),
    );
  }
}
