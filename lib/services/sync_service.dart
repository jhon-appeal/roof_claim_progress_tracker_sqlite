import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/milestone_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/supabase_models.dart';

/// Service to handle synchronization between SQLite and Supabase
class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      debugPrint('Connectivity result: $connectivityResult');
      
      // Check for any active network connection
      final hasConnection = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.other);
      
      if (hasConnection) {
        debugPrint('Network interface detected: $connectivityResult');
        // If we have a network interface, assume we're online
        // The actual sync operations will handle real connectivity errors
        return true;
      }
      
      debugPrint('No network interface detected');
      return false;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      // If connectivity check fails, assume we're offline
      return false;
    }
  }

  /// Check if database is empty (fresh install)
  Future<bool> isDatabaseEmpty() async {
    return await _dbHelper.isEmpty();
  }

  /// Sync all pending changes to Supabase
  Future<Map<String, dynamic>> syncToSupabase() async {
    String? errorMessage;
    
    if (!SupabaseConfig.isInitialized) {
      return {'success': false, 'error': 'Supabase not initialized'};
    }

    final client = SupabaseConfig.client;
    
    // Check authentication
    if (client.auth.currentUser == null) {
      return {'success': false, 'error': 'User not authenticated. Please log in again.'};
    }
    
    // Check connectivity (but don't fail if check fails - let actual operations handle errors)
    final onlineCheck = await isOnline();
    if (!onlineCheck) {
      debugPrint('Connectivity check suggests offline, but attempting sync anyway...');
      // Continue anyway - the actual Supabase operations will fail if truly offline
    }

    try {

      // Sync new/updated projects
      final projectsToSync = await _dbHelper.getProjectsNeedingSync();
      debugPrint('Syncing ${projectsToSync.length} projects to Supabase...');
      
      int projectsSynced = 0;
      int projectsFailed = 0;
      
      for (final project in projectsToSync) {
        try {
          final supabaseId = project.id;

          final projectMap = project.toJson();
          // Remove local id, use supabase id
          final supabaseProjectMap = Map<String, dynamic>.from(projectMap);
          supabaseProjectMap.remove('id');

          // Check if project exists in Supabase
          try {
            final existing = await client
                .from('projects')
                .select('id')
                .eq('id', supabaseId)
                .maybeSingle();

            if (existing != null) {
              // Update existing project in Supabase
              debugPrint('Updating project $supabaseId in Supabase...');
              await client
                  .from('projects')
                  .update(supabaseProjectMap)
                  .eq('id', supabaseId);
            } else {
              // Create new project in Supabase
              debugPrint('Creating project $supabaseId in Supabase...');
              supabaseProjectMap['id'] = supabaseId;
              await client.from('projects').insert(supabaseProjectMap);
            }

            // Mark as synced
            await _dbHelper.markProjectAsSynced(project.id, supabaseId);
            projectsSynced++;
            debugPrint('Project $supabaseId synced successfully');
          } catch (e) {
            projectsFailed++;
            debugPrint('Failed to sync project ${project.id}: $e');
            errorMessage = 'Failed to sync some projects: ${e.toString()}';
            // Continue with next project if one fails
            continue;
          }
        } catch (e) {
          projectsFailed++;
          debugPrint('Error processing project ${project.id}: $e');
          errorMessage = 'Error processing projects: ${e.toString()}';
          // Continue with next project if one fails
          continue;
        }
      }
      
      debugPrint('Projects sync completed: $projectsSynced synced, $projectsFailed failed');

      // Sync deleted projects
      final deletedProjects = await _dbHelper.getDeletedProjectsNeedingSync();
      for (final project in deletedProjects) {
        try {
          final supabaseId = project.id;

          // Check if it was synced before (has supabase id)
          final existingProject = await _dbHelper.getProject(project.id);
          if (existingProject != null) {
            // Delete from Supabase
            await client.from('projects').delete().eq('id', supabaseId);
          }

          // Remove from local database after successful sync
          final db = await _dbHelper.database;
          await db.delete('projects', where: 'id = ?', whereArgs: [project.id]);
        } catch (e) {
          // Continue with next project if one fails
          continue;
        }
      }

      // Sync new/updated milestones
      final milestonesToSync = await _dbHelper.getMilestonesNeedingSync();
      debugPrint('Syncing ${milestonesToSync.length} milestones to Supabase...');
      
      int milestonesSynced = 0;
      int milestonesFailed = 0;
      
      for (final milestone in milestonesToSync) {
        try {
          final supabaseId = milestone.id;

          final milestoneMap = milestone.toJson();
          // Remove local id, use supabase id
          final supabaseMilestoneMap = Map<String, dynamic>.from(milestoneMap);
          supabaseMilestoneMap.remove('id');

          // Check if milestone exists in Supabase
          try {
            final existing = await client
                .from('milestones')
                .select('id')
                .eq('id', supabaseId)
                .maybeSingle();

            if (existing != null) {
              // Update existing milestone in Supabase
              debugPrint('Updating milestone $supabaseId in Supabase...');
              await client
                  .from('milestones')
                  .update(supabaseMilestoneMap)
                  .eq('id', supabaseId);
            } else {
              // Create new milestone in Supabase
              debugPrint('Creating milestone $supabaseId in Supabase...');
              supabaseMilestoneMap['id'] = supabaseId;
              await client.from('milestones').insert(supabaseMilestoneMap);
            }

            // Mark as synced
            await _dbHelper.markMilestoneAsSynced(milestone.id, supabaseId);
            milestonesSynced++;
            debugPrint('Milestone $supabaseId synced successfully');
          } catch (e) {
            milestonesFailed++;
            debugPrint('Failed to sync milestone ${milestone.id}: $e');
            if (errorMessage == null) {
              errorMessage = 'Failed to sync some milestones: ${e.toString()}';
            }
            // Continue with next milestone if one fails
            continue;
          }
        } catch (e) {
          milestonesFailed++;
          debugPrint('Error processing milestone ${milestone.id}: $e');
          if (errorMessage == null) {
            errorMessage = 'Error processing milestones: ${e.toString()}';
          }
          // Continue with next milestone if one fails
          continue;
        }
      }
      
      debugPrint('Milestones sync completed: $milestonesSynced synced, $milestonesFailed failed');

      // Sync deleted milestones
      final deletedMilestones = await _dbHelper.getDeletedMilestonesNeedingSync();
      for (final milestone in deletedMilestones) {
        try {
          final supabaseId = milestone.id;

          // Delete from Supabase
          await client.from('milestones').delete().eq('id', supabaseId);

          // Remove from local database after successful sync
          final db = await _dbHelper.database;
          await db.delete('milestones', where: 'id = ?', whereArgs: [milestone.id]);
        } catch (e) {
          // Continue with next milestone if one fails
          continue;
        }
      }

      // Return success if at least some items were synced or if there was nothing to sync
      if (projectsToSync.isEmpty && milestonesToSync.isEmpty) {
        return {'success': true, 'message': 'No items to sync'};
      }
      
      if (errorMessage != null) {
        return {'success': false, 'error': errorMessage};
      }
      
      return {'success': true, 'message': 'Sync completed'};
    } catch (e, stackTrace) {
      // Sync failed
      debugPrint('Sync failed with error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'error': 'Sync failed: ${e.toString()}'};
    }
  }

  /// Pull data from Supabase to SQLite
  Future<Map<String, dynamic>> syncFromSupabase() async {
    if (!SupabaseConfig.isInitialized) {
      return {'success': false, 'error': 'Supabase not initialized'};
    }

    final client = SupabaseConfig.client;
    
    // Check authentication
    if (client.auth.currentUser == null) {
      return {'success': false, 'error': 'User not authenticated. Please log in again.'};
    }
    
    // Check connectivity (but don't fail if check fails - let actual operations handle errors)
    final onlineCheck = await isOnline();
    if (!onlineCheck) {
      debugPrint('Connectivity check suggests offline, but attempting sync anyway...');
      // Continue anyway - the actual Supabase operations will fail if truly offline
    }

    try {

      // Sync projects
      final projectsResponse = await client
          .from('projects')
          .select()
          .order('updated_at', ascending: false);

      if (projectsResponse != null) {
        final projects = (projectsResponse as List)
            .map((json) => Project.fromMap(json as Map<String, dynamic>))
            .toList();

        for (final supabaseProject in projects) {
          final supabaseId = supabaseProject.id;

          // Check if project already exists locally
          final existingProject = await _dbHelper.getProjectBySupabaseId(supabaseId);

          if (existingProject == null) {
            // Insert new project
            final projectModel = ProjectModel(
              id: supabaseProject.id,
              address: supabaseProject.address,
              homeownerId: supabaseProject.homeownerId,
              roofingCompanyId: supabaseProject.roofingCompanyId,
              assessDirectId: supabaseProject.assessDirectId,
              status: supabaseProject.status.toSupabaseValue(),
              createdAt: supabaseProject.createdAt,
              updatedAt: supabaseProject.updatedAt,
            );
            await _dbHelper.insertProject(projectModel, needsSync: false);
            await _dbHelper.markProjectAsSynced(projectModel.id, supabaseId);
          } else {
            // Update existing project if Supabase version is newer
            final localUpdatedAt = existingProject.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final supabaseUpdatedAt = supabaseProject.updatedAt;

            if (supabaseUpdatedAt.isAfter(localUpdatedAt) ||
                supabaseUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
              // Only update if local doesn't have unsynced changes
              final db = await _dbHelper.database;
              final result = await db.query(
                'projects',
                columns: ['needsSync'],
                where: 'id = ?',
                whereArgs: [existingProject.id],
              );
              final needsSync = result.isNotEmpty
                  ? (result.first['needsSync'] as int? ?? 0) == 1
                  : false;

              if (!needsSync) {
                final projectModel = ProjectModel(
                  id: supabaseProject.id,
                  address: supabaseProject.address,
                  homeownerId: supabaseProject.homeownerId,
                  roofingCompanyId: supabaseProject.roofingCompanyId,
                  assessDirectId: supabaseProject.assessDirectId,
                  status: supabaseProject.status.toSupabaseValue(),
                  createdAt: supabaseProject.createdAt,
                  updatedAt: supabaseProject.updatedAt,
                );
                await _dbHelper.updateProject(projectModel);
                // Mark as synced after update
                await _dbHelper.markProjectAsSynced(projectModel.id, supabaseId);
              }
            }
          }
        }
      }

      // Sync milestones
      final milestonesResponse = await client
          .from('milestones')
          .select()
          .order('updated_at', ascending: false);

      if (milestonesResponse != null) {
        final milestones = (milestonesResponse as List)
            .map((json) => Milestone.fromMap(json as Map<String, dynamic>))
            .toList();

        for (final supabaseMilestone in milestones) {
          final supabaseId = supabaseMilestone.id;

          // Check if milestone already exists locally
          final existingMilestone = await _dbHelper.getMilestoneBySupabaseId(supabaseId);

          if (existingMilestone == null) {
            // Insert new milestone
            final milestoneModel = MilestoneModel(
              id: supabaseMilestone.id,
              projectId: supabaseMilestone.projectId,
              name: supabaseMilestone.name,
              description: supabaseMilestone.description,
              status: supabaseMilestone.status.toSupabaseValue(),
              dueDate: supabaseMilestone.dueDate,
              completedAt: supabaseMilestone.completedAt,
              createdAt: supabaseMilestone.createdAt,
              updatedAt: supabaseMilestone.updatedAt,
            );
            await _dbHelper.insertMilestone(milestoneModel, needsSync: false);
            await _dbHelper.markMilestoneAsSynced(milestoneModel.id, supabaseId);
          } else {
            // Update existing milestone if Supabase version is newer
            final localUpdatedAt = existingMilestone.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final supabaseUpdatedAt = supabaseMilestone.updatedAt;

            if (supabaseUpdatedAt.isAfter(localUpdatedAt) ||
                supabaseUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
              // Only update if local doesn't have unsynced changes
              final db = await _dbHelper.database;
              final result = await db.query(
                'milestones',
                columns: ['needsSync'],
                where: 'id = ?',
                whereArgs: [existingMilestone.id],
              );
              final needsSync = result.isNotEmpty
                  ? (result.first['needsSync'] as int? ?? 0) == 1
                  : false;

              if (!needsSync) {
                final milestoneModel = MilestoneModel(
                  id: supabaseMilestone.id,
                  projectId: supabaseMilestone.projectId,
                  name: supabaseMilestone.name,
                  description: supabaseMilestone.description,
                  status: supabaseMilestone.status.toSupabaseValue(),
                  dueDate: supabaseMilestone.dueDate,
                  completedAt: supabaseMilestone.completedAt,
                  createdAt: supabaseMilestone.createdAt,
                  updatedAt: supabaseMilestone.updatedAt,
                );
                await _dbHelper.updateMilestone(milestoneModel);
                // Mark as synced after update
                await _dbHelper.markMilestoneAsSynced(milestoneModel.id, supabaseId);
              }
            }
          }
        }
      }

      return {'success': true, 'message': 'Data synced from Supabase'};
    } catch (e, stackTrace) {
      // Sync failed
      debugPrint('Failed to sync from Supabase: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'success': false, 'error': 'Failed to sync from server: ${e.toString()}'};
    }
  }

  /// Full sync: pull from Supabase then push local changes
  Future<Map<String, dynamic>> fullSync() async {
    debugPrint('Starting full sync...');
    
    final pullResult = await syncFromSupabase();
    final pushResult = await syncToSupabase();
    
    debugPrint('Pull result: $pullResult');
    debugPrint('Push result: $pushResult');
    
    final bothSuccess = pullResult['success'] == true && pushResult['success'] == true;
    
    if (bothSuccess) {
      return {'success': true, 'message': 'Sync completed successfully'};
    } else {
      final errors = <String>[];
      if (pullResult['success'] != true) {
        errors.add('Pull: ${pullResult['error'] ?? 'Failed'}');
      }
      if (pushResult['success'] != true) {
        errors.add('Push: ${pushResult['error'] ?? 'Failed'}');
      }
      return {'success': false, 'error': errors.join('; ')};
    }
  }

  /// Initial sync for fresh install: fetch all data from Supabase
  /// This should be called when the database is empty and user is logged in
  Future<Map<String, dynamic>> initialSyncFromSupabase() async {
    if (!SupabaseConfig.isInitialized) {
      return {'success': false, 'error': 'Supabase not initialized'};
    }

    // Check if user is authenticated
    final client = SupabaseConfig.client;
    if (client.auth.currentUser == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    // Use regular sync which handles both insert and update
    return await syncFromSupabase();
  }
}
