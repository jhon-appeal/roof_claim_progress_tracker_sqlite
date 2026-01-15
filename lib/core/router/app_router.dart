import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/claims_list_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/login_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/auth_viewmodel.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/claims_list_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouter {
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = SupabaseConfig.isInitialized
          ? SupabaseConfig.client.auth.currentSession
          : null;
      final isLoggedIn = session != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        return '/claims';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/claims',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => ClaimsListViewModel(),
          child: const ClaimsListScreen(),
        ),
      ),
    ],
  );
}
