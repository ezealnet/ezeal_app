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
import '../../data/models/student_profile_model.dart';
import '../controllers/student_profile_controller.dart';
import '../widgets/profile_completion_widget.dart';

class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;

  // Personal & Location Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Dynamic Education Stage Controllers
  final _schoolNameController = TextEditingController();
  final _pucCollegeController = TextEditingController();
  final _pucBoardController = TextEditingController();
  final _diplomaSemController = TextEditingController();
  final _diplomaInstController = TextEditingController();
  final _diplomaBoardController = TextEditingController();
  final _ugSpecializationController = TextEditingController();
  final _ugYearSemController = TextEditingController();
  final _ugCollegeController = TextEditingController();
  final _ugUnivController = TextEditingController();
  final _pgSpecializationController = TextEditingController();
  final _pgYearSemController = TextEditingController();
  final _pgCollegeController = TextEditingController();
  final _pgUnivController = TextEditingController();
  final _wpJobTitleController = TextEditingController();
  final _wpExperienceController = TextEditingController();
  final _wpOrgController = TextEditingController();
  final _wpHighestQualController = TextEditingController();

  // Selected Dropdown States
  DateTime? _dob;
  String? _gender;
  String? _educationStage;

  // School Student Dropdown States
  String? _schoolClass;
  String? _schoolBoard;

  // PUC / Intermediate Dropdown States
  String? _pucYear;
  String? _pucStream;

  // Diploma Dropdown States
  String? _diplomaBranch;

  // Undergraduate Dropdown States
  String? _ugDegree;

  // Postgraduate Dropdown States
  String? _pgDegree;

  // Working Professional Dropdown States
  String? _wpIndustry;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _stateController.dispose();

    _schoolNameController.dispose();
    _pucCollegeController.dispose();
    _pucBoardController.dispose();
    _diplomaSemController.dispose();
    _diplomaInstController.dispose();
    _diplomaBoardController.dispose();
    _ugSpecializationController.dispose();
    _ugYearSemController.dispose();
    _ugCollegeController.dispose();
    _ugUnivController.dispose();
    _pgSpecializationController.dispose();
    _pgYearSemController.dispose();
    _pgCollegeController.dispose();
    _pgUnivController.dispose();
    _wpJobTitleController.dispose();
    _wpExperienceController.dispose();
    _wpOrgController.dispose();
    _wpHighestQualController.dispose();
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
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _handleSave(StudentProfileModel currentProfile) async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> metadata = {};

      if (_educationStage == 'School Student') {
        metadata['class'] = _schoolClass ?? '';
        metadata['board'] = _schoolBoard ?? '';
        metadata['school_name'] = _schoolNameController.text.trim();
      } else if (_educationStage == 'PUC / Intermediate') {
        metadata['year'] = _pucYear ?? '';
        metadata['stream'] = _pucStream ?? '';
        metadata['college_name'] = _pucCollegeController.text.trim();
        metadata['board'] = _pucBoardController.text.trim();
      } else if (_educationStage == 'Diploma') {
        metadata['branch'] = _diplomaBranch ?? '';
        metadata['semester'] = _diplomaSemController.text.trim();
        metadata['institution_name'] = _diplomaInstController.text.trim();
        metadata['board_or_university'] = _diplomaBoardController.text.trim();
      } else if (_educationStage == 'Undergraduate') {
        metadata['degree'] = _ugDegree ?? '';
        metadata['specialization'] = _ugSpecializationController.text.trim();
        metadata['year_or_semester'] = _ugYearSemController.text.trim();
        metadata['college_name'] = _ugCollegeController.text.trim();
        metadata['university'] = _ugUnivController.text.trim();
      } else if (_educationStage == 'Postgraduate') {
        metadata['degree'] = _pgDegree ?? '';
        metadata['specialization'] = _pgSpecializationController.text.trim();
        metadata['year_or_semester'] = _pgYearSemController.text.trim();
        metadata['college_name'] = _pgCollegeController.text.trim();
        metadata['university'] = _pgUnivController.text.trim();
      } else if (_educationStage == 'Working Professional') {
        metadata['job_title'] = _wpJobTitleController.text.trim();
        metadata['industry'] = _wpIndustry ?? '';
        metadata['experience_years'] = _wpExperienceController.text.trim();
        metadata['organization'] = _wpOrgController.text.trim();
        metadata['highest_qualification'] = _wpHighestQualController.text.trim();
      }

      // Include stage in metadata
      metadata['education_stage'] = _educationStage;

      final updatedProfile = currentProfile.copyWith(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        educationStage: _educationStage,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        educationMetadata: metadata,
      );

      final success = await ref
          .read(studentProfileControllerProvider.notifier)
          .saveProfile(updatedProfile);

      if (mounted) {
        if (success) {
          SnackbarHelper.showSuccess(context, 'Profile updated successfully.');
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

    // Initialize fields once data is loaded
    profileAsync.whenData((profile) {
      if (profile != null && !_initialized) {
        _fullNameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phone;
        _dob = profile.dateOfBirth;
        if (_dob != null) {
          _dobController.text = "${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}";
        }

        // Validate Gender Dropdown values
        final validGenders = ['Male', 'Female', 'Other', 'Prefer not to say'];
        _gender = validGenders.contains(profile.gender) ? profile.gender : null;

        // Validate Education Stage Dropdown values
        final validStages = ['School Student', 'PUC / Intermediate', 'Diploma', 'Undergraduate', 'Postgraduate', 'Working Professional'];
        _educationStage = validStages.contains(profile.educationStage) ? profile.educationStage : null;

        _cityController.text = profile.city ?? '';
        _stateController.text = profile.state ?? '';

        // Hydrate dynamic fields from educationMetadata and validate dropdown values
        final meta = profile.educationMetadata;
        if (_educationStage == 'School Student') {
          final validClasses = ['6', '7', '8', '9', '10', '11', '12'];
          final cl = meta['class']?.toString();
          _schoolClass = validClasses.contains(cl) ? cl : null;

          final validBoards = ['CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE', 'Others'];
          final bd = meta['board']?.toString();
          _schoolBoard = validBoards.contains(bd) ? bd : null;

          _schoolNameController.text = meta['school_name']?.toString() ?? '';
        } else if (_educationStage == 'PUC / Intermediate') {
          final validYears = ['1st Year', '2nd Year'];
          final yr = meta['year']?.toString();
          _pucYear = validYears.contains(yr) ? yr : null;

          final validStreams = ['Science', 'Commerce', 'Arts'];
          final str = meta['stream']?.toString();
          _pucStream = validStreams.contains(str) ? str : null;

          _pucCollegeController.text = meta['college_name']?.toString() ?? '';
          _pucBoardController.text = meta['board']?.toString() ?? '';
        } else if (_educationStage == 'Diploma') {
          final validBranches = ['Computer Science', 'Mechanical', 'Civil', 'Electrical', 'Electronics', 'Others'];
          final br = meta['branch']?.toString();
          _diplomaBranch = validBranches.contains(br) ? br : null;

          _diplomaSemController.text = meta['semester']?.toString() ?? '';
          _diplomaInstController.text = meta['institution_name']?.toString() ?? '';
          _diplomaBoardController.text = meta['board_or_university']?.toString() ?? '';
        } else if (_educationStage == 'Undergraduate') {
          final validUGDegrees = ['B.Tech', 'BE', 'BCA', 'BBA', 'B.Com', 'BA', 'BSc', 'LLB', 'MBBS', 'BDS', 'B.Pharm', 'Others'];
          final ug = meta['degree']?.toString();
          _ugDegree = validUGDegrees.contains(ug) ? ug : null;

          _ugSpecializationController.text = meta['specialization']?.toString() ?? '';
          _ugYearSemController.text = meta['year_or_semester']?.toString() ?? '';
          _ugCollegeController.text = meta['college_name']?.toString() ?? '';
          _ugUnivController.text = meta['university']?.toString() ?? '';
        } else if (_educationStage == 'Postgraduate') {
          final validPGDegrees = ['MBA', 'MCA', 'M.Tech', 'M.Com', 'MA', 'MSc', 'LLM', 'MD', 'M.Pharm', 'Others'];
          final pg = meta['degree']?.toString();
          _pgDegree = validPGDegrees.contains(pg) ? pg : null;

          _pgSpecializationController.text = meta['specialization']?.toString() ?? '';
          _pgYearSemController.text = meta['year_or_semester']?.toString() ?? '';
          _pgCollegeController.text = meta['college_name']?.toString() ?? '';
          _pgUnivController.text = meta['university']?.toString() ?? '';
        } else if (_educationStage == 'Working Professional') {
          _wpJobTitleController.text = meta['job_title']?.toString() ?? '';

          final validIndustries = ['IT', 'Banking', 'Finance', 'Healthcare', 'Education', 'Manufacturing', 'Government', 'Entrepreneur', 'Others'];
          final ind = meta['industry']?.toString();
          _wpIndustry = validIndustries.contains(ind) ? ind : null;

          _wpExperienceController.text = meta['experience_years']?.toString() ?? '';
          _wpOrgController.text = meta['organization']?.toString() ?? '';
          _wpHighestQualController.text = meta['highest_qualification']?.toString() ?? '';
        }

        _initialized = true;
      }
    });

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
                      completionPercentage: profile.profileCompletion,
                      showButton: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section A: Personal Information
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Information',
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
                        AppTextField(
                          labelText: 'Mobile Number *',
                          controller: _phoneController,
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: AppValidators.phoneIndia,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: AppTextField(
                              labelText: 'Date of Birth *',
                              controller: _dobController,
                              prefixIcon: Icons.calendar_today,
                              validator: (v) => AppValidators.requiredText(v, 'Date of Birth'),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: InputDecoration(
                            labelText: 'Gender *',
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
                          validator: (v) => v == null ? 'Gender is required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section B: Dynamic Education Form
                  _buildEducationSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Section C: Location
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Details',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          labelText: 'City *',
                          controller: _cityController,
                          prefixIcon: Icons.location_city,
                          validator: (v) => AppValidators.requiredText(v, 'City'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          labelText: 'State *',
                          controller: _stateController,
                          prefixIcon: Icons.map,
                          validator: (v) => AppValidators.requiredText(v, 'State'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save Button
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

  Widget _buildEducationSection() {
    if (kDebugMode) {
      final profile = ref.read(studentProfileProvider).value;
      print('ProfilePage Debug: education_stage = $_educationStage');
      print('ProfilePage Debug: education_metadata = ${profile?.educationMetadata}');
      print('ProfilePage Debug: dropdown values before rendering: gender = $_gender, schoolClass = $_schoolClass, schoolBoard = $_schoolBoard, pucYear = $_pucYear, pucStream = $_pucStream, diplomaBranch = $_diplomaBranch, ugDegree = $_ugDegree, pgDegree = $_pgDegree, wpIndustry = $_wpIndustry');
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Education Information',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _educationStage,
            decoration: InputDecoration(
              labelText: 'Education Stage *',
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
            validator: (v) => v == null ? 'Education Stage is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (_educationStage == 'School Student') ..._buildSchoolStudentFields(),
          if (_educationStage == 'PUC / Intermediate') ..._buildPUCFields(),
          if (_educationStage == 'Diploma') ..._buildDiplomaFields(),
          if (_educationStage == 'Undergraduate') ..._buildUndergraduateFields(),
          if (_educationStage == 'Postgraduate') ..._buildPostgraduateFields(),
          if (_educationStage == 'Working Professional') ..._buildWorkingProfessionalFields(),
        ],
      ),
    );
  }

  List<Widget> _buildSchoolStudentFields() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _schoolClass,
        decoration: InputDecoration(
          labelText: 'Class *',
          prefixIcon: const Icon(Icons.class_, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: ['6', '7', '8', '9', '10', '11', '12']
            .map((c) => DropdownMenuItem(value: c, child: Text('Class $c')))
            .toList(),
        onChanged: (val) => setState(() => _schoolClass = val),
        validator: (v) => v == null ? 'Class is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<String>(
        initialValue: _schoolBoard,
        decoration: InputDecoration(
          labelText: 'Board *',
          prefixIcon: const Icon(Icons.assignment, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: ['CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE', 'Others']
            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
            .toList(),
        onChanged: (val) => setState(() => _schoolBoard = val),
        validator: (v) => v == null ? 'Board is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'School Name *',
        controller: _schoolNameController,
        prefixIcon: Icons.account_balance,
        validator: (v) => AppValidators.requiredText(v, 'School Name'),
      ),
    ];
  }

  List<Widget> _buildPUCFields() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _pucYear,
        decoration: InputDecoration(
          labelText: 'Year *',
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: const [
          DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
          DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
        ],
        onChanged: (val) => setState(() => _pucYear = val),
        validator: (v) => v == null ? 'Year is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<String>(
        initialValue: _pucStream,
        decoration: InputDecoration(
          labelText: 'Stream *',
          prefixIcon: const Icon(Icons.book, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: const [
          DropdownMenuItem(value: 'Science', child: Text('Science')),
          DropdownMenuItem(value: 'Commerce', child: Text('Commerce')),
          DropdownMenuItem(value: 'Arts', child: Text('Arts')),
        ],
        onChanged: (val) => setState(() => _pucStream = val),
        validator: (v) => v == null ? 'Stream is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'College Name *',
        controller: _pucCollegeController,
        prefixIcon: Icons.account_balance,
        validator: (v) => AppValidators.requiredText(v, 'College Name'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Board *',
        controller: _pucBoardController,
        prefixIcon: Icons.assignment,
        validator: (v) => AppValidators.requiredText(v, 'Board'),
      ),
    ];
  }

  List<Widget> _buildDiplomaFields() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _diplomaBranch,
        decoration: InputDecoration(
          labelText: 'Diploma Branch *',
          prefixIcon: const Icon(Icons.code, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: ['Computer Science', 'Mechanical', 'Civil', 'Electrical', 'Electronics', 'Others']
            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
            .toList(),
        onChanged: (val) => setState(() => _diplomaBranch = val),
        validator: (v) => v == null ? 'Diploma Branch is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Semester *',
        controller: _diplomaSemController,
        prefixIcon: Icons.timeline,
        validator: (v) => AppValidators.requiredText(v, 'Semester'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Institution Name *',
        controller: _diplomaInstController,
        prefixIcon: Icons.account_balance,
        validator: (v) => AppValidators.requiredText(v, 'Institution Name'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Board / University *',
        controller: _diplomaBoardController,
        prefixIcon: Icons.book,
        validator: (v) => AppValidators.requiredText(v, 'Board / University'),
      ),
    ];
  }

  List<Widget> _buildUndergraduateFields() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _ugDegree,
        decoration: InputDecoration(
          labelText: 'Degree *',
          prefixIcon: const Icon(Icons.school, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: const [
          DropdownMenuItem(value: 'B.Tech', child: Text('B.Tech')),
          DropdownMenuItem(value: 'BE', child: Text('BE')),
          DropdownMenuItem(value: 'BCA', child: Text('BCA')),
          DropdownMenuItem(value: 'BBA', child: Text('BBA')),
          DropdownMenuItem(value: 'B.Com', child: Text('B.Com')),
          DropdownMenuItem(value: 'BA', child: Text('BA')),
          DropdownMenuItem(value: 'BSc', child: Text('BSc')),
          DropdownMenuItem(value: 'LLB', child: Text('LLB')),
          DropdownMenuItem(value: 'MBBS', child: Text('MBBS')),
          DropdownMenuItem(value: 'BDS', child: Text('BDS')),
          DropdownMenuItem(value: 'B.Pharm', child: Text('B.Pharm')),
          DropdownMenuItem(value: 'Others', child: Text('Others')),
        ],
        onChanged: (val) => setState(() => _ugDegree = val),
        validator: (v) => v == null ? 'Degree is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Specialization *',
        controller: _ugSpecializationController,
        prefixIcon: Icons.bookmark,
        validator: (v) => AppValidators.requiredText(v, 'Specialization'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Year / Semester *',
        controller: _ugYearSemController,
        prefixIcon: Icons.timeline,
        validator: (v) => AppValidators.requiredText(v, 'Year / Semester'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'College Name *',
        controller: _ugCollegeController,
        prefixIcon: Icons.account_balance,
        validator: (v) => AppValidators.requiredText(v, 'College Name'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'University *',
        controller: _ugUnivController,
        prefixIcon: Icons.book,
        validator: (v) => AppValidators.requiredText(v, 'University'),
      ),
    ];
  }

  List<Widget> _buildPostgraduateFields() {
    return [
      DropdownButtonFormField<String>(
        initialValue: _pgDegree,
        decoration: InputDecoration(
          labelText: 'Degree *',
          prefixIcon: const Icon(Icons.school, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: const [
          DropdownMenuItem(value: 'MBA', child: Text('MBA')),
          DropdownMenuItem(value: 'MCA', child: Text('MCA')),
          DropdownMenuItem(value: 'M.Tech', child: Text('M.Tech')),
          DropdownMenuItem(value: 'M.Com', child: Text('M.Com')),
          DropdownMenuItem(value: 'MA', child: Text('MA')),
          DropdownMenuItem(value: 'MSc', child: Text('MSc')),
          DropdownMenuItem(value: 'LLM', child: Text('LLM')),
          DropdownMenuItem(value: 'MD', child: Text('MD')),
          DropdownMenuItem(value: 'M.Pharm', child: Text('M.Pharm')),
          DropdownMenuItem(value: 'Others', child: Text('Others')),
        ],
        onChanged: (val) => setState(() => _pgDegree = val),
        validator: (v) => v == null ? 'Degree is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Specialization *',
        controller: _pgSpecializationController,
        prefixIcon: Icons.bookmark,
        validator: (v) => AppValidators.requiredText(v, 'Specialization'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Year / Semester *',
        controller: _pgYearSemController,
        prefixIcon: Icons.timeline,
        validator: (v) => AppValidators.requiredText(v, 'Year / Semester'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'College Name *',
        controller: _pgCollegeController,
        prefixIcon: Icons.account_balance,
        validator: (v) => AppValidators.requiredText(v, 'College Name'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'University *',
        controller: _pgUnivController,
        prefixIcon: Icons.book,
        validator: (v) => AppValidators.requiredText(v, 'University'),
      ),
    ];
  }

  List<Widget> _buildWorkingProfessionalFields() {
    return [
      AppTextField(
        labelText: 'Job Title *',
        controller: _wpJobTitleController,
        prefixIcon: Icons.work,
        validator: (v) => AppValidators.requiredText(v, 'Job Title'),
      ),
      const SizedBox(height: AppSpacing.md),
      DropdownButtonFormField<String>(
        initialValue: _wpIndustry,
        decoration: InputDecoration(
          labelText: 'Industry *',
          prefixIcon: const Icon(Icons.business, size: 20),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        items: const [
          DropdownMenuItem(value: 'IT', child: Text('IT')),
          DropdownMenuItem(value: 'Banking', child: Text('Banking')),
          DropdownMenuItem(value: 'Finance', child: Text('Finance')),
          DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
          DropdownMenuItem(value: 'Education', child: Text('Education')),
          DropdownMenuItem(value: 'Manufacturing', child: Text('Manufacturing')),
          DropdownMenuItem(value: 'Government', child: Text('Government')),
          DropdownMenuItem(value: 'Entrepreneur', child: Text('Entrepreneur')),
          DropdownMenuItem(value: 'Others', child: Text('Others')),
        ],
        onChanged: (val) => setState(() => _wpIndustry = val),
        validator: (v) => v == null ? 'Industry is required' : null,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Years of Experience *',
        controller: _wpExperienceController,
        prefixIcon: Icons.timeline,
        keyboardType: TextInputType.number,
        validator: (v) => AppValidators.requiredText(v, 'Years of Experience'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Current Organization *',
        controller: _wpOrgController,
        prefixIcon: Icons.business_center,
        validator: (v) => AppValidators.requiredText(v, 'Current Organization'),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        labelText: 'Highest Qualification *',
        controller: _wpHighestQualController,
        prefixIcon: Icons.workspace_premium,
        validator: (v) => AppValidators.requiredText(v, 'Highest Qualification'),
      ),
    ];
  }
}
