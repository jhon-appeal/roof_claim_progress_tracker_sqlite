import 'package:uuid/uuid.dart';

/// User roles enum matching Supabase user_role type
enum UserRole {
  homeowner,
  roofingCompany, // Maps to 'roofing_company' in Supabase
  assessDirect, // Maps to 'assess_direct' in Supabase
}

/// Project status enum matching Supabase project_status type
enum ProjectStatus {
  pending,
  inspection,
  claimLodged, // Maps to 'claim_lodged' in Supabase
  claimApproved, // Maps to 'claim_approved' in Supabase
  construction,
  completed,
  closed,
}

/// Milestone status enum matching Supabase milestone_status type
enum MilestoneStatus {
  pending,
  inProgress, // Maps to 'in_progress' in Supabase
  completed,
  approved,
}

/// Milestone name enum matching Supabase milestone_name type
enum MilestoneName {
  initialInspection, // Maps to 'Initial Inspection' in Supabase
  claimLodged, // Maps to 'Claim Lodged' in Supabase
  claimApproved, // Maps to 'Claim Approved' in Supabase
  roofConstruction, // Maps to 'Roof Construction' in Supabase
  finalInspection, // Maps to 'Final Inspection' in Supabase
}

/// Extension to convert enum names to Supabase snake_case format
extension UserRoleExtension on UserRole {
  String toSupabaseValue() {
    switch (this) {
      case UserRole.homeowner:
        return 'homeowner';
      case UserRole.roofingCompany:
        return 'roofing_company';
      case UserRole.assessDirect:
        return 'assess_direct';
    }
  }

  static UserRole fromSupabaseValue(String value) {
    switch (value) {
      case 'homeowner':
        return UserRole.homeowner;
      case 'roofing_company':
        return UserRole.roofingCompany;
      case 'assess_direct':
        return UserRole.assessDirect;
      default:
        return UserRole.homeowner;
    }
  }
}

extension ProjectStatusExtension on ProjectStatus {
  String toSupabaseValue() {
    switch (this) {
      case ProjectStatus.pending:
        return 'pending';
      case ProjectStatus.inspection:
        return 'inspection';
      case ProjectStatus.claimLodged:
        return 'claim_lodged';
      case ProjectStatus.claimApproved:
        return 'claim_approved';
      case ProjectStatus.construction:
        return 'construction';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.closed:
        return 'closed';
    }
  }

  static ProjectStatus fromSupabaseValue(String value) {
    switch (value) {
      case 'pending':
        return ProjectStatus.pending;
      case 'inspection':
        return ProjectStatus.inspection;
      case 'claim_lodged':
        return ProjectStatus.claimLodged;
      case 'claim_approved':
        return ProjectStatus.claimApproved;
      case 'construction':
        return ProjectStatus.construction;
      case 'completed':
        return ProjectStatus.completed;
      case 'closed':
        return ProjectStatus.closed;
      default:
        return ProjectStatus.pending;
    }
  }
}

extension MilestoneStatusExtension on MilestoneStatus {
  String toSupabaseValue() {
    switch (this) {
      case MilestoneStatus.pending:
        return 'pending';
      case MilestoneStatus.inProgress:
        return 'in_progress';
      case MilestoneStatus.completed:
        return 'completed';
      case MilestoneStatus.approved:
        return 'approved';
    }
  }

  static MilestoneStatus fromSupabaseValue(String value) {
    switch (value) {
      case 'pending':
        return MilestoneStatus.pending;
      case 'in_progress':
        return MilestoneStatus.inProgress;
      case 'completed':
        return MilestoneStatus.completed;
      case 'approved':
        return MilestoneStatus.approved;
      default:
        return MilestoneStatus.pending;
    }
  }
}

extension MilestoneNameExtension on MilestoneName {
  String toSupabaseValue() {
    switch (this) {
      case MilestoneName.initialInspection:
        return 'Initial Inspection';
      case MilestoneName.claimLodged:
        return 'Claim Lodged';
      case MilestoneName.claimApproved:
        return 'Claim Approved';
      case MilestoneName.roofConstruction:
        return 'Roof Construction';
      case MilestoneName.finalInspection:
        return 'Final Inspection';
    }
  }

  static MilestoneName fromSupabaseValue(String value) {
    switch (value) {
      case 'Initial Inspection':
        return MilestoneName.initialInspection;
      case 'Claim Lodged':
        return MilestoneName.claimLodged;
      case 'Claim Approved':
        return MilestoneName.claimApproved;
      case 'Roof Construction':
        return MilestoneName.roofConstruction;
      case 'Final Inspection':
        return MilestoneName.finalInspection;
      default:
        return MilestoneName.initialInspection;
    }
  }
}

/// Profile model matching Supabase profiles table
class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final UserRole role;
  final String? companyName;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.email,
    this.fullName,
    required this.role,
    this.companyName,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.toSupabaseValue(),
      'company_name': companyName,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      role: UserRoleExtension.fromSupabaseValue(map['role'] as String),
      companyName: map['company_name'] as String?,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Project model matching Supabase projects table
class Project {
  final String id;
  final String address;
  final String? homeownerId;
  final String? roofingCompanyId;
  final String? assessDirectId;
  final ProjectStatus status;
  final String? claimNumber;
  final String? insuranceCompany;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    String? id,
    required this.address,
    this.homeownerId,
    this.roofingCompanyId,
    this.assessDirectId,
    this.status = ProjectStatus.pending,
    this.claimNumber,
    this.insuranceCompany,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'homeowner_id': homeownerId,
      'roofing_company_id': roofingCompanyId,
      'assess_direct_id': assessDirectId,
      'status': status.toSupabaseValue(),
      'claim_number': claimNumber,
      'insurance_company': insuranceCompany,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      address: map['address'] as String,
      homeownerId: map['homeowner_id'] as String?,
      roofingCompanyId: map['roofing_company_id'] as String?,
      assessDirectId: map['assess_direct_id'] as String?,
      status: ProjectStatusExtension.fromSupabaseValue(map['status'] as String),
      claimNumber: map['claim_number'] as String?,
      insuranceCompany: map['insurance_company'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Project copyWith({
    String? id,
    String? address,
    String? homeownerId,
    String? roofingCompanyId,
    String? assessDirectId,
    ProjectStatus? status,
    String? claimNumber,
    String? insuranceCompany,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      address: address ?? this.address,
      homeownerId: homeownerId ?? this.homeownerId,
      roofingCompanyId: roofingCompanyId ?? this.roofingCompanyId,
      assessDirectId: assessDirectId ?? this.assessDirectId,
      status: status ?? this.status,
      claimNumber: claimNumber ?? this.claimNumber,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Milestone model matching Supabase milestones table
class Milestone {
  final String id;
  final String projectId;
  final String name; // Can be custom text or use MilestoneName enum
  final String? description;
  final MilestoneStatus status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Milestone({
    String? id,
    required this.projectId,
    required this.name,
    this.description,
    this.status = MilestoneStatus.pending,
    this.dueDate,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'description': description,
      'status': status.toSupabaseValue(),
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      status: MilestoneStatusExtension.fromSupabaseValue(
        map['status'] as String,
      ),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

/// Progress Photo model matching Supabase progress_photos table
class ProgressPhoto {
  final String id;
  final String milestoneId;
  final String projectId;
  final String storagePath;
  final String uploadedBy;
  final String? description;
  final DateTime createdAt;

  ProgressPhoto({
    String? id,
    required this.milestoneId,
    required this.projectId,
    required this.storagePath,
    required this.uploadedBy,
    this.description,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'milestone_id': milestoneId,
      'project_id': projectId,
      'storage_path': storagePath,
      'uploaded_by': uploadedBy,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProgressPhoto.fromMap(Map<String, dynamic> map) {
    return ProgressPhoto(
      id: map['id'] as String,
      milestoneId: map['milestone_id'] as String,
      projectId: map['project_id'] as String,
      storagePath: map['storage_path'] as String,
      uploadedBy: map['uploaded_by'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Status History model matching Supabase status_history table
class StatusHistory {
  final String id;
  final String projectId;
  final ProjectStatus? oldStatus;
  final ProjectStatus newStatus;
  final String changedBy;
  final String? notes;
  final DateTime createdAt;

  StatusHistory({
    String? id,
    required this.projectId,
    this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'old_status': oldStatus?.toSupabaseValue(),
      'new_status': newStatus.toSupabaseValue(),
      'changed_by': changedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      oldStatus: map['old_status'] != null
          ? ProjectStatusExtension.fromSupabaseValue(
              map['old_status'] as String,
            )
          : null,
      newStatus: ProjectStatusExtension.fromSupabaseValue(
        map['new_status'] as String,
      ),
      changedBy: map['changed_by'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
