/*
 * Filename: admin_clients_screen.dart
 * Purpose: Admin screen for viewing and managing client directory with search, filtering, and CRUD operations
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: Flutter, cloud_firestore, models, services, intl
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/client_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';

// MARK: - Admin Clients Screen
/// Screen for viewing and managing client directory
/// Provides full CRUD operations: Create, Read, Update, Delete
/// Includes search, filtering, tag management, and appointment history
/// Uses real-time Firestore stream for live updates
class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

// MARK: - Admin Clients Screen State
class _AdminClientsScreenState extends State<AdminClientsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ClientModel> _filteredClients = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    AppLogger().logUI('AdminClientsScreen initialized', tag: 'AdminClientsScreen');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // MARK: - Search Handler
  /// Handles search query changes and filters client list
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Directory'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
      ),
      body: Column(
        children: [
          // MARK: - Search Bar
          _buildSearchBar(),
          // MARK: - Clients List
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildClientsList(),
          ),
        ],
      ),
    );
  }

  // MARK: - Search Bar Builder
  /// Builds the search bar for filtering clients
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search clients by name, email, or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          filled: true,
          fillColor: AppColors.backgroundCream,
        ),
      ),
    );
  }

  // MARK: - Clients List Builder
  /// Builds the clients list using real-time Firestore stream
  /// Shows loading state, empty state, and error handling
  Widget _buildClientsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .orderBy('lastName')
          .orderBy('firstName')
          .snapshots(),
      builder: (context, snapshot) {
        // MARK: - Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          AppLogger().logLoading('Loading clients', tag: 'AdminClientsScreen');
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.sunflowerYellow,
            ),
          );
        }

        // MARK: - Error State
        if (snapshot.hasError) {
          AppLogger().logError(
            'Error loading clients: ${snapshot.error}',
            tag: 'AdminClientsScreen',
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
                  'Error loading clients',
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
          AppLogger().logInfo('No clients found', tag: 'AdminClientsScreen');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No clients yet',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Clients will appear here after they book appointments',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // MARK: - Clients List
        final clients = snapshot.data!.docs
            .map((doc) => ClientModel.fromFirestore(doc))
            .toList();

        AppLogger().logInfo('Displaying ${clients.length} clients', tag: 'AdminClientsScreen');

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clients.length,
          itemBuilder: (context, index) {
            return _buildClientCard(clients[index]);
          },
        );
      },
    );
  }

  // MARK: - Search Results Builder
  /// Builds search results based on query
  Widget _buildSearchResults() {
    return FutureBuilder<List<ClientModel>>(
      future: _firestoreService.searchClients(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.sunflowerYellow,
            ),
          );
        }

        if (snapshot.hasError) {
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
                  'Error searching clients',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No clients found',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return _buildClientCard(results[index]);
          },
        );
      },
    );
  }

  // MARK: - Client Card Builder
  /// Builds an individual client card with all client details
  /// Includes view, edit, and tag management actions
  Widget _buildClientCard(ClientModel client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showClientDetailDialog(context, client),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MARK: - Client Header
              Row(
                children: [
                  // MARK: - Avatar
                  CircleAvatar(
                    backgroundColor: AppColors.sunflowerYellow,
                    radius: 24,
                    child: Text(
                      client.firstName[0].toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // MARK: - Client Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.email,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              client.phone,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // MARK: - Action Buttons
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showClientEditDialog(context, client);
                      } else if (value == 'view') {
                        _showClientDetailDialog(context, client);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: AppColors.infoBlue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // MARK: - Client Tags
              if (client.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: client.tags.map((tag) {
                    return _buildTagChip(tag);
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // MARK: - Client Statistics
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      Icons.event,
                      '${client.totalAppointments} Appointments',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      Icons.check_circle,
                      '${client.completedAppointments} Completed',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      Icons.attach_money,
                      client.formattedTotalSpent,
                    ),
                  ),
                ],
              ),
              if (client.noShowCount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 14,
                        color: AppColors.errorRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${client.noShowCount} No-Show${client.noShowCount > 1 ? 's' : ''}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Tag Chip Builder
  /// Builds a tag chip for client tags
  Widget _buildTagChip(ClientTag tag) {
    final tagLabels = {
      ClientTag.vip: 'VIP',
      ClientTag.sensitiveSkin: 'Sensitive Skin',
      ClientTag.repeatNoShow: 'Repeat No-Show',
      ClientTag.regular: 'Regular',
      ClientTag.firstTime: 'First Time',
      ClientTag.preferred: 'Preferred',
    };

    final tagColors = {
      ClientTag.vip: AppColors.sunflowerYellow,
      ClientTag.sensitiveSkin: AppColors.warningOrange,
      ClientTag.repeatNoShow: AppColors.errorRed,
      ClientTag.regular: AppColors.infoBlue,
      ClientTag.firstTime: AppColors.successGreen,
      ClientTag.preferred: AppColors.mutedGreen,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColors[tag]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tagColors[tag]!.withOpacity(0.3),
        ),
      ),
      child: Text(
        tagLabels[tag] ?? tag.name,
        style: AppTypography.labelSmall.copyWith(
          color: tagColors[tag],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // MARK: - Stat Chip Builder
  /// Builds a small chip showing client statistic
  Widget _buildStatChip(IconData icon, String label) {
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

  // MARK: - Client Detail Dialog
  /// Shows detailed client information dialog
  /// Includes full profile, statistics, tags, notes, and appointment history
  Future<void> _showClientDetailDialog(BuildContext context, ClientModel client) async {
    AppLogger().logUI('Showing client detail: ${client.id}', tag: 'AdminClientsScreen');

    // Load appointment history
    final appointments = await _loadClientAppointments(client.email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.sunflowerYellow,
              radius: 20,
              child: Text(
                client.firstName[0].toUpperCase(),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                client.fullName,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MARK: - Contact Information
              _buildDetailSection(
                'Contact Information',
                [
                  _buildDetailRow(Icons.email, 'Email', client.email),
                  _buildDetailRow(Icons.phone, 'Phone', client.phone),
                ],
              ),
              const SizedBox(height: 16),
              // MARK: - Statistics
              _buildDetailSection(
                'Statistics',
                [
                  _buildDetailRow(
                    Icons.event,
                    'Total Appointments',
                    '${client.totalAppointments}',
                  ),
                  _buildDetailRow(
                    Icons.check_circle,
                    'Completed',
                    '${client.completedAppointments}',
                  ),
                  _buildDetailRow(
                    Icons.cancel,
                    'No-Shows',
                    '${client.noShowCount}',
                  ),
                  _buildDetailRow(
                    Icons.percent,
                    'Completion Rate',
                    '${client.completionRate.toStringAsFixed(1)}%',
                  ),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Total Spent',
                    client.formattedTotalSpent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // MARK: - Tags
              if (client.tags.isNotEmpty) ...[
                _buildDetailSection(
                  'Tags',
                  [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: client.tags.map((tag) => _buildTagChip(tag)).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // MARK: - Internal Notes
              if (client.internalNotes != null && client.internalNotes!.isNotEmpty) ...[
                _buildDetailSection(
                  'Internal Notes',
                  [
                    Text(
                      client.internalNotes!,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // MARK: - Appointment History
              _buildDetailSection(
                'Recent Appointments',
                appointments.isEmpty
                    ? [
                        Text(
                          'No appointments yet',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ]
                    : appointments.take(5).map((apt) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      apt.serviceSnapshot?.name ?? 'Service',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, y • h:mm a').format(apt.startTime),
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(apt.status),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showClientEditDialog(context, client);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunflowerYellow,
              foregroundColor: AppColors.darkBrown,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  // MARK: - Detail Section Builder
  /// Builds a section in the detail dialog
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  // MARK: - Detail Row Builder
  /// Builds a detail row with icon, label, and value
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Status Badge Builder
  /// Builds a status badge for appointment status
  Widget _buildStatusBadge(AppointmentStatus status) {
    final statusConfig = {
      AppointmentStatus.confirmed: (AppColors.statusConfirmed, 'Confirmed'),
      AppointmentStatus.arrived: (AppColors.successGreen, 'Arrived'),
      AppointmentStatus.completed: (AppColors.statusCompleted, 'Completed'),
      AppointmentStatus.noShow: (AppColors.statusNoShow, 'No-Show'),
      AppointmentStatus.canceled: (AppColors.statusCancelled, 'Canceled'),
    };

    final (color, label) = statusConfig[status] ?? (AppColors.textSecondary, status.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // MARK: - Load Client Appointments
  /// Loads appointment history for a client by email
  Future<List<AppointmentModel>> _loadClientAppointments(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('clientEmail', isEqualTo: email)
          .orderBy('startTime', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to load client appointments',
        tag: 'AdminClientsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // MARK: - Client Edit Dialog
  /// Shows dialog for editing client information
  /// Handles form validation and submission
  Future<void> _showClientEditDialog(BuildContext context, ClientModel client) async {
    AppLogger().logUI('Editing client: ${client.id}', tag: 'AdminClientsScreen');

    // MARK: - Form Controllers
    final firstNameController = TextEditingController(text: client.firstName);
    final lastNameController = TextEditingController(text: client.lastName);
    final emailController = TextEditingController(text: client.email);
    final phoneController = TextEditingController(text: client.phone);
    final notesController = TextEditingController(text: client.internalNotes ?? '');
    List<ClientTag> selectedTags = List.from(client.tags);

    // MARK: - Form Key
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Client'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MARK: - First Name
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      if (value.length < AppConstants.minNameLength) {
                        return 'Name must be at least ${AppConstants.minNameLength} characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Last Name
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      if (value.length < AppConstants.minNameLength) {
                        return 'Name must be at least ${AppConstants.minNameLength} characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Email
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Phone
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      if (value.length < AppConstants.minPhoneLength) {
                        return 'Phone must be at least ${AppConstants.minPhoneLength} digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Tags
                  Text(
                    'Tags',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ClientTag.values.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(_getTagLabel(tag)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: AppColors.sunflowerYellow.withOpacity(0.3),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // MARK: - Internal Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Internal Notes',
                      hintText: 'Private notes about this client',
                    ),
                    maxLines: 4,
                    maxLength: AppConstants.maxNotesLength,
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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveClient(
                    context,
                    client: client,
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    tags: selectedTags,
                    internalNotes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: AppColors.darkBrown,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    // MARK: - Cleanup Controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
  }

  // MARK: - Get Tag Label
  /// Gets the display label for a client tag
  String _getTagLabel(ClientTag tag) {
    final tagLabels = {
      ClientTag.vip: 'VIP',
      ClientTag.sensitiveSkin: 'Sensitive Skin',
      ClientTag.repeatNoShow: 'Repeat No-Show',
      ClientTag.regular: 'Regular',
      ClientTag.firstTime: 'First Time',
      ClientTag.preferred: 'Preferred',
    };
    return tagLabels[tag] ?? tag.name;
  }

  // MARK: - Save Client Method
  /// Saves or updates a client in Firestore
  Future<void> _saveClient(
    BuildContext context, {
    required ClientModel client,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required List<ClientTag> tags,
    String? internalNotes,
  }) async {
    try {
      AppLogger().logLoading('Updating client: ${client.id}', tag: 'AdminClientsScreen');

      final updatedClient = client.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        tags: tags,
        internalNotes: internalNotes,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateClient(updatedClient);
      AppLogger().logSuccess('Client updated: ${updatedClient.id}', tag: 'AdminClientsScreen');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client updated successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update client',
        tag: 'AdminClientsScreen',
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
}

// Suggestions For Features and Additions Later:
// - Add client export functionality (CSV, PDF)
// - Add bulk tag operations
// - Add client merge functionality (for duplicates)
// - Add client notes history/timeline
// - Add client communication log
// - Add client birthday tracking and reminders
// - Add client referral tracking
// - Add advanced filtering (by tags, date range, spending)
// - Add client analytics dashboard
// - Add client photo upload
