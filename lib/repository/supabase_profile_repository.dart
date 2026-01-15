import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';

/// Repository for Supabase profiles operations
class SupabaseProfileRepository {
  final _supabase = SupabaseConfig.client;

  /// Get profile by ID
  Future<Profile?> getProfile(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      if (response == null) return null;
      return Profile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Get current user's profile
  Future<Profile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      return await getProfile(user.id);
    } catch (e) {
      throw Exception('Failed to fetch current user profile: $e');
    }
  }

  /// Create or update profile
  Future<Profile> upsertProfile(Profile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .upsert(profile.toMap())
          .select()
          .single();

      return Profile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to upsert profile: $e');
    }
  }

  /// Update profile
  Future<Profile> updateProfile(Profile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .update(profile.toMap())
          .eq('id', profile.id)
          .select()
          .single();

      return Profile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get profiles by role
  Future<List<Profile>> getProfilesByRole(UserRole role) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', role.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Profile.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch profiles: $e');
    }
  }
}
