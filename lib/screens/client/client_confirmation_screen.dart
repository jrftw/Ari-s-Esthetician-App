/*
 * Filename: client_confirmation_screen.dart
 * Purpose: Appointment confirmation screen after successful booking
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: Flutter, models, services, go_router, intl
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../core/logging/app_logger.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';

// MARK: - Client Confirmation Screen
/// Screen displayed after successful appointment booking
/// Shows appointment details and provides calendar add option
class ClientConfirmationScreen extends StatefulWidget {
  final String appointmentId;

  const ClientConfirmationScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<ClientConfirmationScreen> createState() => _ClientConfirmationScreenState();
}

// MARK: - Client Confirmation Screen State
class _ClientConfirmationScreenState extends State<ClientConfirmationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PaymentService _paymentService = PaymentService();
  AppointmentModel? _appointment;
  bool _isLoading = true;
  String? _errorMessage;
  
  // MARK: - Post-Appointment Tip State
  bool _showTipDialog = false;
  int _postTipAmountCents = 0;
  final TextEditingController _postTipAmountController = TextEditingController();
  final List<int> _quickTipOptions = [500, 1000, 1500, 2000, 2500, 5000]; // $5, $10, $15, $20, $25, $50
  bool _isProcessingTip = false;
  
  // MARK: - Payment Form Controllers for Tip
  final _tipCardNumberController = TextEditingController();
  final _tipExpiryMonthController = TextEditingController();
  final _tipExpiryYearController = TextEditingController();
  final _tipCvcController = TextEditingController();
  final _tipCardholderNameController = TextEditingController();
  final _tipFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    logUI('ClientConfirmationScreen initState called', tag: 'ClientConfirmationScreen');
    _loadAppointment();
  }

  // MARK: - Load Appointment
  /// Load appointment details from Firestore
  Future<void> _loadAppointment() async {
    try {
      logLoading('Loading appointment: ${widget.appointmentId}', tag: 'ClientConfirmationScreen');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final appointment = await _firestoreService.getAppointmentById(widget.appointmentId);
      
      if (appointment == null) {
        throw Exception('Appointment not found');
      }

      logSuccess('Appointment loaded successfully', tag: 'ClientConfirmationScreen');
      
      setState(() {
        _appointment = appointment;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to load appointment', tag: 'ClientConfirmationScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load appointment details.';
      });
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building ClientConfirmationScreen widget', tag: 'ClientConfirmationScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: AppColors.sunflowerYellow,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _appointment != null
                    ? _buildConfirmationContent()
                    : _buildErrorState(),
      ),
    );
  }

  // MARK: - Error State
  /// Build error state UI
  Widget _buildErrorState() {
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
              _errorMessage ?? 'Something went wrong',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.darkBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeClientBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: AppColors.darkBrown,
              ),
              child: const Text('Back to Booking'),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Confirmation Content
  /// Build confirmation content with appointment details
  Widget _buildConfirmationContent() {
    final appointment = _appointment!;
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sunflowerYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 48,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Success Message
          Center(
            child: Text(
              'Booking Confirmed!',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Your appointment has been successfully booked',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Appointment Details Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Details',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Service
                _buildDetailRow(
                  icon: Icons.spa,
                  label: 'Service',
                  value: appointment.serviceSnapshot?.name ?? 'Service',
                ),
                const SizedBox(height: 16),
                
                // Date
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: dateFormat.format(appointment.startTime),
                ),
                const SizedBox(height: 16),
                
                // Time
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: timeFormat.format(appointment.startTime),
                ),
                const SizedBox(height: 16),
                
                // Duration
                _buildDetailRow(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: appointment.serviceSnapshot != null
                      ? '${appointment.serviceSnapshot!.durationMinutes} minutes'
                      : 'N/A',
                ),
                const SizedBox(height: 16),
                
                // Client Name
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: appointment.clientFullName,
                ),
                const SizedBox(height: 16),
                
                // Email
                _buildDetailRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: appointment.clientEmail,
                ),
                const SizedBox(height: 16),
                
                // Phone
                _buildDetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: appointment.clientPhone,
                ),
                const Divider(height: 32),
                
                // Payment Information (only show if payment was made)
                if (appointment.stripePaymentIntentId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sunflowerYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Deposit Paid',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              appointment.formattedDeposit,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.darkBrown,
                              ),
                            ),
                          ],
                        ),
                        if (appointment.tipAmountCents > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tip (Pre-appointment)',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                appointment.formattedPreTip,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (appointment.postAppointmentTipAmountCents != null && appointment.postAppointmentTipAmountCents! > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tip (Post-appointment)',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                appointment.formattedPostTip,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.darkBrown,
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
                              'Total Paid',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${((appointment.depositAmountCents + appointment.totalTipAmountCents) / 100).toStringAsFixed(2)}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // No payment made - show pricing info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sunflowerYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.sunflowerYellow.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service Price',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              appointment.formattedDeposit,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.darkBrown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
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
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Info Card
          Container(
            width: double.infinity,
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
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.sunflowerYellow,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'What\'s Next?',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• You will receive a confirmation email shortly\n'
                  '• A reminder will be sent 24 hours before your appointment\n'
                  '• Please arrive 10 minutes early for your appointment',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Add Tip Button (if appointment is completed or past)
          if (appointment.isPast || appointment.status == AppointmentStatus.completed)
            SizedBox(
              width: double.infinity,
              height: AppConstants.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () => _showAddTipDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkBrown,
                  side: BorderSide(color: AppColors.sunflowerYellow, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                ),
                icon: const Icon(Icons.volunteer_activism),
                label: Text(
                  appointment.postAppointmentTipAmountCents != null && appointment.postAppointmentTipAmountCents! > 0
                      ? 'Update Tip'
                      : 'Add a Tip',
                  style: AppTypography.buttonText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (appointment.isPast || appointment.status == AppointmentStatus.completed)
            const SizedBox(height: 12),
          
          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: () => context.go(AppConstants.routeClientBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: AppColors.darkBrown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              child: Text(
                'Book Another Appointment',
                style: AppTypography.buttonText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: OutlinedButton(
              onPressed: () => context.go(AppConstants.routeWelcome),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkBrown,
                side: BorderSide(color: AppColors.sunflowerYellow, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              child: Text(
                'Back to Home',
                style: AppTypography.buttonText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Detail Row
  /// Build detail row with icon, label, and value
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MARK: - Post-Appointment Tip
  /// Show dialog to add tip after appointment
  Future<void> _showAddTipDialog() async {
    _postTipAmountCents = _appointment?.postAppointmentTipAmountCents ?? 0;
    if (_postTipAmountCents > 0) {
      _postTipAmountController.text = (_postTipAmountCents / 100).toStringAsFixed(2);
    }
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add a Tip',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _tipFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show your appreciation with a tip',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quick Tip Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _quickTipOptions.map((tipCents) {
                    final isSelected = _postTipAmountCents == tipCents;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _postTipAmountCents = isSelected ? 0 : tipCents;
                          _postTipAmountController.text = isSelected ? '' : (tipCents / 100).toStringAsFixed(2);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                ? AppColors.darkBrown
                                : AppColors.textPrimary,
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
                  controller: _postTipAmountController,
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
                        _postTipAmountCents = 0;
                      });
                      return;
                    }
                    final tipDollars = double.tryParse(value) ?? 0.0;
                    setState(() {
                      _postTipAmountCents = (tipDollars * 100).round();
                    });
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
                
                // Card Input Section
                Text(
                  'Payment Information',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Cardholder Name
                TextFormField(
                  controller: _tipCardholderNameController,
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
                const SizedBox(height: 12),
                
                // Card Number
                TextFormField(
                  controller: _tipCardNumberController,
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
                const SizedBox(height: 12),
                
                // Expiry and CVC Row
                Row(
                  children: [
                    // Expiry Month
                    Expanded(
                      child: TextFormField(
                        controller: _tipExpiryMonthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Month (MM)',
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
                        controller: _tipExpiryYearController,
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
                        controller: _tipCvcController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'CVC',
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isProcessingTip ? null : () => _processPostAppointmentTip(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sunflowerYellow,
              foregroundColor: AppColors.darkBrown,
            ),
            child: _isProcessingTip
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBrown),
                    ),
                  )
                : Text(
                    'Add Tip',
                    style: AppTypography.buttonText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Process post-appointment tip payment
  Future<void> _processPostAppointmentTip() async {
    if (_postTipAmountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a tip amount'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    
    if (!_tipFormKey.currentState!.validate()) {
      return;
    }
    
    try {
      setState(() {
        _isProcessingTip = true;
      });
      
      logLoading('Processing post-appointment tip...', tag: 'ClientConfirmationScreen');
      
      // Parse card details
      final cardNumber = _tipCardNumberController.text.replaceAll(RegExp(r'\D'), '');
      final expiryMonth = int.tryParse(_tipExpiryMonthController.text) ?? 0;
      final expiryYear = int.tryParse(_tipExpiryYearController.text) ?? 0;
      final cvc = _tipCvcController.text;
      
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
        name: _tipCardholderNameController.text.trim().isNotEmpty
            ? _tipCardholderNameController.text.trim()
            : _appointment!.clientFullName,
        email: _appointment!.clientEmail,
        phone: _appointment!.clientPhone,
      );
      
      // Process tip payment
      final tipPaymentIntentId = await _paymentService.processPostAppointmentTip(
        tipAmountCents: _postTipAmountCents,
        currency: AppConstants.stripeCurrency,
        appointmentId: _appointment!.id,
        paymentMethodParams: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );
      
      // Update appointment with tip
      await _firestoreService.updateAppointment(
        _appointment!.copyWith(
          postAppointmentTipAmountCents: _postTipAmountCents,
          postAppointmentTipPaymentIntentId: tipPaymentIntentId,
        ),
      );
      
      // Reload appointment
      await _loadAppointment();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip of ${_paymentService.formatAmount(_postTipAmountCents, AppConstants.stripeCurrency)} added successfully!'),
            backgroundColor: AppColors.sunflowerYellow,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      logSuccess('Post-appointment tip processed successfully', tag: 'ClientConfirmationScreen');
    } on StripeException catch (e) {
      logError('Stripe tip payment failed', tag: 'ClientConfirmationScreen', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip payment failed: ${e.error?.message ?? 'Please check your card details and try again.'}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e, stackTrace) {
      logError('Failed to process post-appointment tip', tag: 'ClientConfirmationScreen', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process tip: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingTip = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _postTipAmountController.dispose();
    _tipCardNumberController.dispose();
    _tipExpiryMonthController.dispose();
    _tipExpiryYearController.dispose();
    _tipCvcController.dispose();
    _tipCardholderNameController.dispose();
    super.dispose();
  }
}

// Suggestions For Features and Additions Later:
// - Add "Add to Calendar" functionality (Google Calendar, iCal)
// - Add email confirmation resend option
// - Add appointment cancellation option
// - Add appointment rescheduling option
// - Add receipt download
// - Add appointment QR code
// - Add directions to location
// - Add contact information
