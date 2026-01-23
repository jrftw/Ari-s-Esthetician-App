/*
 * Filename: payment_service.dart
 * Purpose: Stripe payment processing service for handling deposits and payments
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: flutter_stripe, http, cloud_functions, firestore_service
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import '../core/logging/app_logger.dart';
import '../core/constants/app_constants.dart';
import '../models/business_settings_model.dart';
import 'firestore_service.dart';

// MARK: - Payment Service
/// Service for processing Stripe payments
/// Handles payment intent creation, confirmation, and validation
class PaymentService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // MARK: - Initialization
  /// Initialize Stripe with publishable key from business settings
  Future<void> initializeStripe() async {
    try {
      logInfo('Initializing Stripe...', tag: 'PaymentService');
      
      final settings = await _firestoreService.getBusinessSettings();
      if (settings == null || settings.stripePublishableKey == null || settings.stripePublishableKey!.isEmpty) {
        logWarning('Stripe publishable key not configured', tag: 'PaymentService');
        return;
      }

      Stripe.publishableKey = settings.stripePublishableKey!;
      
      // For web, we need to set up Stripe properly
      // For mobile, this is handled automatically
      logSuccess('Stripe initialized successfully', tag: 'PaymentService');
    } catch (e, stackTrace) {
      logError('Failed to initialize Stripe', tag: 'PaymentService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // MARK: - Payment Intent Creation
  /// Create a payment intent for the deposit amount
  /// This should be called from a Cloud Function for security (secret key handling)
  Future<PaymentIntent> createPaymentIntent({
    required int amountCents,
    required String currency,
    String? customerEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      logLoading('Creating payment intent for ${amountCents / 100} $currency', tag: 'PaymentService');
      
      // Call Cloud Function to create payment intent securely
      // The Cloud Function will use the secret key
      final callable = _functions.httpsCallable('createPaymentIntent');
      
      final result = await callable.call({
        'amount': amountCents,
        'currency': currency,
        'customerEmail': customerEmail,
        'metadata': metadata ?? {},
      });

      final paymentIntentData = result.data as Map<String, dynamic>;
      final clientSecret = paymentIntentData['clientSecret'] as String;
      
      logSuccess('Payment intent created successfully', tag: 'PaymentService');
      
      // Parse the payment intent from client secret
      // Use created timestamp from server if available, otherwise use current time
      final createdTimestamp = paymentIntentData['created']?.toString() ?? 
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      return PaymentIntent(
        id: paymentIntentData['id'] as String,
        clientSecret: clientSecret,
        amount: amountCents,
        currency: currency,
        created: createdTimestamp,
        status: PaymentIntentsStatus.RequiresPaymentMethod,
        livemode: paymentIntentData['livemode'] as bool? ?? false,
        captureMethod: CaptureMethod.Automatic,
        confirmationMethod: ConfirmationMethod.Automatic,
      );
    } catch (e, stackTrace) {
      logError('Failed to create payment intent', tag: 'PaymentService', error: e, stackTrace: stackTrace);
      
      // Fallback: If Cloud Function doesn't exist, throw helpful error
      if (e.toString().contains('not found') || e.toString().contains('UNAVAILABLE')) {
        throw Exception('Payment processing not configured. Please contact support.');
      }
      
      rethrow;
    }
  }

  // MARK: - Payment Confirmation
  /// Confirm payment with Stripe using payment method
  /// Returns the payment intent ID if successful
  Future<String> confirmPayment({
    required PaymentIntent paymentIntent,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    try {
      logLoading('Confirming payment...', tag: 'PaymentService');
      
      // Confirm the payment
      final paymentIntentResult = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent.clientSecret!,
        data: paymentMethodParams,
      );

      if (paymentIntentResult.status == PaymentIntentsStatus.Succeeded ||
          paymentIntentResult.status == PaymentIntentsStatus.RequiresCapture) {
        logSuccess('Payment confirmed successfully: ${paymentIntent.id}', tag: 'PaymentService');
        return paymentIntent.id;
      } else {
        throw Exception('Payment confirmation failed: ${paymentIntentResult.status}');
      }
    } catch (e, stackTrace) {
      logError('Failed to confirm payment', tag: 'PaymentService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // MARK: - Payment Method Creation
  /// Create payment method from card details
  /// Note: For web, Stripe Elements should be used. This is a simplified version.
  /// For production, consider using Stripe Elements for better security.
  Future<PaymentMethod> createPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    String? cardholderName,
    BillingDetails? billingDetails,
  }) async {
    try {
      logLoading('Creating payment method...', tag: 'PaymentService');
      
      // Clean card number (remove spaces)
      final cleanedCardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
      
      // Create payment method with card details
      // Note: On web, this requires Stripe.js and proper setup
      // For now, we'll use the card payment method params
      final paymentMethodParams = PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: billingDetails,
        ),
      );

      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: paymentMethodParams,
      );

      logSuccess('Payment method created successfully', tag: 'PaymentService');
      return paymentMethod;
    } catch (e, stackTrace) {
      logError('Failed to create payment method', tag: 'PaymentService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // MARK: - Post-Appointment Tip Payment
  /// Create and process a tip payment for a completed appointment
  Future<String> processPostAppointmentTip({
    required int tipAmountCents,
    required String currency,
    required String appointmentId,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    try {
      logLoading('Processing post-appointment tip: ${tipAmountCents / 100} $currency', tag: 'PaymentService');
      
      // Create payment intent for tip
      final paymentIntent = await createPaymentIntent(
        amountCents: tipAmountCents,
        currency: currency,
        metadata: {
          'type': 'post_appointment_tip',
          'appointmentId': appointmentId,
        },
      );
      
      // Confirm payment
      final paymentIntentId = await confirmPayment(
        paymentIntent: paymentIntent,
        paymentMethodParams: paymentMethodParams,
      );
      
      logSuccess('Post-appointment tip processed successfully: $paymentIntentId', tag: 'PaymentService');
      return paymentIntentId;
    } catch (e, stackTrace) {
      logError('Failed to process post-appointment tip', tag: 'PaymentService', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // MARK: - Payment Validation
  /// Validate payment intent status
  Future<bool> validatePayment(String paymentIntentId) async {
    try {
      logInfo('Validating payment: $paymentIntentId', tag: 'PaymentService');
      
      // Call Cloud Function to validate payment
      final callable = _functions.httpsCallable('validatePaymentIntent');
      
      final result = await callable.call({
        'paymentIntentId': paymentIntentId,
      });

      final isValid = result.data['valid'] as bool? ?? false;
      
      if (isValid) {
        logSuccess('Payment validated successfully', tag: 'PaymentService');
      } else {
        logWarning('Payment validation failed', tag: 'PaymentService');
      }
      
      return isValid;
    } catch (e, stackTrace) {
      logError('Failed to validate payment', tag: 'PaymentService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // MARK: - Helper Methods
  /// Format amount in cents to currency string
  String formatAmount(int amountCents, String currency) {
    return '\$${(amountCents / 100).toStringAsFixed(2)}';
  }

  /// Validate card number (basic Luhn algorithm check)
  bool validateCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  /// Validate expiry date
  bool validateExpiryDate(int month, int year) {
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final expiryDate = DateTime(year, month);
    final currentDate = DateTime(now.year, now.month);
    
    return expiryDate.isAfter(currentDate) || expiryDate.isAtSameMomentAs(currentDate);
  }

  /// Validate CVC
  bool validateCVC(String cvc) {
    final cleaned = cvc.replaceAll(RegExp(r'\D'), '');
    return cleaned.length == 3 || cleaned.length == 4;
  }
}

// Suggestions For Features and Additions Later:
// - Add support for multiple payment methods (Apple Pay, Google Pay)
// - Add payment retry logic
// - Add payment refund functionality
// - Add payment history tracking
// - Add subscription payment support
// - Add split payment support
// - Add payment webhook handling
// - Add payment receipt generation
// - Add payment dispute handling
