import 'package:flutter/foundation.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/profile_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  ProfileModel? _currentProfile;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfileModel? get currentProfile => _currentProfile;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      await loadProfile();
    }
    notifyListeners();
  }

  Future<void> loadProfile() async {
    try {
      _currentProfile = await _authService.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email, password);
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? companyName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        companyName: companyName,
      );
      await loadProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign up failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _currentProfile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign out failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
