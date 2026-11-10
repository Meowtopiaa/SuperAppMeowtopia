import '../../../core/navigation/app_feature.dart';
import '../../feeding_spot/data/feeding_session.dart';

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.feature,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
    this.detailRoute,
  });

  final String id;
  final AppFeature feature;
  final String title;
  final String description;
  final String status;
  final DateTime? createdAt;
  final String? detailRoute;
  String get route => detailRoute ?? feature.route;

  factory ActivityEntry.fromFeeding(FeedingSubmission submission) =>
      ActivityEntry(
        id: 'feeding-${submission.id}',
        feature: AppFeature.feeding,
        title: submission.spot.name,
        description: submission.foodLabel,
        status: submission.statusLabel,
        createdAt: submission.createdAt,
        detailRoute:
            '/feeding/submission/${Uri.encodeComponent(submission.id)}',
      );

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final feature = AppFeature.values.byName(json['feature'] as String);
    return ActivityEntry(
      id: json['id'].toString(),
      feature: feature,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      status: json['status_label'] as String? ?? 'Tercatat',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
