import '../../cat/data/cat_model.dart';

class UserCatDexModel {
  final int id;
  final int catId;
  final int encountersCount;
  final int friendshipLevel;
  final DateTime firstCapturedAt;
  final CatModel? cat;

  UserCatDexModel({
    required this.id,
    required this.catId,
    required this.encountersCount,
    required this.friendshipLevel,
    required this.firstCapturedAt,
    this.cat,
  });

  factory UserCatDexModel.fromJson(Map<String, dynamic> json) {
    return UserCatDexModel(
      id: json['id'] ?? 0,
      catId: json['cat_id'] ?? 0,
      encountersCount: json['encounters_count'] ?? 1,
      friendshipLevel: json['friendship_level'] ?? 1,
      firstCapturedAt:
          DateTime.tryParse(json['first_captured_at'] ?? '') ?? DateTime.now(),
      cat: json['cat'] != null ? CatModel.fromJson(json['cat']) : null,
    );
  }
}

class LeaderboardEntry {
  final int id;
  final String name;
  final int pointsBalance;
  final String? avatarUrl;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.pointsBalance,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      pointsBalance: json['points_balance'] ?? 0,
      avatarUrl: json['avatar_url'],
    );
  }
}
