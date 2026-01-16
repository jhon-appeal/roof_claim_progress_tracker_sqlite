import '../services/supabase_service.dart';

class ProgressPhotoModel {
  final String id;
  final String milestoneId;
  final String projectId;
  final String storagePath;
  final String uploadedBy;
  final String? description;
  final DateTime? createdAt;

  ProgressPhotoModel({
    required this.id,
    required this.milestoneId,
    required this.projectId,
    required this.storagePath,
    required this.uploadedBy,
    this.description,
    this.createdAt,
  });

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoModel(
      id: json['id'] as String,
      milestoneId: json['milestone_id'] as String,
      projectId: json['project_id'] as String,
      storagePath: json['storage_path'] as String,
      uploadedBy: json['uploaded_by'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'milestone_id': milestoneId,
      'project_id': projectId,
      'storage_path': storagePath,
      'uploaded_by': uploadedBy,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Get public URL for the photo
  String getPublicUrl() {
    return SupabaseService.client.storage
        .from('progress-photos')
        .getPublicUrl(storagePath);
  }
}
