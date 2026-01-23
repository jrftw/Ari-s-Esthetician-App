/*
 * Filename: client_booking_screen.dart
 * Purpose: Complete booking experience with service selection, date/time picker, client form, and payment
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter, services, models, table_calendar, flutter_datetime_picker_plus, flutter_stripe, go_router
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/view_mode_service.dart';
import '../../services/auth_service.dart';
import 'client_confirmation_screen.dart';

// MARK: - Booking Step Enum
/// Steps in the booking process
enum BookingStep {
  serviceSelection,
  dateTimeSelection,
  clientInformation,
  payment,
  confirmation,
}

// MARK: - Client Booking Screen
/// Complete booking experience with multi-step flow
/// Handles service selection, scheduling, client info, and payment
class ClientBookingScreen extends StatefulWidget {
  const ClientBookingScreen({super.key});

  @override
  State<ClientBookingScreen> createState() => _ClientBookingScreenState();
}

// MARK: - Client Booking Screen State
class _ClientBookingScreenState extends State<ClientBookingScreen> {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ViewModeService _viewModeService = ViewModeService.instance;
  
  // MARK: - State Variables
  bool _isAdminViewingAsClient = false;
  BookingStep _currentStep = BookingStep.serviceSelection;
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDateTime;
  bool _isLoadingServices = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // MARK: - Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  // MARK: - Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime _firstDay = DateTime.now();
  DateTime _lastDay = DateTime.now().add(const Duration(days: AppConstants.maxBookingAdvanceDays));
  
  // MARK: - Available Time Slots
  List<TimeOfDay> _availableTimeSlots = [];
  
  @override
  void initState() {
    super.initState();
    logUI('ClientBookingScreen initState called', tag: 'ClientBookingScreen');
    logWidgetLifecycle('ClientBookingScreen', 'initState', tag: 'ClientBookingScreen');
    _loadServices();
    _generateTimeSlots();
    _checkAdminViewMode();
    
    // Listen to view mode changes
    _viewModeService.addListener(_onViewModeChanged);
  }

  /// Check if admin is viewing as client
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
      logError('Failed to check admin view mode', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle view mode changes
  void _onViewModeChanged() {
    if (mounted) {
      _checkAdminViewMode();
    }
  }
  
  @override
  void dispose() {
    _viewModeService.removeListener(_onViewModeChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  // MARK: - Service Loading
  /// Load active services from Firestore
  Future<void> _loadServices() async {
    try {
      logLoading('Loading services...', tag: 'ClientBookingScreen');
      setState(() {
        _isLoadingServices = true;
        _errorMessage = null;
      });
      
      final services = await _firestoreService.getActiveServices();
      logSuccess('Loaded ${services.length} services', tag: 'ClientBookingScreen');
      
      setState(() {
        _services = services;
        _isLoadingServices = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to load services', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoadingServices = false;
        _errorMessage = 'Failed to load services. Please try again.';
      });
    }
  }
  
  // MARK: - Time Slot Generation
  /// Generate available time slots (9 AM - 6 PM, every 30 minutes)
  void _generateTimeSlots() {
    _availableTimeSlots = [];
    for (int hour = 9; hour < 18; hour++) {
      _availableTimeSlots.add(TimeOfDay(hour: hour, minute: 0));
      _availableTimeSlots.add(TimeOfDay(hour: hour, minute: 30));
    }
  }
  
  // MARK: - Step Navigation
  /// Move to next step in booking process
  void _nextStep() {
    if (_currentStep == BookingStep.serviceSelection) {
      if (_selectedService == null) {
        _showError('Please select a service');
        return;
      }
      setState(() {
        _currentStep = BookingStep.dateTimeSelection;
      });
    } else if (_currentStep == BookingStep.dateTimeSelection) {
      if (_selectedDate == null || _selectedTime == null) {
        _showError('Please select a date and time');
        return;
      }
      _selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      // Validate selected time is in the future
      if (_selectedDateTime!.isBefore(DateTime.now().add(const Duration(hours: AppConstants.minBookingAdvanceHours)))) {
        _showError('Please select a time at least ${AppConstants.minBookingAdvanceHours} hours in advance');
        return;
      }
      
      setState(() {
        _currentStep = BookingStep.clientInformation;
      });
    } else if (_currentStep == BookingStep.clientInformation) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      setState(() {
        _currentStep = BookingStep.payment;
      });
      _processPayment();
    }
  }
  
  /// Move to previous step
  void _previousStep() {
    if (_currentStep == BookingStep.dateTimeSelection) {
      setState(() {
        _currentStep = BookingStep.serviceSelection;
      });
    } else if (_currentStep == BookingStep.clientInformation) {
      setState(() {
        _currentStep = BookingStep.dateTimeSelection;
      });
    } else if (_currentStep == BookingStep.payment) {
      setState(() {
        _currentStep = BookingStep.clientInformation;
      });
    }
  }
  
  // MARK: - Error Handling
  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // MARK: - Payment Processing
  /// Process Stripe payment
  Future<void> _processPayment() async {
    if (_selectedService == null || _selectedDateTime == null) {
      _showError('Missing booking information');
      return;
    }
    
    try {
      logLoading('Processing payment...', tag: 'ClientBookingScreen');
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      
      // TODO: Initialize Stripe payment intent
      // For now, we'll create the appointment without payment
      // In production, you would:
      // 1. Create payment intent on backend
      // 2. Confirm payment with Stripe
      // 3. Get payment intent ID
      
      await _submitBooking();
    } catch (e, stackTrace) {
      logError('Payment processing failed', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      _showError('Payment processing failed. Please try again.');
      setState(() {
        _isSubmitting = false;
        _currentStep = BookingStep.clientInformation;
      });
    }
  }
  
  // MARK: - Booking Submission
  /// Submit booking to Firestore
  Future<void> _submitBooking() async {
    try {
      logLoading('Submitting booking...', tag: 'ClientBookingScreen');
      
      // Create appointment model
      final appointment = AppointmentModel.create(
        serviceId: _selectedService!.id,
        serviceSnapshot: _selectedService,
        clientFirstName: _firstNameController.text.trim(),
        clientLastName: _lastNameController.text.trim(),
        clientEmail: _emailController.text.trim(),
        clientPhone: _phoneController.text.trim(),
        intakeNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        startTime: _selectedDateTime!,
        durationMinutes: _selectedService!.durationMinutes,
        depositAmountCents: _selectedService!.depositAmountCents,
        stripePaymentIntentId: null, // TODO: Add after Stripe integration
      );
      
      // Create appointment in Firestore
      final appointmentId = await _firestoreService.createAppointment(appointment);
      
      logSuccess('Booking submitted successfully: $appointmentId', tag: 'ClientBookingScreen');
      
      // Navigate to confirmation screen
      if (mounted) {
        context.go('${AppConstants.routeClientConfirmation}/$appointmentId');
      }
    } catch (e, stackTrace) {
      logError('Failed to submit booking', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      _showError('Failed to submit booking. Please try again.');
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building ClientBookingScreen widget', tag: 'ClientBookingScreen');
    
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        leading: _currentStep != BookingStep.serviceSelection
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Admin View Banner (if admin is viewing as client)
            if (_isAdminViewingAsClient) _buildAdminViewBanner(context),
            
            // Progress Indicator
            _buildProgressIndicator(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorRed),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.errorRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Step Content
                    if (_currentStep == BookingStep.serviceSelection)
                      _buildServiceSelection()
                    else if (_currentStep == BookingStep.dateTimeSelection)
                      _buildDateTimeSelection()
                    else if (_currentStep == BookingStep.clientInformation)
                      _buildClientInformation()
                    else if (_currentStep == BookingStep.payment)
                      _buildPaymentProcessing(),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Button
            if (_currentStep != BookingStep.payment)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sunflowerYellow,
                        foregroundColor: AppColors.darkBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: Text(
                        _getNextButtonText(),
                        style: AppTypography.buttonText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // MARK: - Admin View Banner
  /// Build banner showing admin is viewing as client with option to switch back
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
            color: AppColors.darkBrown,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Viewing as Client',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              logInfo('Admin switching back to admin view', tag: 'ClientBookingScreen');
              _viewModeService.switchToAdminView();
              context.go(AppConstants.routeAdminDashboard);
            },
            child: Text(
              'Back to Admin',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Progress Indicator
  /// Build progress indicator showing current step
  Widget _buildProgressIndicator() {
    final steps = [
      'Service',
      'Date & Time',
      'Information',
      'Payment',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isActive = index <= _currentStep.index;
          final isCurrent = index == _currentStep.index;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.sunflowerYellow
                              : AppColors.textSecondary.withOpacity(0.2),
                        ),
                        child: Center(
                          child: isActive
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: AppColors.darkBrown,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isCurrent
                                        ? AppColors.darkBrown
                                        : AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step,
                        style: AppTypography.bodySmall.copyWith(
                          color: isActive
                              ? AppColors.darkBrown
                              : AppColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    height: 2,
                    width: 20,
                    color: isActive
                        ? AppColors.sunflowerYellow
                        : AppColors.textSecondary.withOpacity(0.2),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // MARK: - Service Selection
  /// Build service selection UI
  Widget _buildServiceSelection() {
    if (_isLoadingServices) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No services available',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a Service',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the service you\'d like to book',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ..._services.map((service) => _buildServiceCard(service)),
      ],
    );
  }
  
  /// Build individual service card
  Widget _buildServiceCard(ServiceModel service) {
    final isSelected = _selectedService?.id == service.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: isSelected
              ? AppColors.sunflowerYellow
              : AppColors.shadowColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedService = service;
          });
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Selection Indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sunflowerYellow
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                  color: isSelected
                      ? AppColors.sunflowerYellow
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.darkBrown,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationMinutes} min',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          service.formattedPrice,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.darkBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // MARK: - Date/Time Selection
  /// Build date and time selection UI
  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date & Time',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred appointment date and time',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        
        // Calendar
        Container(
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
          child: TableCalendar(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              if (_selectedDate == null) return false;
              return _selectedDate!.year == day.year &&
                  _selectedDate!.month == day.month &&
                  _selectedDate!.day == day.day;
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay;
                _selectedTime = null; // Reset time when date changes
              });
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.sunflowerYellow,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.sunflowerYellow.withOpacity(0.5),
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
            enabledDayPredicate: (day) {
              // Disable past dates and dates too far in advance
              final now = DateTime.now();
              final minDate = now.add(const Duration(hours: AppConstants.minBookingAdvanceHours));
              return day.isAfter(minDate.subtract(const Duration(days: 1))) &&
                  day.isBefore(_lastDay.add(const Duration(days: 1)));
            },
          ),
        ),
        const SizedBox(height: 24),
        
        // Time Selection
        if (_selectedDate != null) ...[
          Text(
            'Select Time',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableTimeSlots.map((time) {
              final isSelected = _selectedTime == time;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.sunflowerYellow
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.sunflowerYellow
                          : AppColors.shadowColor,
                    ),
                  ),
                  child: Text(
                    _formatTimeOfDay(time),
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.darkBrown
                          : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  // MARK: - Client Information
  /// Build client information form
  Widget _buildClientInformation() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Information',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your contact information',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // First Name
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your first name';
              }
              if (value.trim().length < AppConstants.minNameLength) {
                return 'First name must be at least ${AppConstants.minNameLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Last Name
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your last name';
              }
              if (value.trim().length < AppConstants.minNameLength) {
                return 'Last name must be at least ${AppConstants.minNameLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Phone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.trim().length < AppConstants.minPhoneLength) {
                return 'Phone number must be at least ${AppConstants.minPhoneLength} digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Notes (Optional)
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Special Requests or Notes (Optional)',
              prefixIcon: const Icon(Icons.note_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            maxLength: AppConstants.maxNotesLength,
          ),
          const SizedBox(height: 24),
          
          // Booking Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.sunflowerYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: AppColors.sunflowerYellow.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Summary',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Service', _selectedService?.name ?? ''),
                _buildSummaryRow('Date', _selectedDate != null
                    ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                    : ''),
                _buildSummaryRow('Time', _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : ''),
                _buildSummaryRow('Duration', '${_selectedService?.durationMinutes ?? 0} minutes'),
                const Divider(),
                _buildSummaryRow(
                  'Deposit Required',
                  _selectedService?.formattedDeposit ?? '\$0.00',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build summary row
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.darkBrown,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  // MARK: - Payment Processing
  /// Build payment processing UI
  Widget _buildPaymentProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing Payment...',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we process your booking',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  // MARK: - Helper Methods
  /// Format TimeOfDay to string (e.g., "9:00 AM")
  String _formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }
  
  /// Get next button text based on current step
  String _getNextButtonText() {
    switch (_currentStep) {
      case BookingStep.serviceSelection:
        return 'Continue';
      case BookingStep.dateTimeSelection:
        return 'Continue';
      case BookingStep.clientInformation:
        return 'Proceed to Payment';
      default:
        return 'Continue';
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add service images
// - Add availability checking (block booked times)
// - Add recurring appointment support
// - Add appointment reminders
// - Add calendar integration
// - Add payment receipt generation
// - Add booking confirmation email
// - Add appointment rescheduling
// - Add cancellation functionality
