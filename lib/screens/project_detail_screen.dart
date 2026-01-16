import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/theme/app_theme.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/project_detail_viewmodel.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String? _selectedNewStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectDetailViewModel>().loadProject(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: Consumer<ProjectDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.project == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.project == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.loadProject(widget.projectId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final project = viewModel.project;
          if (project == null) {
            return const Center(child: Text('Project not found'));
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadProject(widget.projectId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.address,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              _buildStatusChip(project.status),
                            ],
                          ),
                          // Status Change Section
                          if (viewModel.canChangeStatus()) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            _buildStatusChangeSection(
                              context,
                              viewModel,
                              project.status,
                            ),
                          ],
                          if (project.claimNumber != null) ...[
                            const SizedBox(height: 8),
                            Text('Claim Number: ${project.claimNumber}'),
                          ],
                          if (project.insuranceCompany != null) ...[
                            const SizedBox(height: 8),
                            Text('Insurance: ${project.insuranceCompany}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Milestones Section
                  const Text(
                    'Milestones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (viewModel.milestones.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No milestones yet')),
                      ),
                    )
                  else
                    ...viewModel.milestones.map((milestone) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            milestone.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (milestone.description != null) ...[
                                const SizedBox(height: 4),
                                Text(milestone.description!),
                              ],
                              const SizedBox(height: 8),
                              _buildStatusChip(milestone.status),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push(
                              '/milestones/${project.id}/${milestone.id}',
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: AppTheme.getStatusColor(status.toLowerCase()),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildStatusChangeSection(
    BuildContext context,
    ProjectDetailViewModel viewModel,
    String currentStatus,
  ) {
    final allowedStatusesRaw = viewModel.getAllowedNextStatuses();

    // Remove duplicates to prevent dropdown errors
    final allowedStatuses = allowedStatusesRaw.toSet().toList();

    if (allowedStatuses.isEmpty) {
      // Reset selection if no allowed statuses
      if (_selectedNewStatus != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedNewStatus = null;
            });
          }
        });
      }
      return const SizedBox.shrink();
    }

    // Check if selected status is still valid, reset if not
    String? validSelectedStatus;
    if (_selectedNewStatus != null) {
      final isValid = allowedStatuses.any(
        (status) =>
            status.toLowerCase().trim() ==
            _selectedNewStatus!.toLowerCase().trim(),
      );
      if (isValid) {
        // Find the exact value from allowedStatuses to ensure case/whitespace match
        validSelectedStatus = allowedStatuses.firstWhere(
          (status) =>
              status.toLowerCase().trim() ==
              _selectedNewStatus!.toLowerCase().trim(),
        );
      } else {
        // Invalid selection, reset it
        validSelectedStatus = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedNewStatus = null;
            });
          }
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Change Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'New Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          initialValue: validSelectedStatus,
          items: allowedStatuses.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status.replaceAll('_', ' ').toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedNewStatus = value;
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    if (_selectedNewStatus == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a status'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final success = await viewModel.updateProjectStatus(
                      _selectedNewStatus!,
                    );
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {
                          _selectedNewStatus = null;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              viewModel.errorMessage ??
                                  'Failed to update status',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.update),
            label: const Text('Update Status'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
