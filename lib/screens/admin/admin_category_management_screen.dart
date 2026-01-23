/*
 * Filename: admin_category_management_screen.dart
 * Purpose: Admin screen for managing service categories (add, edit, delete, toggle active status)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: Flutter, cloud_firestore, models, services
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/service_category_model.dart';
import '../../services/firestore_service.dart';

// MARK: - Admin Category Management Screen
/// Screen for managing service categories
/// Provides full CRUD operations: Create, Read, Update, Delete (soft delete)
/// Uses real-time Firestore stream for live updates
class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  State<AdminCategoryManagementScreen> createState() => _AdminCategoryManagementScreenState();
}

// MARK: - Admin Category Management Screen State
class _AdminCategoryManagementScreenState extends State<AdminCategoryManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    AppLogger().logUI('AdminCategoryManagementScreen initialized', tag: 'AdminCategoryManagementScreen');
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppLogger().logInfo('Settings button tapped', tag: 'AdminCategoryManagementScreen');
              context.push(AppConstants.routeSettings);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _buildCategoriesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryFormDialog(context),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        child: const Icon(Icons.add),
      ),
    );
  }

  // MARK: - Categories List Builder
  /// Builds the categories list using real-time Firestore stream
  /// Shows loading state, empty state, and error handling
  Widget _buildCategoriesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .orderBy('isActive', descending: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        // MARK: - Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          AppLogger().logLoading('Loading categories', tag: 'AdminCategoryManagementScreen');
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.sunflowerYellow,
            ),
          );
        }

        // MARK: - Error State
        if (snapshot.hasError) {
          AppLogger().logError(
            'Error loading categories: ${snapshot.error}',
            tag: 'AdminCategoryManagementScreen',
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
                  'Error loading categories',
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
          AppLogger().logInfo('No categories found', tag: 'AdminCategoryManagementScreen');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No categories yet',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first category',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // MARK: - Categories List
        final categories = snapshot.data!.docs
            .map((doc) => ServiceCategoryModel.fromFirestore(doc))
            .toList();

        AppLogger().logInfo('Displaying ${categories.length} categories', tag: 'AdminCategoryManagementScreen');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index]);
          },
        );
      },
    );
  }

  // MARK: - Category Card Builder
  /// Builds an individual category card with all category details
  /// Includes edit and delete actions, active status toggle
  Widget _buildCategoryCard(ServiceCategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCategoryFormDialog(context, category: category),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MARK: - Category Header
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
                                category.name,
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
                                color: category.isActive
                                    ? AppColors.successGreen.withOpacity(0.1)
                                    : AppColors.disabledColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category.isActive ? 'Active' : 'Inactive',
                                style: AppTypography.labelSmall.copyWith(
                                  color: category.isActive
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
                          'Sort Order: ${category.sortOrder}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // MARK: - Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // MARK: - Toggle Active Status
                  IconButton(
                    icon: Icon(
                      category.isActive ? Icons.visibility_off : Icons.visibility,
                      color: category.isActive
                          ? AppColors.textSecondary
                          : AppColors.sunflowerYellow,
                    ),
                    onPressed: () => _toggleCategoryStatus(category),
                    tooltip: category.isActive
                        ? 'Deactivate category'
                        : 'Activate category',
                  ),
                  // MARK: - Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.infoBlue),
                    onPressed: () => _showCategoryFormDialog(context, category: category),
                    tooltip: 'Edit category',
                  ),
                  // MARK: - Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.errorRed),
                    onPressed: () => _confirmDeleteCategory(category),
                    tooltip: 'Delete category',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Category Form Dialog
  /// Shows dialog for creating or editing a category
  /// Handles form validation and submission
  Future<void> _showCategoryFormDialog(
    BuildContext context, {
    ServiceCategoryModel? category,
  }) async {
    final isEditing = category != null;
    AppLogger().logUI(
      isEditing ? 'Editing category: ${category.id}' : 'Creating new category',
      tag: 'AdminCategoryManagementScreen',
    );

    // MARK: - Form Controllers
    final nameController = TextEditingController(text: category?.name ?? '');
    final sortOrderController = TextEditingController(
      text: category?.sortOrder.toString() ?? '0',
    );

    bool isActive = category?.isActive ?? true;

    // MARK: - Form Key
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MARK: - Category Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      hintText: 'e.g., Facial Treatments',
                    ),
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
                  await _saveCategory(
                    context,
                    category: category,
                    name: nameController.text.trim(),
                    sortOrder: int.tryParse(sortOrderController.text) ?? 0,
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
    sortOrderController.dispose();
  }

  // MARK: - Save Category Method
  /// Saves or updates a category in Firestore
  /// Handles both create and update operations
  Future<void> _saveCategory(
    BuildContext context, {
    ServiceCategoryModel? category,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    try {
      AppLogger().logLoading(
        category != null ? 'Updating category' : 'Creating category',
        tag: 'AdminCategoryManagementScreen',
      );

      if (category != null) {
        // MARK: - Update Existing Category
        final updatedCategory = category.copyWith(
          name: name,
          sortOrder: sortOrder,
          isActive: isActive,
          updatedAt: DateTime.now(),
        );

        await _firestoreService.updateCategory(updatedCategory);
        AppLogger().logSuccess(
          'Category updated: ${updatedCategory.id}',
          tag: 'AdminCategoryManagementScreen',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category updated successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // MARK: - Create New Category
        final newCategory = ServiceCategoryModel.create(
          name: name,
          sortOrder: sortOrder,
          isActive: isActive,
        );

        await _firestoreService.createCategory(newCategory);
        AppLogger().logSuccess(
          'Category created successfully',
          tag: 'AdminCategoryManagementScreen',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category created successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save category',
        tag: 'AdminCategoryManagementScreen',
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

  // MARK: - Toggle Category Status Method
  /// Toggles the active/inactive status of a category
  Future<void> _toggleCategoryStatus(ServiceCategoryModel category) async {
    try {
      AppLogger().logLoading(
        'Toggling category status: ${category.id}',
        tag: 'AdminCategoryManagementScreen',
      );

      final updatedCategory = category.copyWith(
        isActive: !category.isActive,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateCategory(updatedCategory);
      AppLogger().logSuccess(
        'Category status toggled: ${category.id} -> ${updatedCategory.isActive ? "Active" : "Inactive"}',
        tag: 'AdminCategoryManagementScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedCategory.isActive
                  ? 'Category activated'
                  : 'Category deactivated',
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to toggle category status',
        tag: 'AdminCategoryManagementScreen',
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
  /// Shows confirmation dialog before deleting a category
  Future<void> _confirmDeleteCategory(ServiceCategoryModel category) async {
    AppLogger().logUI(
      'Delete confirmation requested for category: ${category.id}',
      tag: 'AdminCategoryManagementScreen',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
          'This will set the category to inactive. Services using this category will still be visible, '
          'but the category tab will not appear.\n\n'
          'This action cannot be undone.',
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
      await _deleteCategory(category);
    }
  }

  // MARK: - Delete Category Method
  /// Soft deletes a category (sets isActive to false)
  /// Does NOT update services that reference this category
  Future<void> _deleteCategory(ServiceCategoryModel category) async {
    try {
      AppLogger().logLoading(
        'Deleting category: ${category.id}',
        tag: 'AdminCategoryManagementScreen',
      );

      await _firestoreService.deleteCategory(category.id);
      AppLogger().logSuccess(
        'Category deleted: ${category.id}',
        tag: 'AdminCategoryManagementScreen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete category',
        tag: 'AdminCategoryManagementScreen',
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
// - Add category icons/images
// - Add category descriptions
// - Add category color coding
// - Add drag-and-drop reordering for sort order
// - Add bulk operations (activate/deactivate multiple)
// - Add category duplication feature
// - Add category analytics (service count per category)
// - Add category search/filter functionality