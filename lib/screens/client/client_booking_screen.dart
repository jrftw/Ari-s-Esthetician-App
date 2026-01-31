/*
 * Filename: client_booking_screen.dart
 * Purpose: Complete booking experience with service selection, date/time picker, client form, and payment
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: Flutter, services, models, table_calendar, flutter_datetime_picker_plus, flutter_stripe, go_router
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/service_model.dart';
import '../../models/service_category_model.dart';
import '../../models/appointment_model.dart';
import '../../models/business_settings_model.dart';
import '../../models/coupon_model.dart';
import '../../services/firestore_service.dart';
import '../../services/view_mode_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/email_service.dart';
import '../../services/device_metadata_service.dart';
import '../../core/constants/terms_and_conditions.dart';
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
  final PaymentService _paymentService = PaymentService();
  final EmailService _emailService = EmailService();
  
  // MARK: - State Variables
  bool _isAdminViewingAsClient = false;
  BookingStep _currentStep = BookingStep.serviceSelection;
  List<ServiceModel> _services = [];
  List<ServiceModel> _filteredServices = [];
  List<ServiceModel> _selectedServices = [];
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDateTime;
  bool _isLoadingServices = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _paymentsEnabled = false;
  BusinessSettingsModel? _businessSettings;
  
  // MARK: - Category State Variables
  List<ServiceCategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  String? _selectedCategoryId; // null = "All", empty string = "Other" (Uncategorized)
  
  // MARK: - Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _couponCodeController = TextEditingController();
  
  // MARK: - Coupon State
  /// Whether any active coupons exist (hide coupon section when false)
  bool _hasActiveCoupons = false;
  CouponModel? _appliedCoupon;
  String? _couponErrorMessage;
  bool _isValidatingCoupon = false;
  
  // MARK: - Payment Form Controllers
  final _cardNumberController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  
  // MARK: - Payment State
  PaymentIntent? _paymentIntent;
  String? _paymentIntentId;
  bool _isProcessingPayment = false;
  
  // MARK: - Tip State
  int _tipAmountCents = 0;
  final TextEditingController _tipAmountController = TextEditingController();
  final List<int> _quickTipOptions = [500, 1000, 1500, 2000, 2500, 5000]; // $5, $10, $15, $20, $25, $50
  
  /// Total deposit before coupon (sum of selected services' deposit)
  int _getTotalDepositCents() {
    return _selectedServices.fold<int>(
      0,
      (sum, s) => sum + s.depositAmountCents,
    );
  }
  
  /// Discount amount in cents from applied coupon (0 if none)
  int _getDiscountAmountCents() {
    if (_appliedCoupon == null) return 0;
    return _appliedCoupon!.calculateDiscountCents(_getTotalDepositCents());
  }
  
  /// Deposit after discount (for payment and display)
  int _getDepositAfterDiscountCents() {
    return (_getTotalDepositCents() - _getDiscountAmountCents()).clamp(0, _getTotalDepositCents());
  }
  
  /// Initialize payment service when entering payment step
  Future<void> _initializePaymentForStep() async {
    try {
      await _paymentService.initializeStripe();
    } catch (e, stackTrace) {
      logError('Failed to initialize payment service', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
    }
  }
  
  // MARK: - Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime _firstDay = DateTime.now();
  DateTime _lastDay = DateTime.now().add(const Duration(days: AppConstants.maxBookingAdvanceDays));
  
  // MARK: - Available Time Slots
  List<TimeOfDay> _availableTimeSlots = [];
  List<TimeOfDay> _filteredAvailableTimeSlots = [];
  bool _isLoadingAvailability = false;
  
  // MARK: - Description Expansion State
  /// Set of service IDs whose descriptions are currently expanded
  final Set<String> _expandedDescriptions = {};
  
  // MARK: - Legal Compliance State
  /// Health disclosure checkboxes
  bool _hasSkinConditions = false;
  bool _hasAllergies = false;
  bool _hasCurrentMedications = false;
  bool _isPregnantOrBreastfeeding = false;
  bool _hasRecentCosmeticTreatments = false;
  bool _hasKnownReactions = false;
  /// Per-item answer: detail when checked, or "Not applicable" when unchecked (required)
  final TextEditingController _skinConditionsDetailController = TextEditingController();
  final TextEditingController _allergiesDetailController = TextEditingController();
  final TextEditingController _currentMedicationsDetailController = TextEditingController();
  final TextEditingController _pregnantOrBreastfeedingDetailController = TextEditingController();
  final TextEditingController _recentCosmeticTreatmentsDetailController = TextEditingController();
  final TextEditingController _knownReactionsDetailController = TextEditingController();
  final TextEditingController _healthDisclosureNotesController = TextEditingController();
  
  /// Required acknowledgment checkboxes
  bool _understandsResultsNotGuaranteed = false;
  bool _understandsServicesNonMedical = false;
  bool _agreesToFollowAftercare = false;
  bool _acceptsInherentRisks = false;
  
  /// Terms & Conditions acceptance
  bool _termsAccepted = false;
  
  /// Cancellation policy acknowledgment
  bool _cancellationPolicyAcknowledged = false;
  
  /// Terms & Conditions modal visibility
  bool _showTermsModal = false;
  
  @override
  void initState() {
    super.initState();
    logUI('ClientBookingScreen initState called', tag: 'ClientBookingScreen');
    logWidgetLifecycle('ClientBookingScreen', 'initState', tag: 'ClientBookingScreen');
    _loadServices();
    _loadCategories();
    _checkAdminViewMode();
    _loadBusinessSettings().then((_) {
      // Generate time slots after settings are loaded
      _generateTimeSlots();
      // If user already selected a date, refresh filtered slots with latest settings
      if (mounted && _selectedDate != null) {
        _filterAvailableTimeSlots();
      }
    });
    _loadHasActiveCoupons();
    _initializePayment();
    
    // Listen to view mode changes
    _viewModeService.addListener(_onViewModeChanged);
  }
  
  /// Load business settings to check if payments are enabled and get working hours
  Future<void> _loadBusinessSettings() async {
    try {
      logLoading('Loading business settings...', tag: 'ClientBookingScreen');
      final settings = await _firestoreService.getBusinessSettings();
      if (mounted && settings != null) {
        setState(() {
          _businessSettings = settings;
          _paymentsEnabled = settings.paymentsEnabled;
        });
        logInfo('Payments enabled: $_paymentsEnabled', tag: 'ClientBookingScreen');
        logInfo('Working hours loaded: ${settings.weeklyHours.length} days configured', tag: 'ClientBookingScreen');
      }
    } catch (e, stackTrace) {
      logError('Failed to load business settings', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      // Default to payments disabled if we can't load settings
      setState(() {
        _businessSettings = null;
        _paymentsEnabled = false;
      });
    }
  }

  /// Load whether any active coupons exist (hide coupon section when none)
  Future<void> _loadHasActiveCoupons() async {
    try {
      final hasCoupons = await _firestoreService.hasActiveCoupons();
      if (mounted) {
        setState(() => _hasActiveCoupons = hasCoupons);
      }
    } catch (e, stackTrace) {
      logError('Failed to check active coupons', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _hasActiveCoupons = false);
      }
    }
  }

  /// Initialize Stripe payment service
  Future<void> _initializePayment() async {
    try {
      await _paymentService.initializeStripe();
    } catch (e, stackTrace) {
      logError('Failed to initialize payment service', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
    }
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
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _couponCodeController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    _tipAmountController.dispose();
    _skinConditionsDetailController.dispose();
    _allergiesDetailController.dispose();
    _currentMedicationsDetailController.dispose();
    _pregnantOrBreastfeedingDetailController.dispose();
    _recentCosmeticTreatmentsDetailController.dispose();
    _knownReactionsDetailController.dispose();
    _healthDisclosureNotesController.dispose();
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
        _applyFilters(); // Apply current category and search filters
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
  
  // MARK: - Category Loading
  /// Load active categories from Firestore
  Future<void> _loadCategories() async {
    try {
      logLoading('Loading categories...', tag: 'ClientBookingScreen');
      setState(() {
        _isLoadingCategories = true;
      });
      
      final categories = await _firestoreService.getActiveCategories();
      logSuccess('Loaded ${categories.length} categories', tag: 'ClientBookingScreen');
      
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to load categories', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      // Don't show error to user - categories are optional, services will still work
      setState(() {
        _categories = [];
        _isLoadingCategories = false;
      });
    }
  }
  
  // MARK: - Time Slot Generation
  /// Generate available time slots based on business working hours
  /// If no business settings are available, defaults to 9 AM - 6 PM, every 30 minutes
  void _generateTimeSlots() {
    _availableTimeSlots = [];
    
    // If no business settings, use default hours
    if (_businessSettings == null || _businessSettings!.weeklyHours.isEmpty) {
      logWarning('No business settings available, using default hours (9 AM - 6 PM)', tag: 'ClientBookingScreen');
      for (int hour = 9; hour < 18; hour++) {
        _availableTimeSlots.add(TimeOfDay(hour: hour, minute: 0));
        _availableTimeSlots.add(TimeOfDay(hour: hour, minute: 30));
      }
      return;
    }
    
    // Generate time slots for all days based on working hours
    // We'll filter by day when a date is selected
    final allTimeSlots = <TimeOfDay>{};
    
    for (final dayHours in _businessSettings!.weeklyHours) {
      if (!dayHours.isOpen || dayHours.timeSlots.isEmpty) {
        continue;
      }
      
      // Process each time slot pair (start, end)
      for (int i = 0; i < dayHours.timeSlots.length; i += 2) {
        if (i + 1 >= dayHours.timeSlots.length) break;
        
        final startTimeStr = dayHours.timeSlots[i];
        final endTimeStr = dayHours.timeSlots[i + 1];
        
        // Parse start and end times (format: "HH:mm")
        final startParts = startTimeStr.split(':');
        final endParts = endTimeStr.split(':');
        
        if (startParts.length != 2 || endParts.length != 2) continue;
        
        final startHour = int.tryParse(startParts[0]);
        final startMinute = int.tryParse(startParts[1]);
        final endHour = int.tryParse(endParts[0]);
        final endMinute = int.tryParse(endParts[1]);
        
        if (startHour == null || startMinute == null || endHour == null || endMinute == null) continue;
        
        // Generate 30-minute intervals between start and end
        var currentHour = startHour;
        var currentMinute = startMinute;
        
        while (currentHour < endHour || (currentHour == endHour && currentMinute < endMinute)) {
          allTimeSlots.add(TimeOfDay(hour: currentHour, minute: currentMinute));
          
          // Add 30 minutes
          currentMinute += 30;
          if (currentMinute >= 60) {
            currentMinute -= 60;
            currentHour += 1;
          }
        }
      }
    }
    
    _availableTimeSlots = allTimeSlots.toList()..sort((a, b) {
      if (a.hour != b.hour) return a.hour.compareTo(b.hour);
      return a.minute.compareTo(b.minute);
    });
    
    logInfo('Generated ${_availableTimeSlots.length} time slots from business hours', tag: 'ClientBookingScreen');
  }
  
  /// Default working hours when business settings are missing or a day has no configured hours.
  /// Sunday (0) and Saturday (6) closed; Monday (1)–Friday (5) 08:00–17:30.
  /// Ensures users see time slots when Firestore has no business_settings document or weeklyHours is empty.
  BusinessHoursModel? _getDefaultHoursForDay(int dayOfWeek) {
    if (dayOfWeek < 0 || dayOfWeek > 6) return null;
    final isWeekday = dayOfWeek >= 1 && dayOfWeek <= 5;
    return BusinessHoursModel(
      dayOfWeek: dayOfWeek,
      isOpen: isWeekday,
      timeSlots: isWeekday ? ['08:00', '17:30'] : [],
    );
  }

  /// Filter available time slots based on business working hours, booked appointments, and time-off
  Future<void> _filterAvailableTimeSlots() async {
    if (_selectedDate == null) {
      setState(() {
        _filteredAvailableTimeSlots = [];
      });
      return;
    }
    
    setState(() {
      _isLoadingAvailability = true;
    });
    
    try {
      logLoading('Filtering available time slots...', tag: 'ClientBookingScreen');
      
      // Get day of week (0 = Sunday, 6 = Saturday) — matches BusinessHoursModel convention
      final dayOfWeek = _selectedDate!.weekday % 7; // Convert Monday=1 to Sunday=0 format
      
      // Get working hours for this day from settings, or use default when none configured
      BusinessHoursModel? dayHours;
      if (_businessSettings != null) {
        dayHours = _businessSettings!.getHoursForDay(dayOfWeek);
      }
      // When no business settings (e.g. no Firestore document) or this day not in weeklyHours, use default
      if (dayHours == null) {
        dayHours = _getDefaultHoursForDay(dayOfWeek);
        logInfo('Using default hours for day $dayOfWeek (no settings or day not configured)', tag: 'ClientBookingScreen');
      }
      
      // If business is closed on this day (explicitly or default weekend), no slots available
      if (dayHours == null || !dayHours.isOpen || dayHours.timeSlots.isEmpty) {
        logInfo('Business is closed on selected day (dayOfWeek: $dayOfWeek)', tag: 'ClientBookingScreen');
        setState(() {
          _filteredAvailableTimeSlots = [];
          _isLoadingAvailability = false;
        });
        return;
      }
      
      // Generate time slots for this specific day based on working hours
      final dayTimeSlots = <TimeOfDay>[];
      for (int i = 0; i < dayHours.timeSlots.length; i += 2) {
        if (i + 1 >= dayHours.timeSlots.length) break;
        
        final startTimeStr = dayHours.timeSlots[i];
        final endTimeStr = dayHours.timeSlots[i + 1];
        
        final startParts = startTimeStr.split(':');
        final endParts = endTimeStr.split(':');
        
        if (startParts.length != 2 || endParts.length != 2) continue;
        
        final startHour = int.tryParse(startParts[0]);
        final startMinute = int.tryParse(startParts[1]);
        final endHour = int.tryParse(endParts[0]);
        final endMinute = int.tryParse(endParts[1]);
        
        if (startHour == null || startMinute == null || endHour == null || endMinute == null) continue;
        
        // Generate 30-minute intervals between start and end
        var currentHour = startHour;
        var currentMinute = startMinute;
        
        while (currentHour < endHour || (currentHour == endHour && currentMinute < endMinute)) {
          dayTimeSlots.add(TimeOfDay(hour: currentHour, minute: currentMinute));
          
          // Add 30 minutes
          currentMinute += 30;
          if (currentMinute >= 60) {
            currentMinute -= 60;
            currentHour += 1;
          }
        }
      }
      
      // Calculate total duration needed for all selected services
      final totalDurationMinutes = _selectedServices.fold<int>(
        0,
        (sum, service) => sum + service.durationMinutes + service.bufferTimeAfterMinutes,
      );
      
      final availableSlots = <TimeOfDay>[];
      
      final now = DateTime.now();
      // When same-day booking is disabled, first bookable slot is 24h from now; otherwise use min advance (e.g. 2h)
      final allowSameDay = _businessSettings?.allowSameDayBooking ?? true;
      final minSlotTime = allowSameDay
          ? now.add(const Duration(hours: AppConstants.minBookingAdvanceHours))
          : now.add(const Duration(hours: 24));
      
      for (final timeSlot in dayTimeSlots) {
        // Create DateTime for this time slot
        final slotDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          timeSlot.hour,
          timeSlot.minute,
        );
        
        // Skip past slots: slot must start at or after minSlotTime
        if (slotDateTime.isBefore(minSlotTime)) continue;
        
        // Calculate end time for all services
        final slotEndDateTime = slotDateTime.add(Duration(minutes: totalDurationMinutes));
        
        // Check if end time is still within working hours
        bool isWithinWorkingHours = false;
        for (int i = 0; i < dayHours.timeSlots.length; i += 2) {
          if (i + 1 >= dayHours.timeSlots.length) break;
          
          final startTimeStr = dayHours.timeSlots[i];
          final endTimeStr = dayHours.timeSlots[i + 1];
          
          final startParts = startTimeStr.split(':');
          final endParts = endTimeStr.split(':');
          
          if (startParts.length != 2 || endParts.length != 2) continue;
          
          final slotStartHour = int.tryParse(startParts[0]);
          final slotStartMinute = int.tryParse(startParts[1]);
          final slotEndHour = int.tryParse(endParts[0]);
          final slotEndMinute = int.tryParse(endParts[1]);
          
          if (slotStartHour == null || slotStartMinute == null || slotEndHour == null || slotEndMinute == null) continue;
          
          final slotStartTime = TimeOfDay(hour: slotStartHour, minute: slotStartMinute);
          final slotEndTime = TimeOfDay(hour: slotEndHour, minute: slotEndMinute);
          
          // Check if the appointment fits within this time slot
          if (_isTimeOfDayBeforeOrEqual(slotStartTime, timeSlot) &&
              _isTimeOfDayBeforeOrEqual(timeSlot, slotEndTime)) {
            // Check if end time is also within working hours
            final endTimeOfDay = TimeOfDay(hour: slotEndDateTime.hour, minute: slotEndDateTime.minute);
            if (_isTimeOfDayBeforeOrEqual(endTimeOfDay, slotEndTime)) {
              isWithinWorkingHours = true;
              break;
            }
          }
        }
        
        if (!isWithinWorkingHours) continue;
        
        // Check if this time slot is available (not blocked by appointments or time-off)
        // Per-slot try/catch so one Firestore error does not clear all slots
        bool isAvailable = false;
        try {
          isAvailable = await _firestoreService.isTimeSlotAvailable(
            slotDateTime,
            slotEndDateTime,
          );
        } catch (slotError, slotStack) {
          logError(
            'Availability check failed for slot ${timeSlot.hour}:${timeSlot.minute.toString().padLeft(2, '0')}',
            tag: 'ClientBookingScreen',
            error: slotError,
            stackTrace: slotStack,
          );
          // Treat as unavailable to avoid double-booking; other slots still get checked
        }
        
        if (isAvailable) {
          availableSlots.add(timeSlot);
        }
      }
      
      if (availableSlots.isEmpty) {
        logInfo(
          'No available time slots for ${_selectedDate!.toString().substring(0, 10)} (dayOfWeek: $dayOfWeek, day had ${dayTimeSlots.length} candidate slots)',
          tag: 'ClientBookingScreen',
        );
      } else {
        logSuccess('Filtered ${availableSlots.length} available time slots', tag: 'ClientBookingScreen');
      }
      
      setState(() {
        _filteredAvailableTimeSlots = availableSlots;
        _isLoadingAvailability = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to filter available time slots', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _filteredAvailableTimeSlots = []; // Fallback to empty if error
        _isLoadingAvailability = false;
      });
    }
  }
  
  /// Helper method to compare TimeOfDay values
  bool _isTimeOfDayBeforeOrEqual(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour) return true;
    if (a.hour > b.hour) return false;
    return a.minute <= b.minute;
  }
  
  // MARK: - Service Filtering
  /// Apply all filters (category and search) to services
  void _applyFilters() {
    List<ServiceModel> filtered = List.from(_services);
    
    // Apply category filter
    if (_selectedCategoryId != null) {
      if (_selectedCategoryId!.isEmpty) {
        // "Other" tab: services with no category (null, empty, or missing categoryId)
        filtered = filtered.where((service) {
          return service.categoryId == null || 
                 service.categoryId!.isEmpty ||
                 // Check if category is inactive or missing
                 !_categories.any((cat) => cat.id == service.categoryId && cat.isActive);
        }).toList();
      } else {
        // Specific category tab
        filtered = filtered.where((service) {
          return service.categoryId == _selectedCategoryId;
        }).toList();
      }
    }
    // If _selectedCategoryId is null, show all services (no category filter)
    
    // Apply search filter
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered.where((service) {
        return service.name.toLowerCase().contains(lowerQuery) ||
            service.description.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    
    setState(() {
      _filteredServices = filtered;
    });
    
    logInfo('Filtered services: ${_filteredServices.length} of ${_services.length} (category: ${_selectedCategoryId ?? "All"}, search: "${searchQuery}")', 
            tag: 'ClientBookingScreen');
  }
  
  /// Filter services based on search query
  void _filterServices(String query) {
    _applyFilters();
  }
  
  /// Select a category tab
  void _selectCategory(String? categoryId) {
    logUI('Category selected: ${categoryId ?? "All"}', tag: 'ClientBookingScreen');
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilters();
  }
  
  // MARK: - Service Selection
  /// Toggle service selection (add/remove from selected list)
  void _toggleServiceSelection(ServiceModel service) {
    setState(() {
      if (_selectedServices.any((s) => s.id == service.id)) {
        _selectedServices.removeWhere((s) => s.id == service.id);
      } else {
        _selectedServices.add(service);
      }
    });
  }
  
  /// Check if service is selected
  bool _isServiceSelected(ServiceModel service) {
    return _selectedServices.any((s) => s.id == service.id);
  }
  
  // MARK: - Step Navigation
  /// Move to next step in booking process
  Future<void> _nextStep() async {
    if (_currentStep == BookingStep.serviceSelection) {
      if (_selectedServices.isEmpty) {
        _showError('Please select at least one service');
        return;
      }
      setState(() {
        _errorMessage = null;
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
      
      // Validate selected time meets advance requirement (same-day: min advance hours; no same-day: 24h)
      final allowSameDay = _businessSettings?.allowSameDayBooking ?? true;
      final minAdvance = allowSameDay
          ? const Duration(hours: AppConstants.minBookingAdvanceHours)
          : const Duration(hours: 24);
      if (_selectedDateTime!.isBefore(DateTime.now().add(minAdvance))) {
        if (allowSameDay) {
          _showError('Please select a time at least ${AppConstants.minBookingAdvanceHours} hours in advance');
        } else {
          _showError('Bookings must be at least 24 hours in advance. Please select another date or time.');
        }
        return;
      }
      
      // Double-check availability before proceeding
      final totalDurationMinutes = _selectedServices.fold<int>(
        0,
        (sum, service) => sum + service.durationMinutes + service.bufferTimeAfterMinutes,
      );
      final endDateTime = _selectedDateTime!.add(Duration(minutes: totalDurationMinutes));
      
      final isAvailable = await _firestoreService.isTimeSlotAvailable(
        _selectedDateTime!,
        endDateTime,
      );
      
      if (!isAvailable) {
        _showError('This time slot is no longer available. Please select a different time.');
        // Refresh available slots
        await _filterAvailableTimeSlots();
        return;
      }
      
      setState(() {
        _errorMessage = null;
        _currentStep = BookingStep.clientInformation;
      });
    } else if (_currentStep == BookingStep.clientInformation) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      
      // Validate compliance forms only when business setting requires them
      if (_businessSettings?.requireComplianceForms != false) {
        // Validate Health & Skin Disclosure: each item must be checked OR have "Not applicable"
        final healthNotApplicable = _isHealthDisclosureItemNotApplicable;
        if (!_hasSkinConditions && !healthNotApplicable(_skinConditionsDetailController.text)) {
          _showError('Health & Skin Disclosure: For "Skin conditions", either check the box or type "Not applicable" below.');
          return;
        }
        if (!_hasAllergies && !healthNotApplicable(_allergiesDetailController.text)) {
          _showError('Health & Skin Disclosure: For "Allergies", either check the box or type "Not applicable" below.');
          return;
        }
        if (!_hasCurrentMedications && !healthNotApplicable(_currentMedicationsDetailController.text)) {
          _showError('Health & Skin Disclosure: For "Current medications", either check the box or type "Not applicable" below.');
          return;
        }
        if (!_isPregnantOrBreastfeeding && !healthNotApplicable(_pregnantOrBreastfeedingDetailController.text)) {
          _showError('Health & Skin Disclosure: For "Pregnancy or breastfeeding", either check the box or type "Not applicable" below.');
          return;
        }
        if (!_hasRecentCosmeticTreatments && !healthNotApplicable(_recentCosmeticTreatmentsDetailController.text)) {
          _showError('Health & Skin Disclosure: For "Recent cosmetic treatments", either check the box or type "Not applicable" below.');
          return;
        }
        if (!_hasKnownReactions && !healthNotApplicable(_knownReactionsDetailController.text)) {
          _showError('Health & Skin Disclosure: For "Known reactions to skincare products", either check the box or type "Not applicable" below.');
          return;
        }
        if (!_termsAccepted) {
          _showError('You must accept the Terms & Conditions to proceed');
          return;
        }
        if (!_understandsResultsNotGuaranteed ||
            !_understandsServicesNonMedical ||
            !_agreesToFollowAftercare ||
            !_acceptsInherentRisks) {
          _showError('You must accept all required acknowledgments to proceed');
          return;
        }
        if (!_cancellationPolicyAcknowledged) {
          _showError('You must check "I understand and agree to the cancellation and no-show policy" to proceed');
          return;
        }
      }
      
      // If payments are enabled, go to payment step
      if (_paymentsEnabled) {
        setState(() {
          _errorMessage = null;
          _currentStep = BookingStep.payment;
        });
        // Initialize payment and create payment intent when entering payment step
        await _initializePaymentForStep();
        _createPaymentIntent();
      } else {
        // If payments are disabled, skip payment step and submit booking directly
        await _submitBooking();
      }
    }
  }
  
  /// Move to previous step
  void _previousStep() {
    if (_currentStep == BookingStep.dateTimeSelection) {
      setState(() {
        _errorMessage = null;
        _currentStep = BookingStep.serviceSelection;
      });
    } else if (_currentStep == BookingStep.clientInformation) {
      setState(() {
        _errorMessage = null;
        _currentStep = BookingStep.dateTimeSelection;
      });
    } else if (_currentStep == BookingStep.payment) {
      setState(() {
        _errorMessage = null;
        _currentStep = BookingStep.clientInformation;
      });
    }
  }
  
  // MARK: - Error Handling
  /// Returns true if the text indicates "Not applicable" (required when checkbox unchecked)
  bool _isHealthDisclosureItemNotApplicable(String text) {
    final t = text.trim().toLowerCase();
    return t == 'not applicable' || t == 'n/a' || t == 'na';
  }

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
  /// Create payment intent when entering payment step
  Future<void> _createPaymentIntent() async {
    if (_selectedServices.isEmpty || _selectedDateTime == null) {
      _showError('Missing booking information');
      return;
    }
    
    try {
      logLoading('Creating payment intent...', tag: 'ClientBookingScreen');
      setState(() {
        _isProcessingPayment = true;
        _errorMessage = null;
      });
      
      // Calculate total amount (deposit after discount + tip)
      final totalDepositCents = _getDepositAfterDiscountCents();
      final totalAmountCents = totalDepositCents + _tipAmountCents;
      
      // Create payment intent for deposit + tip
      _paymentIntent = await _paymentService.createPaymentIntent(
        amountCents: totalAmountCents,
        currency: AppConstants.stripeCurrency,
        customerEmail: _emailController.text.trim(),
        metadata: {
          'bookingType': 'appointment',
          'serviceCount': _selectedServices.length.toString(),
          'depositAmount': totalDepositCents.toString(),
          'tipAmount': _tipAmountCents.toString(),
          if (_appliedCoupon != null) 'couponCode': _appliedCoupon!.code,
        },
      );
      
      logSuccess('Payment intent created successfully', tag: 'ClientBookingScreen');
      
      setState(() {
        _isProcessingPayment = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to create payment intent', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      
      String errorMessage = 'Failed to initialize payment. Please try again.';
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('not configured') || errorString.contains('not found')) {
        errorMessage = 'Payment processing is not configured. Please contact support.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      _showError(errorMessage);
      setState(() {
        _isProcessingPayment = false;
        _currentStep = BookingStep.clientInformation; // Go back to previous step
      });
    }
  }
  
  /// Process Stripe payment and submit booking
  /// Only called when payments are enabled
  Future<void> _processPayment() async {
    if (!_paymentsEnabled) {
      // If payments are disabled, just submit booking without payment
      await _submitBooking();
      return;
    }
    
    if (_paymentIntent == null) {
      _showError('Payment not initialized. Please try again.');
      return;
    }
    
    if (!_paymentFormKey.currentState!.validate()) {
      return;
    }
    
    try {
      logLoading('Processing payment...', tag: 'ClientBookingScreen');
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      
      // Parse card details
      final cardNumber = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
      final expiryMonth = int.tryParse(_expiryMonthController.text) ?? 0;
      final expiryYear = int.tryParse(_expiryYearController.text) ?? 0;
      final cvc = _cvcController.text;
      
      // Validate card details
      if (!_paymentService.validateCardNumber(cardNumber)) {
        throw Exception('Invalid card number');
      }
      if (!_paymentService.validateExpiryDate(expiryMonth, expiryYear)) {
        throw Exception('Invalid expiry date');
      }
      if (!_paymentService.validateCVC(cvc)) {
        throw Exception('Invalid CVC');
      }
      
      // Create billing details
      final billingDetails = BillingDetails(
        name: _cardholderNameController.text.trim().isNotEmpty
            ? _cardholderNameController.text.trim()
            : '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      
      // Create payment method params with card details
      // Note: For web, Stripe Elements should be used for better security
      // This is a simplified implementation
      final paymentMethodParams = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: billingDetails,
        ),
      );
      
      // Confirm payment with payment method
      _paymentIntentId = await _paymentService.confirmPayment(
        paymentIntent: _paymentIntent!,
        paymentMethodParams: paymentMethodParams,
      );
      
      logSuccess('Payment confirmed: $_paymentIntentId', tag: 'ClientBookingScreen');
      
      // Now submit booking with payment intent ID
      await _submitBooking();
    } on StripeException catch (e) {
      logError('Stripe payment failed', tag: 'ClientBookingScreen', error: e);
      _showError('Payment failed: ${e.error?.message ?? 'Please check your card details and try again.'}');
      setState(() {
        _isSubmitting = false;
      });
    } on TimeoutException catch (e) {
      logError('Payment processing timed out', tag: 'ClientBookingScreen', error: e);
      _showError('Request timed out. Please check your connection and try again.');
      setState(() {
        _isSubmitting = false;
        _currentStep = BookingStep.clientInformation;
      });
    } catch (e, stackTrace) {
      logError('Payment processing failed', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      
      String errorMessage = 'Payment processing failed. Please try again.';
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid card')) {
        errorMessage = 'Invalid card details. Please check and try again.';
      } else if (errorString.contains('declined') || errorString.contains('insufficient')) {
        errorMessage = 'Payment was declined. Please use a different payment method.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      _showError(errorMessage);
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  // MARK: - Booking Submission
  /// Submit booking to Firestore
  /// Creates multiple appointments if multiple services are selected
  /// Captures and stores all legal compliance data
  Future<void> _submitBooking() async {
    try {
      logLoading('Submitting booking...', tag: 'ClientBookingScreen');
      
      // Capture device metadata and compliance data only when business requires compliance forms
      final requireCompliance = _businessSettings?.requireComplianceForms != false;
      final deviceMetadata = await DeviceMetadataService.getDeviceMetadata();
      final nowUtc = DateTime.now().toUtc();
      final nowLocal = DateTime.now();
      
      TermsAcceptanceMetadata? termsAcceptanceMetadata;
      HealthDisclosure? healthDisclosure;
      RequiredAcknowledgments? requiredAcknowledgments;
      Map<String, String>? healthDisclosureDetails;
      DateTime? requiredAcknowledgmentsAcceptedAt;
      CancellationPolicySnapshot? cancellationPolicySnapshot;
      bool cancellationPolicyAcknowledged = false;
      
      if (requireCompliance) {
        termsAcceptanceMetadata = TermsAcceptanceMetadata(
          termsAccepted: _termsAccepted,
          termsAcceptedAtUtc: nowUtc,
          termsAcceptedAtLocal: nowLocal,
          ipAddress: deviceMetadata['ipAddress'],
          userAgent: deviceMetadata['userAgent'],
          platform: deviceMetadata['platform'],
          osVersion: deviceMetadata['osVersion'],
        );
        healthDisclosure = HealthDisclosure(
          hasSkinConditions: _hasSkinConditions,
          hasAllergies: _hasAllergies,
          hasCurrentMedications: _hasCurrentMedications,
          isPregnantOrBreastfeeding: _isPregnantOrBreastfeeding,
          hasRecentCosmeticTreatments: _hasRecentCosmeticTreatments,
          hasKnownReactions: _hasKnownReactions,
          additionalNotes: _healthDisclosureNotesController.text.trim().isEmpty
              ? null
              : _healthDisclosureNotesController.text.trim(),
        );
        requiredAcknowledgments = RequiredAcknowledgments(
          understandsResultsNotGuaranteed: _understandsResultsNotGuaranteed,
          understandsServicesNonMedical: _understandsServicesNonMedical,
          agreesToFollowAftercare: _agreesToFollowAftercare,
          acceptsInherentRisks: _acceptsInherentRisks,
        );
        String detailOrNotApplicable(TextEditingController c, bool checked) {
          final t = c.text.trim();
          if (checked) return t.isEmpty ? 'Yes' : t;
          return t.isEmpty ? 'Not applicable' : t;
        }
        healthDisclosureDetails = <String, String>{
          'skinConditions': detailOrNotApplicable(_skinConditionsDetailController, _hasSkinConditions),
          'allergies': detailOrNotApplicable(_allergiesDetailController, _hasAllergies),
          'currentMedications': detailOrNotApplicable(_currentMedicationsDetailController, _hasCurrentMedications),
          'pregnantOrBreastfeeding': detailOrNotApplicable(_pregnantOrBreastfeedingDetailController, _isPregnantOrBreastfeeding),
          'recentCosmeticTreatments': detailOrNotApplicable(_recentCosmeticTreatmentsDetailController, _hasRecentCosmeticTreatments),
          'knownReactions': detailOrNotApplicable(_knownReactionsDetailController, _hasKnownReactions),
        };
        if (_healthDisclosureNotesController.text.trim().isNotEmpty) {
          healthDisclosureDetails['additionalNotes'] = _healthDisclosureNotesController.text.trim();
        }
        requiredAcknowledgmentsAcceptedAt = nowUtc;
        cancellationPolicySnapshot = CancellationPolicySnapshot(
          acknowledged: _cancellationPolicyAcknowledged,
          acknowledgedAt: nowUtc,
          policyVersion: TermsAndConditions.cancellationPolicyVersion,
          policyTextHash: null,
        );
        cancellationPolicyAcknowledged = _cancellationPolicyAcknowledged;
      }
      
      // Total discount for this booking (same value stored on each appointment)
      final bookingDiscountCents = _getDiscountAmountCents();
      final bookingCouponCode = _appliedCoupon?.code;
      
      // Create appointments for each selected service
      // Services will be scheduled sequentially (one after another)
      DateTime currentStartTime = _selectedDateTime!;
      List<String> appointmentIds = [];
      
      for (int i = 0; i < _selectedServices.length; i++) {
        final service = _selectedServices[i];
        
        // Calculate tip per service (if multiple services, split tip proportionally)
        // For simplicity, we'll apply the full tip to the first service
        // In a more complex system, you might want to split it proportionally
        final tipPerService = i == 0 ? _tipAmountCents : 0;
        
        // Create appointment model with legal compliance data
        // If payments are disabled, payment intent ID will be null
        final appointment = AppointmentModel.create(
          serviceId: service.id,
          serviceSnapshot: service,
          clientFirstName: _firstNameController.text.trim(),
          clientLastName: _lastNameController.text.trim(),
          clientEmail: _emailController.text.trim(),
          clientPhone: _phoneController.text.trim(),
          intakeNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          startTime: currentStartTime,
          durationMinutes: service.durationMinutes,
          depositAmountCents: service.depositAmountCents,
          stripePaymentIntentId: _paymentsEnabled ? _paymentIntentId : null, // Only set if payments enabled
          tipAmountCents: _paymentsEnabled ? tipPerService : 0, // Only set tip if payments enabled
          tipPaymentIntentId: (_paymentsEnabled && _tipAmountCents > 0) ? _paymentIntentId : null, // Only set if payments enabled and tip included
          termsAcceptanceMetadata: termsAcceptanceMetadata,
          healthDisclosure: healthDisclosure,
          requiredAcknowledgments: requiredAcknowledgments,
          cancellationPolicyAcknowledged: cancellationPolicyAcknowledged,
          healthDisclosureDetails: healthDisclosureDetails,
          requiredAcknowledgmentsAcceptedAt: requiredAcknowledgmentsAcceptedAt,
          cancellationPolicySnapshot: cancellationPolicySnapshot,
          couponCode: bookingCouponCode,
          discountAmountCents: bookingDiscountCents,
        );
        
        // Create appointment in Firestore
        logInfo('Creating appointment for service: ${service.name} at ${currentStartTime}', tag: 'ClientBookingScreen');
        final appointmentId = await _firestoreService.createAppointment(appointment);
        appointmentIds.add(appointmentId);
        logInfo('Successfully created appointment: $appointmentId', tag: 'ClientBookingScreen');
        
        // Calculate next service start time (current end time + buffer)
        currentStartTime = currentStartTime.add(
          Duration(
            minutes: service.durationMinutes + service.bufferTimeAfterMinutes,
          ),
        );
        
        logInfo('Created appointment $appointmentId for service ${service.name}', tag: 'ClientBookingScreen');
      }
      
      logSuccess('Booking submitted successfully: ${appointmentIds.length} appointment(s) created', tag: 'ClientBookingScreen');
      
      // Increment coupon usage after successful booking
      if (_appliedCoupon != null) {
        try {
          await _firestoreService.incrementCouponUsage(_appliedCoupon!.id);
        } catch (e, stackTrace) {
          logError('Failed to increment coupon usage', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
          // Don't fail the booking if increment fails
        }
      }
      
      // Send confirmation email for the first appointment
      if (appointmentIds.isNotEmpty) {
        try {
          final firstAppointment = await _firestoreService.getAppointmentById(appointmentIds.first);
          if (firstAppointment != null) {
            await _emailService.sendConfirmationEmail(appointment: firstAppointment);
          }
        } catch (e, stackTrace) {
          logError('Failed to send confirmation email', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
          // Don't fail the booking if email fails
        }
      }
      
      // Navigate to confirmation screen with first appointment ID
      // The confirmation screen can be updated later to show all appointments
      if (mounted && appointmentIds.isNotEmpty) {
        context.go('${AppConstants.routeClientConfirmation}/${appointmentIds.first}');
      }
    } catch (e, stackTrace) {
      logError('Failed to submit booking', tag: 'ClientBookingScreen', error: e, stackTrace: stackTrace);
      
      // Provide more specific error message
      String errorMessage = 'Failed to submit booking. Please try again.';
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        errorMessage = 'Permission denied. Please check your connection and try again.';
      } else if (e.toString().contains('already booked') || e.toString().contains('overlapping')) {
        errorMessage = 'This time slot is no longer available. Please select a different time.';
      } else if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      _showError(errorMessage);
      setState(() {
        _isSubmitting = false;
        _currentStep = BookingStep.clientInformation; // Reset to previous step on error
      });
    }
  }
  
  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building ClientBookingScreen widget', tag: 'ClientBookingScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        elevation: 0,
        leading: _currentStep != BookingStep.serviceSelection
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              logInfo('Appointments button tapped', tag: 'ClientBookingScreen');
              context.push(AppConstants.routeClientAppointments);
            },
            tooltip: 'My Appointments',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              logInfo('Settings button tapped', tag: 'ClientBookingScreen');
              context.push(AppConstants.routeSettings);
            },
            tooltip: 'Settings',
          ),
        ],
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
            if (_currentStep == BookingStep.payment)
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
                      onPressed: _isSubmitting ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sunflowerYellow,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                              ),
                            )
                          : Text(
                              'Pay & Complete Booking',
                              style: AppTypography.buttonText.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              )
            else if (_currentStep != BookingStep.payment)
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
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
              logInfo('Admin switching back to admin view', tag: 'ClientBookingScreen');
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

  // MARK: - Progress Indicator
  /// Build progress indicator showing current step
  Widget _buildProgressIndicator() {
    // Only show payment step if payments are enabled
    final steps = _paymentsEnabled
        ? [
            'Service',
            'Date & Time',
            'Information',
            'Payment',
          ]
        : [
            'Service',
            'Date & Time',
            'Information',
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
          // Map current step index to progress indicator index
          // When payments disabled, clamp step index to max 2 (Information step)
          final currentStepIndex = _paymentsEnabled
              ? _currentStep.index
              : (_currentStep.index > 2 ? 2 : _currentStep.index);
          final isActive = index <= currentStepIndex;
          final isCurrent = index == currentStepIndex;
          
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
                              : context.themeSecondaryTextColor.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: isActive
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: context.themePrimaryTextColor,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isCurrent
                                        ? context.themePrimaryTextColor
                                        : context.themeSecondaryTextColor,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step,
                        style: AppTypography.bodySmall.copyWith(
                          color: isActive
                              ? context.themePrimaryTextColor
                              : context.themeSecondaryTextColor,
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
                        : context.themeSecondaryTextColor.withValues(alpha: 0.2),
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
              color: context.themeSecondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No services available',
              style: AppTypography.titleMedium.copyWith(
                color: context.themeSecondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themeSecondaryTextColor,
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
          'Select Service(s)',
          style: AppTypography.headlineSmall.copyWith(
            color: context.themePrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose one or more services to book',
          style: AppTypography.bodyMedium.copyWith(
            color: context.themeSecondaryTextColor,
          ),
        ),
        const SizedBox(height: 24),
        
        // Category Tabs
        _buildCategoryTabs(),
        const SizedBox(height: 16),
        
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search services...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterServices('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: _filterServices,
        ),
        const SizedBox(height: 16),
        
        // Selected Services Count
        if (_selectedServices.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sunflowerYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(
                color: AppColors.sunflowerYellow.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.sunflowerYellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedServices.length} service${_selectedServices.length > 1 ? 's' : ''} selected',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.themePrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Service List
        if (_filteredServices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: context.themeSecondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services found',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._filteredServices.map((service) => _buildServiceCard(service)),
      ],
    );
  }
  
  // MARK: - Category Tabs Builder
  /// Build category tabs/chips for filtering services
  Widget _buildCategoryTabs() {
    // Build list of category tabs: "All", then each active category, then "Other"
    final tabs = <_CategoryTab>[];
    
    // "All" tab
    tabs.add(_CategoryTab(
      id: null,
      name: 'All',
      count: _services.length,
    ));
    
    // Active category tabs
    for (final category in _categories) {
      final count = _services.where((s) => s.categoryId == category.id).length;
      if (count > 0) {
        tabs.add(_CategoryTab(
          id: category.id,
          name: category.name,
          count: count,
        ));
      }
    }
    
    // "Other" tab (uncategorized services)
    final uncategorizedCount = _services.where((s) {
      return s.categoryId == null || 
             s.categoryId!.isEmpty ||
             !_categories.any((cat) => cat.id == s.categoryId && cat.isActive);
    }).length;
    
    if (uncategorizedCount > 0) {
      tabs.add(_CategoryTab(
        id: '',
        name: 'Other',
        count: uncategorizedCount,
      ));
    }
    
    // Don't show tabs if there's only "All" or no categories
    if (tabs.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedCategoryId == tab.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${tab.name} (${tab.count})'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _selectCategory(tab.id);
                }
              },
              selectedColor: AppColors.sunflowerYellow,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: AppTypography.bodyMedium.copyWith(
                color: isSelected ? context.themePrimaryTextColor : context.themePrimaryTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// Build individual service card
  Widget _buildServiceCard(ServiceModel service) {
    final isSelected = _isServiceSelected(service);
    final isDescriptionExpanded = _expandedDescriptions.contains(service.id);
    
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
          _toggleServiceSelection(service);
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Indicator (Checkbox)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sunflowerYellow
                        : context.themeSecondaryTextColor,
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
                        color: context.themePrimaryTextColor,
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
                        color: context.themePrimaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description with expand/collapse functionality
                    _buildServiceDescription(service, isDescriptionExpanded),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: context.themeSecondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationMinutes} min',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.themeSecondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          service.formattedPrice,
                          style: AppTypography.titleSmall.copyWith(
                            color: context.themePrimaryTextColor,
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
  
  // MARK: - Service Description Builder
  /// Build service description with "View more" / "View less" toggle
  /// Uses LayoutBuilder to measure if text exceeds 2 lines and shows toggle accordingly
  Widget _buildServiceDescription(ServiceModel service, bool isExpanded) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure if text exceeds 2 lines at the available width
        final textPainter = TextPainter(
          text: TextSpan(
            text: service.description,
            style: AppTypography.bodySmall.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);
        final needsExpansion = textPainter.didExceedMaxLines;
        
        // If description is short, just show it without toggle
        if (!needsExpansion) {
          return Text(
            service.description,
            style: AppTypography.bodySmall.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          );
        }
        
        // Description is long, show with expand/collapse
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.description,
              style: AppTypography.bodySmall.copyWith(
                color: context.themeSecondaryTextColor,
              ),
              maxLines: isExpanded ? null : 2,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedDescriptions.remove(service.id);
                  } else {
                    _expandedDescriptions.add(service.id);
                  }
                });
                logUI('Toggled description expansion for service ${service.id}', tag: 'ClientBookingScreen');
              },
              child: Text(
                isExpanded ? 'View less' : 'View more',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.sunflowerYellow,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      },
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
            color: context.themePrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred appointment date and time',
          style: AppTypography.bodyMedium.copyWith(
            color: context.themeSecondaryTextColor,
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
              // Filter available time slots when date changes
              _filterAvailableTimeSlots();
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
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            enabledDayPredicate: (day) {
              // Disable past dates and dates too far in advance. When same-day disabled, first selectable day is 24h from now.
              final now = DateTime.now();
              final allowSameDay = _businessSettings?.allowSameDayBooking ?? true;
              final DateTime minSelectableDate;
              if (allowSameDay) {
                final minDate = now.add(const Duration(hours: AppConstants.minBookingAdvanceHours));
                minSelectableDate = minDate.subtract(const Duration(days: 1));
                // Allow day > minDate - 1 day (i.e. today and future when today has slots 2h+ from now)
                return day.isAfter(minSelectableDate) &&
                    day.isBefore(_lastDay.add(const Duration(days: 1)));
              } else {
                final nowPlus24 = now.add(const Duration(hours: 24));
                minSelectableDate = DateTime(nowPlus24.year, nowPlus24.month, nowPlus24.day).subtract(const Duration(days: 1));
                return day.isAfter(minSelectableDate) &&
                    day.isBefore(_lastDay.add(const Duration(days: 1)));
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        
        // Time Selection
        if (_selectedDate != null) ...[
          Text(
            'Select Time',
            style: AppTypography.titleMedium.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingAvailability)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredAvailableTimeSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.errorRed, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No available time slots for this date. Please select a different date.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _filteredAvailableTimeSlots.map((time) {
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
                          ? context.themePrimaryTextColor
                          : context.themePrimaryTextColor,
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
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your contact information',
            style: AppTypography.bodyMedium.copyWith(
              color: context.themeSecondaryTextColor,
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
          
          // MARK: - Coupon Section (only when admin has created at least one active coupon)
          if (_hasActiveCoupons) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sunflowerYellow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              border: Border.all(color: AppColors.sunflowerYellow.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coupon Code',
                  style: AppTypography.titleSmall.copyWith(
                    color: context.themePrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _couponCodeController,
                        decoration: InputDecoration(
                          hintText: 'Enter code',
                          prefixIcon: const Icon(Icons.local_offer_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          ),
                          errorText: _couponErrorMessage,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) {
                          if (_couponErrorMessage != null) {
                            setState(() => _couponErrorMessage = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_appliedCoupon == null)
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isValidatingCoupon
                              ? null
                              : () async {
                                  final code = _couponCodeController.text.trim();
                                  if (code.isEmpty) {
                                    setState(() => _couponErrorMessage = 'Enter a coupon code');
                                    return;
                                  }
                                  setState(() {
                                    _couponErrorMessage = null;
                                    _isValidatingCoupon = true;
                                  });
                                  try {
                                    final coupon = await _firestoreService.validateCoupon(code);
                                    if (mounted) {
                                      setState(() {
                                        _appliedCoupon = coupon;
                                        _isValidatingCoupon = false;
                                        _paymentIntent = null;
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _couponErrorMessage = e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Invalid coupon';
                                        _isValidatingCoupon = false;
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunflowerYellow,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: _isValidatingCoupon
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Apply'),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.sunflowerYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _appliedCoupon!.code,
                              style: AppTypography.bodyMedium.copyWith(
                                color: context.themePrimaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _appliedCoupon = null;
                                _couponCodeController.clear();
                                _couponErrorMessage = null;
                                _paymentIntent = null;
                              });
                            },
                            child: Text('Remove', style: TextStyle(color: AppColors.errorRed)),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_appliedCoupon != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_appliedCoupon!.discountDescription} applied',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.sunflowerYellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          ],
          
          // MARK: - Compliance Forms (only when business setting requires them)
          if (_businessSettings?.requireComplianceForms != false) ...[
            _buildHealthDisclosureSection(),
            const SizedBox(height: 32),
            _buildRequiredAcknowledgmentsSection(),
            const SizedBox(height: 32),
            _buildTermsAndConditionsSection(),
            const SizedBox(height: 32),
            _buildCancellationPolicySection(),
            const SizedBox(height: 24),
          ],
          
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
                    color: context.themePrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Selected Services
                if (_selectedServices.length == 1)
                  _buildSummaryRow('Service', _selectedServices.first.name)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services (${_selectedServices.length})',
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.themeSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._selectedServices.map((service) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Text(
                          '• ${service.name}',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.themePrimaryTextColor,
                          ),
                        ),
                      )),
                    ],
                  ),
                const SizedBox(height: 8),
                _buildSummaryRow('Date', _selectedDate != null
                    ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                    : ''),
                _buildSummaryRow('Time', _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : ''),
                _buildSummaryRow(
                  'Total Duration',
                  '${_selectedServices.fold<int>(0, (sum, s) => sum + s.durationMinutes)} minutes',
                ),
                const Divider(),
                if (_paymentsEnabled) ...[
                  _buildSummaryRow(
                    'Deposit',
                    '\$${(_getTotalDepositCents() / 100).toStringAsFixed(2)}',
                  ),
                  if (_getDiscountAmountCents() > 0)
                    _buildSummaryRow(
                      'Discount',
                      '-\$${(_getDiscountAmountCents() / 100).toStringAsFixed(2)}',
                    ),
                  if (_tipAmountCents > 0)
                    _buildSummaryRow(
                      'Tip',
                      '\$${(_tipAmountCents / 100).toStringAsFixed(2)}',
                    ),
                  _buildSummaryRow(
                    'Total Amount',
                    '\$${((_getDepositAfterDiscountCents() + _tipAmountCents) / 100).toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ] else ...[
                  // Show actual service price when payment not required
                  _buildSummaryRow(
                    'Service Price',
                    '\$${(_selectedServices.fold<int>(0, (sum, s) => sum + s.priceCents) / 100).toStringAsFixed(2)}',
                  ),
                  if (_getDiscountAmountCents() > 0)
                    _buildSummaryRow(
                      'Discount',
                      '-\$${(_getDiscountAmountCents() / 100).toStringAsFixed(2)}',
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppColors.sunflowerYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.sunflowerYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.sunflowerYellow,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment not required at this time. You can pay when you arrive.',
                            style: AppTypography.bodySmall.copyWith(
                              color: context.themePrimaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              color: context.themeSecondaryTextColor,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  
  // MARK: - Health Disclosure Section
  /// Build health disclosure section with checkboxes
  Widget _buildHealthDisclosureSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.shadowColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health & Skin Disclosure (required)',
            style: AppTypography.titleLarge.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For each item: check the box if it applies to you, or type "Not applicable" in the field below.',
            style: AppTypography.bodySmall.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildHealthCheckbox(
            'Skin conditions (acne, rosacea, eczema, psoriasis)',
            _hasSkinConditions,
            (value) => setState(() => _hasSkinConditions = value ?? false),
          ),
          _buildHealthDisclosureDetailField(_skinConditionsDetailController, _hasSkinConditions),
          const SizedBox(height: 12),
          _buildHealthCheckbox(
            'Allergies or sensitivities',
            _hasAllergies,
            (value) => setState(() => _hasAllergies = value ?? false),
          ),
          _buildHealthDisclosureDetailField(_allergiesDetailController, _hasAllergies),
          const SizedBox(height: 12),
          _buildHealthCheckbox(
            'Current medications (topical or oral)',
            _hasCurrentMedications,
            (value) => setState(() => _hasCurrentMedications = value ?? false),
          ),
          _buildHealthDisclosureDetailField(_currentMedicationsDetailController, _hasCurrentMedications),
          const SizedBox(height: 12),
          _buildHealthCheckbox(
            'Pregnancy or breastfeeding',
            _isPregnantOrBreastfeeding,
            (value) => setState(() => _isPregnantOrBreastfeeding = value ?? false),
          ),
          _buildHealthDisclosureDetailField(_pregnantOrBreastfeedingDetailController, _isPregnantOrBreastfeeding),
          const SizedBox(height: 12),
          _buildHealthCheckbox(
            'Recent cosmetic treatments (peels, injectables, laser)',
            _hasRecentCosmeticTreatments,
            (value) => setState(() => _hasRecentCosmeticTreatments = value ?? false),
          ),
          _buildHealthDisclosureDetailField(_recentCosmeticTreatmentsDetailController, _hasRecentCosmeticTreatments),
          const SizedBox(height: 12),
          _buildHealthCheckbox(
            'Known reactions to skincare products',
            _hasKnownReactions,
            (value) => setState(() => _hasKnownReactions = value ?? false),
          ),
          _buildHealthDisclosureDetailField(_knownReactionsDetailController, _hasKnownReactions),
          const SizedBox(height: 16),
          TextFormField(
            controller: _healthDisclosureNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Please provide any additional health information...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            maxLength: 500,
          ),
        ],
      ),
    );
  }
  
  /// Build health disclosure checkbox
  Widget _buildHealthCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: context.themePrimaryTextColor,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.sunflowerYellow,
      checkColor: Theme.of(context).colorScheme.onPrimary,
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Build required detail field: when unchecked user must type "Not applicable"; when checked optional details
  Widget _buildHealthDisclosureDetailField(TextEditingController controller, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: isChecked ? 'Optional: add details' : "Required: type 'Not applicable' if this does not apply",
          hintStyle: TextStyle(
            fontSize: 12,
            color: isChecked ? context.themeSecondaryTextColor : AppColors.errorRed.withOpacity(0.8),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        maxLength: 200,
      ),
    );
  }
  
  // MARK: - Required Acknowledgments Section
  /// Build required acknowledgments section
  Widget _buildRequiredAcknowledgmentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.shadowColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Acknowledgments (required)',
            style: AppTypography.titleLarge.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You must check all four acknowledgments below to proceed.',
            style: AppTypography.bodySmall.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildAcknowledgmentCheckbox(
            'I understand results are not guaranteed',
            _understandsResultsNotGuaranteed,
            (value) => setState(() => _understandsResultsNotGuaranteed = value ?? false),
          ),
          const SizedBox(height: 12),
          _buildAcknowledgmentCheckbox(
            'I understand services are non-medical',
            _understandsServicesNonMedical,
            (value) => setState(() => _understandsServicesNonMedical = value ?? false),
          ),
          const SizedBox(height: 12),
          _buildAcknowledgmentCheckbox(
            'I agree to follow aftercare instructions',
            _agreesToFollowAftercare,
            (value) => setState(() => _agreesToFollowAftercare = value ?? false),
          ),
          const SizedBox(height: 12),
          _buildAcknowledgmentCheckbox(
            'I accept the inherent risks of esthetic services',
            _acceptsInherentRisks,
            (value) => setState(() => _acceptsInherentRisks = value ?? false),
          ),
        ],
      ),
    );
  }
  
  /// Build acknowledgment checkbox
  Widget _buildAcknowledgmentCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: context.themePrimaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.sunflowerYellow,
      checkColor: Theme.of(context).colorScheme.onPrimary,
      contentPadding: EdgeInsets.zero,
    );
  }
  
  // MARK: - Terms & Conditions Section
  /// Build Terms & Conditions acceptance section
  Widget _buildTermsAndConditionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: _termsAccepted ? AppColors.sunflowerYellow : AppColors.errorRed,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terms & Conditions',
                  style: AppTypography.titleLarge.copyWith(
                    color: context.themePrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showTermsModal = true;
                  });
                  _showTermsAndConditionsDialog();
                },
                child: Text(
                  'View Full Terms',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.sunflowerYellow,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: Text(
              TermsAndConditions.consentText,
              style: AppTypography.bodyMedium.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            activeColor: AppColors.sunflowerYellow,
            checkColor: Theme.of(context).colorScheme.onPrimary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (!_termsAccepted)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: Text(
                'You must accept the Terms & Conditions to proceed',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Show Terms & Conditions dialog
  void _showTermsAndConditionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
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
                        'Terms & Conditions',
                        style: AppTypography.titleLarge.copyWith(
                          color: context.themePrimaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _showTermsModal = false;
                        });
                      },
                      color: context.themePrimaryTextColor,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    TermsAndConditions.fullText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.themePrimaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.shadowColor),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _showTermsModal = false;
                        _termsAccepted = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunflowerYellow,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'I Accept',
                      style: AppTypography.buttonText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // MARK: - Cancellation Policy Section
  /// Build cancellation policy acknowledgment section
  Widget _buildCancellationPolicySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.shadowColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation & No-Show Policy (required)',
            style: AppTypography.titleSmall.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: Text(
              'I understand and agree to the cancellation and no-show policy',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Cancellations must be made at least 24 hours in advance. No-shows may result in forfeiture of deposit.',
                style: AppTypography.bodySmall,
              ),
            ),
            value: _cancellationPolicyAcknowledged,
            onChanged: (value) {
              setState(() {
                _cancellationPolicyAcknowledged = value ?? false;
              });
            },
            activeColor: AppColors.sunflowerYellow,
            checkColor: Theme.of(context).colorScheme.onPrimary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
  
  // MARK: - Payment Processing
  /// Build payment processing UI with card input form
  Widget _buildPaymentProcessing() {
    if (_isProcessingPayment) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Initializing Payment...',
              style: AppTypography.titleLarge.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we set up your payment',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themeSecondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_paymentIntent == null) {
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
              'Payment Not Available',
              style: AppTypography.titleLarge.copyWith(
                color: context.themePrimaryTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to initialize payment. Please try again.',
              style: AppTypography.bodyMedium.copyWith(
                color: context.themeSecondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = BookingStep.clientInformation;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }
    
    // Total deposit after coupon discount
    final totalDepositCents = _getDepositAfterDiscountCents();
    final totalDeposit = _paymentService.formatAmount(totalDepositCents, AppConstants.stripeCurrency);
    
    return Form(
      key: _paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: AppTypography.headlineSmall.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please enter your payment details to complete your booking',
            style: AppTypography.bodyMedium.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Total Deposit Display
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getDiscountAmountCents() > 0 ? 'Deposit (after discount)' : 'Deposit Required',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.themeSecondaryTextColor,
                      ),
                    ),
                    Text(
                      totalDeposit,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.themePrimaryTextColor,
                      ),
                    ),
                  ],
                ),
                if (_getDiscountAmountCents() > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coupon (${_appliedCoupon?.code ?? ''})',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.themeSecondaryTextColor,
                        ),
                      ),
                      Text(
                        '-\$${(_getDiscountAmountCents() / 100).toStringAsFixed(2)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.sunflowerYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_tipAmountCents > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tip',
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.themeSecondaryTextColor,
                        ),
                      ),
                      Text(
                        _paymentService.formatAmount(_tipAmountCents, AppConstants.stripeCurrency),
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.themePrimaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTypography.titleMedium.copyWith(
                        color: context.themePrimaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _paymentService.formatAmount(totalDepositCents + _tipAmountCents, AppConstants.stripeCurrency),
                      style: AppTypography.titleLarge.copyWith(
                        color: context.themePrimaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tip Section
          Text(
            'Add a Tip (Optional)',
            style: AppTypography.titleMedium.copyWith(
              color: context.themePrimaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show your appreciation with a tip',
            style: AppTypography.bodySmall.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Tip Buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _quickTipOptions.map((tipCents) {
              final isSelected = _tipAmountCents == tipCents;
              return InkWell(
                onTap: () {
                  setState(() {
                    _tipAmountCents = isSelected ? 0 : tipCents;
                    _tipAmountController.text = isSelected ? '' : (tipCents / 100).toStringAsFixed(2);
                    _paymentIntent = null; // Reset payment intent to recreate with new amount
                  });
                  // Recreate payment intent with new tip amount
                  _createPaymentIntent();
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
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '\$${(tipCents / 100).toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? context.themePrimaryTextColor
                          : context.themePrimaryTextColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Custom Tip Input
          TextFormField(
            controller: _tipAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Custom Tip Amount (\$)',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              hintText: '0.00',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _tipAmountCents = 0;
                        _paymentIntent = null; // Reset payment intent to recreate with new amount
                      });
                      return;
                    }
                    final tipDollars = double.tryParse(value) ?? 0.0;
                    final newTipCents = (tipDollars * 100).round();
                    if (newTipCents != _tipAmountCents) {
                      setState(() {
                        _tipAmountCents = newTipCents;
                        _paymentIntent = null; // Reset payment intent to recreate with new amount
                      });
                      // Recreate payment intent with new tip amount (async, don't await)
                      if (_paymentIntent == null) {
                        _createPaymentIntent();
                      }
                    }
                  },
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final tipDollars = double.tryParse(value);
                if (tipDollars == null || tipDollars < 0) {
                  return 'Please enter a valid tip amount';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Cardholder Name
          TextFormField(
            controller: _cardholderNameController,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Card Number',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              hintText: '1234 5678 9012 3456',
            ),
            maxLength: 19,
            inputFormatters: [
              // Format as: XXXX XXXX XXXX XXXX
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter card number';
              }
              final cleaned = value.replaceAll(RegExp(r'\D'), '');
              if (!_paymentService.validateCardNumber(cleaned)) {
                return 'Invalid card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Expiry Date and CVC Row
          Row(
            children: [
              // Expiry Month
              Expanded(
                child: TextFormField(
                  controller: _expiryMonthController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Month (MM)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    hintText: '12',
                  ),
                  maxLength: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'MM';
                    }
                    final month = int.tryParse(value);
                    if (month == null || month < 1 || month > 12) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Expiry Year
              Expanded(
                child: TextFormField(
                  controller: _expiryYearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Year (YYYY)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    hintText: '2026',
                  ),
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'YYYY';
                    }
                    final year = int.tryParse(value);
                    if (year == null || year < DateTime.now().year) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // CVC
              Expanded(
                child: TextFormField(
                  controller: _cvcController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CVC',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    hintText: '123',
                  ),
                  maxLength: 4,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'CVC';
                    }
                    if (!_paymentService.validateCVC(value)) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Security Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sunflowerYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  color: AppColors.sunflowerYellow,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment is secured by Stripe. We never store your card details.',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                ),
              ],
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
        return _paymentsEnabled ? 'Proceed to Payment' : 'Complete Booking';
      default:
        return 'Continue';
    }
  }
}

// MARK: - Category Tab Helper Class
/// Helper class for category tab data
class _CategoryTab {
  final String? id; // null = "All", empty string = "Other"
  final String name;
  final int count;
  
  _CategoryTab({
    required this.id,
    required this.name,
    required this.count,
  });
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
