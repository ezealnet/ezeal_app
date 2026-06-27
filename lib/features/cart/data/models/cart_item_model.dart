import '../../../assessments/data/models/assessment_model.dart';

class CartItem {
  final String id;
  final String userId;
  final String assessmentId;
  final DateTime? createdAt;
  final Assessment? assessment;

  const CartItem({
    required this.id,
    required this.userId,
    required this.assessmentId,
    this.createdAt,
    this.assessment,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      assessment: json['assessments'] != null
          ? Assessment.fromJson(json['assessments'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assessment_id': assessmentId,
      'created_at': createdAt?.toIso8601String(),
      if (assessment != null) 'assessments': assessment!.toJson(),
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? assessmentId,
    DateTime? createdAt,
    Assessment? assessment,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessmentId: assessmentId ?? this.assessmentId,
      createdAt: createdAt ?? this.createdAt,
      assessment: assessment ?? this.assessment,
    );
  }
}
