/*
 * Filename: appointment_model.dart
 * Purpose: Data model for client appointments with status tracking and payment information
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'service_model.dart';

part 'appointment_model.g.dart';

// MARK: - Appointment Status Enum
/// Status of an appointment throughout its lifecycle
enum AppointmentStatus {
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('arrived')
  arrived,
  @JsonValue('completed')
  completed,
  @JsonValue('no_show')
  noShow,
  @JsonValue('canceled')
  canceled,
}

// MARK: - Appointment Model
/// Represents a client appointment booking
/// This model tracks the full lifecycle of an appointment from booking to completion
@JsonSerializable()
class AppointmentModel extends Equatable {
  /// Unique identifier for the appointment
  final String id;
  
  /// Reference to the service being booked
  final String serviceId;
  
  /// Service snapshot at time of booking (for historical accuracy)
  @JsonKey(fromJson: _serviceModelFromJson, toJson: _serviceModelToJson)
  final ServiceModel? serviceSnapshot;
  
  /// Client first name
  final String clientFirstName;
  
  /// Client last name
  final String clientLastName;
  
  /// Client email address
  final String clientEmail;
  
  /// Client phone number
  final String clientPhone;
  
  /// Optional intake notes from client
  final String? intakeNotes;
  
  /// Appointment start date and time
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime startTime;
  
  /// Appointment end date and time (calculated from service duration)
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime endTime;
  
  /// Current status of the appointment
  final AppointmentStatus status;
  
  /// Deposit amount paid in cents
  final int depositAmountCents;
  
  /// Stripe payment intent ID for deposit
  final String? stripePaymentIntentId;
  
  /// Tip amount paid during booking (in cents)
  final int tipAmountCents;
  
  /// Stripe payment intent ID for tip (if paid separately from deposit)
  final String? tipPaymentIntentId;
  
  /// Post-appointment tip amount (in cents) - added after appointment completion
  final int? postAppointmentTipAmountCents;
  
  /// Stripe payment intent ID for post-appointment tip
  final String? postAppointmentTipPaymentIntentId;
  
  /// Whether deposit has been forfeited (no-show)
  final bool depositForfeited;
  
  /// Whether appointment has been synced to Google Calendar
  final bool calendarSynced;
  
  /// Google Calendar event ID (if synced)
  final String? googleCalendarEventId;
  
  /// Timestamp when the appointment was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when the appointment was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  
  /// Timestamp when confirmation email was sent
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? confirmationEmailSentAt;
  
  /// Timestamp when reminder email was sent
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? reminderEmailSentAt;
  
  /// Timestamp when day-of reminder email was sent
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? dayOfReminderEmailSentAt;
  
  /// Admin notes (internal use only)
  final String? adminNotes;

  // MARK: - Constructor
  const AppointmentModel({
    required this.id,
    required this.serviceId,
    this.serviceSnapshot,
    required this.clientFirstName,
    required this.clientLastName,
    required this.clientEmail,
    required this.clientPhone,
    this.intakeNotes,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.confirmed,
    required this.depositAmountCents,
    this.stripePaymentIntentId,
    this.tipAmountCents = 0,
    this.tipPaymentIntentId,
    this.postAppointmentTipAmountCents,
    this.postAppointmentTipPaymentIntentId,
    this.depositForfeited = false,
    this.calendarSynced = false,
    this.googleCalendarEventId,
    required this.createdAt,
    required this.updatedAt,
    this.confirmationEmailSentAt,
    this.reminderEmailSentAt,
    this.dayOfReminderEmailSentAt,
    this.adminNotes,
  });

  // MARK: - Factory Constructors
  /// Create an AppointmentModel from Firestore document
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create an AppointmentModel from JSON
  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$AppointmentModelFromJson(json);

  /// Create a new AppointmentModel for booking
  factory AppointmentModel.create({
    required String serviceId,
    ServiceModel? serviceSnapshot,
    required String clientFirstName,
    required String clientLastName,
    required String clientEmail,
    required String clientPhone,
    String? intakeNotes,
    required DateTime startTime,
    required int durationMinutes,
    required int depositAmountCents,
    String? stripePaymentIntentId,
    int tipAmountCents = 0,
    String? tipPaymentIntentId,
  }) {
    final now = DateTime.now();
    final endTime = startTime.add(Duration(minutes: durationMinutes));
    
    return AppointmentModel(
      id: '', // Will be set by Firestore
      serviceId: serviceId,
      serviceSnapshot: serviceSnapshot,
      clientFirstName: clientFirstName,
      clientLastName: clientLastName,
      clientEmail: clientEmail,
      clientPhone: clientPhone,
      intakeNotes: intakeNotes,
      startTime: startTime,
      endTime: endTime,
      status: AppointmentStatus.confirmed,
      depositAmountCents: depositAmountCents,
      stripePaymentIntentId: stripePaymentIntentId,
      tipAmountCents: tipAmountCents,
      tipPaymentIntentId: tipPaymentIntentId,
      depositForfeited: false,
      calendarSynced: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert AppointmentModel to JSON
  Map<String, dynamic> toJson() => _$AppointmentModelToJson(this);

  /// Convert AppointmentModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    return json;
  }

  // MARK: - Helper Methods
  /// Get full client name
  String get clientFullName {
    return '$clientFirstName $clientLastName';
  }

  /// Get formatted deposit as string
  String get formattedDeposit {
    return '\$${(depositAmountCents / 100).toStringAsFixed(2)}';
  }

  /// Get total tip amount (pre + post appointment) in cents
  int get totalTipAmountCents {
    return tipAmountCents + (postAppointmentTipAmountCents ?? 0);
  }

  /// Get formatted total tip as string
  String get formattedTotalTip {
    return '\$${(totalTipAmountCents / 100).toStringAsFixed(2)}';
  }

  /// Get formatted pre-appointment tip as string
  String get formattedPreTip {
    return '\$${(tipAmountCents / 100).toStringAsFixed(2)}';
  }

  /// Get formatted post-appointment tip as string
  String get formattedPostTip {
    if (postAppointmentTipAmountCents == null || postAppointmentTipAmountCents == 0) {
      return '\$0.00';
    }
    return '\$${(postAppointmentTipAmountCents! / 100).toStringAsFixed(2)}';
  }

  /// Check if appointment is in the past
  bool get isPast {
    return endTime.isBefore(DateTime.now());
  }

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Check if appointment is upcoming
  bool get isUpcoming {
    return startTime.isAfter(DateTime.now());
  }

  /// Check if appointment can be canceled (within cancellation window)
  bool canCancel(DateTime cancellationDeadline) {
    return startTime.isAfter(cancellationDeadline) &&
        status != AppointmentStatus.canceled &&
        status != AppointmentStatus.completed;
  }

  /// Create a copy with updated fields
  AppointmentModel copyWith({
    String? id,
    String? serviceId,
    ServiceModel? serviceSnapshot,
    String? clientFirstName,
    String? clientLastName,
    String? clientEmail,
    String? clientPhone,
    String? intakeNotes,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    int? depositAmountCents,
    String? stripePaymentIntentId,
    int? tipAmountCents,
    String? tipPaymentIntentId,
    int? postAppointmentTipAmountCents,
    String? postAppointmentTipPaymentIntentId,
    bool? depositForfeited,
    bool? calendarSynced,
    String? googleCalendarEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmationEmailSentAt,
    DateTime? reminderEmailSentAt,
    DateTime? dayOfReminderEmailSentAt,
    String? adminNotes,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceSnapshot: serviceSnapshot ?? this.serviceSnapshot,
      clientFirstName: clientFirstName ?? this.clientFirstName,
      clientLastName: clientLastName ?? this.clientLastName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      intakeNotes: intakeNotes ?? this.intakeNotes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      depositAmountCents: depositAmountCents ?? this.depositAmountCents,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      tipAmountCents: tipAmountCents ?? this.tipAmountCents,
      tipPaymentIntentId: tipPaymentIntentId ?? this.tipPaymentIntentId,
      postAppointmentTipAmountCents: postAppointmentTipAmountCents ?? this.postAppointmentTipAmountCents,
      postAppointmentTipPaymentIntentId: postAppointmentTipPaymentIntentId ?? this.postAppointmentTipPaymentIntentId,
      depositForfeited: depositForfeited ?? this.depositForfeited,
      calendarSynced: calendarSynced ?? this.calendarSynced,
      googleCalendarEventId: googleCalendarEventId ?? this.googleCalendarEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      confirmationEmailSentAt: confirmationEmailSentAt ?? this.confirmationEmailSentAt,
      reminderEmailSentAt: reminderEmailSentAt ?? this.reminderEmailSentAt,
      dayOfReminderEmailSentAt: dayOfReminderEmailSentAt ?? this.dayOfReminderEmailSentAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        serviceId,
        serviceSnapshot,
        clientFirstName,
        clientLastName,
        clientEmail,
        clientPhone,
        intakeNotes,
        startTime,
        endTime,
        status,
        depositAmountCents,
        stripePaymentIntentId,
        tipAmountCents,
        tipPaymentIntentId,
        postAppointmentTipAmountCents,
        postAppointmentTipPaymentIntentId,
        depositForfeited,
        calendarSynced,
        googleCalendarEventId,
        createdAt,
        updatedAt,
        confirmationEmailSentAt,
        reminderEmailSentAt,
        dayOfReminderEmailSentAt,
        adminNotes,
      ];

  // MARK: - Timestamp Helpers
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  // MARK: - Service Model Helpers
  /// Convert ServiceModel from JSON Map
  static ServiceModel? _serviceModelFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return ServiceModel.fromJson(json);
    }
    return null;
  }

  /// Convert ServiceModel to JSON Map
  static dynamic _serviceModelToJson(ServiceModel? serviceModel) {
    if (serviceModel == null) return null;
    return serviceModel.toJson();
  }
}

// Suggestions For Features and Additions Later:
// - Add appointment recurrence support
// - Add waitlist functionality
// - Add appointment ratings/reviews
// - Add appointment add-ons/upsells
// - Add appointment rescheduling history
