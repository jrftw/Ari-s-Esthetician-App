/*
 * Filename: admin_software_enhancements_screen.dart
 * Purpose: Admin screen for managing software enhancements (bugs, features, suggestions)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter, cloud_firestore, intl
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/software_enhancement_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

// MARK: - Admin Software Enhancements Screen
/// Screen for super admins to manage software enhancements
/// Allows creating, viewing, updating, and tracking bugs, features, and suggestions
class AdminSoftwareEnhancementsScreen extends StatefulWidget {
  const AdminSoftwareEnhancementsScreen({super.key});

  @override
  State<AdminSoftwareEnhancementsScreen> createState() => _AdminSoftwareEnhancementsScreenState();
}

// MARK: - Admin Software Enhancements Screen State
class _AdminSoftwareEnhancementsScreenState extends State<AdminSoftwareEnhancementsScreen> {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // MARK: - State Variables
  List<SoftwareEnhancementModel> _enhancements = [];
  bool _isLoading = true;
  String? _errorMessage;
  EnhancementType? _filterType;
  EnhancementStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    logUI('AdminSoftwareEnhancementsScreen initState called', tag: 'AdminSoftwareEnhancementsScreen');
    _loadEnhancements();
  }

  // MARK: - Data Loading
  /// Load enhancements from Firestore with real-time updates
  void _loadEnhancements() {
    logLoading('Loading software enhancements...', tag: 'AdminSoftwareEnhancementsScreen');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load enhancements stream for real-time updates
      final stream = _firestoreService.getSoftwareEnhancementsStream();
      stream.listen(
        (enhancements) {
          logSuccess('Loaded ${enhancements.length} enhancements', tag: 'AdminSoftwareEnhancementsScreen');
          if (mounted) {
            setState(() {
              _enhancements = enhancements;
              _isLoading = false;
            });
          }
        },
        onError: (error, stackTrace) {
          logError(
            'Failed to load enhancements',
            tag: 'AdminSoftwareEnhancementsScreen',
            error: error,
            stackTrace: stackTrace,
          );
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          }
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize enhancements stream',
        tag: 'AdminSoftwareEnhancementsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // MARK: - Enhancement Actions
  /// Create a new enhancement
  Future<void> _createEnhancement() async {
    final result = await showDialog<SoftwareEnhancementModel>(
      context: context,
      builder: (context) => _EnhancementDialog(
        title: 'Create Enhancement',
        enhancement: null,
      ),
    );

    if (result != null && mounted) {
      try {
        logLoading('Creating enhancement...', tag: 'AdminSoftwareEnhancementsScreen');
        await _firestoreService.createSoftwareEnhancement(result);
        logSuccess('Enhancement created', tag: 'AdminSoftwareEnhancementsScreen');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enhancement created successfully'),
              backgroundColor: AppColors.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e, stackTrace) {
        logError(
          'Failed to create enhancement',
          tag: 'AdminSoftwareEnhancementsScreen',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create enhancement: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// Edit an existing enhancement
  Future<void> _editEnhancement(SoftwareEnhancementModel enhancement) async {
    final result = await showDialog<SoftwareEnhancementModel>(
      context: context,
      builder: (context) => _EnhancementDialog(
        title: 'Edit Enhancement',
        enhancement: enhancement,
      ),
    );

    if (result != null && mounted) {
      try {
        logLoading('Updating enhancement...', tag: 'AdminSoftwareEnhancementsScreen');
        await _firestoreService.updateSoftwareEnhancement(result);
        logSuccess('Enhancement updated', tag: 'AdminSoftwareEnhancementsScreen');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enhancement updated successfully'),
              backgroundColor: AppColors.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e, stackTrace) {
        logError(
          'Failed to update enhancement',
          tag: 'AdminSoftwareEnhancementsScreen',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update enhancement: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// View enhancement details
  void _viewEnhancement(SoftwareEnhancementModel enhancement) {
    showDialog(
      context: context,
      builder: (context) => _EnhancementDetailsDialog(enhancement: enhancement),
    );
  }

  // MARK: - Filtering
  /// Get filtered enhancements based on current filters
  List<SoftwareEnhancementModel> get _filteredEnhancements {
    return _enhancements.where((enhancement) {
      if (_filterType != null && enhancement.type != _filterType) {
        return false;
      }
      if (_filterStatus != null && enhancement.status != _filterStatus) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // Sort by priority (descending), then by created date (descending)
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  // MARK: - UI Builders
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Enhancements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnhancements,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // MARK: - Filters
          _buildFilters(),
          // MARK: - Content
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEnhancement,
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Type:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _filterType == null,
                onSelected: (selected) {
                  setState(() {
                    _filterType = null;
                  });
                },
              ),
              ...EnhancementType.values.map((type) => _buildFilterChip(
                label: _getTypeLabel(type),
                selected: _filterType == type,
                onSelected: (selected) {
                  setState(() {
                    _filterType = selected ? type : null;
                  });
                },
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Filter by Status:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                label: 'All',
                selected: _filterStatus == null,
                onSelected: (selected) {
                  setState(() {
                    _filterStatus = null;
                  });
                },
              ),
              ...EnhancementStatus.values.map((status) => _buildFilterChip(
                label: _getStatusLabel(status),
                selected: _filterStatus == status,
                onSelected: (selected) {
                  setState(() {
                    _filterStatus = selected ? status : null;
                  });
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.sunflowerYellow.withOpacity(0.3),
      checkmarkColor: AppColors.darkBrown,
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading enhancements',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEnhancements,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: AppColors.darkBrown,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredEnhancements;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No enhancements',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create a new bug report, feature request, or suggestion.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadEnhancements();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildEnhancementCard(filtered[index]);
        },
      ),
    );
  }

  /// Build enhancement card
  Widget _buildEnhancementCard(SoftwareEnhancementModel enhancement) {
    final typeColor = _getTypeColor(enhancement.type);
    final statusColor = _getStatusColor(enhancement.status);
    final typeIcon = _getTypeIcon(enhancement.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewEnhancement(enhancement),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enhancement.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusLabel(enhancement.status),
                                style: AppTypography.bodySmall.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getTypeLabel(enhancement.type),
                                style: AppTypography.bodySmall.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < enhancement.priority
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: AppColors.sunflowerYellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editEnhancement(enhancement),
                    tooltip: 'Edit',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                enhancement.description,
                style: AppTypography.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created by ${enhancement.createdByName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(enhancement.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (enhancement.updatedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated by ${enhancement.updatedByName ?? "Unknown"} on ${_formatDateTime(enhancement.updatedAt!)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Helper Methods
  /// Get type label
  String _getTypeLabel(EnhancementType type) {
    switch (type) {
      case EnhancementType.bug:
        return 'Bug';
      case EnhancementType.feature:
        return 'Feature';
      case EnhancementType.suggestion:
        return 'Suggestion';
      case EnhancementType.improvement:
        return 'Improvement';
    }
  }

  /// Get status label
  String _getStatusLabel(EnhancementStatus status) {
    switch (status) {
      case EnhancementStatus.open:
        return 'Open';
      case EnhancementStatus.inProgress:
        return 'In Progress';
      case EnhancementStatus.completed:
        return 'Completed';
      case EnhancementStatus.deferred:
        return 'Deferred';
      case EnhancementStatus.rejected:
        return 'Rejected';
    }
  }

  /// Get type color
  Color _getTypeColor(EnhancementType type) {
    switch (type) {
      case EnhancementType.bug:
        return AppColors.errorRed;
      case EnhancementType.feature:
        return AppColors.successGreen;
      case EnhancementType.suggestion:
        return AppColors.sunflowerYellow;
      case EnhancementType.improvement:
        return AppColors.darkBrown;
    }
  }

  /// Get status color
  Color _getStatusColor(EnhancementStatus status) {
    switch (status) {
      case EnhancementStatus.open:
        return AppColors.sunflowerYellow;
      case EnhancementStatus.inProgress:
        return Colors.blue;
      case EnhancementStatus.completed:
        return AppColors.successGreen;
      case EnhancementStatus.deferred:
        return AppColors.textSecondary;
      case EnhancementStatus.rejected:
        return AppColors.errorRed;
    }
  }

  /// Get type icon
  IconData _getTypeIcon(EnhancementType type) {
    switch (type) {
      case EnhancementType.bug:
        return Icons.bug_report;
      case EnhancementType.feature:
        return Icons.star;
      case EnhancementType.suggestion:
        return Icons.lightbulb;
      case EnhancementType.improvement:
        return Icons.trending_up;
    }
  }

  /// Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}

// MARK: - Enhancement Dialog
/// Dialog for creating/editing enhancements
class _EnhancementDialog extends StatefulWidget {
  final String title;
  final SoftwareEnhancementModel? enhancement;

  const _EnhancementDialog({
    required this.title,
    this.enhancement,
  });

  @override
  State<_EnhancementDialog> createState() => _EnhancementDialogState();
}

class _EnhancementDialogState extends State<_EnhancementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  EnhancementType _selectedType = EnhancementType.bug;
  EnhancementStatus _selectedStatus = EnhancementStatus.open;
  int _selectedPriority = 3;

  @override
  void initState() {
    super.initState();
    if (widget.enhancement != null) {
      final e = widget.enhancement!;
      _titleController.text = e.title;
      _descriptionController.text = e.description;
      _notesController.text = e.notes ?? '';
      _selectedType = e.type;
      _selectedStatus = e.status;
      _selectedPriority = e.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    
    if (user == null) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('You must be logged in to create enhancements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type
              Text(
                'Type',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EnhancementType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: EnhancementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Status (only if editing)
              if (widget.enhancement != null) ...[
                Text(
                  'Status',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<EnhancementStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: EnhancementStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusLabel(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              // Priority
              Text(
                'Priority (1-5)',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _selectedPriority.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _selectedPriority.toString(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final authService = AuthService();
              final user = FirebaseAuth.instance.currentUser;
              
              if (user == null) {
                Navigator.of(context).pop();
                return;
              }

              // Get user info
              authService.getUserRole().then((role) async {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();
                
                final userName = userDoc.data()?['firstName'] != null
                    ? '${userDoc.data()!['firstName']} ${userDoc.data()!['lastName'] ?? ''}'.trim()
                    : user.email?.split('@').first ?? 'Unknown';
                
                SoftwareEnhancementModel enhancement;
                
                if (widget.enhancement != null) {
                  // Update existing
                  enhancement = widget.enhancement!.updateWith(
                    status: _selectedStatus,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    updatedByUserId: user.uid,
                    updatedByEmail: user.email ?? '',
                    updatedByName: userName,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    priority: _selectedPriority,
                  );
                } else {
                  // Create new
                  enhancement = SoftwareEnhancementModel.create(
                    type: _selectedType,
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    createdByUserId: user.uid,
                    createdByEmail: user.email ?? '',
                    createdByName: userName,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    priority: _selectedPriority,
                  );
                }
                
                Navigator.of(context).pop(enhancement);
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sunflowerYellow,
            foregroundColor: AppColors.darkBrown,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getTypeLabel(EnhancementType type) {
    switch (type) {
      case EnhancementType.bug:
        return 'Bug';
      case EnhancementType.feature:
        return 'Feature';
      case EnhancementType.suggestion:
        return 'Suggestion';
      case EnhancementType.improvement:
        return 'Improvement';
    }
  }

  String _getStatusLabel(EnhancementStatus status) {
    switch (status) {
      case EnhancementStatus.open:
        return 'Open';
      case EnhancementStatus.inProgress:
        return 'In Progress';
      case EnhancementStatus.completed:
        return 'Completed';
      case EnhancementStatus.deferred:
        return 'Deferred';
      case EnhancementStatus.rejected:
        return 'Rejected';
    }
  }
}

// MARK: - Enhancement Details Dialog
/// Dialog for viewing enhancement details
class _EnhancementDetailsDialog extends StatelessWidget {
  final SoftwareEnhancementModel enhancement;

  const _EnhancementDetailsDialog({required this.enhancement});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(enhancement.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Type', _getTypeLabel(enhancement.type)),
            _buildDetailRow('Status', _getStatusLabel(enhancement.status)),
            _buildDetailRow('Priority', '${enhancement.priority}/5'),
            const SizedBox(height: 16),
            Text(
              'Description',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              enhancement.description,
              style: AppTypography.bodyMedium,
            ),
            if (enhancement.notes != null && enhancement.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                enhancement.notes!,
                style: AppTypography.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Created by', enhancement.createdByName),
            _buildDetailRow('Created at', _formatDateTime(enhancement.createdAt)),
            if (enhancement.updatedAt != null) ...[
              _buildDetailRow('Updated by', enhancement.updatedByName ?? 'Unknown'),
              _buildDetailRow('Updated at', _formatDateTime(enhancement.updatedAt!)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(EnhancementType type) {
    switch (type) {
      case EnhancementType.bug:
        return 'Bug';
      case EnhancementType.feature:
        return 'Feature';
      case EnhancementType.suggestion:
        return 'Suggestion';
      case EnhancementType.improvement:
        return 'Improvement';
    }
  }

  String _getStatusLabel(EnhancementStatus status) {
    switch (status) {
      case EnhancementStatus.open:
        return 'Open';
      case EnhancementStatus.inProgress:
        return 'In Progress';
      case EnhancementStatus.completed:
        return 'Completed';
      case EnhancementStatus.deferred:
        return 'Deferred';
      case EnhancementStatus.rejected:
        return 'Rejected';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }
}

// Suggestions For Features and Additions Later:
// - Add search functionality
// - Add bulk actions (mark multiple as completed)
// - Add export functionality
// - Add attachment support
// - Add comments/thread system
// - Add assignee field
// - Add due dates
// - Add time tracking
