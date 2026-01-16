import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:uuid/uuid.dart';

/// Service to handle synchronization between SQLite and Supabase
class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

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
  Future<void> syncToSupabase() async {
    if (!await isOnline()) {
      return;
    }

    if (!SupabaseConfig.isInitialized) {
      return;
    }

    try {
      final client = SupabaseConfig.client;
      final db = await _dbHelper.database;

      // Sync new/updated claims
      final claimsToSync = await _dbHelper.getClaimsNeedingSync();
      for (final claim in claimsToSync) {
        try {
          if (claim.id == null) continue;

          // Get supabaseId from database
          final result = await db.query(
            'claims',
            columns: ['supabaseId'],
            where: 'id = ?',
            whereArgs: [claim.id],
          );
          final supabaseIdFromDb = result.isNotEmpty
              ? result.first['supabaseId'] as String?
              : null;

          final claimMap = {
            'homeowner_name': claim.homeownerName,
            'address': claim.address,
            'phone_number': claim.phoneNumber,
            'insurance_company': claim.insuranceCompany,
            'claim_number': claim.claimNumber,
            'status': claim.status,
            'notes': claim.notes,
            'created_at': claim.createdAt.toIso8601String(),
            'updated_at': claim.updatedAt.toIso8601String(),
          };

          String? supabaseId = supabaseIdFromDb;

          if (supabaseId != null) {
            // Update existing claim in Supabase
            await client
                .from('claims')
                .update(claimMap)
                .eq('id', supabaseId);
          } else {
            // Create new claim in Supabase
            supabaseId = _uuid.v4();
            claimMap['id'] = supabaseId;
            await client.from('claims').insert(claimMap);
          }

          // Mark as synced
          if (claim.id != null && supabaseId != null) {
            await _dbHelper.markClaimAsSynced(claim.id!, supabaseId);
          }
        } catch (e) {
          // Continue with next claim if one fails
          continue;
        }
      }

      // Sync deleted claims
      final deletedClaims = await _dbHelper.getDeletedClaimsNeedingSync();
      for (final claim in deletedClaims) {
        try {
          if (claim.id == null) continue;

          final db2 = await _dbHelper.database;
          final result = await db2.query(
            'claims',
            columns: ['supabaseId'],
            where: 'id = ?',
            whereArgs: [claim.id],
          );
          final supabaseId = result.isNotEmpty
              ? result.first['supabaseId'] as String?
              : null;

          if (supabaseId != null) {
            // Delete from Supabase
            await client.from('claims').delete().eq('id', supabaseId);
          }

          // Remove from local database after successful sync
          final db3 = await _dbHelper.database;
          await db3.delete('claims', where: 'id = ?', whereArgs: [claim.id]);
        } catch (e) {
          // Continue with next claim if one fails
          continue;
        }
      }
    } catch (e) {
      // Sync failed, but app continues to work offline
    }
  }

  /// Pull data from Supabase to SQLite
  Future<void> syncFromSupabase() async {
    if (!await isOnline()) {
      return;
    }

    if (!SupabaseConfig.isInitialized) {
      return;
    }

    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('claims')
          .select()
          .order('updated_at', ascending: false);

      if (response == null) return;

      final claims = (response as List).map((json) {
        return {
          'supabaseId': json['id'] as String?,
          'homeownerName': json['homeowner_name'] as String? ?? '',
          'address': json['address'] as String? ?? '',
          'phoneNumber': json['phone_number'] as String? ?? '',
          'insuranceCompany': json['insurance_company'] as String? ?? '',
          'claimNumber': json['claim_number'] as String? ?? '',
          'status': json['status'] as String? ?? '',
          'notes': json['notes'] as String? ?? '',
          'createdAt': json['created_at'] as String? ?? '',
          'updatedAt': json['updated_at'] as String? ?? '',
        };
      }).toList();

      final db = await _dbHelper.database;

      for (final claimData in claims) {
        final supabaseId = claimData['supabaseId'] as String?;
        if (supabaseId == null) continue;

        // Check if claim already exists locally
        final existingClaim =
            await _dbHelper.getClaimBySupabaseId(supabaseId);

        if (existingClaim == null) {
          // Insert new claim
          await db.insert('claims', {
            ...claimData,
            'isSynced': 1,
            'needsSync': 0,
            'deleted': 0,
          });
        } else {
          // Update existing claim if Supabase version is newer
          final localUpdatedAt = DateTime.parse(
            claimData['updatedAt'] as String,
          );
          if (localUpdatedAt.isAfter(existingClaim.updatedAt) ||
              existingClaim.updatedAt.isAtSameMomentAs(localUpdatedAt)) {
            // Only update if local doesn't have unsynced changes
            final db2 = await _dbHelper.database;
            final result = await db2.query(
              'claims',
              columns: ['needsSync'],
              where: 'id = ?',
              whereArgs: [existingClaim.id],
            );
            final needsSync = result.isNotEmpty
                ? (result.first['needsSync'] as int? ?? 0) == 1
                : false;

            if (!needsSync) {
              await db.update(
                'claims',
                {
                  ...claimData,
                  'isSynced': 1,
                  'needsSync': 0,
                },
                where: 'id = ?',
                whereArgs: [existingClaim.id],
              );
            }
          }
        }
      }
    } catch (e) {
      // Sync failed, but app continues to work offline
    }
  }

  /// Full sync: pull from Supabase then push local changes
  Future<void> fullSync() async {
    await syncFromSupabase();
    await syncToSupabase();
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
      await syncFromSupabase();
      return true;
    }

    try {
      final response = await client
          .from('claims')
          .select()
          .order('updated_at', ascending: false);

      if (response == null) return false;

      final claims = (response as List).map((json) {
        return {
          'supabaseId': json['id'] as String?,
          'homeownerName': json['homeowner_name'] as String? ?? '',
          'address': json['address'] as String? ?? '',
          'phoneNumber': json['phone_number'] as String? ?? '',
          'insuranceCompany': json['insurance_company'] as String? ?? '',
          'claimNumber': json['claim_number'] as String? ?? '',
          'status': json['status'] as String? ?? '',
          'notes': json['notes'] as String? ?? '',
          'createdAt': json['created_at'] as String? ?? '',
          'updatedAt': json['updated_at'] as String? ?? '',
        };
      }).toList();

      final db = await _dbHelper.database;

      // Insert all claims from Supabase
      for (final claimData in claims) {
        final supabaseId = claimData['supabaseId'] as String?;
        if (supabaseId == null) continue;

        await db.insert('claims', {
          ...claimData,
          'isSynced': 1,
          'needsSync': 0,
          'deleted': 0,
        });
      }

      return true;
    } catch (e) {
      // Initial sync failed
      return false;
    }
  }
}
