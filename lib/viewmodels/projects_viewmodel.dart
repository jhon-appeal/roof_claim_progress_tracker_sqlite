import 'package:flutter/foundation.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_project_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';

class ProjectsViewModel extends ChangeNotifier {
  final SupabaseProjectRepository _projectRepository = SupabaseProjectRepository();

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
