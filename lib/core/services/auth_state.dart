import '../enums/user_role.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final String status;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String?;
    UserRole parsedRole = UserRole.student;
    for (final val in UserRole.values) {
      if (val.name == roleStr) {
        parsedRole = val;
        break;
      }
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: parsedRole,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.name,
      'status': status,
    };
  }
}
