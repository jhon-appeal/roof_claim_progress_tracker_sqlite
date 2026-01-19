import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';

/// Repository for Supabase milestones operations
class SupabaseMilestoneRepository {
  final _supabase = SupabaseConfig.client;

  /// Get all milestones for a project
  Future<List<Milestone>> getMilestonesByProject(String projectId) async {
    try {
      final response = await _supabase
          .from('milestones')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Milestone.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch milestones: $e');
    }
  }

  /// Get milestone by ID
  Future<Milestone?> getMilestone(String id) async {
    try {
      final response = await _supabase
          .from('milestones')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Milestone.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch milestone: $e');
    }
  }

  /// Create a new milestone
  Future<Milestone> createMilestone(Milestone milestone) async {
    try {
      final response = await _supabase
          .from('milestones')
          .insert(milestone.toMap())
          .select()
          .single();

      return Milestone.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create milestone: $e');
    }
  }

  /// Update an existing milestone
  Future<Milestone> updateMilestone(Milestone milestone) async {
    try {
      final response = await _supabase
          .from('milestones')
          .update(milestone.toMap())
          .eq('id', milestone.id)
          .select()
          .single();

      return Milestone.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update milestone: $e');
    }
  }

  /// Update milestone status
  Future<Milestone> updateMilestoneStatus(
    String milestoneId,
    MilestoneStatus status,
  ) async {
    try {
      final milestone = await getMilestone(milestoneId);
      if (milestone == null) {
        throw Exception('Milestone not found');
      }

      final updatedMilestone = Milestone(
        id: milestone.id,
        projectId: milestone.projectId,
        name: milestone.name,
        description: milestone.description,
        status: status,
        dueDate: milestone.dueDate,
        completedAt: status == MilestoneStatus.completed
            ? DateTime.now()
            : milestone.completedAt,
        createdAt: milestone.createdAt,
        updatedAt: DateTime.now(),
      );

      return await updateMilestone(updatedMilestone);
    } catch (e) {
      throw Exception('Failed to update milestone status: $e');
    }
  }

  /// Delete a milestone
  Future<void> deleteMilestone(String id) async {
    try {
      await _supabase.from('milestones').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete milestone: $e');
    }
  }
}
