class AssessmentAnswer {
  final String id;
  final String attemptId;
  final String questionId;
  final String? selectedOptionId;
  final String? answerValue;
  final DateTime answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssessmentAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.selectedOptionId,
    this.answerValue,
    required this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentAnswer.fromJson(Map<String, dynamic> json) {
    return AssessmentAnswer(
      id: json['id'] as String? ?? '',
      attemptId: json['attempt_id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      selectedOptionId: json['selected_option_id'] as String?,
      answerValue: json['answer_value'] as String?,
      answeredAt: json['answered_at'] != null ? DateTime.parse(json['answered_at'] as String) : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'selected_option_id': selectedOptionId,
      'answer_value': answerValue,
      'answered_at': answeredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
