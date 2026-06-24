import 'dart:convert';
import 'package:flutter/foundation.dart';

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
    final dobStr = subProfile['date_of_birth'] as String?;
    if (dobStr != null && dobStr.isNotEmpty) {
      try {
        dob = DateTime.parse(dobStr);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date_of_birth: $e');
        }
      }
    }

    final String? educationStage = subProfile['education_stage'] as String?;
    
    Map<String, dynamic> metadata = {};
    final metadataRaw = subProfile['education_metadata'];
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

    // Backward compatibility migration:
    // If metadata is empty (or only contains education_stage) but legacy fields exist, migrate them.
    if ((metadata.isEmpty || (metadata.length == 1 && metadata.containsKey('education_stage'))) && educationStage != null) {
      final legacyGrade = subProfile['grade_or_year'] as String? ?? '';
      final legacySchool = subProfile['school_or_college'] as String? ?? '';
      final legacyBoard = subProfile['board_or_university'] as String? ?? '';
      
      if (legacyGrade.isNotEmpty || legacySchool.isNotEmpty || legacyBoard.isNotEmpty) {
        if (educationStage == 'School Student') {
          metadata = {
            'education_stage': educationStage,
            'class': legacyGrade,
            'board': legacyBoard,
            'school_name': legacySchool,
          };
        } else if (educationStage == 'PUC / Intermediate') {
          metadata = {
            'education_stage': educationStage,
            'year': legacyGrade,
            'board': legacyBoard,
            'college_name': legacySchool,
            'stream': '',
          };
        } else if (educationStage == 'Diploma') {
          metadata = {
            'education_stage': educationStage,
            'semester': legacyGrade,
            'board_or_university': legacyBoard,
            'institution_name': legacySchool,
            'branch': '',
          };
        } else if (educationStage == 'Undergraduate' || educationStage == 'Postgraduate') {
          metadata = {
            'education_stage': educationStage,
            'year_or_semester': legacyGrade,
            'university': legacyBoard,
            'college_name': legacySchool,
            'degree': '',
            'specialization': '',
          };
        } else if (educationStage == 'Working Professional') {
          metadata = {
            'education_stage': educationStage,
            'experience_years': legacyGrade,
            'organization': legacySchool,
            'job_title': '',
            'industry': '',
            'highest_qualification': '',
          };
        }
      }
    }

    return StudentProfileModel(
      userId: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      educationStage: educationStage,
      gradeOrYear: subProfile['grade_or_year'] as String?,
      schoolOrCollege: subProfile['school_or_college'] as String?,
      boardOrUniversity: subProfile['board_or_university'] as String?,
      city: subProfile['city'] as String?,
      state: subProfile['state'] as String?,
      dateOfBirth: dob,
      gender: subProfile['gender'] as String?,
      profileCompletion: (subProfile['profile_completion'] as num?)?.toInt() ?? 0,
      educationMetadata: metadata,
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
  }) {
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
      educationMetadata: educationMetadata ?? this.educationMetadata,
    );
  }
}
