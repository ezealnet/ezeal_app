import 'assessment_question_option_model.dart';

class AssessmentQuestion {
  final String id;
  final String assessmentId;
  final String questionText;
  final String questionType;
  final int questionOrder;
  final String? scoringKey;
  final bool isActive;
  final List<AssessmentQuestionOption> options;

  const AssessmentQuestion({
    required this.id,
    required this.assessmentId,
    required this.questionText,
    required this.questionType,
    required this.questionOrder,
    this.scoringKey,
    required this.isActive,
    required this.options,
  });

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json, [List<AssessmentQuestionOption> options = const []]) {
    return AssessmentQuestion(
      id: json['id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'single_choice',
      questionOrder: json['question_order'] as int? ?? 1,
      scoringKey: json['scoring_key'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'question_text': questionText,
      'question_type': questionType,
      'question_order': questionOrder,
      'scoring_key': scoringKey,
      'is_active': isActive,
    };
  }
}
