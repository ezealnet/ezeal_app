import 'package:flutter_test/flutter_test.dart';
import 'package:ezeal/features/student/data/models/student_profile_model.dart';
import 'package:ezeal/features/student/presentation/controllers/student_profile_controller.dart';

void main() {
  group('StudentQualification Tests', () {
    test('fromJson & toJson serialization', () {
      final json = {
        'id': 'q-1',
        'type': 'Undergraduate',
        'institution_name': 'Harvard',
        'board_or_university': 'Ivy League',
        'course_or_stream': 'CS',
        'grade_or_year': 'A',
        'start_year': '2020',
        'end_year': '2024',
        'is_current': false,
        'city': 'Boston',
        'state': 'MA'
      };

      final qual = StudentQualification.fromJson(json);
      expect(qual.id, 'q-1');
      expect(qual.type, 'Undergraduate');
      expect(qual.institutionName, 'Harvard');
      expect(qual.isCurrent, false);

      final outJson = qual.toJson();
      expect(outJson['institution_name'], 'Harvard');
      expect(outJson['is_current'], false);
    });
  });

  group('StudentProfileModel Legacy Migration Tests', () {
    test('loads empty qualifications correctly', () {
      final raw = {
        'id': 'usr-1',
        'email': 'student@ezeal.net',
        'full_name': 'Jane Doe',
        'phone': '9876543210',
        'student_profiles': {
          'education_stage': null,
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'profile_completion': 40,
          'education_metadata': {}
        }
      };

      final model = StudentProfileModel.fromJson(raw);
      expect(model.qualifications, isEmpty);
    });

    test('prefills default qualification when stage is present but qualifications is empty', () {
      final raw = {
        'id': 'usr-1',
        'email': 'student@ezeal.net',
        'full_name': 'Jane Doe',
        'phone': '9876543210',
        'student_profiles': {
          'education_stage': 'School Student',
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'profile_completion': 40,
          'education_metadata': {}
        }
      };

      final model = StudentProfileModel.fromJson(raw);
      expect(model.qualifications, isNotEmpty);
      expect(model.qualifications.first.type, 'School');
      expect(model.qualifications.first.city, 'Bengaluru');
      expect(model.qualifications.first.state, 'Karnataka');
    });

    test('migrates legacy fields from metadata into qualifications', () {
      final raw = {
        'id': 'usr-1',
        'email': 'student@ezeal.net',
        'full_name': 'Jane Doe',
        'phone': '9876543210',
        'student_profiles': {
          'education_stage': 'School Student',
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'profile_completion': 40,
          'education_metadata': {
            'school_name': 'St. Josephs',
            'board': 'CBSE',
            'class': '10'
          }
        }
      };

      final model = StudentProfileModel.fromJson(raw);
      expect(model.qualifications, isNotEmpty);
      expect(model.qualifications.first.type, 'School');
      expect(model.qualifications.first.institutionName, 'St. Josephs');
      expect(model.qualifications.first.boardOrUniversity, 'CBSE');
      expect(model.qualifications.first.gradeOrYear, '10');
    });

    test('migrates legacy fields from columns if metadata is absent', () {
      final raw = {
        'id': 'usr-2',
        'email': 'student@ezeal.net',
        'full_name': 'Jane Doe',
        'phone': '9876543210',
        'student_profiles': {
          'education_stage': 'PUC / Intermediate',
          'school_or_college': 'PUC College',
          'board_or_university': 'State Board',
          'grade_or_year': '12',
          'profile_completion': 30,
          'education_metadata': null
        }
      };

      final model = StudentProfileModel.fromJson(raw);
      expect(model.qualifications, isNotEmpty);
      expect(model.qualifications.first.type, 'PUC');
      expect(model.qualifications.first.institutionName, 'PUC College');
      expect(model.qualifications.first.boardOrUniversity, 'State Board');
      expect(model.qualifications.first.gradeOrYear, '12');
    });
  });

  group('StudentProfileController Completion Calculation Tests', () {
    final controller = StudentProfileController();

    test('calculates correct completion for partially filled profile (legacy wrapper)', () {
      final completion = controller.calculateCompletion(
        fullName: 'Jane Doe',
        phone: '9876543210',
        dateOfBirth: null,
        gender: '',
        educationStage: 'School Student',
        city: '',
        state: '',
        metadata: {},
      );

      // Personal: Name (7.5%), Phone (7.5%) = 15.0%
      // Location: 0%
      // Education/Qualifications: Stage (5.0%), qualifications list is empty = 5.0%
      // Total = 15.0% + 5.0% = 20.0%
      expect(completion, 20);
    });

    test('calculates correct completion with qualifications and parent details (legacy wrapper)', () {
      final completion = controller.calculateCompletion(
        fullName: 'Jane Doe',
        phone: '9876543210',
        dateOfBirth: DateTime(2005, 1, 1),
        gender: 'Female',
        educationStage: 'School Student',
        city: 'Bengaluru',
        state: 'Karnataka',
        metadata: {
          'qualifications': [
            {
              'type': 'School',
              'institution_name': 'High School',
              'board_or_university': '',
              'course_or_stream': '',
              'grade_or_year': '',
            }
          ],
          'guardian_name': 'John Doe'
        },
      );

      // Personal: Name (7.5%), Phone (7.5%), DOB (7.5%), Gender (7.5%) = 30.0%
      // Location: City (7.5%), State (7.5%) = 15.0%
      // Education: Stage (5.0%), card present (5.0%), type "School" (5.0%), institution "High School" (5.0%) = 20.0%
      // Guardian: Name (3.33%) = 3.33%
      // Total = 30.0% + 15.0% + 20.0% + 3.33% = 68.33% (rounds to 68%)
      expect(completion, 68);
    });

    test('empty profile = 0%', () {
      final emptyProfile = StudentProfileModel(
        userId: 'u1',
        email: 'u1@ezeal.net',
        fullName: '',
        phone: '',
        educationStage: '',
        city: '',
        state: '',
        dateOfBirth: null,
        gender: '',
        educationMetadata: {},
        qualifications: [],
      );

      final completion = StudentProfileController.calculateLiveCompletion(emptyProfile);
      expect(completion, 0);
    });

    test('signup metadata prefill profile = 45%', () {
      final signupProfile = StudentProfileModel(
        userId: 'u1',
        email: 'u1@ezeal.net',
        fullName: 'Jane Doe',
        phone: '9876543210',
        educationStage: 'School Student',
        city: 'Bengaluru',
        state: 'Karnataka',
        dateOfBirth: null,
        gender: '',
        educationMetadata: {},
        qualifications: [
          StudentQualification(
            id: 'initial_1',
            type: 'School',
            institutionName: '',
            boardOrUniversity: '',
            courseOrStream: '',
            gradeOrYear: '',
          ),
        ],
      );

      // Personal: Name (7.5%), Phone (7.5%) = 15.0%
      // Location: City (7.5%), State (7.5%) = 15.0%
      // Education: Stage (5.0%), card present (5.0%), type "School" (5.0%) = 15.0%
      // Total = 45%
      final completion = StudentProfileController.calculateLiveCompletion(signupProfile);
      expect(completion, 45);
    });

    test('partial qualification details calculation', () {
      final partialProfile = StudentProfileModel(
        userId: 'u1',
        email: 'u1@ezeal.net',
        fullName: 'Jane Doe',
        phone: '9876543210',
        educationStage: 'School Student',
        city: 'Bengaluru',
        state: 'Karnataka',
        dateOfBirth: null,
        gender: '',
        educationMetadata: {},
        qualifications: [
          StudentQualification(
            id: 'initial_1',
            type: 'School',
            institutionName: 'St. Marys',
            boardOrUniversity: 'CBSE',
            courseOrStream: '',
            gradeOrYear: '',
          ),
        ],
      );

      // Personal: 15%
      // Location: 15%
      // Education: Stage (5%), Card (5%), Type (5%), Inst (5%), Board (5%) = 25%
      // Total = 55%
      final completion = StudentProfileController.calculateLiveCompletion(partialProfile);
      expect(completion, 55);
    });

    test('full qualification details calculation', () {
      final fullQualProfile = StudentProfileModel(
        userId: 'u1',
        email: 'u1@ezeal.net',
        fullName: 'Jane Doe',
        phone: '9876543210',
        educationStage: 'School Student',
        city: 'Bengaluru',
        state: 'Karnataka',
        dateOfBirth: DateTime(2005, 1, 1),
        gender: 'Female',
        educationMetadata: {},
        qualifications: [
          StudentQualification(
            id: 'initial_1',
            type: 'School',
            institutionName: 'St. Marys',
            boardOrUniversity: 'CBSE',
            courseOrStream: 'Science',
            gradeOrYear: '10',
          ),
        ],
      );

      // Personal: 30%
      // Location: 15%
      // Education: Stage (5%), Card (5%), Type (5%), Inst (5%), Board (5%), Course (5%), Grade (5%) = 35%
      // Total = 80%
      final completion = StudentProfileController.calculateLiveCompletion(fullQualProfile);
      expect(completion, 80);
    });

    test('full qualification + guardian details calculation', () {
      final guardianProfile = StudentProfileModel(
        userId: 'u1',
        email: 'u1@ezeal.net',
        fullName: 'Jane Doe',
        phone: '9876543210',
        educationStage: 'School Student',
        city: 'Bengaluru',
        state: 'Karnataka',
        dateOfBirth: DateTime(2005, 1, 1),
        gender: 'Female',
        educationMetadata: {
          'guardian_name': 'John Doe',
          'guardian_phone': '9999999999',
          'guardian_relation': 'Father',
        },
        qualifications: [
          StudentQualification(
            id: 'initial_1',
            type: 'School',
            institutionName: 'St. Marys',
            boardOrUniversity: 'CBSE',
            courseOrStream: 'Science',
            gradeOrYear: '10',
          ),
        ],
      );

      // Personal: 30%
      // Location: 15%
      // Education: 35%
      // Guardian: Name (3.33%), Phone (3.33%), Relation (3.34%) = 10%
      // Total = 90%
      final completion = StudentProfileController.calculateLiveCompletion(guardianProfile);
      expect(completion, 90);
    });

    test('full profile + verified Aadhaar calculation (clamped to 100%)', () {
      final verifiedProfile = StudentProfileModel(
        userId: 'u1',
        email: 'u1@ezeal.net',
        fullName: 'Jane Doe',
        phone: '9876543210',
        educationStage: 'School Student',
        city: 'Bengaluru',
        state: 'Karnataka',
        dateOfBirth: DateTime(2005, 1, 1),
        gender: 'Female',
        educationMetadata: {
          'guardian_name': 'John Doe',
          'guardian_phone': '9999999999',
          'guardian_relation': 'Father',
        },
        qualifications: [
          StudentQualification(
            id: 'initial_1',
            type: 'School',
            institutionName: 'St. Marys',
            boardOrUniversity: 'CBSE',
            courseOrStream: 'Science',
            gradeOrYear: '10',
          ),
        ],
      );

      // Personal: 30%
      // Location: 15%
      // Education: 35%
      // Guardian: 10%
      // Verification: 10%
      // Total = 100%
      final completion = StudentProfileController.calculateLiveCompletion(verifiedProfile, isVerified: true);
      expect(completion, 100);
    });
  });
}
