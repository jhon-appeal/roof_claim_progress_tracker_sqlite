import 'package:flutter/material.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim_photo.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/claim_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/photo_service.dart';

/// ViewModel for ClaimDetailScreen
/// Manages the state and business logic for claim details
class ClaimDetailViewModel extends ChangeNotifier {
  final ClaimRepository _repository = ClaimRepository();
  final PhotoService _photoService = PhotoService();

  Claim? _claim;
  List<ClaimPhoto> _photos = [];
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  Claim? get claim => _claim;
  List<ClaimPhoto> get photos => _photos;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load claim by ID
  Future<void> loadClaim(int id) async {
    _setLoading(true);
    _clearError();

    try {
      _claim = await _repository.getClaim(id);
      if (_claim == null) {
        _setError('Claim not found');
      } else {
        // Load photos for this claim
        await loadPhotos(id.toString());
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load claim: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load photos for a claim
  Future<void> loadPhotos(String claimId) async {
    try {
      _photos = await _photoService.getPhotosByClaim(claimId);
      notifyListeners();
    } catch (e) {
      // Photos loading failure shouldn't block the claim view
      _photos = [];
      notifyListeners();
    }
  }

  /// Upload photo for a claim
  Future<bool> uploadPhoto(String claimId, String imagePath, {String? description}) async {
    _isUploadingPhoto = true;
    _clearError();
    notifyListeners();

    try {
      await _photoService.uploadPhoto(
        claimId: claimId,
        imagePath: imagePath,
        description: description,
      );
      // Reload photos
      await loadPhotos(claimId);
      _isUploadingPhoto = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to upload photo: ${e.toString()}');
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(ClaimPhoto photo) async {
    _clearError();
    try {
      await _photoService.deletePhoto(photo.id, photo.storagePath);
      _photos.removeWhere((p) => p.id == photo.id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete photo: ${e.toString()}');
      notifyListeners();
      return false;
    }
  }

  /// Update claim status
  Future<bool> updateStatus(String newStatus) async {
    if (_claim == null) return false;

    _clearError();
    try {
      final updatedClaim = _claim!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _repository.updateClaim(updatedClaim);
      _claim = updatedClaim;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update status: ${e.toString()}');
      return false;
    }
  }

  /// Get color for status indicator
  Color getStatusColor(String status) {
    switch (status) {
      case ClaimStatus.hailEvent:
      case ClaimStatus.customerOutreach:
        return const Color(0xFFFF9800);
      case ClaimStatus.inspection:
      case ClaimStatus.claimEnablement:
        return const Color(0xFF2196F3);
      case ClaimStatus.claimManagement:
      case ClaimStatus.claimApproval:
        return const Color(0xFF9C27B0);
      case ClaimStatus.roofConstruction:
      case ClaimStatus.progressValidation:
        return const Color(0xFF009688);
      case ClaimStatus.paymentFlow:
        return const Color(0xFF4CAF50);
      case ClaimStatus.projectClosure:
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
