import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim_photo.dart';

class PhotoService {
  final _client = SupabaseConfig.client;
  static const String storageBucket = 'soteria';

  // Upload photo to Supabase Storage
  Future<void> uploadPhoto({
    required String claimId,
    required String imagePath,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Create storage path: {claim_id}/{timestamp}_{filename}
    final fileName = path.basename(imagePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$claimId/${timestamp}_$fileName';

    // Upload file to storage
    final file = File(imagePath);

    await _client.storage.from(storageBucket).upload(storagePath, file);

    // Create record in database
    await _client.from('claim_photos').insert({
      'claim_id': claimId,
      'storage_path': storagePath,
      'uploaded_by': userId,
      'description': description,
    });
  }

  // Get photos by claim
  Future<List<ClaimPhoto>> getPhotosByClaim(String claimId) async {
    final response = await _client
        .from('claim_photos')
        .select()
        .eq('claim_id', claimId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ClaimPhoto.fromJson(json)).toList();
  }

  // Get photo URL
  String getPhotoUrl(String storagePath) {
    return _client.storage.from(storageBucket).getPublicUrl(storagePath);
  }

  // Delete photo
  Future<void> deletePhoto(String photoId, String storagePath) async {
    // Delete from storage
    await _client.storage.from(storageBucket).remove([storagePath]);

    // Delete from database
    await _client.from('claim_photos').delete().eq('id', photoId);
  }
}
