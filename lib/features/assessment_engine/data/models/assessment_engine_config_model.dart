class AssessmentEngineConfig {
  final String id;
  final String assessmentId;
  final bool passingRequired;
  final bool allowResume;
  final bool randomizeQuestions;
  final bool randomizeOptions;
  final bool showProgress;
  final int durationMinutes;

  const AssessmentEngineConfig({
    required this.id,
    required this.assessmentId,
    required this.passingRequired,
    required this.allowResume,
    required this.randomizeQuestions,
    required this.randomizeOptions,
    required this.showProgress,
    required this.durationMinutes,
  });

  factory AssessmentEngineConfig.fromJson(Map<String, dynamic> json) {
    return AssessmentEngineConfig(
      id: json['id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      passingRequired: json['passing_required'] as bool? ?? false,
      allowResume: json['allow_resume'] as bool? ?? true,
      randomizeQuestions: json['randomize_questions'] as bool? ?? false,
      randomizeOptions: json['randomize_options'] as bool? ?? false,
      showProgress: json['show_progress'] as bool? ?? true,
      durationMinutes: json['duration_minutes'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'passing_required': passingRequired,
      'allow_resume': allowResume,
      'randomize_questions': randomizeQuestions,
      'randomize_options': randomizeOptions,
      'show_progress': showProgress,
      'duration_minutes': durationMinutes,
    };
  }
}
