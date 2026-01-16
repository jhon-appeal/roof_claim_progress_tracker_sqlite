class MilestoneModel {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MilestoneModel({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.status,
    this.dueDate,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
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
      'project_id': projectId,
      'name': name,
      'description': description,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
