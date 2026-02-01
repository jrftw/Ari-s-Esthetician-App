/*
 * Filename: client_appointments_screen.dart
 * Purpose: Client view of their upcoming and past appointments
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter, go_router, firebase_auth, cloud_firestore
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/view_mode_service.dart';

// MARK: - Client Appointments Screen
/// Screen for clients to view their upcoming and past appointments
/// Displays appointments in two tabs: Upcoming and Past
class ClientAppointmentsScreen extends StatefulWidget {
  const ClientAppointmentsScreen({super.key});

  @override
  State<ClientAppointmentsScreen> createState() => _ClientAppointmentsScreenState();
}

// MARK: - Client Appointments Screen State
class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen> with SingleTickerProviderStateMixin {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ViewModeService _viewModeService = ViewModeService.instance;
  
  // MARK: - State Variables
  late TabController _tabController;
  String? _clientEmail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdminViewingAsClient = false;
  
  // MARK: - Lifecycle
  @override
  void initState() {
    super.initState();
    logUI('ClientAppointmentsScreen initState called', tag: 'ClientAppointmentsScreen');
    logWidgetLifecycle('ClientAppointmentsScreen', 'initState', tag: 'ClientAppointmentsScreen');
    
    // Set admin-viewing-as-client synchronously so "Return to Admin" shows on first frame
    // (avoids disappearing when router refreshes and widget is recreated)
    _isAdminViewingAsClient = _viewModeService.isViewingAsClient;
    
    _tabController = TabController(length: 2, vsync: this);
    _loadClientEmail();
    _checkAdminViewMode();
    _viewModeService.addListener(_onViewModeChanged);
  }
  
  @override
  void dispose() {
    _viewModeService.removeListener(_onViewModeChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  // MARK: - Admin View Mode (View as Client)
  /// Check if current user is admin viewing as client
  Future<void> _checkAdminViewMode() async {
    try {
      final isAdmin = await _authService.isAdmin();
      final isViewingAsClient = _viewModeService.isViewingAsClient;
      if (mounted) {
        setState(() {
          _isAdminViewingAsClient = isAdmin && isViewingAsClient;
        });
      }
    } catch (e, stackTrace) {
      logError('Failed to check admin view mode', tag: 'ClientAppointmentsScreen', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Handle view mode changes from ViewModeService
  void _onViewModeChanged() {
    if (mounted) _checkAdminViewMode();
  }
  
  // MARK: - Client Email Loading
  /// Load client email from current authenticated user
  Future<void> _loadClientEmail() async {
    try {
      logLoading('Loading client email...', tag: 'ClientAppointmentsScreen');
      final user = _authService.currentUser;
      
      if (user == null) {
        logError('No authenticated user found', tag: 'ClientAppointmentsScreen');
        if (mounted) {
          setState(() {
            _errorMessage = 'Please log in to view your appointments';
            _isLoading = false;
          });
        }
        return;
      }
      
      setState(() {
        _clientEmail = user.email;
        _isLoading = false;
      });
      
      logSuccess('Client email loaded: ${_clientEmail ?? "null"}', tag: 'ClientAppointmentsScreen');
    } catch (e, stackTrace) {
      logError('Failed to load client email', tag: 'ClientAppointmentsScreen', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load appointments. Please try again.';
          _isLoading = false;
        });
      }
    }
  }
  
  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building ClientAppointmentsScreen widget', tag: 'ClientAppointmentsScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            logInfo('Back button tapped', tag: 'ClientAppointmentsScreen');
            context.pop();
          },
        ),
        actions: [
          // Back to Admin - always visible when admin is viewing as client
          if (_isAdminViewingAsClient)
            TextButton.icon(
              onPressed: () {
                logInfo('Admin switching back to admin view (AppBar)', tag: 'ClientAppointmentsScreen');
                _viewModeService.switchToAdminView();
                context.go(AppConstants.routeAdminDashboard);
              },
              icon: const Icon(Icons.admin_panel_settings, size: 20),
              label: const Text('Back to Admin'),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              logInfo('Add appointment button tapped', tag: 'ClientAppointmentsScreen');
              context.push(AppConstants.routeClientBooking);
            },
            tooltip: 'Book New Appointment',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isAdminViewingAsClient) _buildAdminViewBanner(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
  
  // MARK: - Admin View Banner
  /// Build banner showing admin is viewing as client with option to go back to admin panel
  Widget _buildAdminViewBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sunflowerYellow.withOpacity(0.2),
        border: Border(
          bottom: BorderSide(
            color: AppColors.sunflowerYellow,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: context.themePrimaryTextColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Viewing as Client',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              logInfo('Admin switching back to admin view', tag: 'ClientAppointmentsScreen');
              _viewModeService.switchToAdminView();
              context.go(AppConstants.routeAdminDashboard);
            },
            child: Text(
              'Go back to admin panel',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // MARK: - Body Builder
  /// Build main body content
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                _errorMessage!,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.errorRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _loadClientEmail();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunflowerYellow,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_clientEmail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: context.themeSecondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your appointments',
                style: AppTypography.titleMedium.copyWith(
                  color: context.themeSecondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUpcomingAppointments(),
        _buildPastAppointments(),
      ],
    );
  }
  
  // MARK: - Upcoming Appointments Builder
  /// Build upcoming appointments tab
  Widget _buildUpcomingAppointments() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _firestoreService.getAppointmentsByClientEmailStream(_clientEmail!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logError('Error loading appointments: ${snapshot.error}', tag: 'ClientAppointmentsScreen');
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
                  'Failed to load appointments',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final allAppointments = snapshot.data ?? [];
        final now = DateTime.now();
        final upcomingAppointments = allAppointments.where((apt) {
          return apt.startTime.isAfter(now) && 
                 apt.status != AppointmentStatus.canceled &&
                 apt.status != AppointmentStatus.completed &&
                 apt.status != AppointmentStatus.noShow;
        }).toList();
        
        if (upcomingAppointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: context.themeSecondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Upcoming Appointments',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your first appointment to get started',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      logInfo('Book appointment button tapped from empty state', tag: 'ClientAppointmentsScreen');
                      context.push(AppConstants.routeClientBooking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunflowerYellow,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingAppointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(upcomingAppointments[index]);
          },
        );
      },
    );
  }
  
  // MARK: - Past Appointments Builder
  /// Build past appointments tab
  Widget _buildPastAppointments() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _firestoreService.getAppointmentsByClientEmailStream(_clientEmail!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          logError('Error loading appointments: ${snapshot.error}', tag: 'ClientAppointmentsScreen');
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
                  'Failed to load appointments',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final allAppointments = snapshot.data ?? [];
        final now = DateTime.now();
        final pastAppointments = allAppointments.where((apt) {
          return apt.endTime.isBefore(now) || 
                 apt.status == AppointmentStatus.completed ||
                 apt.status == AppointmentStatus.canceled ||
                 apt.status == AppointmentStatus.noShow;
        }).toList();
        
        if (pastAppointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 64,
                    color: context.themeSecondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Past Appointments',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed appointments will appear here',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pastAppointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(pastAppointments[index]);
          },
        );
      },
    );
  }
  
  // MARK: - Appointment Card Builder
  /// Build appointment card widget
  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final serviceName = appointment.serviceSnapshot?.name ?? 'Service';
    final isUpcoming = appointment.isUpcoming && 
                       appointment.status != AppointmentStatus.canceled &&
                       appointment.status != AppointmentStatus.completed &&
                       appointment.status != AppointmentStatus.noShow;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          logInfo('Appointment card tapped: ${appointment.id}', tag: 'ClientAppointmentsScreen');
          _showAppointmentDetails(appointment);
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(appointment.status),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Date
                  Text(
                    _formatDate(appointment.startTime),
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Service Name
              Text(
                serviceName,
                style: AppTypography.titleMedium.copyWith(
                  color: context.themePrimaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Time and Duration
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: context.themeSecondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: context.themeSecondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${appointment.serviceSnapshot?.durationMinutes ?? 0} min',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                ],
              ),
              if (appointment.intakeNotes != null && appointment.intakeNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${appointment.intakeNotes}',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.themeSecondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  // MARK: - Appointment Details Dialog
  /// Show appointment details in a dialog
  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appointment.serviceSnapshot?.name ?? 'Appointment Details',
          style: AppTypography.titleLarge.copyWith(
            color: context.themePrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', _formatDate(appointment.startTime)),
              _buildDetailRow('Time', '${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}'),
              _buildDetailRow('Duration', '${appointment.serviceSnapshot?.durationMinutes ?? 0} minutes'),
              _buildDetailRow('Status', _formatStatus(appointment.status)),
              _buildDetailRow('Deposit', appointment.formattedDeposit),
              if (appointment.intakeNotes != null && appointment.intakeNotes!.isNotEmpty)
                _buildDetailRow('Notes', appointment.intakeNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themePrimaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build detail row for appointment details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themeSecondaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: context.themePrimaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // MARK: - Helper Methods
  /// Get status color based on appointment status
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.infoBlue;
      case AppointmentStatus.arrived:
        return AppColors.sunflowerYellow;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.canceled:
        return AppColors.errorRed;
      case AppointmentStatus.noShow:
        return Colors.orange;
    }
  }
  
  /// Format appointment status for display
  String _formatStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.arrived:
        return 'Arrived';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.canceled:
        return 'Canceled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
  
  /// Format date for display (e.g., "Jan 22, 2026")
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  /// Format time for display (e.g., "9:00 AM")
  String _formatTime(DateTime dateTime) {
    final hour12 = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }
}

// Suggestions For Features and Additions Later:
// - Add appointment cancellation functionality
// - Add appointment rescheduling
// - Add appointment reminders
// - Add calendar export functionality
// - Add appointment rating/review system
// - Add filter and search functionality
// - Add appointment history export
