import 'package:flutter/foundation.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/claim_repository.dart';

/// ViewModel for AddEditClaimScreen
/// Manages the state and business logic for creating/editing claims
class AddEditClaimViewModel extends ChangeNotifier {
  final ClaimRepository _repository = ClaimRepository();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isSuccess => _isSuccess;

  /// Save or update a claim
  Future<bool> saveClaim({
    int? id,
    required String homeownerName,
    required String address,
    required String phoneNumber,
    required String insuranceCompany,
    required String claimNumber,
    required String status,
    String notes = '',
    DateTime? createdAt,
  }) async {
    _setLoading(true);
    _clearError();
    _isSuccess = false;

    try {
      final now = DateTime.now();
      final claim = Claim(
        id: id,
        homeownerName: homeownerName.trim(),
        address: address.trim(),
        phoneNumber: phoneNumber.trim(),
        insuranceCompany: insuranceCompany.trim(),
        claimNumber: claimNumber.trim(),
        status: status,
        notes: notes.trim(),
        createdAt: createdAt ?? now,
        updatedAt: now,
      );

      if (id == null) {
        await _repository.createClaim(claim);
      } else {
        await _repository.updateClaim(claim);
      }

      _isSuccess = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save claim: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
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

  void reset() {
    _isSuccess = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
