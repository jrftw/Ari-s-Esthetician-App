/*
 * Filename: admin_services_screen.dart
 * Purpose: Admin screen for managing services (add, edit, delete, toggle active status)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: Flutter, cloud_firestore, models, services
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// Web-specific imports (conditional)
import 'dart:html'
    if (dart.library.io) 'html_stub.dart' as html;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/service_model.dart';
import '../../models/service_category_model.dart';
import '../../services/firestore_service.dart';

// MARK: - Service Sort Option Enum
/// Enum for different sorting options for services
enum ServiceSortOption {
  /// Sort alphabetically by name (A to Z)
  nameAscending,
  
  /// Sort by price (lowest to highest)
  priceAscending,
  
  /// Sort by price (highest to lowest)
  priceDescending,
  
  /// Sort by tier (Higher, Mid, Lower)
  tierAscending,
  
  /// Sort by tier (Lower, Mid, Higher)
  tierDescending,
  
  /// Default sort by display order
  displayOrder;

  /// Get display name for the sort option
  String get displayName {
    switch (this) {
      case ServiceSortOption.nameAscending:
        return 'Name (A-Z)';
      case ServiceSortOption.priceAscending:
        return 'Price (Low to High)';
      case ServiceSortOption.priceDescending:
        return 'Price (High to Low)';
      case ServiceSortOption.tierAscending:
        return 'Tier (Higher to Lower)';
      case ServiceSortOption.tierDescending:
        return 'Tier (Lower to Higher)';
      case ServiceSortOption.displayOrder:
        return 'Display Order';
    }
  }
}

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
  
  // MARK: - Sorting State
  /// Current sorting option for services list
  ServiceSortOption _currentSortOption = ServiceSortOption.displayOrder;

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
        actions: [
          // MARK: - PDF Export Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateServicesPDF(context),
            tooltip: 'Export to PDF',
          ),
          // MARK: - Sort Button
          PopupMenuButton<ServiceSortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Services',
            onSelected: (ServiceSortOption option) {
              setState(() {
                _currentSortOption = option;
                AppLogger().logInfo('Sort option changed: ${option.displayName}', tag: 'AdminServicesScreen');
              });
            },
            itemBuilder: (BuildContext context) => ServiceSortOption.values.map((option) {
              return PopupMenuItem<ServiceSortOption>(
                value: option,
                child: Row(
                  children: [
                    if (_currentSortOption == option)
                      const Icon(Icons.check, size: 20, color: AppColors.sunflowerYellow)
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(option.displayName),
                  ],
                ),
              );
            }).toList(),
          ),
          // MARK: - Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppLogger().logInfo('Settings button tapped', tag: 'AdminServicesScreen');
              context.push(AppConstants.routeSettings);
            },
            tooltip: 'Settings',
          ),
        ],
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

        // MARK: - Apply Sorting
        final sortedServices = _sortServices(services, _currentSortOption);

        AppLogger().logInfo('Displaying ${sortedServices.length} services (sorted by ${_currentSortOption.displayName})', tag: 'AdminServicesScreen');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedServices.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(sortedServices[index]);
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
              const SizedBox(height: 8),
              // MARK: - Package Tier Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPackageTierColor(service.packageTier).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPackageTierColor(service.packageTier).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: _getPackageTierColor(service.packageTier),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.packageTier.displayName} Tier',
                          style: AppTypography.labelSmall.copyWith(
                            color: _getPackageTierColor(service.packageTier),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  // MARK: - Package Tier Color Helper
  /// Returns a color based on the package tier
  /// Higher tier gets a premium color, mid gets standard, lower gets basic
  Color _getPackageTierColor(ServicePackageTier tier) {
    switch (tier) {
      case ServicePackageTier.higher:
        return AppColors.sunflowerYellow; // Premium gold/yellow
      case ServicePackageTier.mid:
        return AppColors.infoBlue; // Standard blue
      case ServicePackageTier.lower:
        return AppColors.textSecondary; // Basic gray
    }
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
    
    // Load business settings to get minimum deposit requirement
    final businessSettings = await _firestoreService.getBusinessSettings();

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

    ServicePackageTier selectedPackageTier = service?.packageTier ?? ServicePackageTier.mid;
    bool isActive = service?.isActive ?? true;
    
    // MARK: - Category State
    List<ServiceCategoryModel> availableCategories = [];
    String? selectedCategoryId = service?.categoryId;
    bool isLoadingCategories = true;
    
    // Load categories
    try {
      availableCategories = await _firestoreService.getActiveCategories();
      isLoadingCategories = false;
    } catch (e) {
      AppLogger().logError('Failed to load categories', tag: 'AdminServicesScreen', error: e);
      isLoadingCategories = false;
    }

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
                      
                      // Use business settings minimum deposit if set, otherwise allow any amount (including 0)
                      final minDepositCents = businessSettings?.minDepositAmountCents;
                      if (minDepositCents != null && depositCents < minDepositCents) {
                        return 'Deposit must be at least \$${(minDepositCents / 100).toStringAsFixed(2)}';
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
                  // MARK: - Package Tier Selector
                  DropdownButtonFormField<ServicePackageTier>(
                    value: selectedPackageTier,
                    decoration: const InputDecoration(
                      labelText: 'Package Tier *',
                      hintText: 'Select package tier',
                      helperText: 'Categorize service as Higher, Mid, or Lower tier',
                    ),
                    items: ServicePackageTier.values.map((tier) {
                      return DropdownMenuItem<ServicePackageTier>(
                        value: tier,
                        child: Text(tier.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedPackageTier = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Package tier is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Category Selector
                  if (isLoadingCategories)
                    const CircularProgressIndicator()
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Select a category (optional)',
                            helperText: 'Leave empty for "Other" / Uncategorized',
                          ),
                          items: [
                            // "None (Other)" option
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None (Other)'),
                            ),
                            // Category options
                            ...availableCategories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }),
                            // "Create New Category" option
                            const DropdownMenuItem<String>(
                              value: '__CREATE_NEW__',
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 18),
                                  SizedBox(width: 8),
                                  Text('Create New Category...'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == '__CREATE_NEW__') {
                              // Store current selection to restore if dialog is cancelled
                              final previousSelection = selectedCategoryId;
                              
                              // Immediately reset to previous value to prevent showing "__CREATE_NEW__"
                              setDialogState(() {
                                selectedCategoryId = previousSelection;
                              });
                              
                              // Show create category dialog
                              final newCategory = await _showCreateCategoryDialog(context, setDialogState);
                              if (newCategory != null) {
                                // Refresh categories list
                                try {
                                  final updatedCategories = await _firestoreService.getActiveCategories();
                                  setDialogState(() {
                                    availableCategories = updatedCategories;
                                    selectedCategoryId = newCategory.id;
                                  });
                                  AppLogger().logSuccess(
                                    'Category created and selected: ${newCategory.id}',
                                    tag: 'AdminServicesScreen',
                                  );
                                  
                                  // Show success message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Category "${newCategory.name}" created and selected'),
                                        backgroundColor: AppColors.successGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  AppLogger().logError(
                                    'Failed to refresh categories after creation',
                                    tag: 'AdminServicesScreen',
                                    error: e,
                                  );
                                  // Still set the selected category even if refresh failed
                                  setDialogState(() {
                                    selectedCategoryId = newCategory.id;
                                  });
                                }
                              }
                            } else {
                              setDialogState(() {
                                selectedCategoryId = value;
                              });
                            }
                          },
                        ),
                      ],
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
                  // Get category name snapshot if category is selected
                  String? categoryNameSnapshot;
                  if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
                    final selectedCategory = availableCategories.firstWhere(
                      (cat) => cat.id == selectedCategoryId,
                      orElse: () => ServiceCategoryModel.create(name: 'Unknown'),
                    );
                    categoryNameSnapshot = selectedCategory.name;
                  }
                  
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
                    packageTier: selectedPackageTier,
                    isActive: isActive,
                    categoryId: selectedCategoryId,
                    categoryNameSnapshot: categoryNameSnapshot,
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
    required ServicePackageTier packageTier,
    required bool isActive,
    String? categoryId,
    String? categoryNameSnapshot,
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
          packageTier: packageTier,
          isActive: isActive,
          categoryId: categoryId,
          categoryNameSnapshot: categoryNameSnapshot,
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
          packageTier: packageTier,
          isActive: isActive,
          categoryId: categoryId,
          categoryNameSnapshot: categoryNameSnapshot,
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

  // MARK: - Create Category Dialog
  /// Shows a dialog to create a new category
  /// Returns the created category if successful, null if cancelled
  Future<ServiceCategoryModel?> _showCreateCategoryDialog(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    AppLogger().logUI('Showing create category dialog', tag: 'AdminServicesScreen');
    
    final categoryNameController = TextEditingController();
    final sortOrderController = TextEditingController(text: '0');
    final categoryFormKey = GlobalKey<FormState>();
    bool isActive = true;
    
    final result = await showDialog<ServiceCategoryModel?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setCategoryDialogState) => AlertDialog(
          title: const Text('Create New Category'),
          content: SingleChildScrollView(
            child: Form(
              key: categoryFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MARK: - Category Name
                  TextFormField(
                    controller: categoryNameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      hintText: 'e.g., Facial Treatments',
                    ),
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Category name is required';
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
                  // MARK: - Sort Order
                  TextFormField(
                    controller: sortOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      hintText: '0',
                      helperText: 'Lower numbers appear first',
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
                    subtitle: const Text('Category visible in client booking'),
                    value: isActive,
                    onChanged: (value) {
                      setCategoryDialogState(() {
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
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            // MARK: - Create Button
            ElevatedButton(
              onPressed: () async {
                if (categoryFormKey.currentState!.validate()) {
                  try {
                    AppLogger().logLoading(
                      'Creating new category',
                      tag: 'AdminServicesScreen',
                    );
                    
                    final newCategory = ServiceCategoryModel.create(
                      name: categoryNameController.text.trim(),
                      sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                      isActive: isActive,
                    );
                    
                    final categoryId = await _firestoreService.createCategory(newCategory);
                    final createdCategory = newCategory.copyWith(id: categoryId);
                    
                    AppLogger().logSuccess(
                      'Category created: $categoryId',
                      tag: 'AdminServicesScreen',
                    );
                    
                    if (context.mounted) {
                      Navigator.of(context).pop(createdCategory);
                    }
                  } catch (e, stackTrace) {
                    AppLogger().logError(
                      'Failed to create category',
                      tag: 'AdminServicesScreen',
                      error: e,
                      stackTrace: stackTrace,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating category: ${e.toString()}'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    
    categoryNameController.dispose();
    sortOrderController.dispose();
    
    return result;
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

  // MARK: - Sort Services Method
  /// Sorts services based on the selected sort option
  /// Returns a new sorted list without modifying the original
  List<ServiceModel> _sortServices(List<ServiceModel> services, ServiceSortOption sortOption) {
    final sortedList = List<ServiceModel>.from(services);
    
    switch (sortOption) {
      case ServiceSortOption.nameAscending:
        sortedList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ServiceSortOption.priceAscending:
        sortedList.sort((a, b) => a.priceCents.compareTo(b.priceCents));
        break;
      case ServiceSortOption.priceDescending:
        sortedList.sort((a, b) => b.priceCents.compareTo(a.priceCents));
        break;
      case ServiceSortOption.tierAscending:
        sortedList.sort((a, b) {
          // Higher = 0, Mid = 1, Lower = 2
          final aTierValue = a.packageTier == ServicePackageTier.higher ? 0 : 
                           (a.packageTier == ServicePackageTier.mid ? 1 : 2);
          final bTierValue = b.packageTier == ServicePackageTier.higher ? 0 : 
                           (b.packageTier == ServicePackageTier.mid ? 1 : 2);
          return aTierValue.compareTo(bTierValue);
        });
        break;
      case ServiceSortOption.tierDescending:
        sortedList.sort((a, b) {
          // Higher = 0, Mid = 1, Lower = 2
          final aTierValue = a.packageTier == ServicePackageTier.higher ? 0 : 
                           (a.packageTier == ServicePackageTier.mid ? 1 : 2);
          final bTierValue = b.packageTier == ServicePackageTier.higher ? 0 : 
                           (b.packageTier == ServicePackageTier.mid ? 1 : 2);
          return bTierValue.compareTo(aTierValue);
        });
        break;
      case ServiceSortOption.displayOrder:
        sortedList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        break;
    }
    
    return sortedList;
  }

  // MARK: - Generate Services PDF Method
  /// Generates a beautiful PDF document with all service details
  /// Includes service name, description, duration, price, package tier, and category
  /// Shows preview on both web and mobile platforms before allowing print/share/save
  Future<void> _generateServicesPDF(BuildContext context) async {
    // Show loading indicator
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      AppLogger().logLoading('Generating services PDF', tag: 'AdminServicesScreen');
      
      // Fetch all services
      final services = await _firestoreService.getAllServices();
      
      if (services.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No services to export'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      // Fetch categories for display
      final categories = await _firestoreService.getActiveCategories();
      final categoryMap = {for (var cat in categories) cat.id: cat.name};

      // Create PDF document
      final pdf = pw.Document();
      
      // Define colors matching app theme
      final primaryColor = PdfColor.fromHex('#F4C430'); // Sunflower Yellow
      final darkColor = PdfColor.fromHex('#5D4037'); // Dark Brown
      final lightColor = PdfColor.fromHex('#FFF8E7'); // Soft Cream
      final textColor = PdfColor.fromHex('#3E2723'); // Dark text
      final secondaryTextColor = PdfColor.fromHex('#757575'); // Secondary text

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // MARK: - PDF Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Services Catalog',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'A',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: darkColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // MARK: - Services List
              ...services.map((service) {
                
                // Get category name
                final categoryName = service.categoryId != null && 
                                    categoryMap.containsKey(service.categoryId)
                    ? categoryMap[service.categoryId]!
                    : (service.categoryNameSnapshot ?? 'Uncategorized');

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: lightColor,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: primaryColor, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Service Name and Status
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              service.name,
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: service.isActive 
                                  ? PdfColor(0.298, 0.686, 0.314, 0.2) // #4CAF50 with 0.2 opacity
                                  : PdfColor(0.620, 0.620, 0.620, 0.2), // #9E9E9E with 0.2 opacity
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Text(
                              service.isActive ? 'Active' : 'Inactive',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: service.isActive 
                                    ? PdfColor.fromHex('#4CAF50')
                                    : PdfColor.fromHex('#9E9E9E'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      
                      // Description
                      pw.Text(
                        service.description,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      
                      // Details Row
                      pw.Row(
                        children: [
                          // Duration
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Duration',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    '${service.durationMinutes} min',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          
                          // Price
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Price',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    service.formattedPrice,
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          
                          // Deposit
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Deposit',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    service.formattedDeposit,
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      
                      // Package Tier and Category
                      pw.Row(
                        children: [
                          // Package Tier
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColor(0.957, 0.769, 0.188, 0.1), // primaryColor with 0.1 opacity
                              borderRadius: pw.BorderRadius.circular(12),
                              border: pw.Border.all(
                                color: PdfColor(0.957, 0.769, 0.188, 0.3), // primaryColor with 0.3 opacity
                                width: 1,
                              ),
                            ),
                            child: pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text(
                                  '★ ',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.Text(
                                  '${service.packageTier.displayName} Tier',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          
                          // Category
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColor(0.365, 0.251, 0.216, 0.1), // darkColor with 0.1 opacity
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Text(
                              'Category: $categoryName',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: darkColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ];
          },
        ),
      );

      // MARK: - Platform-Specific PDF Preview and Export
      final pdfBytes = await pdf.save();
      
      // Close loading dialog before showing preview
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // MARK: - Web Platform Handler
      /// For web, use direct download or browser print
      if (kIsWeb) {
        await _handleWebPDF(context, pdfBytes);
      } else {
        // MARK: - Mobile Platform Handler
        /// For mobile, use printing package with preview
        await _handleMobilePDF(context, pdfBytes);
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to generate services PDF',
        tag: 'AdminServicesScreen',
        error: e,
        stackTrace: stackTrace,
      );

      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

    // MARK: - Web PDF Handler
  /// Handles PDF preview and download for web platform
  /// Shows a dialog with options to preview, download, or print
  Future<void> _handleWebPDF(BuildContext context, Uint8List pdfBytes) async {
    // Only execute on web platform
    if (!kIsWeb) return;
    
    try {
      // Show dialog with options
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Services PDF'),
          content: const Text(
            'Choose an action:\n\n'
            '• Preview: View PDF in browser\n'
            '• Download: Save PDF to device\n'
            '• Print: Print PDF directly',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('preview'),
              child: const Text('Preview'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('download'),
              child: const Text('Download'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('print'),
              child: const Text('Print'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (action == null) return;

      // Create blob URL for preview/download (web only)
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..download = 'services_catalog_${DateTime.now().toString().split(' ')[0]}.pdf';

      switch (action) {
        case 'preview':
          // Open in new tab for preview
          anchor.target = '_blank';
          anchor.download = null; // Remove download attribute for preview
          anchor.click();
          html.Url.revokeObjectUrl(url);
          AppLogger().logSuccess('PDF preview opened in browser', tag: 'AdminServicesScreen');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF opened in new tab for preview'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
          break;

        case 'download':
          // Trigger download
          anchor.click();
          html.Url.revokeObjectUrl(url);
          AppLogger().logSuccess('PDF download started', tag: 'AdminServicesScreen');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF download started'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
          break;

        case 'print':
          // Create an iframe to load PDF and trigger print
          final iframe = html.IFrameElement()
            ..src = url
            ..style.display = 'none';
          html.document.body?.append(iframe);
          
          // Wait for PDF to load, then trigger print
          iframe.onLoad.listen((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              html.window.print();
              // Clean up
              iframe.remove();
              html.Url.revokeObjectUrl(url);
            });
          });
          
          AppLogger().logSuccess('PDF print dialog opened', tag: 'AdminServicesScreen');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Print dialog will open shortly'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
          break;
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to handle web PDF',
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

  // MARK: - Mobile PDF Handler
  /// Handles PDF preview and sharing for mobile platforms
  /// Uses printing package to show preview with share/save/print options
  Future<void> _handleMobilePDF(BuildContext context, Uint8List pdfBytes) async {
    try {
      // Use printing package for mobile - it handles preview automatically
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        format: PdfPageFormat.a4,
      );

      AppLogger().logSuccess(
        'Services PDF preview shown on mobile',
        tag: 'AdminServicesScreen',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF ready! Use the preview to share, save, or print.'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to handle mobile PDF',
        tag: 'AdminServicesScreen',
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback: Try sharePdf if layoutPdf fails
      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'services_catalog_${DateTime.now().toString().split(' ')[0]}.pdf',
        );
        AppLogger().logSuccess('PDF shared successfully (fallback method)', tag: 'AdminServicesScreen');
      } catch (shareError) {
        AppLogger().logError(
          'Both PDF methods failed',
          tag: 'AdminServicesScreen',
          error: shareError,
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
