import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_project_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/auth_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';

class ProjectsViewModel extends ChangeNotifier {
  final SupabaseProjectRepository _projectRepository = SupabaseProjectRepository();
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

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
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        try {
          // Try to load from Supabase first
          final supabaseProjects = await _projectRepository.getAllProjects();
          _projects = supabaseProjects.map((p) => ProjectModel.fromJson(p.toMap())).toList();
          
          // Also save to SQLite for offline access
          for (final project in _projects) {
            final existing = await _dbHelper.getProject(project.id);
            if (existing == null) {
              await _dbHelper.insertProject(project, needsSync: false);
              await _dbHelper.markProjectAsSynced(project.id, project.id);
            } else {
              await _dbHelper.updateProject(project);
            }
          }
        } catch (e) {
          // If Supabase fails, fall back to SQLite
          _projects = await _dbHelper.getAllProjects();
        }
      } else {
        // Offline: load from SQLite
        _projects = await _dbHelper.getAllProjects();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If everything fails, try SQLite as last resort
      try {
        _projects = await _dbHelper.getAllProjects();
        _isLoading = false;
        notifyListeners();
      } catch (dbError) {
        _errorMessage = 'Failed to load projects: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createProject({
    required String address,
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

      // Always save to SQLite first
      final projectModel = ProjectModel.fromJson(projectToCreate.toMap());
      await _dbHelper.insertProject(projectModel, needsSync: true);

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        try {
          // Try to create in Supabase
          await _projectRepository.createProject(projectToCreate);
          // Mark as synced
          await _dbHelper.markProjectAsSynced(projectModel.id, projectModel.id);
        } catch (e) {
          // If Supabase fails, project is still saved locally and will sync later
        }
      }
      // If offline, project is saved locally and will sync later

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
