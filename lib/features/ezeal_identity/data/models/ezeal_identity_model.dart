class EzealIdentity {
  final String id;
  final String userId;
  final String ezealId;
  final String roleType;
  final bool aadhaarVerified;
  final String verificationStatus;
  final String verificationProvider;
  final String? verificationReference;
  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EzealIdentity({
    required this.id,
    required this.userId,
    required this.ezealId,
    required this.roleType,
    required this.aadhaarVerified,
    required this.verificationStatus,
    required this.verificationProvider,
    this.verificationReference,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory EzealIdentity.fromJson(Map<String, dynamic> json) {
    return EzealIdentity(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      ezealId: json['ezeal_id'] as String? ?? '',
      roleType: json['role_type'] as String? ?? '',
      aadhaarVerified: json['aadhaar_verified'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verificationProvider: json['verification_provider'] as String? ?? 'mock',
      verificationReference: json['verification_reference'] as String?,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ezeal_id': ezealId,
      'role_type': roleType,
      'aadhaar_verified': aadhaarVerified,
      'verification_status': verificationStatus,
      'verification_provider': verificationProvider,
      'verification_reference': verificationReference,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  EzealIdentity copyWith({
    String? id,
    String? userId,
    String? ezealId,
    String? roleType,
    bool? aadhaarVerified,
    String? verificationStatus,
    String? verificationProvider,
    String? verificationReference,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EzealIdentity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ezealId: ezealId ?? this.ezealId,
      roleType: roleType ?? this.roleType,
      aadhaarVerified: aadhaarVerified ?? this.aadhaarVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationProvider: verificationProvider ?? this.verificationProvider,
      verificationReference: verificationReference ?? this.verificationReference,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
