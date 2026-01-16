import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/theme/app_theme.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/utils/constants.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/sync_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/auth_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  bool? _lastSyncSuccess;
  String? _syncError;

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
      _syncError = null;
    });

    try {
      final success = await _syncService.fullSync();
      setState(() {
        _isSyncing = false;
        _lastSyncSuccess = success;
        if (!success) {
          _syncError = 'Sync failed. Please check your internet connection.';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Sync completed successfully' : (_syncError ?? 'Sync failed')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _lastSyncSuccess = false;
        _syncError = 'Sync error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_syncError ?? 'Sync failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSyncIcon() {
    if (_isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_lastSyncSuccess == null) {
      // No sync attempted yet
      return const Icon(Icons.sync);
    }

    if (_lastSyncSuccess == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return const Icon(Icons.error, color: Colors.red);
  }

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
                icon: _buildSyncIcon(),
                tooltip: _isSyncing
                    ? 'Syncing...'
                    : _lastSyncSuccess == true
                        ? 'Last sync successful'
                        : _lastSyncSuccess == false
                            ? 'Last sync failed'
                            : 'Sync',
                onPressed: _isSyncing ? null : _performSync,
              ),
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
                          onTap: () async {
                            final result = await context.push('/projects/new');
                            // Optionally refresh dashboard or show success message
                            if (context.mounted && result == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Project created successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
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
