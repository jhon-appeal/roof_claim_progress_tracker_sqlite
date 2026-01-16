import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/theme/app_theme.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/utils/constants.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/auth_viewmodel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final profile = authViewModel.currentProfile;
        final role = profile?.role ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authViewModel.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await authViewModel.loadProfile();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    color: AppTheme.getRoleColor(role).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${profile?.fullName ?? "User"}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Role: ${_getRoleDisplayName(role)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.getRoleColor(role),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (profile?.companyName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Company: ${profile!.companyName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.folder,
                        title: 'My Projects',
                        color: Colors.blue,
                        onTap: () => context.push('/projects'),
                      ),
                      if (role == AppConstants.roleAssessDirect)
                        _buildActionCard(
                          context,
                          icon: Icons.add_circle,
                          title: 'New Project',
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Create project feature coming soon'),
                              ),
                            );
                          },
                        ),
                      _buildActionCard(
                        context,
                        icon: Icons.person,
                        title: 'Profile',
                        color: Colors.orange,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile feature coming soon'),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.settings,
                        title: 'Settings',
                        color: Colors.grey,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings feature coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleHomeowner:
        return 'Homeowner';
      case AppConstants.roleRoofingCompany:
        return 'Roofing Company';
      case AppConstants.roleAssessDirect:
        return 'Assess Direct';
      default:
        return 'User';
    }
  }
}
