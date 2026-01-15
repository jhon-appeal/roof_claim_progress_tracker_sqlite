import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/add_edit_claim_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/claim_detail_viewmodel.dart';

class ClaimDetailScreen extends StatefulWidget {
  final int claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load claim when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClaimDetailViewModel>().loadClaim(widget.claimId);
    });
  }

  Future<void> _updateStatus(
    BuildContext context,
    ClaimDetailViewModel viewModel,
    String newStatus,
  ) async {
    final success = await viewModel.updateStatus(newStatus);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      } else if (viewModel.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClaimDetailViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Claim Details'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            Consumer<ClaimDetailViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.claim == null) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditClaimScreen(claim: viewModel.claim),
                      ),
                    );
                    viewModel.loadClaim(widget.claimId);
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer<ClaimDetailViewModel>(
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
                      onPressed: () => viewModel.loadClaim(widget.claimId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.claim == null) {
              return const Center(child: Text('Claim not found'));
            }

            final claim = viewModel.claim!;
            final allStatuses = ClaimStatus.getAllStatuses();
            final currentIndex = ClaimStatus.getStatusIndex(claim.status);
            final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
            final statusColor = viewModel.getStatusColor(claim.status);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: statusColor,
                                radius: 30,
                                child: const Icon(
                                  Icons.home,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      claim.homeownerName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        claim.status,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Timeline
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Progress Timeline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...allStatuses.asMap().entries.map((entry) {
                            final index = entry.key;
                            final status = entry.value;
                            final isCompleted = index <= currentIndex;
                            final isCurrent = index == currentIndex;
                            final statusColorForItem = viewModel.getStatusColor(
                              status,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCompleted
                                              ? statusColorForItem
                                              : Colors.grey[300],
                                          border: Border.all(
                                            color: isCurrent
                                                ? statusColorForItem
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                        child: isCompleted
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      if (index < allStatuses.length - 1)
                                        Container(
                                          width: 2,
                                          height: 40,
                                          color: isCompleted
                                              ? statusColorForItem
                                              : Colors.grey[300],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isCompleted
                                                ? Colors.black87
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        if (isCurrent)
                                          const SizedBox(height: 4),
                                        if (isCurrent)
                                          ElevatedButton(
                                            onPressed: () {
                                              final nextStatus =
                                                  ClaimStatus.getNextStatus(
                                                    status,
                                                  );
                                              if (nextStatus != null) {
                                                _updateStatus(
                                                  context,
                                                  viewModel,
                                                  nextStatus,
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  statusColorForItem,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                            ),
                                            child: const Text(
                                              'Move to Next',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Claim Information
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Claim Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.location_on,
                            'Address',
                            claim.address,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.phone,
                            'Phone',
                            claim.phoneNumber,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.business,
                            'Insurance Company',
                            claim.insuranceCompany,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.numbers,
                            'Claim Number',
                            claim.claimNumber,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Created',
                            dateFormat.format(claim.createdAt),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            Icons.update,
                            'Last Updated',
                            dateFormat.format(claim.updatedAt),
                          ),
                          if (claim.notes.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              claim.notes,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
