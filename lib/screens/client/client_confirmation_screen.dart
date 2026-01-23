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
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';

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
  AppointmentModel? _appointment;
  bool _isLoading = true;
  String? _errorMessage;

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
      backgroundColor: AppColors.backgroundCream,
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
                
                // Deposit
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sunflowerYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deposit Paid',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment.formattedDeposit,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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
          const SizedBox(height: 32),
          
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
