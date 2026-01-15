import 'package:flutter/material.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/claim_repository.dart';

/// ViewModel for ClaimsListScreen
/// Manages the state and business logic for the claims list
class ClaimsListViewModel extends ChangeNotifier {
  final ClaimRepository _repository = ClaimRepository();

  List<Claim> _claims = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Claim> get claims => _claims;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load all claims from repository
  Future<void> loadClaims() async {
    _setLoading(true);
    _clearError();

    try {
      _claims = await _repository.getAllClaims();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load claims: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a claim
  Future<bool> deleteClaim(Claim claim) async {
    if (claim.id == null) return false;

    _clearError();
    try {
      await _repository.deleteClaim(claim.id!);
      await loadClaims();
      return true;
    } catch (e) {
      _setError('Failed to delete claim: ${e.toString()}');
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
