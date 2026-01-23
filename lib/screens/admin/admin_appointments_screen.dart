/*
 * Filename: admin_appointments_screen.dart
 * Purpose: Comprehensive admin screen for viewing, managing, and creating appointments
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter, table_calendar, cloud_firestore, intl
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/appointment_model.dart';
import '../../models/service_model.dart';
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

  @override
  void initState() {
    super.initState();
    logUI('AdminAppointmentsScreen initState called', tag: 'AdminAppointmentsScreen');
    logWidgetLifecycle('AdminAppointmentsScreen', 'initState', tag: 'AdminAppointmentsScreen');
    _loadAppointments();
  }

  // MARK: - Data Loading
  /// Load appointments from Firestore with real-time updates
  void _loadAppointments() {
    logLoading('Loading appointments...', tag: 'AdminAppointmentsScreen');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stream = _firestoreService.getAppointmentsStream();
      stream.listen(
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
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
              foregroundColor: AppColors.darkBrown,
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
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments found',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your filters'
                  : 'Create a new appointment to get started',
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
                color: AppColors.darkBrown,
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
            color: AppColors.textSecondary,
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
                      color: AppColors.darkBrown,
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
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Service Name
              if (appointment.serviceSnapshot != null)
                Text(
                  appointment.serviceSnapshot!.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              // Contact Info
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.clientEmail,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    appointment.clientPhone,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                foregroundColor: AppColors.darkBrown,
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

  /// Show appointment details dialog
  Future<void> _showAppointmentDetails(AppointmentModel appointment) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
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
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
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
                const SizedBox(height: 24),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (appointment.status != AppointmentStatus.completed &&
                        appointment.status != AppointmentStatus.canceled)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showStatusUpdateDialog(appointment);
                        },
                        child: const Text('Update Status'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sunflowerYellow,
                        foregroundColor: AppColors.darkBrown,
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

  /// Show create appointment dialog
  Future<void> _showCreateAppointmentDialog() async {
    // TODO: Implement manual appointment creation
    // This would require a form with:
    // - Service selection
    // - Client information (or select existing client)
    // - Date/time picker
    // - Notes
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual appointment creation coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // MARK: - Helper Widgets
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
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkBrown,
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