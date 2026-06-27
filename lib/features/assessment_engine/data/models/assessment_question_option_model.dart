class AssessmentQuestionOption {
  final String id;
  final String questionId;
  final String optionText;
  final String optionValue;
  final int optionOrder;
  final int scoreValue;

  const AssessmentQuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.optionValue,
    required this.optionOrder,
    required this.scoreValue,
  });

  factory AssessmentQuestionOption.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestionOption(
      id: json['id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      optionText: json['option_text'] as String? ?? '',
      optionValue: json['option_value'] as String? ?? '',
      optionOrder: json['option_order'] as int? ?? 1,
      scoreValue: json['score_value'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'option_text': optionText,
      'option_value': optionValue,
      'option_order': optionOrder,
      'score_value': scoreValue,
    };
  }
}
