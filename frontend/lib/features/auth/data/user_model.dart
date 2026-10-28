class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final String? phone;
  final int pointsBalance;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.phone,
    this.pointsBalance = 0,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      studentId: json['student_id'],
      phone: json['phone'],
      pointsBalance: json['points_balance'] ?? 0,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'student_id': studentId,
      'phone': phone,
      'points_balance': pointsBalance,
      'avatar_url': avatarUrl,
    };
  }
}
