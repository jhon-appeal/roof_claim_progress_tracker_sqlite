import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:sqflite/sqflite.dart';

/// Repository layer that abstracts data access
/// This provides a clean interface for ViewModels to interact with data
/// Works offline-first with SQLite, syncs to Supabase when online
class ClaimRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all claims
  Future<List<Claim>> getAllClaims() async {
    return await _dbHelper.getAllClaims();
  }

  /// Get a single claim by ID
  Future<Claim?> getClaim(int id) async {
    return await _dbHelper.getClaim(id);
  }

  /// Create a new claim (offline-first, marks for sync)
  Future<int> createClaim(Claim claim) async {
    final id = await _dbHelper.insertClaim(claim);
    // Mark as needing sync
    if (id > 0) {
      await _dbHelper.updateClaimSyncStatus(id, true);
    }
    return id;
  }

  /// Update an existing claim (offline-first, marks for sync)
  Future<int> updateClaim(Claim claim) async {
    final result = await _dbHelper.updateClaim(claim);
    // Mark as needing sync
    if (claim.id != null && result > 0) {
      await _dbHelper.updateClaimSyncStatus(claim.id!, true);
    }
    return result;
  }

  /// Delete a claim (soft delete, marks for sync)
  Future<int> deleteClaim(int id) async {
    return await _dbHelper.deleteClaim(id);
  }

  /// Get claims filtered by status
  Future<List<Claim>> getClaimsByStatus(String status) async {
    return await _dbHelper.getClaimsByStatus(status);
  }
}
