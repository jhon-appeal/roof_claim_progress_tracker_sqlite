class ProjectModel {
  final String id;
  final String address;
  final String? homeownerId;
  final String? roofingCompanyId;
  final String? assessDirectId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel({
    required this.id,
    required this.address,
    this.homeownerId,
    this.roofingCompanyId,
    this.assessDirectId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      address: json['address'] as String,
      homeownerId: json['homeowner_id'] as String?,
      roofingCompanyId: json['roofing_company_id'] as String?,
      assessDirectId: json['assess_direct_id'] as String?,
      status: json['status'] as String? ?? 'pending',
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
      'address': address,
      'homeowner_id': homeownerId,
      'roofing_company_id': roofingCompanyId,
      'assess_direct_id': assessDirectId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
