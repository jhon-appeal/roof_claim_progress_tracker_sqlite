import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = SupabaseConfig.client;

  // Sign in with email and password
  Future<User> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user!;
  }

  // Sign up with email and password
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? companyName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        if (companyName != null) 'company_name': companyName,
      },
    );
    return response.user!;
  }

  // Get current user profile
  Future<ProfileModel?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;
}
