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

  // MARK: - Legal Compliance Fields
  /// Terms & Conditions acceptance metadata
  @JsonKey(toJson: _termsMetadataToJson, fromJson: _termsMetadataFromJson)
  final TermsAcceptanceMetadata? termsAcceptanceMetadata;
  
  /// Client health disclosure information
  @JsonKey(toJson: _healthDisclosureToJson, fromJson: _healthDisclosureFromJson)
  final HealthDisclosure? healthDisclosure;
  
  /// Required acknowledgment flags
  @JsonKey(toJson: _requiredAcknowledgmentsToJson, fromJson: _requiredAcknowledgmentsFromJson)
  final RequiredAcknowledgments? requiredAcknowledgments;
  
  /// Cancellation and deposit policy acknowledgment
  final bool cancellationPolicyAcknowledged;

  // MARK: - Account Linking & Extended Compliance (additive, backwards compatible)
  /// Optional user ID when appointment is linked to an account
  final String? userId;
  /// Per-item health disclosure detail text or "Not applicable" (key: e.g. skinConditions, allergies)
  @JsonKey(toJson: _healthDisclosureDetailsToJson, fromJson: _healthDisclosureDetailsFromJson)
  final Map<String, String>? healthDisclosureDetails;
  /// UTC timestamp when required acknowledgements were accepted
  @JsonKey(fromJson: _timestampNullableFromJson, toJson: _timestampToJson)
  final DateTime? requiredAcknowledgmentsAcceptedAt;
  /// Cancellation policy snapshot: acknowledged, timestamp, version/hash
  @JsonKey(toJson: _cancellationPolicySnapshotToJson, fromJson: _cancellationPolicySnapshotFromJson)
  final CancellationPolicySnapshot? cancellationPolicySnapshot;

  // MARK: - Coupon Fields
  /// Coupon code applied at booking (null if none)
  final String? couponCode;
  /// Total discount amount in cents for this booking (same on all appointments in the booking)
  @JsonKey(defaultValue: 0)
  final int discountAmountCents;

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
    this.termsAcceptanceMetadata,
    this.healthDisclosure,
    this.requiredAcknowledgments,
    this.cancellationPolicyAcknowledged = false,
    this.userId,
    this.healthDisclosureDetails,
    this.requiredAcknowledgmentsAcceptedAt,
    this.cancellationPolicySnapshot,
    this.couponCode,
    this.discountAmountCents = 0,
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
    TermsAcceptanceMetadata? termsAcceptanceMetadata,
    HealthDisclosure? healthDisclosure,
    RequiredAcknowledgments? requiredAcknowledgments,
    bool cancellationPolicyAcknowledged = false,
    String? userId,
    Map<String, String>? healthDisclosureDetails,
    DateTime? requiredAcknowledgmentsAcceptedAt,
    CancellationPolicySnapshot? cancellationPolicySnapshot,
    String? couponCode,
    int discountAmountCents = 0,
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
      termsAcceptanceMetadata: termsAcceptanceMetadata,
      healthDisclosure: healthDisclosure,
      requiredAcknowledgments: requiredAcknowledgments,
      cancellationPolicyAcknowledged: cancellationPolicyAcknowledged,
      userId: userId,
      healthDisclosureDetails: healthDisclosureDetails,
      requiredAcknowledgmentsAcceptedAt: requiredAcknowledgmentsAcceptedAt,
      cancellationPolicySnapshot: cancellationPolicySnapshot,
      couponCode: couponCode,
      discountAmountCents: discountAmountCents,
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
    TermsAcceptanceMetadata? termsAcceptanceMetadata,
    HealthDisclosure? healthDisclosure,
    RequiredAcknowledgments? requiredAcknowledgments,
    bool? cancellationPolicyAcknowledged,
    String? userId,
    Map<String, String>? healthDisclosureDetails,
    DateTime? requiredAcknowledgmentsAcceptedAt,
    CancellationPolicySnapshot? cancellationPolicySnapshot,
    String? couponCode,
    int? discountAmountCents,
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
      termsAcceptanceMetadata: termsAcceptanceMetadata ?? this.termsAcceptanceMetadata,
      healthDisclosure: healthDisclosure ?? this.healthDisclosure,
      requiredAcknowledgments: requiredAcknowledgments ?? this.requiredAcknowledgments,
      cancellationPolicyAcknowledged: cancellationPolicyAcknowledged ?? this.cancellationPolicyAcknowledged,
      userId: userId ?? this.userId,
      healthDisclosureDetails: healthDisclosureDetails ?? this.healthDisclosureDetails,
      requiredAcknowledgmentsAcceptedAt: requiredAcknowledgmentsAcceptedAt ?? this.requiredAcknowledgmentsAcceptedAt,
      cancellationPolicySnapshot: cancellationPolicySnapshot ?? this.cancellationPolicySnapshot,
      couponCode: couponCode ?? this.couponCode,
      discountAmountCents: discountAmountCents ?? this.discountAmountCents,
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
        termsAcceptanceMetadata,
        healthDisclosure,
        requiredAcknowledgments,
        cancellationPolicyAcknowledged,
        userId,
        healthDisclosureDetails,
        requiredAcknowledgmentsAcceptedAt,
        cancellationPolicySnapshot,
        couponCode,
        discountAmountCents,
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

  /// For optional DateTime? fields: return null when input is null
  static DateTime? _timestampNullableFromJson(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return null;
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

  // MARK: - Legal Compliance Field Helpers
  /// Convert TermsAcceptanceMetadata to JSON Map
  static dynamic _termsMetadataToJson(TermsAcceptanceMetadata? metadata) {
    if (metadata == null) return null;
    return metadata.toJson();
  }

  /// Convert JSON Map to TermsAcceptanceMetadata
  static TermsAcceptanceMetadata? _termsMetadataFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return TermsAcceptanceMetadata.fromJson(json);
    }
    return null;
  }

  /// Convert HealthDisclosure to JSON Map
  static dynamic _healthDisclosureToJson(HealthDisclosure? disclosure) {
    if (disclosure == null) return null;
    return disclosure.toJson();
  }

  /// Convert JSON Map to HealthDisclosure
  static HealthDisclosure? _healthDisclosureFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return HealthDisclosure.fromJson(json);
    }
    return null;
  }

  /// Convert RequiredAcknowledgments to JSON Map
  static dynamic _requiredAcknowledgmentsToJson(RequiredAcknowledgments? acknowledgments) {
    if (acknowledgments == null) return null;
    return acknowledgments.toJson();
  }

  /// Convert JSON Map to RequiredAcknowledgments
  static RequiredAcknowledgments? _requiredAcknowledgmentsFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return RequiredAcknowledgments.fromJson(json);
    }
    return null;
  }

  /// Convert healthDisclosureDetails map to JSON
  static dynamic _healthDisclosureDetailsToJson(Map<String, String>? map) {
    if (map == null) return null;
    return map;
  }

  static Map<String, String>? _healthDisclosureDetailsFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return json.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    return null;
  }

  /// Convert CancellationPolicySnapshot to JSON
  static dynamic _cancellationPolicySnapshotToJson(CancellationPolicySnapshot? s) {
    if (s == null) return null;
    return s.toJson();
  }

  static CancellationPolicySnapshot? _cancellationPolicySnapshotFromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map<String, dynamic>) {
      return CancellationPolicySnapshot.fromJson(json);
    }
    return null;
  }
}

// MARK: - Cancellation Policy Snapshot
/// Snapshot of cancellation/no-show policy agreement at submission time
@JsonSerializable()
class CancellationPolicySnapshot extends Equatable {
  final bool acknowledged;
  @JsonKey(fromJson: AppointmentModel._timestampFromJson, toJson: AppointmentModel._timestampToJson)
  final DateTime acknowledgedAt;
  final String? policyVersion;
  final String? policyTextHash;

  const CancellationPolicySnapshot({
    required this.acknowledged,
    required this.acknowledgedAt,
    this.policyVersion,
    this.policyTextHash,
  });

  factory CancellationPolicySnapshot.fromJson(Map<String, dynamic> json) =>
      _$CancellationPolicySnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$CancellationPolicySnapshotToJson(this);

  @override
  List<Object?> get props => [acknowledged, acknowledgedAt, policyVersion, policyTextHash];
}

// MARK: - Terms Acceptance Metadata
/// Metadata for Terms & Conditions electronic acceptance
/// Stores verifiable audit data for legal compliance
@JsonSerializable()
class TermsAcceptanceMetadata extends Equatable {
  /// Whether terms were accepted
  final bool termsAccepted;
  
  /// UTC timestamp when terms were accepted
  @JsonKey(fromJson: AppointmentModel._timestampFromJson, toJson: AppointmentModel._timestampToJson)
  final DateTime termsAcceptedAtUtc;
  
  /// Local timestamp when terms were accepted
  @JsonKey(fromJson: AppointmentModel._timestampFromJson, toJson: AppointmentModel._timestampToJson)
  final DateTime termsAcceptedAtLocal;
  
  /// IP address of client (best-effort, may be null)
  final String? ipAddress;
  
  /// User agent / device information
  final String? userAgent;
  
  /// Platform information (iOS, Android, Web)
  final String? platform;
  
  /// Operating system version
  final String? osVersion;

  const TermsAcceptanceMetadata({
    required this.termsAccepted,
    required this.termsAcceptedAtUtc,
    required this.termsAcceptedAtLocal,
    this.ipAddress,
    this.userAgent,
    this.platform,
    this.osVersion,
  });

  factory TermsAcceptanceMetadata.fromJson(Map<String, dynamic> json) =>
      _$TermsAcceptanceMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$TermsAcceptanceMetadataToJson(this);

  @override
  List<Object?> get props => [
        termsAccepted,
        termsAcceptedAtUtc,
        termsAcceptedAtLocal,
        ipAddress,
        userAgent,
        platform,
        osVersion,
      ];
}

// MARK: - Health Disclosure
/// Client health and skin disclosure information
/// Required for esthetician services to ensure safe treatment
@JsonSerializable()
class HealthDisclosure extends Equatable {
  /// Skin conditions (acne, rosacea, eczema, psoriasis)
  final bool hasSkinConditions;
  
  /// Allergies or sensitivities
  final bool hasAllergies;
  
  /// Current medications (topical or oral)
  final bool hasCurrentMedications;
  
  /// Pregnancy or breastfeeding status
  final bool isPregnantOrBreastfeeding;
  
  /// Recent cosmetic treatments (peels, injectables, laser)
  final bool hasRecentCosmeticTreatments;
  
  /// Known reactions to skincare products
  final bool hasKnownReactions;
  
  /// Optional free-text notes for additional disclosure
  final String? additionalNotes;

  const HealthDisclosure({
    required this.hasSkinConditions,
    required this.hasAllergies,
    required this.hasCurrentMedications,
    required this.isPregnantOrBreastfeeding,
    required this.hasRecentCosmeticTreatments,
    required this.hasKnownReactions,
    this.additionalNotes,
  });

  factory HealthDisclosure.fromJson(Map<String, dynamic> json) =>
      _$HealthDisclosureFromJson(json);

  Map<String, dynamic> toJson() => _$HealthDisclosureToJson(this);

  @override
  List<Object?> get props => [
        hasSkinConditions,
        hasAllergies,
        hasCurrentMedications,
        isPregnantOrBreastfeeding,
        hasRecentCosmeticTreatments,
        hasKnownReactions,
        additionalNotes,
      ];
}

// MARK: - Required Acknowledgments
/// Required acknowledgment checkboxes for legal compliance
/// All must be true for booking submission
@JsonSerializable()
class RequiredAcknowledgments extends Equatable {
  /// I understand results are not guaranteed
  final bool understandsResultsNotGuaranteed;
  
  /// I understand services are non-medical
  final bool understandsServicesNonMedical;
  
  /// I agree to follow aftercare instructions
  final bool agreesToFollowAftercare;
  
  /// I accept the inherent risks of esthetic services
  final bool acceptsInherentRisks;

  const RequiredAcknowledgments({
    required this.understandsResultsNotGuaranteed,
    required this.understandsServicesNonMedical,
    required this.agreesToFollowAftercare,
    required this.acceptsInherentRisks,
  });

  factory RequiredAcknowledgments.fromJson(Map<String, dynamic> json) =>
      _$RequiredAcknowledgmentsFromJson(json);

  Map<String, dynamic> toJson() => _$RequiredAcknowledgmentsToJson(this);

  /// Check if all required acknowledgments are true
  bool get allAcknowledged {
    return understandsResultsNotGuaranteed &&
        understandsServicesNonMedical &&
        agreesToFollowAftercare &&
        acceptsInherentRisks;
  }

  @override
  List<Object?> get props => [
        understandsResultsNotGuaranteed,
        understandsServicesNonMedical,
        agreesToFollowAftercare,
        acceptsInherentRisks,
      ];
}

// Suggestions For Features and Additions Later:
// - Add appointment recurrence support
// - Add waitlist functionality
// - Add appointment ratings/reviews
// - Add appointment add-ons/upsells
// - Add appointment rescheduling history
