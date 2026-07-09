import 'dart:convert';
import 'package:flutter/foundation.dart';

class StudentQualification {
  final String id;
  final String type;
  final String institutionName;
  final String boardOrUniversity;
  final String courseOrStream;
  final String gradeOrYear;
  final String startYear;
  final String endYear;
  final bool isCurrent;
  final String city;
  final String state;

  const StudentQualification({
    required this.id,
    required this.type,
    this.institutionName = '',
    this.boardOrUniversity = '',
    this.courseOrStream = '',
    this.gradeOrYear = '',
    this.startYear = '',
    this.endYear = '',
    this.isCurrent = false,
    this.city = '',
    this.state = '',
  });

  factory StudentQualification.fromJson(Map<String, dynamic> json) {
    return StudentQualification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'School',
      institutionName: json['institution_name'] as String? ?? '',
      boardOrUniversity: json['board_or_university'] as String? ?? '',
      courseOrStream: json['course_or_stream'] as String? ?? '',
      gradeOrYear: json['grade_or_year'] as String? ?? '',
      startYear: json['start_year'] as String? ?? json['startYear'] as String? ?? '',
      endYear: json['end_year'] as String? ?? json['endYear'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? json['isCurrent'] as bool? ?? false,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'institution_name': institutionName,
      'board_or_university': boardOrUniversity,
      'course_or_stream': courseOrStream,
      'grade_or_year': gradeOrYear,
      'start_year': startYear,
      'end_year': endYear,
      'is_current': isCurrent,
      'city': city,
      'state': state,
    };
  }

  StudentQualification copyWith({
    String? id,
    String? type,
    String? institutionName,
    String? boardOrUniversity,
    String? courseOrStream,
    String? gradeOrYear,
    String? startYear,
    String? endYear,
    bool? isCurrent,
    String? city,
    String? state,
  }) {
    return StudentQualification(
      id: id ?? this.id,
      type: type ?? this.type,
      institutionName: institutionName ?? this.institutionName,
      boardOrUniversity: boardOrUniversity ?? this.boardOrUniversity,
      courseOrStream: courseOrStream ?? this.courseOrStream,
      gradeOrYear: gradeOrYear ?? this.gradeOrYear,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      isCurrent: isCurrent ?? this.isCurrent,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }
}

class StudentProfileModel {
  final String userId;
  final String email;
  final String fullName;
  final String phone;
  final String? educationStage;
  final String? gradeOrYear;
  final String? schoolOrCollege;
  final String? boardOrUniversity;
  final String? city;
  final String? state;
  final DateTime? dateOfBirth;
  final String? gender;
  final int profileCompletion;
  final Map<String, dynamic> educationMetadata;
  final List<StudentQualification> qualifications;

  const StudentProfileModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.phone,
    this.educationStage,
    this.gradeOrYear,
    this.schoolOrCollege,
    this.boardOrUniversity,
    this.city,
    this.state,
    this.dateOfBirth,
    this.gender,
    this.profileCompletion = 0,
    this.educationMetadata = const {},
    this.qualifications = const [],
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    final studentProfilesData = json['student_profiles'];
    Map<String, dynamic> subProfile = {};
    if (studentProfilesData is List && studentProfilesData.isNotEmpty) {
      subProfile = studentProfilesData.first as Map<String, dynamic>;
    } else if (studentProfilesData is Map<String, dynamic>) {
      subProfile = studentProfilesData;
    }

    DateTime? dob;
    final dobStr = subProfile['date_of_birth'] as String? ?? json['date_of_birth'] as String? ?? json['dateOfBirth'] as String?;
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        dob = DateTime.parse(dobStr);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date_of_birth: $e');
        }
      }
    }

    final String? educationStage = subProfile['education_stage'] as String? ?? json['education_stage'] as String? ?? json['educationStage'] as String?;
    
    Map<String, dynamic> metadata = {};
    final metadataRaw = subProfile['education_metadata'] ?? json['education_metadata'] ?? json['educationMetadata'];
    if (metadataRaw is Map<String, dynamic>) {
      metadata = Map<String, dynamic>.from(metadataRaw);
    } else if (metadataRaw is String) {
      try {
        metadata = Map<String, dynamic>.from(jsonDecode(metadataRaw));
      } catch (_) {}
    }

    // Always ensure education_stage is present in metadata
    if (educationStage != null && educationStage.isNotEmpty) {
      metadata['education_stage'] = educationStage;
    }

    final String? city = subProfile['city'] as String? ?? json['city'] as String? ?? json['city'] as String?;
    final String? state = subProfile['state'] as String? ?? json['state'] as String? ?? json['state'] as String?;

    // Extract or Migrate Qualifications:
    List<StudentQualification> qualificationsList = [];
    final qualsRaw = metadata['qualifications'];
    if (qualsRaw is List && qualsRaw.isNotEmpty) {
      qualificationsList = qualsRaw
          .map((e) => StudentQualification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      // Migrate from old metadata format or subProfile legacy fields:
      String type = 'School';
      if (educationStage == 'School Student') {
        type = 'School';
      } else if (educationStage == 'PUC / Intermediate') {
        type = 'PUC';
      } else if (educationStage == 'Diploma') {
        type = 'Diploma';
      } else if (educationStage == 'Undergraduate') {
        type = 'Undergraduate';
      } else if (educationStage == 'Postgraduate') {
        type = 'Postgraduate';
      } else if (educationStage == 'Working Professional') {
        type = 'Work Experience';
      }

      String instName = metadata['school_name'] as String? ?? 
          metadata['college_name'] as String? ?? 
          metadata['institution_name'] as String? ?? 
          metadata['organization'] as String? ?? 
          subProfile['school_or_college'] as String? ?? 
          json['school_or_college'] as String? ?? '';

      String board = metadata['board'] as String? ?? 
          metadata['board_or_university'] as String? ?? 
          metadata['university'] as String? ?? 
          subProfile['board_or_university'] as String? ?? 
          json['board_or_university'] as String? ?? '';

      String course = metadata['stream'] as String? ?? 
          metadata['branch'] as String? ?? 
          metadata['degree'] as String? ?? 
          metadata['job_title'] as String? ?? '';

      String grade = metadata['class'] as String? ?? 
          metadata['year'] as String? ?? 
          metadata['semester'] as String? ?? 
          metadata['year_or_semester'] as String? ?? 
          metadata['experience_years'] as String? ?? 
          subProfile['grade_or_year'] as String? ?? 
          json['grade_or_year'] as String? ?? '';

      if (instName.isNotEmpty || board.isNotEmpty || course.isNotEmpty || grade.isNotEmpty) {
        qualificationsList.add(
          StudentQualification(
            id: 'legacy_1',
            type: type,
            institutionName: instName,
            boardOrUniversity: board,
            courseOrStream: course,
            gradeOrYear: grade,
          ),
        );
      }
    }

    // Default prefill: If qualificationsList is still empty, and we have an educationStage,
    // prefill a single default qualification to avoid showing "No qualifications added yet"
    if (qualificationsList.isEmpty && educationStage != null && educationStage.isNotEmpty && educationStage != 'Other') {
      String type = 'School';
      if (educationStage == 'School Student') {
        type = 'School';
      } else if (educationStage == 'PUC / Intermediate') {
        type = 'PUC';
      } else if (educationStage == 'Diploma') {
        type = 'Diploma';
      } else if (educationStage == 'Undergraduate') {
        type = 'Undergraduate';
      } else if (educationStage == 'Postgraduate') {
        type = 'Postgraduate';
      } else if (educationStage == 'Working Professional') {
        type = 'Work Experience';
      }
      qualificationsList.add(
        StudentQualification(
          id: 'initial_1',
          type: type,
          institutionName: '',
          boardOrUniversity: '',
          courseOrStream: '',
          gradeOrYear: '',
          isCurrent: true,
          city: city ?? '',
          state: state ?? '',
        ),
      );
    }

    // Embed qualifications back into metadata for serialisation consistency
    final finalMetadata = {
      ...metadata,
      'qualifications': qualificationsList.map((q) => q.toJson()).toList(),
    };

    return StudentProfileModel(
      userId: json['id'] as String? ?? json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      educationStage: educationStage,
      gradeOrYear: subProfile['grade_or_year'] as String? ?? json['grade_or_year'] as String?,
      schoolOrCollege: subProfile['school_or_college'] as String? ?? json['school_or_college'] as String?,
      boardOrUniversity: subProfile['board_or_university'] as String? ?? json['board_or_university'] as String?,
      city: city,
      state: state,
      dateOfBirth: dob,
      gender: subProfile['gender'] as String? ?? json['gender'] as String?,
      profileCompletion: (subProfile['profile_completion'] as num? ?? json['profile_completion'] as num?)?.toInt() ?? 0,
      educationMetadata: finalMetadata,
      qualifications: qualificationsList,
    );
  }

  StudentProfileModel copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? phone,
    String? educationStage,
    String? gradeOrYear,
    String? schoolOrCollege,
    String? boardOrUniversity,
    String? city,
    String? state,
    DateTime? dateOfBirth,
    String? gender,
    int? profileCompletion,
    Map<String, dynamic>? educationMetadata,
    List<StudentQualification>? qualifications,
  }) {
    final newQuals = qualifications ?? this.qualifications;
    final Map<String, dynamic> newMeta = Map.from(educationMetadata ?? this.educationMetadata);
    newMeta['qualifications'] = newQuals.map((q) => q.toJson()).toList();

    return StudentProfileModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      educationStage: educationStage ?? this.educationStage,
      gradeOrYear: gradeOrYear ?? this.gradeOrYear,
      schoolOrCollege: schoolOrCollege ?? this.schoolOrCollege,
      boardOrUniversity: boardOrUniversity ?? this.boardOrUniversity,
      city: city ?? this.city,
      state: state ?? this.state,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      educationMetadata: newMeta,
      qualifications: newQuals,
    );
  }
}
