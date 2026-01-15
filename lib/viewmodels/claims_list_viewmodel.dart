import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/repository/claim_repository.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/sync_service.dart';

/// ViewModel for ClaimsListScreen
/// Manages the state and business logic for the claims list
class ClaimsListViewModel extends ChangeNotifier {
  final ClaimRepository _repository = ClaimRepository();
  final SyncService _syncService = SyncService();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Claim> _claims = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = false;
  bool _isSyncing = false;

  List<Claim> get claims => _claims;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  ClaimsListViewModel() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _checkConnectivity();
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Load all claims from repository (offline-first)
  Future<void> loadClaims() async {
    _setLoading(true);
    _clearError();

    try {
      // Always load from local SQLite first (works offline)
      _claims = await _repository.getAllClaims();
      
      // Try to sync if online (non-blocking)
      _checkConnectivityAndSync();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load claims: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    final wasOnline = _isOnline;
    _isOnline = await _syncService.isOnline();
    
    // If we just came online, trigger sync
    if (!wasOnline && _isOnline) {
      _syncData();
    }
    
    notifyListeners();
  }

  /// Check connectivity and sync if online
  Future<void> _checkConnectivityAndSync() async {
    await _checkConnectivity();
  }

  /// Sync data with Supabase (non-blocking)
  Future<void> _syncData() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      await _syncService.fullSync();
      // Reload claims after sync
      _claims = await _repository.getAllClaims();
    } catch (e) {
      // Sync errors are silent - app continues to work offline
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manual sync trigger
  Future<void> syncNow() async {
    await _checkConnectivityAndSync();
  }

  /// Delete a claim (offline-first, marks for sync)
  Future<bool> deleteClaim(Claim claim) async {
    if (claim.id == null) return false;

    _clearError();
    try {
      await _repository.deleteClaim(claim.id!);
      await loadClaims();
      // Try to sync if online (non-blocking)
      _checkConnectivityAndSync();
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
