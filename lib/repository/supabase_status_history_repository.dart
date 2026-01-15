import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';

/// Repository for Supabase status history operations
class SupabaseStatusHistoryRepository {
  final _supabase = SupabaseConfig.client;

  /// Get status history for a project
  Future<List<StatusHistory>> getStatusHistoryByProject(
    String projectId,
  ) async {
    try {
      final response = await _supabase
          .from('status_history')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StatusHistory.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch status history: $e');
    }
  }

  /// Create a status history entry
  Future<StatusHistory> createStatusHistory(StatusHistory history) async {
    try {
      final response = await _supabase
          .from('status_history')
          .insert(history.toMap())
          .select()
          .single();

      return StatusHistory.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create status history: $e');
    }
  }
}
