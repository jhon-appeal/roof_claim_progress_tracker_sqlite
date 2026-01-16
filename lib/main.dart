import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/router/app_router.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/theme/app_theme.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (optional - will fail gracefully if .env is not configured)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    // Supabase initialization failed - app can still work with SQLite only
    debugPrint('Supabase initialization failed: $e');
    debugPrint('App will continue with SQLite only mode');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide AuthViewModel at the app level
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MaterialApp.router(
        title: 'Roof Claim Progress Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
