/*
 * Filename: admin_appointments_screen.dart
 * Purpose: Comprehensive admin screen for viewing, managing, and creating appointments
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: Flutter, table_calendar, cloud_firestore, intl
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// Web-specific imports (conditional for PDF preview/download/print on web)
import 'dart:html'
    if (dart.library.io) 'html_stub.dart' as html;
import '../../core/constants/terms_and_conditions.dart';
import '../../core/constants/app_version.dart';
import '../../models/appointment_model.dart';
import '../../models/service_model.dart';
import '../../models/client_model.dart';
import '../../services/firestore_service.dart';

// MARK: - View Mode Enum
/// Different view modes for displaying appointments
enum AppointmentViewMode {
  list,
  calendar,
}

// MARK: - Admin Appointments Screen
/// Comprehensive screen for managing all appointments
/// Features: List view, calendar view, filtering, search, status updates, manual creation
class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() => _AdminAppointmentsScreenState();
}

// MARK: - Admin Appointments Screen State
class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();

  // MARK: - State Variables
  AppointmentViewMode _viewMode = AppointmentViewMode.list;
  List<AppointmentModel> _allAppointments = [];
  List<AppointmentModel> _filteredAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  AppointmentStatus? _statusFilter;
  DateTime _selectedCalendarDate = DateTime.now();
  DateTime _focusedCalendarDate = DateTime.now();
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  // MARK: - Calendar State
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  final DateTime _firstDay = DateTime.now().subtract(const Duration(days: 365));
  final DateTime _lastDay = DateTime.now().add(const Duration(days: 365));

  // MARK: - Selected Appointment
  AppointmentModel? _selectedAppointment;

  /// Appointments stream subscription; cancelled in dispose to prevent leak and limit Firestore reads.
  StreamSubscription<List<AppointmentModel>>? _appointmentsSubscription;

  @override
  void initState() {
    super.initState();
    logUI('AdminAppointmentsScreen initState called', tag: 'AdminAppointmentsScreen');
    logWidgetLifecycle('AdminAppointmentsScreen', 'initState', tag: 'AdminAppointmentsScreen');
    _loadAppointments();
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    _appointmentsSubscription = null;
    super.dispose();
  }

  // MARK: - Data Loading
  /// Load appointments from Firestore with real-time updates (date-bounded to reduce reads).
  void _loadAppointments() {
    logLoading('Loading appointments...', tag: 'AdminAppointmentsScreen');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stream = _firestoreService.getAppointmentsStream(
        startDate: _firstDay,
        endDate: _lastDay,
      );
      _appointmentsSubscription = stream.listen(
        (appointments) {
          logSuccess('Loaded ${appointments.length} appointments', tag: 'AdminAppointmentsScreen');
          if (mounted) {
            setState(() {
              _allAppointments = appointments;
              _applyFilters();
              _isLoading = false;
            });
          }
        },
        onError: (error, stackTrace) {
          logError(
            'Failed to load appointments',
            tag: 'AdminAppointmentsScreen',
            error: error,
            stackTrace: stackTrace,
          );
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load appointments. Please try again.';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Error setting up appointments stream',
        tag: 'AdminAppointmentsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _errorMessage = 'Failed to load appointments. Please try again.';
        _isLoading = false;
      });
    }
  }

  // MARK: - Filtering
  /// Apply all active filters to appointments
  void _applyFilters() {
    List<AppointmentModel> filtered = List.from(_allAppointments);

    // Status filter
    if (_statusFilter != null) {
      filtered = filtered.where((apt) => apt.status == _statusFilter).toList();
    }

    // Date range filter
    if (_startDateFilter != null) {
      filtered = filtered.where((apt) => apt.startTime.isAfter(_startDateFilter!.subtract(const Duration(days: 1)))).toList();
    }
    if (_endDateFilter != null) {
      filtered = filtered.where((apt) => apt.startTime.isBefore(_endDateFilter!.add(const Duration(days: 1)))).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((apt) {
        return apt.clientFirstName.toLowerCase().contains(query) ||
            apt.clientLastName.toLowerCase().contains(query) ||
            apt.clientEmail.toLowerCase().contains(query) ||
            apt.clientPhone.contains(query) ||
            (apt.serviceSnapshot?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredAppointments = filtered;
    });
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
    });
    _applyFilters();
  }

  // MARK: - Status Updates
  /// Update appointment status
  Future<void> _updateAppointmentStatus(AppointmentModel appointment, AppointmentStatus newStatus) async {
    try {
      logLoading('Updating appointment status to ${newStatus.name}...', tag: 'AdminAppointmentsScreen');
      
      final updatedAppointment = appointment.copyWith(status: newStatus);
      await _firestoreService.updateAppointment(updatedAppointment);

      logSuccess('Appointment status updated', tag: 'AdminAppointmentsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to update appointment status',
        tag: 'AdminAppointmentsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // MARK: - Delete Appointment
  /// Delete an appointment
  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete the appointment for ${appointment.clientFullName} on ${_formatDateTime(appointment.startTime)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      logLoading('Deleting appointment...', tag: 'AdminAppointmentsScreen');
      await _firestoreService.deleteAppointment(appointment.id);
      logSuccess('Appointment deleted', tag: 'AdminAppointmentsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment deleted successfully'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to delete appointment',
        tag: 'AdminAppointmentsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete appointment: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building AdminAppointmentsScreen widget', tag: 'AdminAppointmentsScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        elevation: 0,
        actions: [
          // View Mode Toggle
          IconButton(
            icon: Icon(_viewMode == AppointmentViewMode.list ? Icons.calendar_today : Icons.list),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == AppointmentViewMode.list
                    ? AppointmentViewMode.calendar
                    : AppointmentViewMode.list;
              });
            },
            tooltip: _viewMode == AppointmentViewMode.list ? 'Switch to Calendar View' : 'Switch to List View',
          ),
          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Appointments',
          ),
          // Add Appointment Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateAppointmentDialog,
            tooltip: 'Create New Appointment',
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              logInfo('Settings button tapped', tag: 'AdminAppointmentsScreen');
              context.push(AppConstants.routeSettings);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filter Chips
          if (_hasActiveFilters()) _buildFilterChips(),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _viewMode == AppointmentViewMode.list
                        ? _buildListView()
                        : _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  // MARK: - Search Bar
  /// Build search bar widget
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, email, or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  // MARK: - Filter Chips
  /// Check if any filters are active
  bool _hasActiveFilters() {
    return _statusFilter != null || _startDateFilter != null || _endDateFilter != null;
  }

  /// Build filter chips showing active filters
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.softCream,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_statusFilter != null)
            Chip(
              label: Text('Status: ${_formatStatus(_statusFilter!)}'),
              onDeleted: () {
                setState(() {
                  _statusFilter = null;
                });
                _applyFilters();
              },
              backgroundColor: _getStatusColor(_statusFilter!),
            ),
          if (_startDateFilter != null)
            Chip(
              label: Text('From: ${_formatDate(_startDateFilter!)}'),
              onDeleted: () {
                setState(() {
                  _startDateFilter = null;
                });
                _applyFilters();
              },
            ),
          if (_endDateFilter != null)
            Chip(
              label: Text('To: ${_formatDate(_endDateFilter!)}'),
              onDeleted: () {
                setState(() {
                  _endDateFilter = null;
                });
                _applyFilters();
              },
            ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // MARK: - Error View
  /// Build error view widget
  Widget _buildErrorView() {
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
            _errorMessage ?? 'An error occurred',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.errorRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAppointments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunflowerYellow,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // MARK: - List View
  /// Build list view of appointments
  Widget _buildListView() {
    if (_filteredAppointments.isEmpty) {
      return Center(
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
              'No appointments found',
              style: AppTypography.titleMedium.copyWith(
                color: context.themeSecondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your filters'
                  : 'Create a new appointment to get started',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themeSecondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _filteredAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  // MARK: - Calendar View
  /// Build calendar view of appointments
  Widget _buildCalendarView() {
    return Column(
      children: [
        // Calendar Widget
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar<AppointmentModel>(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedCalendarDate,
            selectedDayPredicate: (day) {
              return _isSameDay(_selectedCalendarDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedCalendarDate = selectedDay;
                _focusedCalendarDate = focusedDay;
              });
            },
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            eventLoader: (day) {
              return _filteredAppointments.where((apt) {
                return _isSameDay(apt.startTime, day);
              }).toList();
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.sunflowerYellow,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.sunflowerYellow.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.infoBlue,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTypography.titleMedium.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Appointments for Selected Date
        Expanded(
          child: _buildSelectedDateAppointments(),
        ),
      ],
    );
  }

  /// Build appointments list for selected calendar date
  Widget _buildSelectedDateAppointments() {
    final selectedDateAppointments = _filteredAppointments.where((apt) {
      return _isSameDay(apt.startTime, _selectedCalendarDate);
    }).toList();

    if (selectedDateAppointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments on ${_formatDate(_selectedCalendarDate)}',
          style: AppTypography.bodyMedium.copyWith(
            color: context.themeSecondaryTextColor,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: selectedDateAppointments.length,
      itemBuilder: (context, index) {
        final appointment = selectedDateAppointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  // MARK: - Appointment Card
  /// Build appointment card widget
  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
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
                  // Time
                  Text(
                    _formatTime(appointment.startTime),
                    style: AppTypography.titleMedium.copyWith(
                      color: context.themePrimaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Client Name
              Text(
                appointment.clientFullName,
                style: AppTypography.titleMedium.copyWith(
                  color: context.themePrimaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Service Name
              if (appointment.serviceSnapshot != null)
                Text(
                  appointment.serviceSnapshot!.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.themeSecondaryTextColor,
                  ),
                ),
              const SizedBox(height: 8),
              // Contact Info
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: context.themeSecondaryTextColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.clientEmail,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.themeSecondaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: context.themeSecondaryTextColor),
                  const SizedBox(width: 4),
                  Text(
                    appointment.clientPhone,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Buttons: Wrap so they don't overflow on narrow screens and remain tappable
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (appointment.status != AppointmentStatus.completed &&
                      appointment.status != AppointmentStatus.canceled)
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Update Status'),
                      onPressed: () => _showStatusUpdateDialog(appointment),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.errorRed,
                    onPressed: () => _deleteAppointment(appointment),
                    tooltip: 'Delete Appointment',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Dialogs
  /// Show filter dialog
  Future<void> _showFilterDialog() async {
    AppointmentStatus? tempStatusFilter = _statusFilter;
    DateTime? tempStartDate = _startDateFilter;
    DateTime? tempEndDate = _endDateFilter;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Appointments'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter
                Text(
                  'Status',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppointmentStatus.values.map((status) {
                    final isSelected = tempStatusFilter == status;
                    return FilterChip(
                      label: Text(_formatStatus(status)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          tempStatusFilter = selected ? status : null;
                        });
                      },
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      selectedColor: _getStatusColor(status),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Date Range Filter
                Text(
                  'Date Range',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              tempStartDate = date;
                            });
                          }
                        },
                        child: Text(
                          tempStartDate != null
                              ? _formatDate(tempStartDate!)
                              : 'Start Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              tempEndDate = date;
                            });
                          }
                        },
                        child: Text(
                          tempEndDate != null
                              ? _formatDate(tempEndDate!)
                              : 'End Date',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  tempStatusFilter = null;
                  tempStartDate = null;
                  tempEndDate = null;
                });
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _statusFilter = tempStatusFilter;
                  _startDateFilter = tempStartDate;
                  _endDateFilter = tempEndDate;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show status update dialog
  Future<void> _showStatusUpdateDialog(AppointmentModel appointment) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppointmentStatus.values.map((status) {
            return ListTile(
              title: Text(_formatStatus(status)),
              leading: Radio<AppointmentStatus>(
                value: status,
                groupValue: appointment.status,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(context).pop();
                    _updateAppointmentStatus(appointment, value);
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show appointment details dialog.
  /// Uses [screenContext] (captured before dialog) for post-pop actions so PDF/status dialogs work after closing.
  Future<void> _showAppointmentDetails(AppointmentModel appointment) async {
    final screenContext = context;
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Appointment Details',
                        style: AppTypography.titleLarge.copyWith(
                          color: dialogContext.themePrimaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                // Client Information
                _buildDetailRow('Client', appointment.clientFullName),
                _buildDetailRow('Email', appointment.clientEmail),
                _buildDetailRow('Phone', appointment.clientPhone),
                const SizedBox(height: 16),
                // Appointment Information
                _buildDetailRow('Date', _formatDate(appointment.startTime)),
                _buildDetailRow('Time', _formatTime(appointment.startTime)),
                _buildDetailRow('Duration', '${appointment.serviceSnapshot?.durationMinutes ?? 0} minutes'),
                _buildDetailRow('Status', _formatStatus(appointment.status)),
                if (appointment.serviceSnapshot != null)
                  _buildDetailRow('Service', appointment.serviceSnapshot!.name),
                const SizedBox(height: 16),
                // Payment Information
                _buildDetailRow('Deposit', appointment.formattedDeposit),
                if (appointment.stripePaymentIntentId != null)
                  _buildDetailRow('Payment ID', appointment.stripePaymentIntentId!),
                const SizedBox(height: 16),
                // Notes
                if (appointment.intakeNotes != null && appointment.intakeNotes!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Notes',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appointment.intakeNotes!,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (appointment.adminNotes != null && appointment.adminNotes!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Notes',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appointment.adminNotes!,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                // Compliance sections: only show when appointment has compliance data (backwards compatible)
                if (_appointmentHasComplianceData(appointment)) ...[
                  _buildDetailSectionTitle('Health & Skin Disclosure'),
                  const SizedBox(height: 6),
                  _buildAppointmentDisclosureContent(appointment),
                  const SizedBox(height: 16),
                  _buildDetailSectionTitle('Required Acknowledgements'),
                  const SizedBox(height: 6),
                  _buildAppointmentAcknowledgementsContent(appointment),
                  const SizedBox(height: 16),
                  _buildDetailSectionTitle('Cancellation / No-Show Policy'),
                  const SizedBox(height: 6),
                  _buildAppointmentCancellationContent(appointment),
                  const SizedBox(height: 16),
                  _buildDetailSectionTitle('Terms & Conditions'),
                  const SizedBox(height: 6),
                  _buildAppointmentTermsContent(appointment),
                  const SizedBox(height: 12),
                ],
                _buildDetailRow('Created', _formatDateTime(appointment.createdAt)),
                _buildDetailRow('Updated', _formatDateTime(appointment.updatedAt)),
                const SizedBox(height: 24),
                // Actions: Wrap so buttons don't overflow on narrow screens and remain tappable
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        if (mounted) _showPDFFormatChoice(screenContext, appointment);
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('Preview / Print PDF'),
                    ),
                    if (appointment.status != AppointmentStatus.completed &&
                        appointment.status != AppointmentStatus.canceled)
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          if (mounted) _showStatusUpdateDialog(appointment);
                        },
                        child: const Text('Update Status'),
                      ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sunflowerYellow,
                        foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Generate PDF for a single appointment (client, details, disclosures, acknowledgements, policy).
  /// [includeSignatureForm] adds a second page with printed name, signature line, and date for wet signature.
  /// Uses app theme: sunflower yellow, dark brown, soft cream. Null-safe for legacy appointments.
  Future<void> _generateAppointmentPDF(BuildContext context, AppointmentModel appointment, {bool includeSignatureForm = false}) async {
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
      AppLogger().logLoading('Generating appointment PDF', tag: 'AdminAppointmentsScreen');
      final pdf = pw.Document();
      // App theme colors (app_colors.dart: sunflower, dark brown, soft cream)
      final sunflowerYellow = PdfColor.fromHex('#FFD700');
      final darkBrown = PdfColor.fromHex('#5D4037');
      final softCream = PdfColor.fromHex('#FFF8E1');
      final textPrimary = PdfColor.fromHex('#5D4037');
      final textSecondary = PdfColor.fromHex('#8D6E63');

      String na(String? v) => (v == null || v.isEmpty) ? '—' : v;
      String fmt(DateTime? d) => d == null ? '—' : DateFormat.yMd().add_Hm().format(d);

      pw.Widget wrapSection(String title, List<pw.Widget> children) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: softCream,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: sunflowerYellow, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
                ),
                child: pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkBrown),
                ),
              ),
              pw.SizedBox(height: 8),
              ...children,
            ],
          ),
        );
      }

      pw.Widget row(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 110,
                child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textSecondary)),
              ),
              pw.Expanded(
                child: pw.Text(value, style: pw.TextStyle(fontSize: 11, color: textPrimary)),
              ),
            ],
          ),
        );
      }

      // Footer for all PDF pages: "Generated by Ari" + date/time + app version
      final pdfGeneratedAtStr = DateFormat.yMd().add_Hm().format(DateTime.now());
      pw.Widget pdfFooter(pw.Context ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Generated by Ari • $pdfGeneratedAtStr • App version: ${AppVersion.versionString}',
          style: pw.TextStyle(fontSize: 8, color: textSecondary),
        ),
      );

      final content = [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: pw.BoxDecoration(
            color: sunflowerYellow,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Appointment Record',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: darkBrown),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated ${DateFormat.yMd().format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: textSecondary),
                  ),
                ],
              ),
              pw.Container(
                width: 48,
                height: 48,
                decoration: pw.BoxDecoration(color: darkBrown, shape: pw.BoxShape.circle),
                child: pw.Center(
                  child: pw.Text('A', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),
        wrapSection('Client information', [
          row('Name', '${appointment.clientFirstName} ${appointment.clientLastName}'),
          row('Email', appointment.clientEmail),
          row('Phone', appointment.clientPhone),
        ]),
        wrapSection('Appointment details', [
          row('Date & time', fmt(appointment.startTime)),
          row('Duration', '${appointment.serviceSnapshot?.durationMinutes ?? 0} minutes'),
          row('Service', appointment.serviceSnapshot?.name ?? na(appointment.serviceId)),
          row('Status', appointment.status.name),
          row('Deposit', appointment.formattedDeposit),
          if (appointment.intakeNotes != null && appointment.intakeNotes!.isNotEmpty)
            row('Client notes', appointment.intakeNotes!),
        ]),
        // Standard PDF: only include compliance sections when appointment has that data (backwards compatible)
        if (_appointmentHasComplianceData(appointment)) ...[
          wrapSection('Health & Skin Disclosure', [
            if (appointment.healthDisclosureDetails != null && appointment.healthDisclosureDetails!.isNotEmpty)
              ...appointment.healthDisclosureDetails!.entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• ${e.key}: ${e.value}', style: pw.TextStyle(fontSize: 11, color: textPrimary)),
              ))
            else if (appointment.healthDisclosure != null)
              pw.Text(
                'Skin conditions: ${appointment.healthDisclosure!.hasSkinConditions}; Allergies: ${appointment.healthDisclosure!.hasAllergies}; Medications: ${appointment.healthDisclosure!.hasCurrentMedications}; Pregnant/breastfeeding: ${appointment.healthDisclosure!.isPregnantOrBreastfeeding}; Recent treatments: ${appointment.healthDisclosure!.hasRecentCosmeticTreatments}; Known reactions: ${appointment.healthDisclosure!.hasKnownReactions}. Notes: ${na(appointment.healthDisclosure!.additionalNotes)}',
                style: pw.TextStyle(fontSize: 11, color: textPrimary),
              )
            else
              pw.Text('—', style: pw.TextStyle(fontSize: 11, color: textSecondary)),
          ]),
          wrapSection('Required Acknowledgements', [
            if (appointment.requiredAcknowledgments != null)
              pw.Text(
                'All acknowledged: ${appointment.requiredAcknowledgments!.allAcknowledged}. Accepted at: ${fmt(appointment.requiredAcknowledgmentsAcceptedAt)}',
                style: pw.TextStyle(fontSize: 11, color: textPrimary),
              )
            else
              pw.Text('—', style: pw.TextStyle(fontSize: 11, color: textSecondary)),
          ]),
          wrapSection('Cancellation / No-Show Policy', [
            if (appointment.cancellationPolicySnapshot != null)
              pw.Text(
                'Acknowledged: ${appointment.cancellationPolicySnapshot!.acknowledged}. At: ${fmt(appointment.cancellationPolicySnapshot!.acknowledgedAt)}. Version: ${na(appointment.cancellationPolicySnapshot!.policyVersion)}',
                style: pw.TextStyle(fontSize: 11, color: textPrimary),
              )
            else
              pw.Text('Acknowledged: ${appointment.cancellationPolicyAcknowledged} (legacy)', style: pw.TextStyle(fontSize: 11, color: textPrimary)),
          ]),
          wrapSection('Terms & Conditions', [
            if (appointment.termsAcceptanceMetadata != null)
              pw.Text(
                'Accepted: ${appointment.termsAcceptanceMetadata!.termsAccepted}. At (UTC): ${fmt(appointment.termsAcceptanceMetadata!.termsAcceptedAtUtc)}',
                style: pw.TextStyle(fontSize: 11, color: textPrimary),
              )
            else
              pw.Text('—', style: pw.TextStyle(fontSize: 11, color: textSecondary)),
          ]),
        ],
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(
            'Record created: ${fmt(appointment.createdAt)}  •  Last updated: ${fmt(appointment.updatedAt)}',
            style: pw.TextStyle(fontSize: 9, color: textSecondary),
          ),
        ),
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          footer: pdfFooter,
          build: (pw.Context ctx) => content,
        ),
      );

      if (includeSignatureForm) {
        // PDF with signature form: appointment record (page 1) + full Terms & Conditions for in-person reading + signature page.
        // Add full agreements/terms so the client can read in person before signing.
        final termsFullText = TermsAndConditions.fullText;
        final termsParagraphs = termsFullText.split(RegExp(r'\n\n+'));
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36),
            footer: pdfFooter,
            build: (pw.Context ctx) {
              return [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: sunflowerYellow,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Terms & Conditions — Please read before signing',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkBrown),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'The following terms and conditions apply to esthetician services. By signing the signature page, the client confirms they have read and agree to these terms.',
                  style: pw.TextStyle(fontSize: 10, color: textSecondary),
                ),
                pw.SizedBox(height: 16),
                ...termsParagraphs.map((p) {
                  final trimmed = p.trim();
                  if (trimmed.isEmpty) return pw.SizedBox(height: 8);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Text(
                      trimmed,
                      style: pw.TextStyle(fontSize: 10, color: textPrimary, lineSpacing: 1.2),
                    ),
                  );
                }),
              ];
            },
          ),
        );

        pw.Widget blankLine() => pw.Container(
          width: double.infinity,
          height: 20,
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400))),
        );
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36),
            footer: pdfFooter,
            build: (pw.Context ctx) {
              return [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: sunflowerYellow,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'Client signature (wet signature) — Complete in person',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: darkBrown),
                  ),
                ),
                pw.SizedBox(height: 16),
                wrapSection('Appointment & client (from booking)', [
                  row('Client', '${appointment.clientFirstName} ${appointment.clientLastName}'),
                  row('Email / phone', '${appointment.clientEmail}  •  ${appointment.clientPhone}'),
                  row('Date & time', fmt(appointment.startTime)),
                  row('Service', appointment.serviceSnapshot?.name ?? na(appointment.serviceId)),
                  row('Duration', '${appointment.serviceSnapshot?.durationMinutes ?? 0} minutes'),
                ]),
                wrapSection('Health & Skin Disclosure', [blankLine()]),
                wrapSection('Required Acknowledgements', [blankLine()]),
                wrapSection('Terms & Conditions', [blankLine()]),
                wrapSection('Cancellation & No-Show Policy', [blankLine()]),
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 16, bottom: 16),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: softCream,
                    border: pw.Border.all(color: darkBrown, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'By signing below, I confirm the accuracy of the information above and my agreement to the Terms & Conditions, Health & Skin Disclosure, Required Acknowledgements, and Cancellation/No-Show Policy.',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkBrown),
                  ),
                ),
                pw.Text('Printed name:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkBrown)),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  height: 22,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Signature:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkBrown)),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  height: 56,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Date:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkBrown)),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: 160,
                  height: 22,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Print and have the client sign in person. Retain for your records.',
                  style: pw.TextStyle(fontSize: 9, color: textSecondary),
                ),
              ];
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      // MARK: - Platform-specific PDF preview/print (web: blob URL options; mobile: printing package)
      if (kIsWeb) {
        await _handleAppointmentWebPDF(context, pdfBytes, appointment);
      } else {
        await _handleAppointmentMobilePDF(context, pdfBytes);
      }
      AppLogger().logSuccess('Appointment PDF shown', tag: 'AdminAppointmentsScreen');
    } catch (e, stackTrace) {
      AppLogger().logError('Failed to generate appointment PDF', tag: 'AdminAppointmentsScreen', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  // MARK: - Web PDF Handler (Appointments)
  /// Handles PDF preview, download, and print for web platform.
  /// Shows dialog with Preview / Download / Print so Standard PDF and PDF with signature form both work on web.
  Future<void> _handleAppointmentWebPDF(BuildContext context, Uint8List pdfBytes, AppointmentModel appointment) async {
    if (!kIsWeb) return;
    try {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Preview / Print PDF'),
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

      final dateStr = DateFormat('yyyy-MM-dd').format(appointment.startTime);
      final safeName = appointment.clientLastName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final filename = 'appointment_${safeName.isEmpty ? "record" : safeName}_$dateStr.pdf';

      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..download = filename;

      switch (action) {
        case 'preview':
          anchor.target = '_blank';
          anchor.download = null;
          anchor.click();
          html.Url.revokeObjectUrl(url);
          AppLogger().logSuccess('Appointment PDF preview opened in browser', tag: 'AdminAppointmentsScreen');
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
          anchor.click();
          html.Url.revokeObjectUrl(url);
          AppLogger().logSuccess('Appointment PDF download started', tag: 'AdminAppointmentsScreen');
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
          final iframe = html.IFrameElement()
            ..src = url
            ..style?.display = 'none';
          html.document.body?.append(iframe);
          iframe.onLoad.listen((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              html.window.print();
              iframe.remove();
              html.Url.revokeObjectUrl(url);
            });
          });
          AppLogger().logSuccess('Appointment PDF print dialog opened', tag: 'AdminAppointmentsScreen');
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
      AppLogger().logError('Failed to handle web appointment PDF', tag: 'AdminAppointmentsScreen', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  // MARK: - Mobile PDF Handler (Appointments)
  /// Handles PDF preview and sharing for mobile (iOS/Android). Uses printing package; fallback to sharePdf.
  Future<void> _handleAppointmentMobilePDF(BuildContext context, Uint8List pdfBytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        format: PdfPageFormat.a4,
      );
      AppLogger().logSuccess('Appointment PDF preview shown on mobile', tag: 'AdminAppointmentsScreen');
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
      AppLogger().logError('Failed to handle mobile appointment PDF', tag: 'AdminAppointmentsScreen', error: e, stackTrace: stackTrace);
      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'appointment_$dateStr.pdf',
        );
        AppLogger().logSuccess('Appointment PDF shared (fallback)', tag: 'AdminAppointmentsScreen');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF shared successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (shareError) {
        AppLogger().logError('Both appointment PDF methods failed', tag: 'AdminAppointmentsScreen', error: shareError);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  /// Show create appointment dialog
  Future<void> _showCreateAppointmentDialog() async {
    logUI('Showing create appointment dialog', tag: 'AdminAppointmentsScreen');
    
    // Load services and clients for selection
    List<ServiceModel> services = [];
    List<ClientModel> clients = [];
    bool isLoadingData = true;
    
    try {
      services = await _firestoreService.getActiveServices();
      clients = await _firestoreService.getAllClients();
      isLoadingData = false;
    } catch (e, stackTrace) {
      logError(
        'Failed to load services/clients for appointment creation',
        tag: 'AdminAppointmentsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Form controllers
    final formKey = GlobalKey<FormState>();
    ServiceModel? selectedService;
    ClientModel? selectedClient;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final clientFirstNameController = TextEditingController();
    final clientLastNameController = TextEditingController();
    final clientEmailController = TextEditingController();
    final clientPhoneController = TextEditingController();
    final intakeNotesController = TextEditingController();
    final adminNotesController = TextEditingController();
    final depositAmountController = TextEditingController(text: '0');
    AppointmentStatus selectedStatus = AppointmentStatus.confirmed;
    bool useExistingClient = false;
    bool isCreating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sunflowerYellow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.defaultBorderRadius),
                        topRight: Radius.circular(AppConstants.defaultBorderRadius),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Create New Appointment',
                            style: AppTypography.titleLarge.copyWith(
                              color: context.themePrimaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: isCreating ? null : () => Navigator.of(context).pop(),
                          color: context.themePrimaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  
                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Service Selection
                                Text(
                                  'Service *',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<ServiceModel>(
                                  value: selectedService,
                                  decoration: InputDecoration(
                                    hintText: 'Select a service',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  items: services.map((service) {
                                    return DropdownMenuItem<ServiceModel>(
                                      value: service,
                                      child: Text('${service.name} (${service.formattedPrice})'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedService = value;
                                      // Auto-fill deposit amount
                                      if (value != null) {
                                        depositAmountController.text = (value.depositAmountCents / 100).toStringAsFixed(2);
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a service';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                
                                // Client Selection Toggle
                                Row(
                                  children: [
                                    Checkbox(
                                      value: useExistingClient,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          useExistingClient = value ?? false;
                                          if (useExistingClient) {
                                            selectedClient = null;
                                          } else {
                                            clientFirstNameController.clear();
                                            clientLastNameController.clear();
                                            clientEmailController.clear();
                                            clientPhoneController.clear();
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      'Use existing client',
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Existing Client Selection
                                if (useExistingClient) ...[
                                  Text(
                                    'Select Client *',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.themePrimaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<ClientModel>(
                                    value: selectedClient,
                                    decoration: InputDecoration(
                                      hintText: 'Search and select client',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                      ),
                                    ),
                                    items: clients.map((client) {
                                      return DropdownMenuItem<ClientModel>(
                                        value: client,
                                        child: Text('${client.fullName} (${client.email})'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedClient = value;
                                        if (value != null) {
                                          clientFirstNameController.text = value.firstName;
                                          clientLastNameController.text = value.lastName;
                                          clientEmailController.text = value.email;
                                          clientPhoneController.text = value.phone;
                                        }
                                      });
                                    },
                                    validator: (value) {
                                      if (useExistingClient && value == null) {
                                        return 'Please select a client';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                
                                // Client Information Fields
                                Text(
                                  'Client Information *',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: clientFirstNameController,
                                        decoration: InputDecoration(
                                          labelText: 'First Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                          ),
                                        ),
                                        enabled: !useExistingClient || selectedClient == null,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'First name is required';
                                          }
                                          if (value.length < AppConstants.minNameLength) {
                                            return 'First name must be at least ${AppConstants.minNameLength} characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: clientLastNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Last Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                          ),
                                        ),
                                        enabled: !useExistingClient || selectedClient == null,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Last name is required';
                                          }
                                          if (value.length < AppConstants.minNameLength) {
                                            return 'Last name must be at least ${AppConstants.minNameLength} characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: clientEmailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email *',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !useExistingClient || selectedClient == null,
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
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: clientPhoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone *',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  enabled: !useExistingClient || selectedClient == null,
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
                                const SizedBox(height: 24),
                                
                                // Date and Time Selection
                                Text(
                                  'Appointment Date & Time *',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(
                                          selectedDate != null
                                              ? DateFormat('MMM d, yyyy').format(selectedDate!)
                                              : 'Select Date',
                                        ),
                                        onPressed: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate ?? DateTime.now(),
                                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (date != null) {
                                            setDialogState(() {
                                              selectedDate = date;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.access_time),
                                        label: Text(
                                          selectedTime != null
                                              ? selectedTime!.format(context)
                                              : 'Select Time',
                                        ),
                                        onPressed: () async {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: selectedTime ?? TimeOfDay.now(),
                                          );
                                          if (time != null) {
                                            setDialogState(() {
                                              selectedTime = time;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedDate == null || selectedTime == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Please select both date and time',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.errorRed,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                
                                // Deposit Amount
                                Text(
                                  'Deposit Amount',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: depositAmountController,
                                  decoration: InputDecoration(
                                    labelText: 'Deposit (\$)',
                                    prefixText: '\$',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Deposit amount is required (use 0 for no deposit)';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null) {
                                      return 'Please enter a valid number';
                                    }
                                    if (amount < 0) {
                                      return 'Deposit cannot be negative';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                
                                // Status Selection
                                Text(
                                  'Status *',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<AppointmentStatus>(
                                  value: selectedStatus,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  items: AppointmentStatus.values.map((status) {
                                    return DropdownMenuItem<AppointmentStatus>(
                                      value: status,
                                      child: Text(_formatStatus(status)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        selectedStatus = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                
                                // Client Notes
                                Text(
                                  'Client Notes (Optional)',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: intakeNotesController,
                                  decoration: InputDecoration(
                                    labelText: 'Intake notes from client',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  maxLines: 3,
                                  maxLength: AppConstants.maxNotesLength,
                                ),
                                const SizedBox(height: 24),
                                
                                // Admin Notes
                                Text(
                                  'Admin Notes (Optional)',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: adminNotesController,
                                  decoration: InputDecoration(
                                    labelText: 'Internal admin notes',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                    ),
                                  ),
                                  maxLines: 3,
                                  maxLength: AppConstants.maxNotesLength,
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.softCream,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppConstants.defaultBorderRadius),
                        bottomRight: Radius.circular(AppConstants.defaultBorderRadius),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isCreating
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isCreating
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  
                                  if (selectedService == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select a service'),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  if (selectedDate == null || selectedTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select both date and time'),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  setDialogState(() {
                                    isCreating = true;
                                  });
                                  
                                  try {
                                    // Combine date and time
                                    final appointmentDateTime = DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                      selectedTime!.hour,
                                      selectedTime!.minute,
                                    );
                                    
                                    // Calculate end time
                                    final endTime = appointmentDateTime.add(
                                      Duration(minutes: selectedService!.durationMinutes),
                                    );
                                    
                                    // Parse deposit amount
                                    final depositAmount = (double.parse(depositAmountController.text) * 100).round();
                                    
                                    // Create appointment
                                    final now = DateTime.now();
                                    final appointment = AppointmentModel(
                                      id: '', // Will be set by Firestore
                                      serviceId: selectedService!.id,
                                      serviceSnapshot: selectedService,
                                      clientFirstName: clientFirstNameController.text.trim(),
                                      clientLastName: clientLastNameController.text.trim(),
                                      clientEmail: clientEmailController.text.trim(),
                                      clientPhone: clientPhoneController.text.trim(),
                                      intakeNotes: intakeNotesController.text.trim().isEmpty
                                          ? null
                                          : intakeNotesController.text.trim(),
                                      startTime: appointmentDateTime,
                                      endTime: endTime,
                                      status: selectedStatus,
                                      depositAmountCents: depositAmount,
                                      createdAt: now,
                                      updatedAt: now,
                                      adminNotes: adminNotesController.text.trim().isEmpty
                                          ? null
                                          : adminNotesController.text.trim(),
                                    );
                                    
                                    // Create appointment in Firestore
                                    await _firestoreService.createAppointment(appointment);
                                    
                                    logSuccess('Manual appointment created successfully', tag: 'AdminAppointmentsScreen');
                                    
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Appointment created successfully'),
                                          backgroundColor: AppColors.successGreen,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e, stackTrace) {
                                    logError(
                                      'Failed to create appointment',
                                      tag: 'AdminAppointmentsScreen',
                                      error: e,
                                      stackTrace: stackTrace,
                                    );
                                    if (mounted) {
                                      setDialogState(() {
                                        isCreating = false;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to create appointment: ${e.toString()}'),
                                          backgroundColor: AppColors.errorRed,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunflowerYellow,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create Appointment'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Cleanup controllers
    clientFirstNameController.dispose();
    clientLastNameController.dispose();
    clientEmailController.dispose();
    clientPhoneController.dispose();
    intakeNotesController.dispose();
    adminNotesController.dispose();
    depositAmountController.dispose();
  }

  // MARK: - Helper Widgets
  /// Section title for appointment detail (matches PDF sections)
  Widget _buildDetailSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: context.themePrimaryTextColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _na(String? v) => (v == null || v.isEmpty) ? '—' : v;

  /// Returns true if the appointment has any compliance data (Health & Skin, Acknowledgements, Cancellation, Terms).
  /// Used to show or hide compliance sections in detail dialog and PDF (backwards compatible).
  bool _appointmentHasComplianceData(AppointmentModel appointment) {
    final hasHealth = (appointment.healthDisclosureDetails != null && appointment.healthDisclosureDetails!.isNotEmpty) ||
        appointment.healthDisclosure != null;
    final hasAcknowledgments = appointment.requiredAcknowledgments != null || appointment.requiredAcknowledgmentsAcceptedAt != null;
    final hasCancellation = appointment.cancellationPolicySnapshot != null || appointment.cancellationPolicyAcknowledged;
    final hasTerms = appointment.termsAcceptanceMetadata != null;
    return hasHealth || hasAcknowledgments || hasCancellation || hasTerms;
  }

  Widget _buildAppointmentDisclosureContent(AppointmentModel appointment) {
    if (appointment.healthDisclosureDetails != null && appointment.healthDisclosureDetails!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: appointment.healthDisclosureDetails!.entries.map((e) {
          final label = e.key.replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase()).replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $label: ${e.value}', style: AppTypography.bodySmall.copyWith(color: context.themePrimaryTextColor)),
          );
        }).toList(),
      );
    }
    if (appointment.healthDisclosure != null) {
      final h = appointment.healthDisclosure!;
      return Text(
        'Skin conditions: ${h.hasSkinConditions}; Allergies: ${h.hasAllergies}; Medications: ${h.hasCurrentMedications}; Pregnant/breastfeeding: ${h.isPregnantOrBreastfeeding}; Recent treatments: ${h.hasRecentCosmeticTreatments}; Known reactions: ${h.hasKnownReactions}. Notes: ${_na(h.additionalNotes)}',
        style: AppTypography.bodySmall.copyWith(color: context.themePrimaryTextColor),
      );
    }
    return Text('—', style: AppTypography.bodySmall.copyWith(color: context.themeSecondaryTextColor));
  }

  Widget _buildAppointmentAcknowledgementsContent(AppointmentModel appointment) {
    if (appointment.requiredAcknowledgments != null) {
      final acceptedAt = appointment.requiredAcknowledgmentsAcceptedAt != null
          ? _formatDateTime(appointment.requiredAcknowledgmentsAcceptedAt!)
          : '—';
      return Text(
        'All acknowledged: ${appointment.requiredAcknowledgments!.allAcknowledged}. Accepted at: $acceptedAt',
        style: AppTypography.bodySmall.copyWith(color: context.themePrimaryTextColor),
      );
    }
    return Text('—', style: AppTypography.bodySmall.copyWith(color: context.themeSecondaryTextColor));
  }

  Widget _buildAppointmentCancellationContent(AppointmentModel appointment) {
    if (appointment.cancellationPolicySnapshot != null) {
      final s = appointment.cancellationPolicySnapshot!;
      return Text(
        'Acknowledged: ${s.acknowledged}. At: ${_formatDateTime(s.acknowledgedAt)}. Version: ${_na(s.policyVersion)}',
        style: AppTypography.bodySmall.copyWith(color: context.themePrimaryTextColor),
      );
    }
    return Text(
      'Acknowledged: ${appointment.cancellationPolicyAcknowledged} (legacy)',
      style: AppTypography.bodySmall.copyWith(color: context.themePrimaryTextColor),
    );
  }

  Widget _buildAppointmentTermsContent(AppointmentModel appointment) {
    if (appointment.termsAcceptanceMetadata != null) {
      final t = appointment.termsAcceptanceMetadata!;
      return Text(
        'Accepted: ${t.termsAccepted}. At (UTC): ${_formatDateTime(t.termsAcceptedAtUtc)}',
        style: AppTypography.bodySmall.copyWith(color: context.themePrimaryTextColor),
      );
    }
    return Text('—', style: AppTypography.bodySmall.copyWith(color: context.themeSecondaryTextColor));
  }

  /// Show choice: Standard PDF or PDF with signature form for wet signature
  Future<void> _showPDFFormatChoice(BuildContext context, AppointmentModel appointment) async {
    if (!context.mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose PDF format'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Standard: Full appointment details for preview or print.'),
            SizedBox(height: 12),
            Text('With signature form: Same content plus a signature page you can print and have the client sign in person (wet signature).'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('standard'),
            child: const Text('Standard PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('signature'),
            child: const Text('PDF with signature form'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    await _generateAppointmentPDF(context, appointment, includeSignatureForm: choice == 'signature');
  }

  /// Build detail row widget
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
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

  // MARK: - Date Helpers
  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // MARK: - Formatting Helpers
  /// Format status to readable string
  String _formatStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.arrived:
        return 'Arrived';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.noShow:
        return 'No Show';
      case AppointmentStatus.canceled:
        return 'Canceled';
    }
  }

  /// Get color for status
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.statusConfirmed;
      case AppointmentStatus.arrived:
        return AppColors.statusPending;
      case AppointmentStatus.completed:
        return AppColors.statusCompleted;
      case AppointmentStatus.noShow:
        return AppColors.statusNoShow;
      case AppointmentStatus.canceled:
        return AppColors.statusCancelled;
    }
  }

  /// Format date to string
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format time to string
  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format date and time to string
  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }
}

// Suggestions For Features and Additions Later:
// - Add manual appointment creation dialog with full form
// - Add appointment rescheduling functionality
// - Add bulk status updates
// - Add appointment export (CSV/PDF)
// - Add appointment statistics/analytics
// - Add email/SMS notifications
// - Add appointment reminders
// - Add recurring appointment support
// - Add appointment templates
// - Add drag-and-drop rescheduling in calendar view