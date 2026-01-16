class ClaimPhoto {
  final String id;
  final String claimId;
  final String storagePath;
  final String uploadedBy;
  final String? description;
  final DateTime createdAt;

  ClaimPhoto({
    required this.id,
    required this.claimId,
    required this.storagePath,
    required this.uploadedBy,
    this.description,
    required this.createdAt,
  });

  factory ClaimPhoto.fromJson(Map<String, dynamic> json) {
    return ClaimPhoto(
      id: json['id'] as String,
      claimId: json['claim_id'] as String,
      storagePath: json['storage_path'] as String,
      uploadedBy: json['uploaded_by'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'claim_id': claimId,
      'storage_path': storagePath,
      'uploaded_by': uploadedBy,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
