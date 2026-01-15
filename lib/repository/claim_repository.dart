import 'package:roof_claim_progress_tracker_sqlite/database/database_helper.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';

/// Repository layer that abstracts data access
/// This provides a clean interface for ViewModels to interact with data
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

  /// Create a new claim
  Future<int> createClaim(Claim claim) async {
    return await _dbHelper.insertClaim(claim);
  }

  /// Update an existing claim
  Future<int> updateClaim(Claim claim) async {
    return await _dbHelper.updateClaim(claim);
  }

  /// Delete a claim
  Future<int> deleteClaim(int id) async {
    return await _dbHelper.deleteClaim(id);
  }

  /// Get claims filtered by status
  Future<List<Claim>> getClaimsByStatus(String status) async {
    return await _dbHelper.getClaimsByStatus(status);
  }
}
