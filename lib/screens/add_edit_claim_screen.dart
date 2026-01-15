import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:roof_claim_progress_tracker_sqlite/viewmodels/add_edit_claim_viewmodel.dart';

class AddEditClaimScreen extends StatefulWidget {
  final Claim? claim;

  const AddEditClaimScreen({super.key, this.claim});

  @override
  State<AddEditClaimScreen> createState() => _AddEditClaimScreenState();
}

class _AddEditClaimScreenState extends State<AddEditClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _homeownerNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _insuranceCompanyController;
  late TextEditingController _claimNumberController;
  late TextEditingController _notesController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    final claim = widget.claim;
    _homeownerNameController = TextEditingController(
      text: claim?.homeownerName ?? '',
    );
    _addressController = TextEditingController(text: claim?.address ?? '');
    _phoneNumberController = TextEditingController(
      text: claim?.phoneNumber ?? '',
    );
    _insuranceCompanyController = TextEditingController(
      text: claim?.insuranceCompany ?? '',
    );
    _claimNumberController = TextEditingController(
      text: claim?.claimNumber ?? '',
    );
    _notesController = TextEditingController(text: claim?.notes ?? '');
    _selectedStatus = claim?.status ?? ClaimStatus.hailEvent;
  }

  @override
  void dispose() {
    _homeownerNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _insuranceCompanyController.dispose();
    _claimNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClaim(AddEditClaimViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.saveClaim(
        id: widget.claim?.id,
        homeownerName: _homeownerNameController.text,
        address: _addressController.text,
        phoneNumber: _phoneNumberController.text,
        insuranceCompany: _insuranceCompanyController.text,
        claimNumber: _claimNumberController.text,
        status: _selectedStatus,
        notes: _notesController.text,
        createdAt: widget.claim?.createdAt,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.claim == null
                    ? 'Claim added successfully'
                    : 'Claim updated successfully',
              ),
            ),
          );
          Navigator.pop(context);
        } else if (viewModel.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? 'Failed to save claim'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.claim != null;

    return ChangeNotifierProvider(
      create: (_) => AddEditClaimViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Claim' : 'Add New Claim'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Consumer<AddEditClaimViewModel>(
          builder: (context, viewModel, child) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _homeownerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Homeowner Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: !viewModel.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter homeowner name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                    enabled: !viewModel.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !viewModel.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _insuranceCompanyController,
                    decoration: const InputDecoration(
                      labelText: 'Insurance Company *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    enabled: !viewModel.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter insurance company';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _claimNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Claim Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    enabled: !viewModel.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter claim number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.track_changes),
                    ),
                    items: ClaimStatus.getAllStatuses().map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: viewModel.isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 4,
                    enabled: !viewModel.isLoading,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _saveClaim(viewModel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: viewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEditing ? 'Update Claim' : 'Save Claim',
                            style: const TextStyle(fontSize: 16),
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
}
