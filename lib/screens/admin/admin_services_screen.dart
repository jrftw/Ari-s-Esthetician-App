/*
 * Filename: admin_services_screen.dart
 * Purpose: Admin screen for managing services (add, edit, delete, toggle active status)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: Flutter, cloud_firestore, models, services
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';

// MARK: - Admin Services Screen
/// Screen for managing services offered by the business
/// Provides full CRUD operations: Create, Read, Update, Delete
/// Also allows toggling service active/inactive status
/// Uses real-time Firestore stream for live updates
class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

// MARK: - Admin Services Screen State
class _AdminServicesScreenState extends State<AdminServicesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    AppLogger().logUI('AdminServicesScreen initialized', tag: 'AdminServicesScreen');
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Management'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
      ),
      body: _buildServicesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceFormDialog(context),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        child: const Icon(Icons.add),
      ),
    );
  }

  // MARK: - Services List Builder
  /// Builds the services list using real-time Firestore stream
  /// Shows loading state, empty state, and error handling
  Widget _buildServicesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .orderBy('displayOrder')
          .snapshots(),
      builder: (context, snapshot) {
        // MARK: - Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          AppLogger().logLoading('Loading services', tag: 'AdminServicesScreen');
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.sunflowerYellow,
            ),
          );
        }

        // MARK: - Error State
        if (snapshot.hasError) {
          AppLogger().logError(
            'Error loading services: ${snapshot.error}',
            tag: 'AdminServicesScreen',
            error: snapshot.error,
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading services',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // MARK: - Empty State
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          AppLogger().logInfo('No services found', tag: 'AdminServicesScreen');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.spa_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No services yet',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first service',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // MARK: - Services List
        final services = snapshot.data!.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList();

        AppLogger().logInfo('Displaying ${services.length} services', tag: 'AdminServicesScreen');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index]);
          },
        );
      },
    );
  }

  // MARK: - Service Card Builder
  /// Builds an individual service card with all service details
  /// Includes edit and delete actions, active status toggle
  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showServiceFormDialog(context, service: service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MARK: - Service Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // MARK: - Active Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: service.isActive
                                    ? AppColors.successGreen.withOpacity(0.1)
                                    : AppColors.disabledColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                service.isActive ? 'Active' : 'Inactive',
                                style: AppTypography.labelSmall.copyWith(
                                  color: service.isActive
                                      ? AppColors.successGreen
                                      : AppColors.disabledColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // MARK: - Service Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailChip(
                      Icons.access_time,
                      '${service.durationMinutes} min',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      Icons.attach_money,
                      service.formattedPrice,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      Icons.payment,
                      'Deposit: ${service.formattedDeposit}',
                    ),
                  ),
                ],
              ),
              if (service.bufferTimeBeforeMinutes > 0 ||
                  service.bufferTimeAfterMinutes > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Buffer: ${service.bufferTimeBeforeMinutes} min before, ${service.bufferTimeAfterMinutes} min after',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // MARK: - Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // MARK: - Toggle Active Status
                  IconButton(
                    icon: Icon(
                      service.isActive ? Icons.visibility_off : Icons.visibility,
                      color: service.isActive
                          ? AppColors.textSecondary
                          : AppColors.sunflowerYellow,
                    ),
                    onPressed: () => _toggleServiceStatus(service),
                    tooltip: service.isActive
                        ? 'Deactivate service'
                        : 'Activate service',
                  ),
                  // MARK: - Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.infoBlue),
                    onPressed: () => _showServiceFormDialog(context, service: service),
                    tooltip: 'Edit service',
                  ),
                  // MARK: - Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.errorRed),
                    onPressed: () => _confirmDeleteService(service),
                    tooltip: 'Delete service',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Detail Chip Builder
  /// Builds a small chip showing service detail (duration, price, etc.)
  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softCream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Service Form Dialog
  /// Shows dialog for creating or editing a service
  /// Handles form validation and submission
  Future<void> _showServiceFormDialog(
    BuildContext context, {
    ServiceModel? service,
  }) async {
    final isEditing = service != null;
    AppLogger().logUI(
      isEditing ? 'Editing service: ${service.id}' : 'Creating new service',
      tag: 'AdminServicesScreen',
    );

    // MARK: - Form Controllers
    final nameController = TextEditingController(text: service?.name ?? '');
    final descriptionController =
        TextEditingController(text: service?.description ?? '');
    final durationController = TextEditingController(
      text: service?.durationMinutes.toString() ?? '60',
    );
    final priceController = TextEditingController(
      text: service != null
          ? (service.priceCents / 100).toStringAsFixed(2)
          : '0.00',
    );
    final depositController = TextEditingController(
      text: service != null
          ? (service.depositAmountCents / 100).toStringAsFixed(2)
          : '0.00',
    );
    final bufferBeforeController = TextEditingController(
      text: service?.bufferTimeBeforeMinutes.toString() ?? '0',
    );
    final bufferAfterController = TextEditingController(
      text: service?.bufferTimeAfterMinutes.toString() ?? '0',
    );
    final displayOrderController = TextEditingController(
      text: service?.displayOrder.toString() ?? '0',
    );

    bool isActive = service?.isActive ?? true;

    // MARK: - Form Key
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Service' : 'Add Service'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MARK: - Service Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Service Name *',
                      hintText: 'e.g., Facial Treatment',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Service name is required';
                      }
                      if (value.length < AppConstants.minNameLength) {
                        return 'Name must be at least ${AppConstants.minNameLength} characters';
                      }
                      if (value.length > AppConstants.maxNameLength) {
                        return 'Name must be less than ${AppConstants.maxNameLength} characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Description
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe the service',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Duration
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes) *',
                      hintText: '60',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Duration is required';
                      }
                      final duration = int.tryParse(value);
                      if (duration == null) {
                        return 'Please enter a valid number';
                      }
                      if (duration < AppConstants.minAppointmentDuration) {
                        return 'Duration must be at least ${AppConstants.minAppointmentDuration} minutes';
                      }
                      if (duration > AppConstants.maxAppointmentDuration) {
                        return 'Duration must be less than ${AppConstants.maxAppointmentDuration} minutes';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Price
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (\$) *',
                      hintText: '150.00',
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Deposit
                  TextFormField(
                    controller: depositController,
                    decoration: const InputDecoration(
                      labelText: 'Deposit Amount (\$) *',
                      hintText: '50.00',
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deposit is required';
                      }
                      final deposit = double.tryParse(value);
                      if (deposit == null || deposit < 0) {
                        return 'Please enter a valid deposit amount';
                      }
                      final depositCents = (deposit * 100).toInt();
                      if (depositCents < AppConstants.minDepositAmountCents) {
                        return 'Deposit must be at least \$${(AppConstants.minDepositAmountCents / 100).toStringAsFixed(2)}';
                      }
                      if (depositCents > AppConstants.maxDepositAmountCents) {
                        return 'Deposit must be less than \$${(AppConstants.maxDepositAmountCents / 100).toStringAsFixed(2)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Buffer Times
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: bufferBeforeController,
                          decoration: const InputDecoration(
                            labelText: 'Buffer Before (min)',
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final buffer = int.tryParse(value);
                              if (buffer == null || buffer < 0) {
                                return 'Invalid';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: bufferAfterController,
                          decoration: const InputDecoration(
                            labelText: 'Buffer After (min)',
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final buffer = int.tryParse(value);
                              if (buffer == null || buffer < 0) {
                                return 'Invalid';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Display Order
                  TextFormField(
                    controller: displayOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Display Order',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final order = int.tryParse(value);
                        if (order == null || order < 0) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Active Status Toggle
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Service visible to clients'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // MARK: - Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            // MARK: - Save Button
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveService(
                    context,
                    service: service,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    durationMinutes: int.parse(durationController.text),
                    priceCents: (double.parse(priceController.text) * 100).toInt(),
                    depositAmountCents:
                        (double.parse(depositController.text) * 100).toInt(),
                    bufferTimeBeforeMinutes:
                        int.tryParse(bufferBeforeController.text) ?? 0,
                    bufferTimeAfterMinutes:
                        int.tryParse(bufferAfterController.text) ?? 0,
                    displayOrder: int.tryParse(displayOrderController.text) ?? 0,
                    isActive: isActive,
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );

    // MARK: - Cleanup Controllers
    nameController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    priceController.dispose();
    depositController.dispose();
    bufferBeforeController.dispose();
    bufferAfterController.dispose();
    displayOrderController.dispose();
  }

  // MARK: - Save Service Method
  /// Saves or updates a service in Firestore
  /// Handles both create and update operations
  Future<void> _saveService(
    BuildContext context, {
    ServiceModel? service,
    required String name,
    required String description,
    required int durationMinutes,
    required int priceCents,
    required int depositAmountCents,
    required int bufferTimeBeforeMinutes,
    required int bufferTimeAfterMinutes,
    required int displayOrder,
    required bool isActive,
  }) async {
    try {
      AppLogger().logLoading(
        service != null ? 'Updating service' : 'Creating service',
        tag: 'AdminServicesScreen',
      );

      if (service != null) {
        // MARK: - Update Existing Service
        final updatedService = service.copyWith(
          name: name,
          description: description,
          durationMinutes: durationMinutes,
          priceCents: priceCents,
          depositAmountCents: depositAmountCents,
          bufferTimeBeforeMinutes: bufferTimeBeforeMinutes,
          bufferTimeAfterMinutes: bufferTimeAfterMinutes,
          displayOrder: displayOrder,
          isActive: isActive,
          updatedAt: DateTime.now(),
        );

        await _firestoreService.updateService(updatedService);
        AppLogger().logSuccess(
          'Service updated: ${updatedService.id}',
          tag: 'AdminServicesScreen',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service updated successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // MARK: - Create New Service
        final newService = ServiceModel.create(
          name: name,
          description: description,
          durationMinutes: durationMinutes,
          priceCents: priceCents,
          depositAmountCents: depositAmountCents,
          bufferTimeBeforeMinutes: bufferTimeBeforeMinutes,
          bufferTimeAfterMinutes: bufferTimeAfterMinutes,
          displayOrder: displayOrder,
          isActive: isActive,
        );

        await _firestoreService.createService(newService);
        AppLogger().logSuccess(
          'Service created successfully',
          tag: 'AdminServicesScreen',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service created successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save service',
        tag: 'AdminServicesScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // MARK: - Toggle Service Status Method
  /// Toggles the active/inactive status of a service
  Future<void> _toggleServiceStatus(ServiceModel service) async {
    try {
      AppLogger().logLoading(
        'Toggling service status: ${service.id}',
        tag: 'AdminServicesScreen',
      );

      final updatedService = service.copyWith(
        isActive: !service.isActive,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateService(updatedService);
      AppLogger().logSuccess(
        'Service status toggled: ${service.id} -> ${updatedService.isActive ? "Active" : "Inactive"}',
        tag: 'AdminServicesScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedService.isActive
                  ? 'Service activated'
                  : 'Service deactivated',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to toggle service status',
        tag: 'AdminServicesScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // MARK: - Confirm Delete Method
  /// Shows confirmation dialog before deleting a service
  Future<void> _confirmDeleteService(ServiceModel service) async {
    AppLogger().logUI(
      'Delete confirmation requested for service: ${service.id}',
      tag: 'AdminServicesScreen',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text(
          'Are you sure you want to delete "${service.name}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteService(service);
    }
  }

  // MARK: - Delete Service Method
  /// Deletes a service from Firestore
  Future<void> _deleteService(ServiceModel service) async {
    try {
      AppLogger().logLoading(
        'Deleting service: ${service.id}',
        tag: 'AdminServicesScreen',
      );

      await _firestoreService.deleteService(service.id);
      AppLogger().logSuccess(
        'Service deleted: ${service.id}',
        tag: 'AdminServicesScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service deleted successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete service',
        tag: 'AdminServicesScreen',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add service categories/tags
// - Add service images upload
// - Add drag-and-drop reordering for display order
// - Add bulk operations (activate/deactivate multiple)
// - Add service duplication feature
// - Add service analytics (booking count, revenue)
// - Add service search/filter functionality
// - Add service templates for quick creation
