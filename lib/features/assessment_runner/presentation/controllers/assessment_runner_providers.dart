import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../assessment_access/presentation/controllers/assessment_access_providers.dart';
import '../../../assessment_engine/presentation/controllers/assessment_engine_providers.dart';
import '../../../assessment_engine/data/models/assessment_question_model.dart';
import '../../data/models/assessment_attempt_model.dart';
import '../../data/models/assessment_session_model.dart';

class AssessmentRunnerState {
  final bool isLoading;
  final String? errorMessage;
  final AssessmentAttempt? attempt;
  final AssessmentSession? session;
  final List<AssessmentQuestion> questions;
  final int currentIndex;
  final Map<String, String> answers; // question_id -> selected_option_id
  final bool isSaving;
  final bool isSubmitting;
  final bool submitSuccess;

  const AssessmentRunnerState({
    this.isLoading = false,
    this.errorMessage,
    this.attempt,
    this.session,
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.isSaving = false,
    this.isSubmitting = false,
    this.submitSuccess = false,
  });

  AssessmentRunnerState copyWith({
    bool? isLoading,
    String? errorMessage,
    AssessmentAttempt? attempt,
    AssessmentSession? session,
    List<AssessmentQuestion>? questions,
    int? currentIndex,
    Map<String, String>? answers,
    bool? isSaving,
    bool? isSubmitting,
    bool? submitSuccess,
  }) {
    return AssessmentRunnerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      attempt: attempt ?? this.attempt,
      session: session ?? this.session,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isSaving: isSaving ?? this.isSaving,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }
}

class AssessmentRunnerController extends Notifier<AssessmentRunnerState> {
  @override
  AssessmentRunnerState build() {
    return const AssessmentRunnerState();
  }

  Future<bool> startOrResumeAttempt(String assessmentId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: 'You must be logged in.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, submitSuccess: false);

    if (kDebugMode) {
      print('--- Runner Started ---');
      print('Assessment ID: $assessmentId');
      print('User ID: ${user.id}');
      print('----------------------');
    }

    try {
      // 1. Fetch user's assessment access record
      final accessRows = await Supabase.instance.client
          .from('assessment_access')
          .select()
          .eq('user_id', user.id)
          .eq('assessment_id', assessmentId)
          .maybeSingle();

      if (accessRows == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'You do not have access to this assessment.');
        return false;
      }

      final accessId = accessRows['id'] as String;
      final accessStatus = accessRows['status'] as String;

      if (accessStatus == 'completed') {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'This assessment has already been completed.',
        );
        return false;
      }

      // 2. Fetch assessment questions
      final questions = await ref.read(assessmentQuestionsProvider(assessmentId).future);
      if (questions.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'No questions configured for this assessment.');
        return false;
      }

      // 3. Search for existing attempts (both in_progress and submitted to enforce one attempt rule)
      final existingAttempts = await Supabase.instance.client
          .from('assessment_attempts')
          .select()
          .eq('user_id', user.id)
          .eq('assessment_id', assessmentId)
          .order('created_at', ascending: false);

      final attemptsList = existingAttempts as List;
      Map<String, dynamic>? activeAttemptJson;
      Map<String, dynamic>? submittedAttemptJson;

      for (final attempt in attemptsList) {
        final status = attempt['status'] as String;
        if (status == 'submitted') {
          submittedAttemptJson = Map<String, dynamic>.from(attempt);
          break;
        } else if (status == 'in_progress') {
          activeAttemptJson = Map<String, dynamic>.from(attempt);
        }
      }

      // Rule: Submitted attempts cannot restart
      if (submittedAttemptJson != null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'This assessment has already been completed.',
        );
        return false;
      }

      AssessmentAttempt attemptModel;
      AssessmentSession sessionModel;
      Map<String, String> answersMap = {};

      if (activeAttemptJson != null) {
        // Resume existing active attempt
        attemptModel = AssessmentAttempt.fromJson(activeAttemptJson);

        // Fetch saved answers
        final savedAnswersResponse = await Supabase.instance.client
            .from('assessment_answers')
            .select()
            .eq('attempt_id', attemptModel.id);

        final answersList = savedAnswersResponse as List;
        for (final answer in answersList) {
          final qId = answer['question_id'] as String;
          final optId = answer['selected_option_id'] as String?;
          if (optId != null) {
            answersMap[qId] = optId;
          }
        }

        final answeredCount = answersMap.length;
        final double completionPercentage = questions.isNotEmpty ? (answeredCount / questions.length) * 100.0 : 0.0;
        attemptModel = attemptModel.copyWith(
          answeredCount: answeredCount,
          completionPercentage: completionPercentage,
        );

        if (kDebugMode) {
          print('--- Attempt Loaded ---');
          print('Attempt ID: ${attemptModel.id}');
          print('Status: ${attemptModel.status}');
          print('----------------------');
          print('--- Attempt Resumed ---');
          print('Attempt ID: ${attemptModel.id}');
          print('Answered Count: $answeredCount');
          print('Progress: $completionPercentage%');
          print('-----------------------');
        }

        // Fetch or create assessment session
        final sessionResponse = await Supabase.instance.client
            .from('assessment_sessions')
            .select()
            .eq('attempt_id', attemptModel.id)
            .maybeSingle();

        if (sessionResponse != null) {
          final currentResumeCount = sessionResponse['resume_count'] as int? ?? 0;
          final updatedSession = await Supabase.instance.client
              .from('assessment_sessions')
              .update({
                'resume_count': currentResumeCount + 1,
                'last_active_at': DateTime.now().toIso8601String(),
                'session_status': 'active',
              })
              .eq('id', sessionResponse['id'] as String)
              .select()
              .single();

          sessionModel = AssessmentSession.fromJson(updatedSession);
        } else {
          // Create session if it was missing
          final newSession = await Supabase.instance.client.from('assessment_sessions').insert({
            'attempt_id': attemptModel.id,
            'user_id': user.id,
            'resume_count': 1,
            'session_status': 'active',
          }).select().single();

          sessionModel = AssessmentSession.fromJson(newSession);
        }
      } else {
        // Create new attempt
        final newAttempt = await Supabase.instance.client.from('assessment_attempts').insert({
          'user_id': user.id,
          'assessment_id': assessmentId,
          'assessment_access_id': accessId,
          'status': 'in_progress',
          'current_question_index': 0,
          'answered_count': 0,
          'completion_percentage': 0,
        }).select().single();

        attemptModel = AssessmentAttempt.fromJson(newAttempt);

        if (kDebugMode) {
          print('--- Attempt Loaded ---');
          print('Attempt ID: ${attemptModel.id}');
          print('Status: ${attemptModel.status}');
          print('----------------------');
        }

        // Create new session
        final newSession = await Supabase.instance.client.from('assessment_sessions').insert({
          'attempt_id': attemptModel.id,
          'user_id': user.id,
          'resume_count': 0,
          'session_status': 'active',
        }).select().single();

        sessionModel = AssessmentSession.fromJson(newSession);

        // Update assessment_access to 'started' (In Progress lifecycle stage)
        await Supabase.instance.client
            .from('assessment_access')
            .update({'status': 'started'})
            .eq('id', accessId);
      }

      int startingIndex = attemptModel.currentQuestionIndex;
      if (startingIndex < 0 || startingIndex >= questions.length) {
        startingIndex = 0;
      }

      state = state.copyWith(
        isLoading: false,
        attempt: attemptModel,
        session: sessionModel,
        questions: questions,
        currentIndex: startingIndex,
        answers: answersMap,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('startOrResumeAttempt error: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to start or resume assessment.');
      return false;
    }
  }

  Future<void> saveAnswer(String questionId, String optionId) async {
    final attempt = state.attempt;
    if (attempt == null || attempt.status != 'in_progress') {
      return;
    }

    // 1. Optimistic State Update
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[questionId] = optionId;

    final answeredCount = updatedAnswers.length;
    final double completionPercentage = (answeredCount / state.questions.length) * 100.0;

    final updatedAttempt = attempt.copyWith(
      answeredCount: answeredCount,
      completionPercentage: completionPercentage,
      lastActiveAt: DateTime.now(),
    );

    state = state.copyWith(
      answers: updatedAnswers,
      attempt: updatedAttempt,
      isSaving: true,
    );

    try {
      // 2. Persist answer to Supabase (using upsert conflict resolution based on unique constraint)
      await Supabase.instance.client.from('assessment_answers').upsert(
        {
          'attempt_id': attempt.id,
          'question_id': questionId,
          'selected_option_id': optionId,
          'answered_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'attempt_id,question_id',
      );

      if (kDebugMode) {
        print('--- Answer Upserted ---');
        print('Attempt ID: ${attempt.id}');
        print('Question ID: $questionId');
        print('Option ID: $optionId');
        print('-----------------------');
      }

      // 3. Update attempt metrics
      await Supabase.instance.client.from('assessment_attempts').update({
        'answered_count': answeredCount,
        'completion_percentage': completionPercentage,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', attempt.id);

      if (kDebugMode) {
        print('--- Progress Updated ---');
        print('Attempt ID: ${attempt.id}');
        print('Answered Count: $answeredCount');
        print('Progress: $completionPercentage%');
        print('------------------------');
      }

      // 4. Update session last active
      if (state.session != null) {
        await Supabase.instance.client.from('assessment_sessions').update({
          'last_active_at': DateTime.now().toIso8601String(),
        }).eq('id', state.session!.id);
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      if (kDebugMode) {
        print('saveAnswer error: $e');
      }
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to auto-save answer.');
    }
  }

  Future<void> goToNextQuestion() async {
    final attempt = state.attempt;
    if (attempt == null || attempt.status != 'in_progress') return;

    if (state.currentIndex + 1 < state.questions.length) {
      final nextIndex = state.currentIndex + 1;
      
      // Optimistic update
      state = state.copyWith(
        currentIndex: nextIndex,
        attempt: attempt.copyWith(currentQuestionIndex: nextIndex),
      );

      if (kDebugMode) {
        print('--- Question Index Updated ---');
        print('Attempt ID: ${attempt.id}');
        print('New Index: $nextIndex');
        print('------------------------------');
      }

      try {
        await Supabase.instance.client.from('assessment_attempts').update({
          'current_question_index': nextIndex,
          'last_active_at': DateTime.now().toIso8601String(),
        }).eq('id', attempt.id);
      } catch (e) {
        if (kDebugMode) {
          print('goToNextQuestion DB update failed: $e');
        }
      }
    }
  }

  Future<void> goToPreviousQuestion() async {
    final attempt = state.attempt;
    if (attempt == null || attempt.status != 'in_progress') return;

    if (state.currentIndex > 0) {
      final prevIndex = state.currentIndex - 1;
      
      // Optimistic update
      state = state.copyWith(
        currentIndex: prevIndex,
        attempt: attempt.copyWith(currentQuestionIndex: prevIndex),
      );

      if (kDebugMode) {
        print('--- Question Index Updated ---');
        print('Attempt ID: ${attempt.id}');
        print('New Index: $prevIndex');
        print('------------------------------');
      }

      try {
        await Supabase.instance.client.from('assessment_attempts').update({
          'current_question_index': prevIndex,
          'last_active_at': DateTime.now().toIso8601String(),
        }).eq('id', attempt.id);
      } catch (e) {
        if (kDebugMode) {
          print('goToPreviousQuestion DB update failed: $e');
        }
      }
    }
  }

  Future<void> updateSessionHeartbeat() async {
    final attempt = state.attempt;
    final session = state.session;
    if (attempt == null || session == null || attempt.status != 'in_progress') return;

    try {
      final now = DateTime.now().toIso8601String();
      await Supabase.instance.client.from('assessment_sessions').update({
        'last_active_at': now,
      }).eq('id', session.id);
    } catch (e) {
      if (kDebugMode) {
        print('Heartbeat update error: $e');
      }
    }
  }

  Future<bool> submitAttempt() async {
    final attempt = state.attempt;
    final session = state.session;
    if (attempt == null || session == null || attempt.status != 'in_progress') {
      state = state.copyWith(errorMessage: 'No active attempt to submit.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    if (kDebugMode) {
      print('--- Submission Started ---');
      print('Attempt ID: ${attempt.id}');
      print('--------------------------');
    }

    final totalQuestions = state.questions.length;
    final answeredCount = state.answers.length;

    if (answeredCount < totalQuestions) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Please answer all questions before submitting.',
      );
      return false;
    }

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Update attempt status to submitted
      await Supabase.instance.client.from('assessment_attempts').update({
        'status': 'submitted',
        'submitted_at': now,
        'last_active_at': now,
        'current_question_index': state.currentIndex,
        'completion_percentage': 100,
        'answered_count': totalQuestions,
      }).eq('id', attempt.id);

      if (kDebugMode) {
        print('--- Submission Completed ---');
        print('Attempt ID: ${attempt.id}');
        print('Status: submitted');
        print('----------------------------');
      }

      // 2. Update access record to completed
      await Supabase.instance.client.from('assessment_access').update({
        'status': 'completed',
      }).eq('id', attempt.assessmentAccessId);

      if (kDebugMode) {
        print('--- Access Updated ---');
        print('Access ID: ${attempt.assessmentAccessId}');
        print('Status: completed');
        print('----------------------');
      }

      // 3. Update session to completed
      await Supabase.instance.client.from('assessment_sessions').update({
        'session_status': 'completed',
        'last_active_at': now,
      }).eq('id', session.id);

      if (kDebugMode) {
        print('--- Session Completed ---');
        print('Session ID: ${session.id}');
        print('Status: completed');
        print('-------------------------');
      }

      state = state.copyWith(
        isSubmitting: false,
        submitSuccess: true,
        attempt: attempt.copyWith(
          status: 'submitted',
          submittedAt: DateTime.now(),
          completionPercentage: 100.0,
          answeredCount: totalQuestions,
        ),
      );

      // Invalidate assessmentAccessProvider only after final submission
      ref.invalidate(assessmentAccessProvider);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('submitAttempt error: $e');
      }
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Unable to submit assessment. Please try again.',
      );
      return false;
    }
  }
}

final assessmentRunnerControllerProvider =
    NotifierProvider<AssessmentRunnerController, AssessmentRunnerState>(() {
  return AssessmentRunnerController();
});
