import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Supabase configuration and initialization
/// Only uses values from .env file
class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      // Load environment variables from .env file
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file not found or error loading it
      debugPrint('Could not load .env file: $e');
      debugPrint('Supabase will not be initialized');
      return;
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint(
        'Warning: SUPABASE_URL or SUPABASE_ANON_KEY is missing in .env file',
      );
      debugPrint('Supabase will not be initialized');
      return; // Don't initialize Supabase if credentials are missing
    }

    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isInitialized {
    try {
      // Try to access the client - if it doesn't throw, Supabase is initialized
      final _ = Supabase.instance.client;
      return true;
    } catch (e) {
      return false;
    }
  }
}
