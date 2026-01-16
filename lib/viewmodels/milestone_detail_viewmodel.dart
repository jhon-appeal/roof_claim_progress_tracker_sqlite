import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/utils/constants.dart';
import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_milestone_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_photo_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/auth_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/milestone_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/progress_photo_model.dart';

class MilestoneDetailViewModel extends ChangeNotifier {
  final SupabaseMilestoneRepository _milestoneRepository = SupabaseMilestoneRepository();
  final SupabasePhotoRepository _photoRepository = SupabasePhotoRepository();
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  MilestoneModel? _milestone;
  List<ProgressPhotoModel> _photos = [];
  String? _currentUserRole;

  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  MilestoneModel? get milestone => _milestone;
  List<ProgressPhotoModel> get photos => _photos;
  String? get currentUserRole => _currentUserRole;

  Future<void> _loadCurrentUserRole() async {
    final profile = await _authService.getCurrentProfile();
    _currentUserRole = profile?.role;
    notifyListeners();
  }

  Future<void> loadMilestone(String milestoneId) async {
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
          final supabaseMilestone = await _milestoneRepository.getMilestone(milestoneId);
          if (supabaseMilestone != null) {
            _milestone = MilestoneModel.fromJson(supabaseMilestone.toMap());
            // Save to SQLite for offline access
            final existing = await _dbHelper.getMilestone(milestoneId);
            if (existing == null) {
              await _dbHelper.insertMilestone(_milestone!, needsSync: false);
              await _dbHelper.markMilestoneAsSynced(_milestone!.id, _milestone!.id);
            } else {
              await _dbHelper.updateMilestone(_milestone!);
            }
            await loadPhotos(milestoneId);
          }
        } catch (e) {
          // If Supabase fails, fall back to SQLite
          _milestone = await _dbHelper.getMilestone(milestoneId);
          // Photos require internet, so we won't load them offline
        }
      } else {
        // Offline: load from SQLite
        _milestone = await _dbHelper.getMilestone(milestoneId);
        // Photos require internet, so we won't load them offline
      }

      await _loadCurrentUserRole();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If everything fails, try SQLite as last resort
      try {
        _milestone = await _dbHelper.getMilestone(milestoneId);
        _isLoading = false;
        notifyListeners();
      } catch (dbError) {
        _errorMessage = 'Failed to load milestone: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadPhotos(String milestoneId) async {
    // Check if online before loading photos
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    if (!isOnline) {
      _errorMessage = 'Photos require an internet connection. Please connect to the internet to view photos.';
      notifyListeners();
      return;
    }

    try {
      final supabasePhotos = await _photoRepository.getPhotosByMilestone(milestoneId);
      _photos = supabasePhotos.map((p) => ProgressPhotoModel.fromJson(p.toMap())).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load photos: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Check if the current user can change the milestone status
  bool canChangeStatus() {
    if (_milestone == null || _currentUserRole == null) return false;
    
    final milestoneName = _milestone!.name.trim();
    
    switch (_currentUserRole!) {
      case AppConstants.roleHomeowner:
        return milestoneName == AppConstants.milestoneNameFinalInspection ||
               milestoneName.toLowerCase() == 'final inspection';
      
      case AppConstants.roleRoofingCompany:
        return milestoneName == AppConstants.milestoneNameInitialInspection ||
               milestoneName.toLowerCase() == 'initial inspection' ||
               milestoneName == AppConstants.milestoneNameRoofConstruction ||
               milestoneName.toLowerCase() == 'roof construction';
      
      case AppConstants.roleAssessDirect:
        return milestoneName == AppConstants.milestoneNameClaimLodged ||
               milestoneName.toLowerCase() == 'claim lodged' ||
               milestoneName == AppConstants.milestoneNameClaimApproved ||
               milestoneName.toLowerCase() == 'claim approved';
      
      default:
        return false;
    }
  }

  /// Get the list of allowed next statuses
  List<String> getAllowedNextStatuses() {
    if (_milestone == null || _currentUserRole == null) return [];
    
    final milestoneName = _milestone!.name.trim();
    final List<String> allowedStatuses = [];
    
    switch (_currentUserRole!) {
      case AppConstants.roleHomeowner:
        if (milestoneName == AppConstants.milestoneNameFinalInspection ||
            milestoneName.toLowerCase() == 'final inspection') {
          allowedStatuses.addAll([
            AppConstants.milestoneCompleted,
            AppConstants.milestoneApproved,
          ]);
        }
        break;
      
      case AppConstants.roleRoofingCompany:
        if (milestoneName == AppConstants.milestoneNameInitialInspection ||
            milestoneName.toLowerCase() == 'initial inspection') {
          allowedStatuses.addAll([AppConstants.milestoneInProgress]);
        } else if (milestoneName == AppConstants.milestoneNameRoofConstruction ||
                   milestoneName.toLowerCase() == 'roof construction') {
          allowedStatuses.addAll([
            AppConstants.milestoneCompleted,
            AppConstants.milestoneInProgress,
          ]);
        }
        break;
      
      case AppConstants.roleAssessDirect:
        if (milestoneName == AppConstants.milestoneNameClaimLodged ||
            milestoneName.toLowerCase() == 'claim lodged') {
          allowedStatuses.addAll([
            AppConstants.milestoneApproved,
            AppConstants.milestoneInProgress,
          ]);
        } else if (milestoneName == AppConstants.milestoneNameClaimApproved ||
                   milestoneName.toLowerCase() == 'claim approved') {
          allowedStatuses.addAll([AppConstants.milestoneInProgress]);
        }
        break;
    }
    
    return allowedStatuses;
  }

  Future<bool> updateMilestoneStatus(String newStatus) async {
    if (_milestone == null) return false;

    if (!canChangeStatus()) {
      _errorMessage = 'You do not have permission to change status at this stage.';
      notifyListeners();
      return false;
    }

    final allowedStatuses = getAllowedNextStatuses();
    final newStatusLower = newStatus.toLowerCase().trim();
    if (!allowedStatuses.any((s) => s.toLowerCase().trim() == newStatusLower)) {
      _errorMessage = 'Invalid status transition. Please select an allowed status.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Always update local SQLite first
      final updatedMilestone = MilestoneModel(
        id: _milestone!.id,
        projectId: _milestone!.projectId,
        name: _milestone!.name,
        description: _milestone!.description,
        status: newStatus,
        dueDate: _milestone!.dueDate,
        completedAt: newStatus == 'completed' ? DateTime.now() : _milestone!.completedAt,
        createdAt: _milestone!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to SQLite with needsSync = true
      await _dbHelper.updateMilestone(updatedMilestone);
      _milestone = updatedMilestone;

      // Check if online to sync to Supabase
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        try {
          MilestoneStatus? milestoneStatus;
          switch (newStatusLower) {
            case 'pending':
              milestoneStatus = MilestoneStatus.pending;
              break;
            case 'in_progress':
              milestoneStatus = MilestoneStatus.inProgress;
              break;
            case 'completed':
              milestoneStatus = MilestoneStatus.completed;
              break;
            case 'approved':
              milestoneStatus = MilestoneStatus.approved;
              break;
          }

          if (milestoneStatus != null) {
            await _milestoneRepository.updateMilestoneStatus(
              _milestone!.id,
              milestoneStatus,
            );
            // Mark as synced after successful update
            await _dbHelper.markMilestoneAsSynced(_milestone!.id, _milestone!.id);
          }
        } catch (e) {
          // If Supabase update fails, the milestone is still saved locally with needsSync = true
          // It will sync later when connection is restored
          // Don't fail the operation since local update succeeded
        }
      }
      // If offline, milestone is saved locally and will sync when connection is restored

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadPhoto(
    String projectId,
    String milestoneId,
    String imagePath,
    String? description,
  ) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    // Check if online before uploading photos
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    if (!isOnline) {
      _errorMessage = 'Photo upload requires an internet connection. Please connect to the internet to upload photos.';
      _isUploading = false;
      notifyListeners();
      return false;
    }

    try {
      if (_milestone == null) {
        _errorMessage = 'Milestone not loaded';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      await _photoRepository.uploadPhoto(
        milestoneId: milestoneId,
        projectId: projectId,
        imagePath: imagePath,
        milestoneName: _milestone!.name,
        description: description,
      );
      await loadPhotos(milestoneId);
      _isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload photo: ${e.toString()}';
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
