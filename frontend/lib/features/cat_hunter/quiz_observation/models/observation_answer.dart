class QuizQuestion {
  final int step;
  final String title;
  final String description;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.step,
    required this.title,
    required this.description,
    required this.options,
  });
}

class QuizOption {
  final String id;
  final String label;
  final String sublabel;
  final String iconEmoji;

  const QuizOption({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.iconEmoji,
  });
}

class ObservationSubmission {
  final String catId;
  final String eyeFaceCondition;
  final String bodyCoatCondition;
  final String behaviorCondition;
  final String timestamp;
  final int earnedTrustModal;

  const ObservationSubmission({
    required this.catId,
    required this.eyeFaceCondition,
    required this.bodyCoatCondition,
    required this.behaviorCondition,
    required this.timestamp,
    this.earnedTrustModal = 75,
  });
}
