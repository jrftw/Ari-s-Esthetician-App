/*
 * Filename: admin_time_off_screen.dart
 * Purpose: Admin screen for managing time-off periods (breaks, vacations, unavailability)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: Flutter, services, models, table_calendar, flutter_datetime_picker_plus
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../services/firestore_service.dart';
import '../../models/time_off_model.dart';

// MARK: - Admin Time Off Screen
/// Screen for managing time-off periods including one-time and recurring breaks
class AdminTimeOffScreen extends StatefulWidget {
  const AdminTimeOffScreen({super.key});

  @override
  State<AdminTimeOffScreen> createState() => _AdminTimeOffScreenState();
}

// MARK: - Admin Time Off Screen State
class _AdminTimeOffScreenState extends State<AdminTimeOffScreen> {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();

  // MARK: - State Variables
  List<TimeOffModel> _timeOffList = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _firstDay = DateTime.now().subtract(const Duration(days: 365));
  DateTime _lastDay = DateTime.now().add(const Duration(days: 365));
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // MARK: - Lifecycle Methods
  @override
  void initState() {
    super.initState();
    logUI('AdminTimeOffScreen initState called', tag: 'AdminTimeOffScreen');
    _loadTimeOff();
  }

  // MARK: - Data Loading
  /// Load all time-off periods
  Future<void> _loadTimeOff() async {
    try {
      logLoading('Loading time-off periods...', tag: 'AdminTimeOffScreen');
      setState(() {
        _isLoading = true;
      });

      final timeOffList = await _firestoreService.getAllTimeOffIncludingInactive();
      logSuccess('Loaded ${timeOffList.length} time-off periods', tag: 'AdminTimeOffScreen');

      setState(() {
        _timeOffList = timeOffList;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to load time-off periods', tag: 'AdminTimeOffScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load time-off periods: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building AdminTimeOffScreen widget', tag: 'AdminTimeOffScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Off Management'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTimeOffDialog(),
            tooltip: 'Add Time Off',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar View
                _buildCalendarView(),
                const Divider(),
                // Time-Off List
                Expanded(
                  child: _buildTimeOffList(),
                ),
              ],
            ),
    );
  }

  // MARK: - Calendar View
  /// Build calendar view showing time-off periods
  Widget _buildCalendarView() {
    return Container(
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
      child: TableCalendar<TimeOffModel>(
        firstDay: _firstDay,
        lastDay: _lastDay,
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: (day) {
          return _timeOffList.where((timeOff) {
            if (!timeOff.isActive) return false;
            if (!timeOff.isRecurring) {
              return _isSameDay(timeOff.startTime, day) ||
                  _isSameDay(timeOff.endTime, day) ||
                  (timeOff.startTime.isBefore(day) && timeOff.endTime.isAfter(day));
            } else {
              // For recurring, check if this day matches the pattern
              return timeOff.isActiveForDateTime(day);
            }
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
            color: AppColors.errorRed,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          titleTextStyle: AppTypography.titleMedium.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  // MARK: - Time-Off List
  /// Build list of time-off periods
  Widget _buildTimeOffList() {
    if (_timeOffList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Time-Off Periods',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add a time-off period',
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
      itemCount: _timeOffList.length,
      itemBuilder: (context, index) {
        final timeOff = _timeOffList[index];
        return _buildTimeOffCard(timeOff);
      },
    );
  }

  // MARK: - Time-Off Card
  /// Build card for a time-off period
  Widget _buildTimeOffCard(TimeOffModel timeOff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          timeOff.isRecurring ? Icons.repeat : Icons.event,
          color: timeOff.isActive ? AppColors.sunflowerYellow : AppColors.textSecondary,
        ),
        title: Text(
          timeOff.title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            decoration: timeOff.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatTimeOffPeriod(timeOff),
              style: AppTypography.bodySmall,
            ),
            if (timeOff.notes != null && timeOff.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeOff.notes!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!timeOff.isActive)
              Icon(
                Icons.visibility_off,
                color: AppColors.textSecondary,
                size: 20,
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditTimeOffDialog(timeOff),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteTimeOffDialog(timeOff),
              tooltip: 'Delete',
              color: AppColors.errorRed,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // MARK: - Helper Methods
  /// Format time-off period for display
  String _formatTimeOffPeriod(TimeOffModel timeOff) {
    if (!timeOff.isRecurring) {
      final startDate = _formatDate(timeOff.startTime);
      final endDate = _formatDate(timeOff.endTime);
      final startTime = _formatTime(timeOff.startTime);
      final endTime = _formatTime(timeOff.endTime);
      
      if (_isSameDay(timeOff.startTime, timeOff.endTime)) {
        return '$startDate, $startTime - $endTime';
      } else {
        return '$startDate $startTime - $endDate $endTime';
      }
    } else {
      final pattern = _formatRecurrencePattern(timeOff.recurrencePattern);
      final timeRange = '${_formatTime(timeOff.startTime)} - ${_formatTime(timeOff.endTime)}';
      String endDate = '';
      if (timeOff.recurrenceEndDate != null) {
        endDate = ' until ${_formatDate(timeOff.recurrenceEndDate!)}';
      }
      return '$pattern, $timeRange$endDate';
    }
  }

  /// Format recurrence pattern
  String _formatRecurrencePattern(RecurrencePattern pattern) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekly:
        return 'Weekly';
      case RecurrencePattern.monthly:
        return 'Monthly';
      case RecurrencePattern.none:
        return 'One-time';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Format time for display
  String _formatTime(DateTime date) {
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // MARK: - Dialogs
  /// Show dialog to add new time-off period
  void _showAddTimeOffDialog() {
    showDialog(
      context: context,
      builder: (context) => _TimeOffDialog(
        firestoreService: _firestoreService,
        onSaved: () {
          _loadTimeOff();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Show dialog to edit time-off period
  void _showEditTimeOffDialog(TimeOffModel timeOff) {
    showDialog(
      context: context,
      builder: (context) => _TimeOffDialog(
        firestoreService: _firestoreService,
        timeOff: timeOff,
        onSaved: () {
          _loadTimeOff();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Show dialog to confirm deletion
  void _showDeleteTimeOffDialog(TimeOffModel timeOff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time-Off Period'),
        content: Text('Are you sure you want to delete "${timeOff.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteTimeOff(timeOff.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadTimeOff();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Time-off period deleted'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${e.toString()}'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// MARK: - Time Off Dialog
/// Dialog for adding/editing time-off periods
class _TimeOffDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final TimeOffModel? timeOff;
  final VoidCallback onSaved;

  const _TimeOffDialog({
    required this.firestoreService,
    this.timeOff,
    required this.onSaved,
  });

  @override
  State<_TimeOffDialog> createState() => _TimeOffDialogState();
}

// MARK: - Time Off Dialog State
class _TimeOffDialogState extends State<_TimeOffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _isRecurring = false;
  RecurrencePattern _recurrencePattern = RecurrencePattern.none;
  DateTime? _recurrenceEndDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.timeOff != null) {
      final timeOff = widget.timeOff!;
      _titleController.text = timeOff.title;
      _notesController.text = timeOff.notes ?? '';
      _startDate = timeOff.startTime;
      _startTime = TimeOfDay.fromDateTime(timeOff.startTime);
      _endDate = timeOff.endTime;
      _endTime = TimeOfDay.fromDateTime(timeOff.endTime);
      _isRecurring = timeOff.isRecurring;
      _recurrencePattern = timeOff.recurrencePattern;
      _recurrenceEndDate = timeOff.recurrenceEndDate;
      _isActive = timeOff.isActive;
    } else {
      // Default to today
      _startDate = DateTime.now();
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endDate = DateTime.now();
      _endTime = const TimeOfDay(hour: 17, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.timeOff == null ? 'Add Time Off' : 'Edit Time Off',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Lunch Break, Vacation, Personal Day',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Start Date & Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_startDate != null
                              ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}'
                              : 'Select date'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _startTime = time;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_startTime != null
                              ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select time'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // End Date & Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_endDate != null
                              ? '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                              : 'Select date'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _endTime = time;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          child: Text(_endTime != null
                              ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                              : 'Select time'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Recurring Toggle
                SwitchListTile(
                  title: const Text('Recurring'),
                  subtitle: const Text('Repeat this time-off period'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  // Recurrence Pattern
                  DropdownButtonFormField<RecurrencePattern>(
                    value: _recurrencePattern,
                    decoration: const InputDecoration(
                      labelText: 'Repeat Pattern',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: RecurrencePattern.daily,
                        child: Text('Daily'),
                      ),
                      DropdownMenuItem(
                        value: RecurrencePattern.weekly,
                        child: Text('Weekly'),
                      ),
                      DropdownMenuItem(
                        value: RecurrencePattern.monthly,
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _recurrencePattern = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Recurrence End Date
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (date != null) {
                        setState(() {
                          _recurrenceEndDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date (Optional)',
                        prefixIcon: Icon(Icons.event_busy),
                        helperText: 'Leave empty for no end date',
                      ),
                      child: Text(_recurrenceEndDate != null
                          ? '${_recurrenceEndDate!.month}/${_recurrenceEndDate!.day}/${_recurrenceEndDate!.year}'
                          : 'No end date'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Active Toggle
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Time-off is currently active'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveTimeOff,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sunflowerYellow,
                        foregroundColor: AppColors.darkBrown,
                      ),
                      child: const Text('Save'),
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

  /// Save time-off period
  Future<void> _saveTimeOff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end date/time'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    try {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      TimeOffModel timeOff;
      if (_isRecurring) {
        timeOff = TimeOffModel.createRecurring(
          title: _titleController.text.trim(),
          startTime: startDateTime,
          endTime: endDateTime,
          recurrencePattern: _recurrencePattern,
          recurrenceEndDate: _recurrenceEndDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        timeOff = TimeOffModel.createOneTime(
          title: _titleController.text.trim(),
          startTime: startDateTime,
          endTime: endDateTime,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }

      // Set active status and ID if editing
      if (widget.timeOff != null) {
        timeOff = timeOff.copyWith(
          id: widget.timeOff!.id,
          isActive: _isActive,
        );
        await widget.firestoreService.updateTimeOff(timeOff);
      } else {
        timeOff = timeOff.copyWith(isActive: _isActive);
        await widget.firestoreService.createTimeOff(timeOff);
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add bulk time-off import/export
// - Add time-off templates
// - Add conflict detection with existing appointments
// - Add time-off approval workflow for multiple staff
// - Add calendar sync for time-off periods
