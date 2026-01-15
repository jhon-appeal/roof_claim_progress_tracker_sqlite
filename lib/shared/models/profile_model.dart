class ProfileModel {
  final String id;
  final String? email;
  final String? fullName;
  final String role;
  final String? companyName;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    this.email,
    this.fullName,
    required this.role,
    this.companyName,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      companyName: json['company_name'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'company_name': companyName,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
