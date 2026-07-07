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
          'education_stage': 'School Student',
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'profile_completion': 40,
          'education_metadata': {}
        }
      };

      final model = StudentProfileModel.fromJson(raw);
      expect(model.qualifications, isEmpty);
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

    test('calculates correct completion for partially filled profile', () {
      // 3 fields: Name, Phone, Stage = 3 / 8 = 38%
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

      expect(completion, 38);
    });

    test('calculates correct completion with qualifications and parent details', () {
      // 8 core fields: Name, Phone, DOB, Gender, City, State, Stage, Qualifications = 8 / 8 = 100%
      // Plus guardian details = total 9 fields. All filled = 100%
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
            {'type': 'School', 'institution_name': 'High School'}
          ],
          'guardian_name': 'John Doe'
        },
      );

      expect(completion, 100);
    });
  });
}
