import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/config/supabase_config.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/dashboard_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/login_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/milestone_detail_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/project_detail_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/projects_list_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/signup_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/milestone_detail_viewmodel.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/project_detail_viewmodel.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/projects_viewmodel.dart';

class AppRouter {
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final session = SupabaseConfig.isInitialized
          ? SupabaseConfig.client.auth.currentSession
          : null;
      final isLoggedIn = session != null;
      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      if (isLoggedIn && isLoginRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => ProjectsViewModel(),
          child: const ProjectsListScreen(),
        ),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => ProjectDetailViewModel(),
            child: ProjectDetailScreen(projectId: projectId),
          );
        },
      ),
      GoRoute(
        path: '/milestones/:projectId/:milestoneId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          final milestoneId = state.pathParameters['milestoneId']!;
          return ChangeNotifierProvider(
            create: (_) => MilestoneDetailViewModel(),
            child: MilestoneDetailScreen(
              projectId: projectId,
              milestoneId: milestoneId,
            ),
          );
        },
      ),
    ],
  );
}
