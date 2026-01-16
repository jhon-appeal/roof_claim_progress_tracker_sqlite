import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/core/theme/app_theme.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/projects_viewmodel.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsViewModel>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: Consumer<ProjectsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.projects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null && viewModel.projects.isEmpty) {
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
                      viewModel.loadProjects();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.projects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No projects found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadProjects(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.projects.length,
              itemBuilder: (context, index) {
                final project = viewModel.projects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      project.address,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildStatusChip(project.status),
                        if (project.claimNumber != null) ...[
                          const SizedBox(height: 4),
                          Text('Claim: ${project.claimNumber}'),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/projects/${project.id}');
                    },
                  ),
                );
              },
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
}
