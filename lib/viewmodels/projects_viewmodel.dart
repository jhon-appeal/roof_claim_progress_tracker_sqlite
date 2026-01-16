import 'package:flutter/foundation.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_project_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/auth_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';

class ProjectsViewModel extends ChangeNotifier {
  final SupabaseProjectRepository _projectRepository = SupabaseProjectRepository();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  List<ProjectModel> _projects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProjectModel> get projects => _projects;

  Future<void> loadProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabaseProjects = await _projectRepository.getAllProjects();
      _projects = supabaseProjects.map((p) => ProjectModel.fromJson(p.toMap())).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load projects: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProject({
    required String address,
    String? claimNumber,
    String? insuranceCompany,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = await _authService.getCurrentProfile();
      if (profile == null) {
        _errorMessage = 'User profile not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create project with appropriate user role ID
      final project = Project(
        address: address,
        claimNumber: claimNumber,
        insuranceCompany: insuranceCompany,
        status: ProjectStatus.pending,
      );

      // Assign project to the appropriate role field based on user role
      Project projectToCreate;
      switch (profile.role?.toLowerCase()) {
        case 'homeowner':
          projectToCreate = project.copyWith(homeownerId: currentUser.id);
          break;
        case 'roofing_company':
          projectToCreate = project.copyWith(roofingCompanyId: currentUser.id);
          break;
        case 'assess_direct':
          projectToCreate = project.copyWith(assessDirectId: currentUser.id);
          break;
        default:
          projectToCreate = project.copyWith(homeownerId: currentUser.id);
      }

      await _projectRepository.createProject(projectToCreate);
      await loadProjects();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create project: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProjectStatus(String projectId, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert string status to ProjectStatus enum
      final project = _projects.firstWhere((p) => p.id == projectId);
      // This will need to be handled by the repository
      await loadProjects();
    } catch (e) {
      _errorMessage = 'Failed to update project: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
