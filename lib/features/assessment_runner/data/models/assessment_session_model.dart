class AssessmentSession {
  final String id;
  final String attemptId;
  final String userId;
  final DateTime startedAt;
  final DateTime lastActiveAt;
  final int resumeCount;
  final String? deviceType;
  final String? browserName;
  final String sessionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssessmentSession({
    required this.id,
    required this.attemptId,
    required this.userId,
    required this.startedAt,
    required this.lastActiveAt,
    required this.resumeCount,
    this.deviceType,
    this.browserName,
    required this.sessionStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentSession.fromJson(Map<String, dynamic> json) {
    return AssessmentSession(
      id: json['id'] as String? ?? '',
      attemptId: json['attempt_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : DateTime.now(),
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at'] as String) : DateTime.now(),
      resumeCount: json['resume_count'] as int? ?? 0,
      deviceType: json['device_type'] as String?,
      browserName: json['browser_name'] as String?,
      sessionStatus: json['session_status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'resume_count': resumeCount,
      'device_type': deviceType,
      'browser_name': browserName,
      'session_status': sessionStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
