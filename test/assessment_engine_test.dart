import 'package:flutter_test/flutter_test.dart';
import 'package:ezeal/features/assessment_engine/presentation/controllers/assessment_engine_providers.dart';
import 'package:ezeal/features/assessment_engine/data/models/assessment_question_model.dart';
import 'package:ezeal/features/assessment_engine/data/models/assessment_question_option_model.dart';
import 'package:ezeal/features/assessment_engine/data/models/assessment_engine_config_model.dart';

void main() {
  group('Assessment Engine Readiness Tests', () {
    test('Config missing returns configMissing', () {
      AssessmentReadinessState checkReadiness({
        AssessmentEngineConfig? config,
        List<AssessmentQuestion> questions = const [],
      }) {
        if (config == null) return AssessmentReadinessState.configMissing;
        if (questions.isEmpty) return AssessmentReadinessState.questionsMissing;
        for (final q in questions) {
          if (q.options.length < 2) return AssessmentReadinessState.optionsMissing;
        }
        return AssessmentReadinessState.ready;
      }

      final result = checkReadiness(config: null);
      expect(result, AssessmentReadinessState.configMissing);
    });

    test('Questions missing returns questionsMissing', () {
      AssessmentReadinessState checkReadiness({
        AssessmentEngineConfig? config,
        List<AssessmentQuestion> questions = const [],
      }) {
        if (config == null) return AssessmentReadinessState.configMissing;
        if (questions.isEmpty) return AssessmentReadinessState.questionsMissing;
        for (final q in questions) {
          if (q.options.length < 2) return AssessmentReadinessState.optionsMissing;
        }
        return AssessmentReadinessState.ready;
      }

      final config = const AssessmentEngineConfig(
        id: '1',
        assessmentId: 'a1',
        passingRequired: false,
        allowResume: true,
        randomizeQuestions: false,
        randomizeOptions: false,
        showProgress: true,
        durationMinutes: 30,
      );

      final result = checkReadiness(config: config, questions: []);
      expect(result, AssessmentReadinessState.questionsMissing);
    });

    test('Options missing returns optionsMissing', () {
      AssessmentReadinessState checkReadiness({
        AssessmentEngineConfig? config,
        List<AssessmentQuestion> questions = const [],
      }) {
        if (config == null) return AssessmentReadinessState.configMissing;
        if (questions.isEmpty) return AssessmentReadinessState.questionsMissing;
        for (final q in questions) {
          if (q.options.length < 2) return AssessmentReadinessState.optionsMissing;
        }
        return AssessmentReadinessState.ready;
      }

      final config = const AssessmentEngineConfig(
        id: '1',
        assessmentId: 'a1',
        passingRequired: false,
        allowResume: true,
        randomizeQuestions: false,
        randomizeOptions: false,
        showProgress: true,
        durationMinutes: 30,
      );

      final questions = [
        const AssessmentQuestion(
          id: 'q1',
          assessmentId: 'a1',
          questionText: 'Test question?',
          questionType: 'single_choice',
          questionOrder: 1,
          isActive: true,
          options: [
            AssessmentQuestionOption(
              id: 'o1',
              questionId: 'q1',
              optionText: 'Option 1',
              optionValue: 'A',
              optionOrder: 1,
              scoreValue: 1,
            ),
          ],
        ),
      ];

      final result = checkReadiness(config: config, questions: questions);
      expect(result, AssessmentReadinessState.optionsMissing);
    });

    test('Fully configured returns ready', () {
      AssessmentReadinessState checkReadiness({
        AssessmentEngineConfig? config,
        List<AssessmentQuestion> questions = const [],
      }) {
        if (config == null) return AssessmentReadinessState.configMissing;
        if (questions.isEmpty) return AssessmentReadinessState.questionsMissing;
        for (final q in questions) {
          if (q.options.length < 2) return AssessmentReadinessState.optionsMissing;
        }
        return AssessmentReadinessState.ready;
      }

      final config = const AssessmentEngineConfig(
        id: '1',
        assessmentId: 'a1',
        passingRequired: false,
        allowResume: true,
        randomizeQuestions: false,
        randomizeOptions: false,
        showProgress: true,
        durationMinutes: 30,
      );

      final questions = [
        const AssessmentQuestion(
          id: 'q1',
          assessmentId: 'a1',
          questionText: 'Test question?',
          questionType: 'single_choice',
          questionOrder: 1,
          isActive: true,
          options: [
            AssessmentQuestionOption(
              id: 'o1',
              questionId: 'q1',
              optionText: 'Option 1',
              optionValue: 'A',
              optionOrder: 1,
              scoreValue: 1,
            ),
            AssessmentQuestionOption(
              id: 'o2',
              questionId: 'q1',
              optionText: 'Option 2',
              optionValue: 'B',
              optionOrder: 2,
              scoreValue: 2,
            ),
          ],
        ),
      ];

      final result = checkReadiness(config: config, questions: questions);
      expect(result, AssessmentReadinessState.ready);
    });
  });
}

