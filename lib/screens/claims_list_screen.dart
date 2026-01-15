import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/add_edit_claim_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/claim_detail_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/auth_viewmodel.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/claims_list_viewmodel.dart';

class ClaimsListScreen extends StatefulWidget {
  const ClaimsListScreen({super.key});

  @override
  State<ClaimsListScreen> createState() => _ClaimsListScreenState();
}

class _ClaimsListScreenState extends State<ClaimsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load claims when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClaimsListViewModel>().loadClaims();
    });
  }

  Future<void> _deleteClaim(
    BuildContext context,
    ClaimsListViewModel viewModel,
    Claim claim,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Claim'),
        content: Text(
          'Are you sure you want to delete the claim for ${claim.homeownerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.deleteClaim(claim);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim deleted successfully')),
        );
      } else if (mounted && viewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to delete claim'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roof Claim Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
        actions: [
          Consumer<ClaimsListViewModel>(
            builder: (context, viewModel, child) {
              return Row(
                children: [
                  // Sync status indicator
                  if (viewModel.isSyncing)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    Icon(
                      viewModel.isOnline ? Icons.cloud_done : Icons.cloud_off,
                      color: viewModel.isOnline ? Colors.green : Colors.grey,
                    ),
                  const SizedBox(width: 8),
                  // Manual sync button
                  IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Sync',
                    onPressed: viewModel.isOnline && !viewModel.isSyncing
                        ? () => viewModel.syncNow()
                        : null,
                  ),
                ],
              );
            },
          ),
          // Logout button
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await authViewModel.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ClaimsListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage ?? 'An error occurred',
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadClaims(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.claims.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No claims yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a new claim',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadClaims(),
            child: ListView.builder(
              itemCount: viewModel.claims.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final claim = viewModel.claims[index];
                final statusColor = viewModel.getStatusColor(claim.status);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor,
                      child: const Icon(Icons.home, color: Colors.white),
                    ),
                    title: Text(
                      claim.homeownerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(claim.address),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            claim.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditClaimScreen(claim: claim),
                            ),
                          ).then((_) => viewModel.loadClaims());
                        } else if (value == 'delete') {
                          _deleteClaim(context, viewModel, claim);
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClaimDetailScreen(claimId: claim.id!),
                        ),
                      ).then((_) => viewModel.loadClaims());
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditClaimScreen()),
          );
          if (mounted) {
            context.read<ClaimsListViewModel>().loadClaims();
          }
        },
        tooltip: 'Add New Claim',
        child: const Icon(Icons.add),
      ),
    );
  }
}
