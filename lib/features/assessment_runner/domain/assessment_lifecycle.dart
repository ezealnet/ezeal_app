enum AssessmentLifecycleStage {
  unlocked,
  inProgress,
  submitted,
  scoring,
  reportGenerated,
  counsellorReview,
  released,
}

extension AssessmentLifecycleStageExtension on AssessmentLifecycleStage {
  String get databaseValue {
    switch (this) {
      case AssessmentLifecycleStage.unlocked:
        return 'unlocked';
      case AssessmentLifecycleStage.inProgress:
        return 'started'; // Map inProgress to database 'started' for assessment_access
      case AssessmentLifecycleStage.submitted:
        return 'completed'; // Map submitted/completed to database 'completed'
      case AssessmentLifecycleStage.scoring:
        return 'scoring';
      case AssessmentLifecycleStage.reportGenerated:
        return 'report_generated';
      case AssessmentLifecycleStage.counsellorReview:
        return 'counsellor_review';
      case AssessmentLifecycleStage.released:
        return 'released';
    }
  }

  String get displayName {
    switch (this) {
      case AssessmentLifecycleStage.unlocked:
        return 'Unlocked';
      case AssessmentLifecycleStage.inProgress:
        return 'In Progress';
      case AssessmentLifecycleStage.submitted:
        return 'Submitted';
      case AssessmentLifecycleStage.scoring:
        return 'Scoring';
      case AssessmentLifecycleStage.reportGenerated:
        return 'Report Generated';
      case AssessmentLifecycleStage.counsellorReview:
        return 'Counsellor Review';
      case AssessmentLifecycleStage.released:
        return 'Released';
    }
  }
}
