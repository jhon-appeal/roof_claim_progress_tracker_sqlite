import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';

/// Repository for Supabase projects operations
class SupabaseProjectRepository {
  final _supabase = SupabaseConfig.client;

  /// Get all projects
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .order('updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Project.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  /// Get project by ID
  Future<Project?> getProject(String id) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Project.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch project: $e');
    }
  }

  /// Get projects by homeowner ID
  Future<List<Project>> getProjectsByHomeowner(String homeownerId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('homeowner_id', homeownerId)
          .order('updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Project.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch projects: $e');
    }
  }

  /// Create a new project
  Future<Project> createProject(Project project) async {
    try {
      final response = await _supabase
          .from('projects')
          .insert(project.toMap())
          .select()
          .single();

      return Project.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Update an existing project
  Future<Project> updateProject(Project project) async {
    try {
      final response = await _supabase
          .from('projects')
          .update(project.toMap())
          .eq('id', project.id)
          .select()
          .single();

      return Project.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Update project status and create status history entry
  Future<Project> updateProjectStatus(
    String projectId,
    ProjectStatus newStatus,
    String changedBy, {
    String? notes,
  }) async {
    try {
      // Get current project
      final currentProject = await getProject(projectId);
      if (currentProject == null) {
        throw Exception('Project not found');
      }

      // Update project status
      final updatedProject = currentProject.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      final projectResponse = await _supabase
          .from('projects')
          .update(updatedProject.toMap())
          .eq('id', projectId)
          .select()
          .single();

      // Create status history entry
      final statusHistory = StatusHistory(
        projectId: projectId,
        oldStatus: currentProject.status,
        newStatus: newStatus,
        changedBy: changedBy,
        notes: notes,
      );

      await _supabase.from('status_history').insert(statusHistory.toMap());

      return Project.fromMap(projectResponse);
    } catch (e) {
      throw Exception('Failed to update project status: $e');
    }
  }

  /// Delete a project
  Future<void> deleteProject(String id) async {
    try {
      await _supabase.from('projects').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }
}
