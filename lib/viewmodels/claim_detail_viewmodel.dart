import 'package:flutter/material.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/claim_repository.dart';

/// ViewModel for ClaimDetailScreen
/// Manages the state and business logic for claim details
class ClaimDetailViewModel extends ChangeNotifier {
  final ClaimRepository _repository = ClaimRepository();

  Claim? _claim;
  bool _isLoading = false;
  String? _errorMessage;

  Claim? get claim => _claim;
  bool get isLoading => _isLoading;
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
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to load claim: ${e.toString()}');
    } finally {
      _setLoading(false);
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
