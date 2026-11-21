class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final String? phone;
  final bool emailVerified;
  final int pointsBalance;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.phone,
    this.emailVerified = false,
    this.pointsBalance = 0,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['user_type'] ?? json['role'] ?? 'UMUM',
      studentId: json['identity_number'] ?? json['student_id'],
      phone: json['phone'],
      emailVerified: json['email_verified'] == true,
      pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
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
      'email_verified': emailVerified,
      'points_balance': pointsBalance,
      'avatar_url': avatarUrl,
    };
  }
}
