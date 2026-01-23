/*
 * Filename: email_service.dart
 * Purpose: Email service for sending appointment confirmations, reminders, and notifications
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: mailer, firestore_service, models
 * Platform Compatibility: iOS, Android, Web (via Cloud Functions)
 */

// MARK: - Imports
import 'package:mailer/mailer.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../core/logging/app_logger.dart';
import '../models/appointment_model.dart';
import '../models/business_settings_model.dart';
import 'firestore_service.dart';

// MARK: - Email Service
/// Service for sending emails via SMTP or Cloud Functions
/// Handles appointment confirmations, reminders, and notifications
class EmailService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // MARK: - Email Sending
  /// Send appointment confirmation email
  /// Uses Cloud Function for secure email sending
  Future<bool> sendConfirmationEmail({
    required AppointmentModel appointment,
  }) async {
    try {
      logLoading('Sending confirmation email to ${appointment.clientEmail}...', tag: 'EmailService');
      
      // Get business settings for email content
      final settings = await _firestoreService.getBusinessSettings();
      if (settings == null) {
        logWarning('Business settings not found, cannot send email', tag: 'EmailService');
        return false;
      }

      // Call Cloud Function to send email securely
      final callable = _functions.httpsCallable('sendAppointmentConfirmationEmail');
      
      final result = await callable.call({
        'appointmentId': appointment.id,
        'clientEmail': appointment.clientEmail,
        'clientName': appointment.clientFullName,
        'serviceName': appointment.serviceSnapshot?.name ?? 'Service',
        'appointmentDate': appointment.startTime.toIso8601String(),
        'appointmentTime': DateFormat('h:mm a').format(appointment.startTime),
        'appointmentDateFormatted': DateFormat('EEEE, MMMM d, y').format(appointment.startTime),
        'depositAmount': appointment.formattedDeposit,
        'businessName': settings.businessName,
        'businessEmail': settings.businessEmail,
        'businessPhone': settings.businessPhone,
        'businessAddress': settings.businessAddress,
      });

      final success = result.data['success'] as bool? ?? false;
      
      if (success) {
        logSuccess('Confirmation email sent successfully', tag: 'EmailService');
        
        // Update appointment with email sent timestamp
        await _firestoreService.updateAppointment(
          appointment.copyWith(
            confirmationEmailSentAt: DateTime.now(),
          ),
        );
      } else {
        logWarning('Failed to send confirmation email', tag: 'EmailService');
      }
      
      return success;
    } catch (e, stackTrace) {
      logError('Failed to send confirmation email', tag: 'EmailService', error: e, stackTrace: stackTrace);
      
      // If Cloud Function doesn't exist, log warning but don't fail booking
      if (e.toString().contains('not found') || e.toString().contains('UNAVAILABLE')) {
        logWarning('Email service not configured. Booking will continue without email.', tag: 'EmailService');
        return false;
      }
      
      return false;
    }
  }

  /// Send appointment reminder email
  Future<bool> sendReminderEmail({
    required AppointmentModel appointment,
    required String reminderType, // '24hour' or 'dayOf'
  }) async {
    try {
      logLoading('Sending $reminderType reminder email to ${appointment.clientEmail}...', tag: 'EmailService');
      
      final settings = await _firestoreService.getBusinessSettings();
      if (settings == null) {
        logWarning('Business settings not found, cannot send email', tag: 'EmailService');
        return false;
      }

      final callable = _functions.httpsCallable('sendAppointmentReminderEmail');
      
      final result = await callable.call({
        'appointmentId': appointment.id,
        'clientEmail': appointment.clientEmail,
        'clientName': appointment.clientFullName,
        'serviceName': appointment.serviceSnapshot?.name ?? 'Service',
        'appointmentDate': appointment.startTime.toIso8601String(),
        'appointmentTime': DateFormat('h:mm a').format(appointment.startTime),
        'appointmentDateFormatted': DateFormat('EEEE, MMMM d, y').format(appointment.startTime),
        'reminderType': reminderType,
        'businessName': settings.businessName,
        'businessEmail': settings.businessEmail,
        'businessPhone': settings.businessPhone,
      });

      final success = result.data['success'] as bool? ?? false;
      
      if (success) {
        logSuccess('Reminder email sent successfully', tag: 'EmailService');
        
        // Update appointment with reminder sent timestamp
        DateTime? reminderSentAt;
        if (reminderType == '24hour') {
          reminderSentAt = DateTime.now();
        } else if (reminderType == 'dayOf') {
          reminderSentAt = DateTime.now();
        }
        
        if (reminderSentAt != null) {
          await _firestoreService.updateAppointment(
            appointment.copyWith(
              reminderEmailSentAt: reminderType == '24hour' ? reminderSentAt : appointment.reminderEmailSentAt,
              dayOfReminderEmailSentAt: reminderType == 'dayOf' ? reminderSentAt : appointment.dayOfReminderEmailSentAt,
            ),
          );
        }
      }
      
      return success;
    } catch (e, stackTrace) {
      logError('Failed to send reminder email', tag: 'EmailService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Send cancellation confirmation email
  Future<bool> sendCancellationEmail({
    required AppointmentModel appointment,
    String? reason,
  }) async {
    try {
      logLoading('Sending cancellation email to ${appointment.clientEmail}...', tag: 'EmailService');
      
      final settings = await _firestoreService.getBusinessSettings();
      if (settings == null) {
        logWarning('Business settings not found, cannot send email', tag: 'EmailService');
        return false;
      }

      final callable = _functions.httpsCallable('sendAppointmentCancellationEmail');
      
      final result = await callable.call({
        'appointmentId': appointment.id,
        'clientEmail': appointment.clientEmail,
        'clientName': appointment.clientFullName,
        'serviceName': appointment.serviceSnapshot?.name ?? 'Service',
        'appointmentDate': appointment.startTime.toIso8601String(),
        'reason': reason,
        'businessName': settings.businessName,
        'businessEmail': settings.businessEmail,
      });

      final success = result.data['success'] as bool? ?? false;
      
      if (success) {
        logSuccess('Cancellation email sent successfully', tag: 'EmailService');
      }
      
      return success;
    } catch (e, stackTrace) {
      logError('Failed to send cancellation email', tag: 'EmailService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // MARK: - Email Template Helpers
  /// Generate confirmation email HTML content
  String generateConfirmationEmailHTML({
    required String clientName,
    required String serviceName,
    required String appointmentDate,
    required String appointmentTime,
    required String depositAmount,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Appointment Confirmation - $businessName</title>
</head>
<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background-color: #FFD700; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
    <h1 style="color: #5D4037; margin: 0;">$businessName</h1>
  </div>
  
  <div style="background-color: #fff; padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
    <h2 style="color: #5D4037;">Appointment Confirmed!</h2>
    
    <p>Dear $clientName,</p>
    
    <p>Your appointment has been successfully confirmed. We're looking forward to seeing you!</p>
    
    <div style="background-color: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <h3 style="color: #5D4037; margin-top: 0;">Appointment Details</h3>
      <p><strong>Service:</strong> $serviceName</p>
      <p><strong>Date:</strong> $appointmentDate</p>
      <p><strong>Time:</strong> $appointmentTime</p>
      <p><strong>Deposit Paid:</strong> $depositAmount</p>
    </div>
    
    <p><strong>What to expect:</strong></p>
    <ul>
      <li>Please arrive 10 minutes early for your appointment</li>
      <li>A reminder will be sent 24 hours before your appointment</li>
      <li>If you need to reschedule or cancel, please contact us at least 24 hours in advance</li>
    </ul>
    
    ${businessAddress != null ? '<p><strong>Location:</strong><br>$businessAddress</p>' : ''}
    ${businessPhone != null ? '<p><strong>Phone:</strong> $businessPhone</p>' : ''}
    
    <p>Thank you for choosing $businessName!</p>
    
    <p>Best regards,<br>$businessName</p>
  </div>
  
  <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
    <p>This is an automated email. Please do not reply to this message.</p>
  </div>
</body>
</html>
''';
  }

  /// Generate plain text confirmation email
  String generateConfirmationEmailText({
    required String clientName,
    required String serviceName,
    required String appointmentDate,
    required String appointmentTime,
    required String depositAmount,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
  }) {
    return '''
Appointment Confirmation - $businessName

Dear $clientName,

Your appointment has been successfully confirmed. We're looking forward to seeing you!

Appointment Details:
- Service: $serviceName
- Date: $appointmentDate
- Time: $appointmentTime
- Deposit Paid: $depositAmount

What to expect:
- Please arrive 10 minutes early for your appointment
- A reminder will be sent 24 hours before your appointment
- If you need to reschedule or cancel, please contact us at least 24 hours in advance

${businessAddress != null ? 'Location: $businessAddress' : ''}
${businessPhone != null ? 'Phone: $businessPhone' : ''}

Thank you for choosing $businessName!

Best regards,
$businessName

---
This is an automated email. Please do not reply to this message.
''';
  }
}

// Suggestions For Features and Additions Later:
// - Add email template customization in admin settings
// - Add email scheduling for reminders
// - Add email tracking (open rates, click rates)
// - Add email attachments (receipts, calendar files)
// - Add multi-language email support
// - Add email unsubscribe functionality
// - Add email bounce handling
// - Add email delivery status tracking
// - Add email A/B testing
// - Add email personalization tokens
