import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/assessment_question_model.dart';
import '../../data/models/assessment_question_option_model.dart';
import '../../data/models/assessment_engine_config_model.dart';

final assessmentEngineConfigProvider = FutureProvider.family<AssessmentEngineConfig?, String>((ref, assessmentId) async {
  try {
    final response = await Supabase.instance.client
        .from('assessment_engine_configs')
        .select()
        .eq('assessment_id', assessmentId)
        .maybeSingle();

    if (response == null) return null;
    return AssessmentEngineConfig.fromJson(response);
  } catch (e) {
    if (kDebugMode) {
      print('assessmentEngineConfigProvider error: $e');
    }
    return null;
  }
});

final assessmentQuestionsProvider = FutureProvider.family<List<AssessmentQuestion>, String>((ref, assessmentId) async {
  try {
    final response = await Supabase.instance.client
        .from('assessment_questions')
        .select('*, assessment_question_options(*)')
        .eq('assessment_id', assessmentId)
        .eq('is_active', true)
        .order('question_order', ascending: true);

    final list = response as List;
    return list.map((qJson) {
      final optJsonList = qJson['assessment_question_options'] as List? ?? [];
      final options = optJsonList
          .map((oJson) => AssessmentQuestionOption.fromJson(oJson as Map<String, dynamic>))
          .toList();
      // Sort options by option_order
      options.sort((a, b) => a.optionOrder.compareTo(b.optionOrder));
      return AssessmentQuestion.fromJson(qJson as Map<String, dynamic>, options);
    }).toList();
  } catch (e) {
    if (kDebugMode) {
      print('assessmentQuestionsProvider error: $e');
    }
    return const [];
  }
});

enum AssessmentReadinessState {
  ready,
  questionsMissing,
  optionsMissing,
  configMissing,
}

final assessmentReadinessProvider = FutureProvider.family<AssessmentReadinessState, String>((ref, assessmentId) async {
  try {
    final config = await ref.watch(assessmentEngineConfigProvider(assessmentId).future);
    if (config == null) return AssessmentReadinessState.configMissing;

    final questions = await ref.watch(assessmentQuestionsProvider(assessmentId).future);
    if (questions.isEmpty) return AssessmentReadinessState.questionsMissing;

    for (final question in questions) {
      if (question.options.length < 2) {
        return AssessmentReadinessState.optionsMissing;
      }
    }

    return AssessmentReadinessState.ready;
  } catch (e) {
    if (kDebugMode) {
      print('assessmentReadinessProvider error: $e');
    }
    return AssessmentReadinessState.questionsMissing;
  }
});
