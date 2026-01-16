import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/screens/add_edit_claim_screen.dart';
import 'package:roof_claim_progress_tracker_sqlite/services/photo_service.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/claim_detail_viewmodel.dart';

class ClaimDetailScreen extends StatefulWidget {
  final int claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  final PhotoService _photoService = PhotoService();

  @override
  void initState() {
    super.initState();
    // Load claim when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClaimDetailViewModel>().loadClaim(widget.claimId);
    });
  }

  Future<void> _pickAndUploadImage() async {
    final viewModel = context.read<ClaimDetailViewModel>();
    if (viewModel.claim == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final success = await viewModel.uploadPhoto(
          widget.claimId.toString(),
          image.path,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  viewModel.errorMessage ?? 'Failed to upload photo',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final viewModel = context.read<ClaimDetailViewModel>();
    if (viewModel.claim == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final success = await viewModel.uploadPhoto(
          widget.claimId.toString(),
          image.path,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  viewModel.errorMessage ?? 'Failed to upload photo',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
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
                  const SizedBox(height: 16),

                  // Photos Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress Photos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Consumer<ClaimDetailViewModel>(
                                builder: (context, viewModel, child) {
                                  return IconButton(
                                    icon: viewModel.isUploadingPhoto
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.add_photo_alternate),
                                    onPressed: viewModel.isUploadingPhoto
                                        ? null
                                        : _showImageSourceDialog,
                                    tooltip: 'Add Photo',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Consumer<ClaimDetailViewModel>(
                            builder: (context, viewModel, child) {
                              if (viewModel.photos.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No photos yet. Tap + to add one.',
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: viewModel.photos.length,
                                itemBuilder: (context, index) {
                                  final photo = viewModel.photos[index];
                                  final photoUrl = _photoService.getPhotoUrl(
                                    photo.storagePath,
                                  );
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: photoUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                        if (photo.description != null)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Colors.black54,
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                photo.description!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Delete Photo',
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this photo?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmed == true &&
                                                  mounted) {
                                                final success = await viewModel
                                                    .deletePhoto(photo);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        success
                                                            ? 'Photo deleted successfully'
                                                            : 'Failed to delete photo',
                                                      ),
                                                      backgroundColor: success
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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
