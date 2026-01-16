import 'package:flutter/foundation.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/utils/constants.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_milestone_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_project_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/auth_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/milestone_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';

class ProjectDetailViewModel extends ChangeNotifier {
  final SupabaseProjectRepository _projectRepository = SupabaseProjectRepository();
  final SupabaseMilestoneRepository _milestoneRepository = SupabaseMilestoneRepository();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  ProjectModel? _project;
  List<MilestoneModel> _milestones = [];
  String? _currentUserRole;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProjectModel? get project => _project;
  List<MilestoneModel> get milestones => _milestones;
  String? get currentUserRole => _currentUserRole;

  Future<void> _loadCurrentUserRole() async {
    final profile = await _authService.getCurrentProfile();
    _currentUserRole = profile?.role;
    notifyListeners();
  }

  Future<void> loadProject(String projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabaseProject = await _projectRepository.getProject(projectId);
      if (supabaseProject != null) {
        _project = ProjectModel.fromJson(supabaseProject.toMap());
        await loadMilestones(projectId);
      }
      await _loadCurrentUserRole();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load project: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMilestones(String projectId) async {
    try {
      final supabaseMilestones = await _milestoneRepository.getMilestonesByProject(projectId);
      _milestones = supabaseMilestones.map((m) => MilestoneModel.fromJson(m.toMap())).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load milestones: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Check if the current user can change the project status
  bool canChangeStatus() {
    if (_project == null || _currentUserRole == null) return false;
    
    final currentStatus = _project!.status.toLowerCase().trim();
    
    switch (_currentUserRole!) {
      case AppConstants.roleHomeowner:
        return currentStatus == AppConstants.statusCompleted.toLowerCase() ||
               currentStatus == 'completed';
      
      case AppConstants.roleRoofingCompany:
        return currentStatus == AppConstants.statusInspection.toLowerCase() ||
               currentStatus == 'inspection' ||
               currentStatus == AppConstants.statusConstruction.toLowerCase() ||
               currentStatus == 'construction';
      
      case AppConstants.roleAssessDirect:
        return currentStatus == AppConstants.statusClaimLodged.toLowerCase() ||
               currentStatus == 'claim_lodged' ||
               currentStatus == AppConstants.statusClaimApproved.toLowerCase() ||
               currentStatus == 'claim_approved';
      
      default:
        return false;
    }
  }

  /// Get the list of allowed next statuses based on current role and status
  List<String> getAllowedNextStatuses() {
    if (_project == null || _currentUserRole == null) return [];
    
    final currentStatus = _project!.status.toLowerCase().trim();
    final List<String> allowedStatuses = [];
    
    switch (_currentUserRole!) {
      case AppConstants.roleHomeowner:
        if (currentStatus == AppConstants.statusCompleted.toLowerCase() ||
            currentStatus == 'completed') {
          allowedStatuses.addAll([AppConstants.statusClosed]);
        }
        break;
      
      case AppConstants.roleRoofingCompany:
        if (currentStatus == AppConstants.statusInspection.toLowerCase() ||
            currentStatus == 'inspection') {
          allowedStatuses.addAll([AppConstants.statusConstruction]);
        } else if (currentStatus == AppConstants.statusConstruction.toLowerCase() ||
                   currentStatus == 'construction') {
          allowedStatuses.addAll([AppConstants.statusCompleted]);
        }
        break;
      
      case AppConstants.roleAssessDirect:
        if (currentStatus == AppConstants.statusClaimLodged.toLowerCase() ||
            currentStatus == 'claim_lodged') {
          allowedStatuses.addAll([
            AppConstants.statusClaimApproved,
            AppConstants.statusInspection,
          ]);
        } else if (currentStatus == AppConstants.statusClaimApproved.toLowerCase() ||
                   currentStatus == 'claim_approved') {
          allowedStatuses.addAll([AppConstants.statusInspection]);
        }
        break;
    }
    
    return allowedStatuses;
  }

  Future<bool> updateProjectStatus(String newStatus) async {
    if (_project == null) return false;

    if (!canChangeStatus()) {
      _errorMessage = 'You do not have permission to change status at this stage.';
      notifyListeners();
      return false;
    }

    final allowedStatuses = getAllowedNextStatuses();
    final newStatusLower = newStatus.toLowerCase().trim();
    if (!allowedStatuses.any((s) => s.toLowerCase().trim() == newStatusLower)) {
      _errorMessage = 'Invalid status transition. Please select an allowed status.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert string to ProjectStatus enum
      ProjectStatus? projectStatus;
      switch (newStatusLower) {
        case 'pending':
          projectStatus = ProjectStatus.pending;
          break;
        case 'inspection':
          projectStatus = ProjectStatus.inspection;
          break;
        case 'claim_lodged':
          projectStatus = ProjectStatus.claimLodged;
          break;
        case 'claim_approved':
          projectStatus = ProjectStatus.claimApproved;
          break;
        case 'construction':
          projectStatus = ProjectStatus.construction;
          break;
        case 'completed':
          projectStatus = ProjectStatus.completed;
          break;
        case 'closed':
          projectStatus = ProjectStatus.closed;
          break;
      }

      if (projectStatus != null) {
        final userId = _authService.currentUser?.id ?? '';
        await _projectRepository.updateProjectStatus(
          _project!.id,
          projectStatus,
          userId,
        );
        await loadProject(_project!.id);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
