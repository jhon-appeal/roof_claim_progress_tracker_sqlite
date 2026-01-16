class AppConstants {
  // Storage
  static const String storageBucket = 'soteria';
  static const String filesBucketPath = 'files';

  // User Roles
  static const String roleHomeowner = 'homeowner';
  static const String roleRoofingCompany = 'roofing_company';
  static const String roleAssessDirect = 'assess_direct';

  // Project Statuses
  static const String statusPending = 'pending';
  static const String statusInspection = 'inspection';
  static const String statusClaimLodged = 'claim_lodged';
  static const String statusClaimApproved = 'claim_approved';
  static const String statusConstruction = 'construction';
  static const String statusCompleted = 'completed';
  static const String statusClosed = 'closed';

  // Milestone Statuses (matches milestone_status ENUM in Supabase)
  static const String milestonePending = 'pending';
  static const String milestoneInProgress = 'in_progress';
  static const String milestoneCompleted = 'completed';
  static const String milestoneApproved = 'approved';

  // Milestone Names (matches milestone_name ENUM in Supabase)
  static const String milestoneNameInitialInspection = 'Initial Inspection';
  static const String milestoneNameClaimLodged = 'Claim Lodged';
  static const String milestoneNameClaimApproved = 'Claim Approved';
  static const String milestoneNameRoofConstruction = 'Roof Construction';
  static const String milestoneNameFinalInspection = 'Final Inspection';
}
