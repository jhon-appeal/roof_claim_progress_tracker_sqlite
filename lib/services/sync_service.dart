import 'package:connectivity_plus/connectivity_plus.dart';
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
      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  /// Check if database is empty (fresh install)
  Future<bool> isDatabaseEmpty() async {
    return await _dbHelper.isEmpty();
  }

  /// Sync all pending changes to Supabase
  Future<bool> syncToSupabase() async {
    if (!await isOnline()) {
      return false;
    }

    if (!SupabaseConfig.isInitialized) {
      return false;
    }

    try {
      final client = SupabaseConfig.client;

      // Sync new/updated projects
      final projectsToSync = await _dbHelper.getProjectsNeedingSync();
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
              await client
                  .from('projects')
                  .update(supabaseProjectMap)
                  .eq('id', supabaseId);
            } else {
              // Create new project in Supabase
              supabaseProjectMap['id'] = supabaseId;
              await client.from('projects').insert(supabaseProjectMap);
            }

            // Mark as synced
            await _dbHelper.markProjectAsSynced(project.id, supabaseId);
          } catch (e) {
            // Continue with next project if one fails
            continue;
          }
        } catch (e) {
          // Continue with next project if one fails
          continue;
        }
      }

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
              await client
                  .from('milestones')
                  .update(supabaseMilestoneMap)
                  .eq('id', supabaseId);
            } else {
              // Create new milestone in Supabase
              supabaseMilestoneMap['id'] = supabaseId;
              await client.from('milestones').insert(supabaseMilestoneMap);
            }

            // Mark as synced
            await _dbHelper.markMilestoneAsSynced(milestone.id, supabaseId);
          } catch (e) {
            // Continue with next milestone if one fails
            continue;
          }
        } catch (e) {
          // Continue with next milestone if one fails
          continue;
        }
      }

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

      return true;
    } catch (e) {
      // Sync failed
      return false;
    }
  }

  /// Pull data from Supabase to SQLite
  Future<bool> syncFromSupabase() async {
    if (!await isOnline()) {
      return false;
    }

    if (!SupabaseConfig.isInitialized) {
      return false;
    }

    try {
      final client = SupabaseConfig.client;

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

      return true;
    } catch (e) {
      // Sync failed
      return false;
    }
  }

  /// Full sync: pull from Supabase then push local changes
  Future<bool> fullSync() async {
    final pullSuccess = await syncFromSupabase();
    final pushSuccess = await syncToSupabase();
    return pullSuccess && pushSuccess;
  }

  /// Initial sync for fresh install: fetch all data from Supabase
  /// This should be called when the database is empty and user is logged in
  Future<bool> initialSyncFromSupabase() async {
    if (!await isOnline()) {
      return false;
    }

    if (!SupabaseConfig.isInitialized) {
      return false;
    }

    // Check if user is authenticated
    final client = SupabaseConfig.client;
    if (client.auth.currentUser == null) {
      return false;
    }

    // Check if database is empty (fresh install)
    final isEmpty = await _dbHelper.isEmpty();
    if (!isEmpty) {
      // Database already has data, use regular sync
      return await syncFromSupabase();
    }

    // Use regular sync which handles both insert and update
    return await syncFromSupabase();
  }
}
