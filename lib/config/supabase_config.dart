import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  // Fallback values (can be overridden by .env file)
  static const String defaultUrl = 'https://qiacdnrjqbiyfzyrvrnl.supabase.co';
  static const String defaultAnonKey = 'sb_publishable_MSBWxTQbhAt7Xs_xNu1M9Q_Av7fBSvS';

  static String? _supabaseUrl;
  static String? _supabaseAnonKey;

  static Future<void> initialize() async {
    try {
      // Try to load environment variables from .env file
      await dotenv.load(fileName: '.env');
      
      _supabaseUrl = dotenv.env['SUPABASE_URL'];
      _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    } catch (e) {
      // .env file not found or error loading it - use default values
      debugPrint('Could not load .env file: $e');
      debugPrint('Using default Supabase configuration');
    }

    // Use values from .env if available, otherwise use defaults
    final supabaseUrl = _supabaseUrl ?? defaultUrl;
    final supabaseAnonKey = _supabaseAnonKey ?? defaultAnonKey;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      debugPrint('Warning: Supabase URL or Anon Key is empty');
      return; // Don't initialize Supabase if credentials are missing
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isInitialized {
    try {
      return Supabase.instance.client != null;
    } catch (e) {
      return false;
    }
  }
}
