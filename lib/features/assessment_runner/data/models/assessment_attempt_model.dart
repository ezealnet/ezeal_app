class AssessmentAttempt {
  final String id;
  final String userId;
  final String assessmentId;
  final String assessmentAccessId;
  final String status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int currentQuestionIndex;
  final int answeredCount;
  final double completionPercentage;
  final DateTime lastActiveAt;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssessmentAttempt({
    required this.id,
    required this.userId,
    required this.assessmentId,
    required this.assessmentAccessId,
    required this.status,
    required this.startedAt,
    this.submittedAt,
    required this.currentQuestionIndex,
    required this.answeredCount,
    required this.completionPercentage,
    required this.lastActiveAt,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentAttempt.fromJson(Map<String, dynamic> json) {
    return AssessmentAttempt(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      assessmentAccessId: json['assessment_access_id'] as String? ?? '',
      status: json['status'] as String? ?? 'in_progress',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : DateTime.now(),
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
      currentQuestionIndex: json['current_question_index'] as int? ?? 0,
      answeredCount: json['answered_count'] as int? ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at'] as String) : DateTime.now(),
      version: json['version'] as int? ?? 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assessment_id': assessmentId,
      'assessment_access_id': assessmentAccessId,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'current_question_index': currentQuestionIndex,
      'answered_count': answeredCount,
      'completion_percentage': completionPercentage,
      'last_active_at': lastActiveAt.toIso8601String(),
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AssessmentAttempt copyWith({
    String? id,
    String? userId,
    String? assessmentId,
    String? assessmentAccessId,
    String? status,
    DateTime? startedAt,
    DateTime? submittedAt,
    int? currentQuestionIndex,
    int? answeredCount,
    double? completionPercentage,
    DateTime? lastActiveAt,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessmentId: assessmentId ?? this.assessmentId,
      assessmentAccessId: assessmentAccessId ?? this.assessmentAccessId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answeredCount: answeredCount ?? this.answeredCount,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
