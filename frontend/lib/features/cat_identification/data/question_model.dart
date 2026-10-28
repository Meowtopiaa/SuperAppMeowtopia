class QuestionModel {
  final int id;
  final String questionText;
  final String traitCategory;
  final List<String> options;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.traitCategory,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? 0,
      questionText: json['question_text'] ?? '',
      traitCategory: json['trait_category'] ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
