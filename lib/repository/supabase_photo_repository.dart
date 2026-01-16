import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/utils/constants.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

/// Repository for Supabase progress photos operations
class SupabasePhotoRepository {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  /// Get all photos for a project
  Future<List<ProgressPhoto>> getPhotosByProject(String projectId) async {
    try {
      final response = await _supabase
          .from('progress_photos')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProgressPhoto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch photos: $e');
    }
  }

  /// Get photos for a milestone
  Future<List<ProgressPhoto>> getPhotosByMilestone(String milestoneId) async {
    try {
      final response = await _supabase
          .from('progress_photos')
          .select()
          .eq('milestone_id', milestoneId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProgressPhoto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch photos: $e');
    }
  }

  /// Upload a photo and create progress photo record
  Future<ProgressPhoto> uploadPhoto({
    required String milestoneId,
    required String projectId,
    required String imagePath,
    required String milestoneName,
    String? description,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert milestone name to filesystem-friendly format (lowercase, spaces to underscores)
      final milestoneStep = milestoneName
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');

      // Generate unique filename using UUID
      final originalExtension = path.extension(imagePath);
      final uniqueFileName = '${_uuid.v4()}$originalExtension';

      // Create storage path: {filesBucketPath}/{project_id}/{milestone_step}/{unique_filename}
      final storagePath =
          '${AppConstants.filesBucketPath}/$projectId/$milestoneStep/$uniqueFileName';

      // Upload file to storage
      final file = File(imagePath);
      await _supabase.storage
          .from(AppConstants.storageBucket)
          .upload(storagePath, file);

      // Create record in database
      final photo = ProgressPhoto(
        milestoneId: milestoneId,
        projectId: projectId,
        storagePath: storagePath,
        uploadedBy: userId,
        description: description,
      );

      final response = await _supabase
          .from('progress_photos')
          .insert(photo.toMap())
          .select()
          .single();

      return ProgressPhoto.fromMap(response);
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String id) async {
    try {
      await _supabase.from('progress_photos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get photo download URL from storage
  Future<String> getPhotoUrl(String storagePath) async {
    try {
      final response = await _supabase.storage
          .from('progress-photos')
          .createSignedUrl(storagePath, 3600);

      return response;
    } catch (e) {
      throw Exception('Failed to get photo URL: $e');
    }
  }
}
