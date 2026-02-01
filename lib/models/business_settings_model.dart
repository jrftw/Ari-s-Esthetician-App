/*
 * Filename: business_settings_model.dart
 * Purpose: Data model for configurable business settings and branding
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'business_settings_model.g.dart';

// MARK: - Business Hours Model
/// Represents working hours for a specific day
@JsonSerializable()
class BusinessHoursModel extends Equatable {
  /// Day of week (0 = Sunday, 6 = Saturday)
  final int dayOfWeek;
  
  /// Whether the business is open on this day
  final bool isOpen;
  
  /// List of time slots (start and end times in 24-hour format)
  /// Format: ["09:00", "12:00", "13:00", "17:00"] for 9am-12pm and 1pm-5pm
  @JsonKey(defaultValue: [])
  final List<String> timeSlots;

  const BusinessHoursModel({
    required this.dayOfWeek,
    this.isOpen = false,
    this.timeSlots = const [],
  });

  factory BusinessHoursModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessHoursModelFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessHoursModelToJson(this);

  @override
  List<Object?> get props => [dayOfWeek, isOpen, timeSlots];
}

// MARK: - Business Settings Model
/// Represents all configurable business settings including branding and policies
/// This model is used to customize the app without code changes
@JsonSerializable()
class BusinessSettingsModel extends Equatable {
  /// Unique identifier (typically "main" or business ID)
  final String id;
  
  /// Business name (displayed throughout the app)
  final String businessName;
  
  /// Business email address
  final String businessEmail;
  
  /// Business phone number
  final String businessPhone;
  
  /// Business address
  final String? businessAddress;
  
  /// Business logo URL
  final String? logoUrl;
  
  /// Primary brand color (hex code)
  final String? primaryColorHex;
  
  /// Secondary brand color (hex code)
  final String? secondaryColorHex;
  
  /// Business website URL
  final String? websiteUrl;
  
  /// Facebook page URL
  final String? facebookUrl;
  
  /// Instagram handle/URL
  final String? instagramUrl;
  
  /// Twitter handle/URL
  final String? twitterUrl;
  
  /// Weekly business hours
  @JsonKey(
    defaultValue: [],
    toJson: _weeklyHoursToJson,
    fromJson: _weeklyHoursFromJson,
  )
  final List<BusinessHoursModel> weeklyHours;
  
  /// Cancellation window in hours
  final int cancellationWindowHours;
  
  /// Late policy text (shown to clients)
  final String latePolicyText;
  
  /// No-show policy text (shown to clients)
  final String noShowPolicyText;
  
  /// General booking policy text
  final String bookingPolicyText;
  
  /// Timezone for the business
  final String timezone;
  
  /// Google Calendar ID for syncing appointments (used when calendarSyncProvider is 'google')
  final String? googleCalendarId;
  
  /// Whether to auto-sync appointments to an external calendar (Google, Apple, or ICS)
  @JsonKey(defaultValue: false)
  final bool calendarSyncEnabled;
  
  /// Which calendar type to sync to: 'google', 'apple', or 'ics' (other/Outlook)
  /// When calendarSyncEnabled is true, appointments are synced to this calendar type
  final String? calendarSyncProvider;
  
  /// Stripe publishable key
  final String? stripePublishableKey;
  
  /// Stripe secret key (stored securely, not in client app)
  final String? stripeSecretKey;
  
  /// Minimum deposit amount in cents (nullable - if null, no minimum required)
  /// Allows business to set custom minimum or disable minimum entirely
  final int? minDepositAmountCents;
  
  /// Cancellation fee in cents (nullable - if null, no cancellation fee)
  /// Applied when clients cancel appointments within the cancellation window
  final int? cancellationFeeCents;
  
  /// Whether payments are enabled for bookings
  /// When false, bookings can be made without payment processing
  /// Pricing is still shown but payment step is skipped
  @JsonKey(defaultValue: false)
  final bool paymentsEnabled;
  
  /// Global toggle for compliance forms at booking. When false, no compliance sections
  /// are shown. When true, each section is controlled by its individual toggle below.
  /// Backwards compatible: old docs without per-form flags behave as "all four on" when global is true.
  @JsonKey(defaultValue: true)
  final bool requireComplianceForms;

  /// When global compliance is on: require Health & Skin Disclosure section.
  /// Null (missing in Firestore) = treat as true for backwards compatibility.
  final bool? requireHealthDisclosure;

  /// When global compliance is on: require Required Acknowledgements section.
  /// Null = treat as true for backwards compatibility.
  final bool? requireRequiredAcknowledgments;

  /// When global compliance is on: require Terms & Conditions section.
  /// Null = treat as true for backwards compatibility.
  final bool? requireTermsAndConditions;

  /// When global compliance is on: require Cancellation & No-Show Policy section.
  /// Null = treat as true for backwards compatibility.
  final bool? requireCancellationPolicy;

  /// Whether to allow same-day booking. When true, clients can book today; only times
  /// that have not yet passed are shown (e.g. at 4 PM they cannot pick 9 AM).
  /// When false, clients cannot book within 24 hours (first bookable slot is 24h from now).
  @JsonKey(defaultValue: true)
  final bool allowSameDayBooking;
  
  /// Timestamp when settings were created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when settings were last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  // MARK: - Constructor
  const BusinessSettingsModel({
    required this.id,
    required this.businessName,
    required this.businessEmail,
    required this.businessPhone,
    this.businessAddress,
    this.logoUrl,
    this.primaryColorHex,
    this.secondaryColorHex,
    this.websiteUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.weeklyHours = const [],
    this.cancellationWindowHours = 24,
    this.latePolicyText = '',
    this.noShowPolicyText = '',
    this.bookingPolicyText = '',
    this.timezone = 'America/New_York',
    this.googleCalendarId,
    this.calendarSyncEnabled = false,
    this.calendarSyncProvider,
    this.stripePublishableKey,
    this.stripeSecretKey,
    this.minDepositAmountCents,
    this.cancellationFeeCents,
    this.paymentsEnabled = false,
    this.requireComplianceForms = true,
    this.requireHealthDisclosure,
    this.requireRequiredAcknowledgments,
    this.requireTermsAndConditions,
    this.requireCancellationPolicy,
    this.allowSameDayBooking = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // MARK: - Effective Compliance Form Getters (backwards compatible)
  /// True when global compliance is on and Health & Skin Disclosure is enabled (or unspecified).
  bool get enableHealthDisclosure =>
      requireComplianceForms && (requireHealthDisclosure ?? true);

  /// True when global compliance is on and Required Acknowledgements is enabled (or unspecified).
  bool get enableRequiredAcknowledgments =>
      requireComplianceForms && (requireRequiredAcknowledgments ?? true);

  /// True when global compliance is on and Terms & Conditions is enabled (or unspecified).
  bool get enableTermsAndConditions =>
      requireComplianceForms && (requireTermsAndConditions ?? true);

  /// True when global compliance is on and Cancellation & No-Show Policy is enabled (or unspecified).
  bool get enableCancellationPolicy =>
      requireComplianceForms && (requireCancellationPolicy ?? true);

  // MARK: - Factory Constructors
  /// Create a BusinessSettingsModel from Firestore document
  factory BusinessSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessSettingsModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a BusinessSettingsModel from JSON
  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessSettingsModelFromJson(json);

  /// Create default business settings
  factory BusinessSettingsModel.createDefault({
    required String businessName,
    required String businessEmail,
    required String businessPhone,
  }) {
    final now = DateTime.now();
    
    // MARK: - Default Working Hours
    /// Default working hours based on business schedule:
    /// Sunday: Closed
    /// Monday-Thursday: 8:00 AM - 5:30 PM
    /// Friday: 9:00 AM - 3:30 PM
    /// Saturday: Closed
    final defaultWeeklyHours = [
      // Sunday (0) - Closed
      BusinessHoursModel(dayOfWeek: 0, isOpen: false, timeSlots: []),
      // Monday (1) - 8:00 AM - 5:30 PM
      BusinessHoursModel(dayOfWeek: 1, isOpen: true, timeSlots: ['08:00', '17:30']),
      // Tuesday (2) - 8:00 AM - 5:30 PM
      BusinessHoursModel(dayOfWeek: 2, isOpen: true, timeSlots: ['08:00', '17:30']),
      // Wednesday (3) - 8:00 AM - 5:30 PM
      BusinessHoursModel(dayOfWeek: 3, isOpen: true, timeSlots: ['08:00', '17:30']),
      // Thursday (4) - 8:00 AM - 5:30 PM
      BusinessHoursModel(dayOfWeek: 4, isOpen: true, timeSlots: ['08:00', '17:30']),
      // Friday (5) - 9:00 AM - 3:30 PM
      BusinessHoursModel(dayOfWeek: 5, isOpen: true, timeSlots: ['09:00', '15:30']),
      // Saturday (6) - Closed
      BusinessHoursModel(dayOfWeek: 6, isOpen: false, timeSlots: []),
    ];
    
    return BusinessSettingsModel(
      id: 'main',
      businessName: businessName,
      businessEmail: businessEmail,
      businessPhone: businessPhone,
      cancellationWindowHours: 24,
      latePolicyText: 'Please arrive on time for your appointment. Late arrivals may result in shortened service time.',
      noShowPolicyText: 'Deposits are non-refundable for no-shows. Please cancel at least 24 hours in advance.',
      bookingPolicyText: 'A non-refundable deposit is required to confirm your appointment.',
      timezone: 'America/New_York',
      weeklyHours: defaultWeeklyHours,
      requireComplianceForms: true,
      requireHealthDisclosure: true,
      requireRequiredAcknowledgments: true,
      requireTermsAndConditions: true,
      requireCancellationPolicy: true,
      allowSameDayBooking: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert BusinessSettingsModel to JSON
  Map<String, dynamic> toJson() => _$BusinessSettingsModelToJson(this);

  /// Convert BusinessSettingsModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    
    // MARK: - Serialize Nested Objects
    // Ensure weeklyHours are properly serialized as maps
    if (json.containsKey('weeklyHours') && json['weeklyHours'] is List) {
      json['weeklyHours'] = (json['weeklyHours'] as List).map((item) {
        if (item is BusinessHoursModel) {
          return item.toJson();
        }
        return item; // Already a map
      }).toList();
    }
    
    return json;
  }

  // MARK: - Helper Methods
  /// Get business hours for a specific day
  BusinessHoursModel? getHoursForDay(int dayOfWeek) {
    try {
      return weeklyHours.firstWhere(
        (hours) => hours.dayOfWeek == dayOfWeek,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if business is open on a specific day
  bool isOpenOnDay(int dayOfWeek) {
    final hours = getHoursForDay(dayOfWeek);
    return hours?.isOpen ?? false;
  }

  /// Create a copy with updated fields
  BusinessSettingsModel copyWith({
    String? id,
    String? businessName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? logoUrl,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? websiteUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? twitterUrl,
    List<BusinessHoursModel>? weeklyHours,
    int? cancellationWindowHours,
    String? latePolicyText,
    String? noShowPolicyText,
    String? bookingPolicyText,
    String? timezone,
    String? googleCalendarId,
    bool? calendarSyncEnabled,
    String? calendarSyncProvider,
    String? stripePublishableKey,
    String? stripeSecretKey,
    bool? paymentsEnabled,
    bool? requireComplianceForms,
    bool? requireHealthDisclosure,
    bool? requireRequiredAcknowledgments,
    bool? requireTermsAndConditions,
    bool? requireCancellationPolicy,
    bool? allowSameDayBooking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessSettingsModel(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      cancellationWindowHours: cancellationWindowHours ?? this.cancellationWindowHours,
      latePolicyText: latePolicyText ?? this.latePolicyText,
      noShowPolicyText: noShowPolicyText ?? this.noShowPolicyText,
      bookingPolicyText: bookingPolicyText ?? this.bookingPolicyText,
      timezone: timezone ?? this.timezone,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      calendarSyncProvider: calendarSyncProvider ?? this.calendarSyncProvider,
      stripePublishableKey: stripePublishableKey ?? this.stripePublishableKey,
      stripeSecretKey: stripeSecretKey ?? this.stripeSecretKey,
      minDepositAmountCents: minDepositAmountCents ?? this.minDepositAmountCents,
      cancellationFeeCents: cancellationFeeCents ?? this.cancellationFeeCents,
      paymentsEnabled: paymentsEnabled ?? this.paymentsEnabled,
      requireComplianceForms: requireComplianceForms ?? this.requireComplianceForms,
      requireHealthDisclosure: requireHealthDisclosure ?? this.requireHealthDisclosure,
      requireRequiredAcknowledgments:
          requireRequiredAcknowledgments ?? this.requireRequiredAcknowledgments,
      requireTermsAndConditions:
          requireTermsAndConditions ?? this.requireTermsAndConditions,
      requireCancellationPolicy:
          requireCancellationPolicy ?? this.requireCancellationPolicy,
      allowSameDayBooking: allowSameDayBooking ?? this.allowSameDayBooking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        businessName,
        businessEmail,
        businessPhone,
        businessAddress,
        logoUrl,
        primaryColorHex,
        secondaryColorHex,
        websiteUrl,
        facebookUrl,
        instagramUrl,
        twitterUrl,
        weeklyHours,
        cancellationWindowHours,
        latePolicyText,
        noShowPolicyText,
        bookingPolicyText,
        timezone,
        googleCalendarId,
        calendarSyncEnabled,
        calendarSyncProvider,
        stripePublishableKey,
        minDepositAmountCents,
        cancellationFeeCents,
        paymentsEnabled,
        requireComplianceForms,
        requireHealthDisclosure,
        requireRequiredAcknowledgments,
        requireTermsAndConditions,
        requireCancellationPolicy,
        allowSameDayBooking,
        createdAt,
        updatedAt,
      ];

  // MARK: - Timestamp Helpers
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  // MARK: - Weekly Hours Converters
  /// Convert list of BusinessHoursModel to JSON list
  static List<Map<String, dynamic>> _weeklyHoursToJson(List<BusinessHoursModel> hours) {
    return hours.map((h) => h.toJson()).toList();
  }

  /// Convert JSON list to list of BusinessHoursModel
  static List<BusinessHoursModel> _weeklyHoursFromJson(List<dynamic> json) {
    return json
        .map((e) => BusinessHoursModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// Suggestions For Features and Additions Later:
// - Add multiple location support
// - Add staff member management
// - Add service-specific availability
// - Add holiday/vacation calendar
// - Add automated email templates customization
