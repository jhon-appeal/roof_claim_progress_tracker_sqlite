import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/utils/constants.dart';
import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_milestone_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/supabase_project_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/auth_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/milestone_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';

class ProjectDetailViewModel extends ChangeNotifier {
  final SupabaseProjectRepository _projectRepository =
      SupabaseProjectRepository();
  final SupabaseMilestoneRepository _milestoneRepository =
      SupabaseMilestoneRepository();
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isLoading = false;
  String? _errorMessage;
  ProjectModel? _project;
  List<MilestoneModel> _milestones = [];
  String? _currentUserRole;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProjectModel? get project => _project;
  List<MilestoneModel> get milestones => _milestones;
  String? get currentUserRole => _currentUserRole;

  Future<void> _loadCurrentUserRole() async {
    try {
      final profile = await _authService.getCurrentProfile();
      _currentUserRole = profile?.role;
      notifyListeners();
    } catch (e) {
      // Don't fail if profile loading fails - try to get role from cached data
      debugPrint('Failed to load profile: $e');
      // Continue without role - UI will handle gracefully
    }
  }

  Future<void> loadProject(String projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      bool projectLoaded = false;

      if (isOnline) {
        try {
          // Try to load from Supabase first (with timeout)
          debugPrint('Loading project $projectId from Supabase...');
          final supabaseProject = await _projectRepository
              .getProject(projectId)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('Timeout loading project from Supabase');
                  throw TimeoutException('Loading project timed out');
                },
              );

          if (supabaseProject != null) {
            _project = ProjectModel.fromJson(supabaseProject.toMap());
            debugPrint('Project loaded from Supabase: ${_project!.address}');
            projectLoaded = true;

            // Save to SQLite for offline access (don't fail if this errors)
            try {
              final existing = await _dbHelper.getProject(projectId);
              if (existing == null) {
                await _dbHelper.insertProject(_project!, needsSync: false);
                await _dbHelper.markProjectAsSynced(_project!.id, _project!.id);
                debugPrint(
                  'Project saved to SQLite (inserted): ${_project!.id}',
                );
              } else {
                // Update without marking as needing sync since it came from Supabase
                // First update the project, then mark as synced
                await _dbHelper.updateProject(_project!);
                // Now mark as synced without needing sync
                await _dbHelper.markProjectAsSynced(_project!.id, _project!.id);
                debugPrint(
                  'Project saved to SQLite (updated): ${_project!.id}',
                );
              }
            } catch (dbError) {
              debugPrint('Failed to save project to SQLite: $dbError');
              debugPrint('Error type: ${dbError.runtimeType}');
              debugPrint('Error stack: ${dbError.toString()}');
              // Continue - project is still loaded from Supabase
            }
          }
        } catch (e) {
          // If Supabase fails, fall back to SQLite
          debugPrint('Failed to load project from Supabase: $e');
          debugPrint('Falling back to SQLite...');
          _project = await _dbHelper.getProject(projectId);
          if (_project != null) {
            debugPrint('Project loaded from SQLite: ${_project!.address}');
            projectLoaded = true;
          }
        }
      } else {
        // Offline: load from SQLite
        debugPrint('Offline - Loading project from SQLite...');
        _project = await _dbHelper.getProject(projectId);
        if (_project != null) {
          debugPrint('Project loaded from SQLite: ${_project!.address}');
          projectLoaded = true;
        }
      }

      // Load milestones and profile regardless of project load status
      if (projectLoaded) {
        // Load milestones (non-blocking - don't fail if this errors)
        try {
          await loadMilestones(projectId);
        } catch (milestoneError) {
          debugPrint('Failed to load milestones: $milestoneError');
          // Continue - milestones might be empty but project will still show
        }
      }

      // Load profile (non-blocking - don't fail if this errors)
      try {
        await _loadCurrentUserRole();
      } catch (profileError) {
        debugPrint('Failed to load profile: $profileError');
        // Continue - profile will be null but project will still show
      }

      if (!projectLoaded) {
        _errorMessage =
            'Project not found. Please ensure you have an internet connection to sync projects.';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading project: $e');
      // If everything fails, try SQLite as last resort
      try {
        _project = await _dbHelper.getProject(projectId);
        if (_project != null) {
          // Try to load milestones even if project load had issues
          try {
            await loadMilestones(projectId);
          } catch (_) {}
          try {
            await _loadCurrentUserRole();
          } catch (_) {}
        }
        if (_project == null) {
          _errorMessage = 'Failed to load project: ${e.toString()}';
        }
        _isLoading = false;
        notifyListeners();
      } catch (dbError) {
        _errorMessage = 'Failed to load project: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMilestones(String projectId) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        try {
          // Try to load from Supabase first (with timeout)
          debugPrint(
            'Loading milestones for project $projectId from Supabase...',
          );
          final supabaseMilestones = await _milestoneRepository
              .getMilestonesByProject(projectId)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('Timeout loading milestones from Supabase');
                  throw TimeoutException('Loading milestones timed out');
                },
              );
          _milestones = supabaseMilestones
              .map((m) => MilestoneModel.fromJson(m.toMap()))
              .toList();
          debugPrint('Loaded ${_milestones.length} milestones from Supabase');

          // Save to SQLite for offline access (don't fail if this errors)
          try {
            for (final milestone in _milestones) {
              try {
                final existing = await _dbHelper.getMilestone(milestone.id);
                if (existing == null) {
                  await _dbHelper.insertMilestone(milestone, needsSync: false);
                  await _dbHelper.markMilestoneAsSynced(
                    milestone.id,
                    milestone.id,
                  );
                  debugPrint(
                    'Milestone saved to SQLite (inserted): ${milestone.id}',
                  );
                } else {
                  // Update without marking as needing sync since it came from Supabase
                  // First update the milestone, then mark as synced
                  await _dbHelper.updateMilestone(milestone);
                  // Now mark as synced without needing sync
                  await _dbHelper.markMilestoneAsSynced(
                    milestone.id,
                    milestone.id,
                  );
                  debugPrint(
                    'Milestone saved to SQLite (updated): ${milestone.id}',
                  );
                }
              } catch (saveError) {
                debugPrint(
                  'Failed to save milestone ${milestone.id} to SQLite: $saveError',
                );
                debugPrint('Error type: ${saveError.runtimeType}');
                debugPrint('Error stack: ${saveError.toString()}');
                // Continue with next milestone
              }
            }
          } catch (dbError) {
            debugPrint('Failed to save milestones to SQLite: $dbError');
            debugPrint('Error type: ${dbError.runtimeType}');
            debugPrint('Error stack: ${dbError.toString()}');
            // Continue - milestones are still loaded from Supabase
          }
        } catch (e) {
          // If Supabase fails, fall back to SQLite
          debugPrint('Failed to load milestones from Supabase: $e');
          debugPrint('Falling back to SQLite...');
          _milestones = await _dbHelper.getMilestonesByProject(projectId);
          debugPrint('Loaded ${_milestones.length} milestones from SQLite');
        }
      } else {
        // Offline: load from SQLite
        debugPrint('Offline - Loading milestones from SQLite...');
        _milestones = await _dbHelper.getMilestonesByProject(projectId);
        debugPrint('Loaded ${_milestones.length} milestones from SQLite');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading milestones: $e');
      // If everything fails, try SQLite as last resort
      try {
        _milestones = await _dbHelper.getMilestonesByProject(projectId);
        debugPrint(
          'Loaded ${_milestones.length} milestones from SQLite (fallback)',
        );
        notifyListeners();
      } catch (dbError) {
        debugPrint('Failed to load milestones from SQLite: $dbError');
        _milestones = []; // Set to empty list instead of failing
        notifyListeners();
      }
    }
  }

  /// Check if the current user can change the project status
  bool canChangeStatus() {
    if (_project == null || _currentUserRole == null) return false;

    final currentStatus = _project!.status.toLowerCase().trim();

    switch (_currentUserRole!) {
      case AppConstants.roleHomeowner:
        return currentStatus == AppConstants.statusCompleted.toLowerCase() ||
            currentStatus == 'completed';

      case AppConstants.roleRoofingCompany:
        return currentStatus == AppConstants.statusInspection.toLowerCase() ||
            currentStatus == 'inspection' ||
            currentStatus == AppConstants.statusConstruction.toLowerCase() ||
            currentStatus == 'construction';

      case AppConstants.roleAssessDirect:
        return currentStatus == AppConstants.statusClaimLodged.toLowerCase() ||
            currentStatus == 'claim_lodged' ||
            currentStatus == AppConstants.statusClaimApproved.toLowerCase() ||
            currentStatus == 'claim_approved';

      default:
        return false;
    }
  }

  /// Get the list of allowed next statuses based on current role and status
  List<String> getAllowedNextStatuses() {
    if (_project == null || _currentUserRole == null) return [];

    final currentStatus = _project!.status.toLowerCase().trim();
    final List<String> allowedStatuses = [];

    switch (_currentUserRole!) {
      case AppConstants.roleHomeowner:
        if (currentStatus == AppConstants.statusCompleted.toLowerCase() ||
            currentStatus == 'completed') {
          allowedStatuses.addAll([AppConstants.statusClosed]);
        }
        break;

      case AppConstants.roleRoofingCompany:
        if (currentStatus == AppConstants.statusInspection.toLowerCase() ||
            currentStatus == 'inspection') {
          allowedStatuses.addAll([AppConstants.statusConstruction]);
        } else if (currentStatus ==
                AppConstants.statusConstruction.toLowerCase() ||
            currentStatus == 'construction') {
          allowedStatuses.addAll([AppConstants.statusCompleted]);
        }
        break;

      case AppConstants.roleAssessDirect:
        if (currentStatus == AppConstants.statusClaimLodged.toLowerCase() ||
            currentStatus == 'claim_lodged') {
          allowedStatuses.addAll([
            AppConstants.statusClaimApproved,
            AppConstants.statusInspection,
          ]);
        } else if (currentStatus ==
                AppConstants.statusClaimApproved.toLowerCase() ||
            currentStatus == 'claim_approved') {
          allowedStatuses.addAll([AppConstants.statusInspection]);
        }
        break;
    }

    return allowedStatuses;
  }

  Future<bool> updateProjectStatus(String newStatus) async {
    if (_project == null) return false;

    if (!canChangeStatus()) {
      _errorMessage =
          'You do not have permission to change status at this stage.';
      notifyListeners();
      return false;
    }

    final allowedStatuses = getAllowedNextStatuses();
    final newStatusLower = newStatus.toLowerCase().trim();
    if (!allowedStatuses.any((s) => s.toLowerCase().trim() == newStatusLower)) {
      _errorMessage =
          'Invalid status transition. Please select an allowed status.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Always update local SQLite first
      final updatedProject = ProjectModel(
        id: _project!.id,
        address: _project!.address,
        homeownerId: _project!.homeownerId,
        roofingCompanyId: _project!.roofingCompanyId,
        assessDirectId: _project!.assessDirectId,
        status: newStatus,
        createdAt: _project!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to SQLite with needsSync = true
      await _dbHelper.updateProject(updatedProject);
      _project = updatedProject;

      // Check if online to sync to Supabase
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        try {
          // Convert string to ProjectStatus enum
          ProjectStatus? projectStatus;
          switch (newStatusLower) {
            case 'pending':
              projectStatus = ProjectStatus.pending;
              break;
            case 'inspection':
              projectStatus = ProjectStatus.inspection;
              break;
            case 'claim_lodged':
              projectStatus = ProjectStatus.claimLodged;
              break;
            case 'claim_approved':
              projectStatus = ProjectStatus.claimApproved;
              break;
            case 'construction':
              projectStatus = ProjectStatus.construction;
              break;
            case 'completed':
              projectStatus = ProjectStatus.completed;
              break;
            case 'closed':
              projectStatus = ProjectStatus.closed;
              break;
          }

          if (projectStatus != null) {
            final userId = _authService.currentUser?.id ?? '';
            await _projectRepository.updateProjectStatus(
              _project!.id,
              projectStatus,
              userId,
            );
            // Mark as synced after successful update
            await _dbHelper.markProjectAsSynced(_project!.id, _project!.id);
          }
        } catch (e) {
          // If Supabase update fails, the project is still saved locally with needsSync = true
          // It will sync later when connection is restored
          // Don't fail the operation since local update succeeded
        }
      }
      // If offline, project is saved locally and will sync when connection is restored

      // Store info about sync status for UI feedback
      if (!isOnline) {
        // Project saved locally, will sync later
        // The error message can be used to inform user
        // but we won't set it as an error since the operation succeeded locally
      }

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
