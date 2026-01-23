/*
 * Filename: app_constants.dart
 * Purpose: Application-wide constants and configuration values
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: None
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Application Constants
/// Centralized constants used throughout the application
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // MARK: - App Information
  /// Application name (can be overridden by business settings)
  static const String appName = "Ari's Esthetician App";
  
  /// Application version (deprecated - use AppVersion.version instead)
  /// @deprecated Use AppVersion.version instead
  @Deprecated('Use AppVersion.version instead')
  static const String appVersion = "1.0.0";
  
  /// Minimum supported iOS version
  static const int minIOSVersion = 12;
  
  /// Minimum supported Android version
  static const int minAndroidVersion = 21;

  // MARK: - Time Constants
  /// Default appointment duration in minutes
  static const int defaultAppointmentDuration = 60;
  
  /// Default buffer time between appointments in minutes
  static const int defaultBufferTime = 15;
  
  /// Reminder email hours before appointment
  static const int reminderHoursBefore = 24;
  
  /// Day-of reminder hours before appointment
  static const int dayOfReminderHours = 2;
  
  /// Minimum booking advance time in hours
  static const int minBookingAdvanceHours = 2;
  
  /// Maximum booking advance time in days
  static const int maxBookingAdvanceDays = 90;

  // MARK: - Booking Constants
  /// Default cancellation window in hours
  static const int defaultCancellationWindowHours = 24;
  
  /// Minimum appointment duration in minutes
  static const int minAppointmentDuration = 1;
  
  /// Maximum appointment duration in minutes
  static const int maxAppointmentDuration = 480; // 8 hours

  // MARK: - Payment Constants
  /// Stripe currency code
  static const String stripeCurrency = "USD";
  
  /// Minimum deposit amount in cents
  static const int minDepositAmountCents = 500; // $5.00
  
  /// Maximum deposit amount in cents
  static const int maxDepositAmountCents = 100000; // $1000.00

  // MARK: - Firestore Collection Names
  /// Services collection name
  static const String firestoreServicesCollection = "services";
  
  /// Appointments collection name
  static const String firestoreAppointmentsCollection = "appointments";
  
  /// Clients collection name
  static const String firestoreClientsCollection = "clients";
  
  /// Business settings collection name
  static const String firestoreBusinessSettingsCollection = "business_settings";
  
  /// Service categories collection name
  static const String firestoreServiceCategoriesCollection = "serviceCategories";
  
  /// Payments collection name
  static const String firestorePaymentsCollection = "payments";
  
  /// Availability collection name
  static const String firestoreAvailabilityCollection = "availability";
  
  /// App version collection name
  static const String firestoreAppVersionCollection = "app_version";
  
  /// Notifications collection name
  static const String firestoreNotificationsCollection = "notifications";
  
  /// Software enhancements collection name
  static const String firestoreSoftwareEnhancementsCollection = "software_enhancements";
  
  /// Time-off collection name
  static const String firestoreTimeOffCollection = "time_off";

  // MARK: - Storage Paths
  /// Logo storage path
  static const String storageLogoPath = "business/logo";
  
  /// Profile images storage path
  static const String storageProfileImagesPath = "profiles";

  // MARK: - Route Names
  /// Welcome/landing route
  static const String routeWelcome = "/welcome";
  
  /// Account choice route
  static const String routeAccountChoice = "/account-choice";
  
  /// Client booking route
  static const String routeClientBooking = "/booking";
  
  /// Client confirmation route
  static const String routeClientConfirmation = "/confirmation";
  
  /// Client appointments route (view upcoming and past bookings)
  static const String routeClientAppointments = "/appointments";
  
  /// Admin dashboard route
  static const String routeAdminDashboard = "/admin";
  
  /// Admin services route
  static const String routeAdminServices = "/admin/services";
  
  /// Admin appointments route
  static const String routeAdminAppointments = "/admin/appointments";
  
  /// Admin clients route
  static const String routeAdminClients = "/admin/clients";
  
  /// Admin settings route
  static const String routeAdminSettings = "/admin/settings";
  
  /// Admin categories route
  static const String routeAdminCategories = "/admin/categories";
  
  /// Admin earnings route
  static const String routeAdminEarnings = "/admin/earnings";
  
  /// Admin notifications route
  static const String routeAdminNotifications = "/admin/notifications";
  
  /// Admin software enhancements route
  static const String routeAdminSoftwareEnhancements = "/admin/software-enhancements";
  
  /// Admin time-off route
  static const String routeAdminTimeOff = "/admin/time-off";
  
  /// General settings route (accessible to all users)
  static const String routeSettings = "/settings";

  // MARK: - Validation Constants
  /// Minimum name length
  static const int minNameLength = 2;
  
  /// Maximum name length
  static const int maxNameLength = 50;
  
  /// Minimum phone length
  static const int minPhoneLength = 10;
  
  /// Maximum phone length
  static const int maxPhoneLength = 15;
  
  /// Maximum notes length
  static const int maxNotesLength = 1000;

  // MARK: - UI Constants
  /// Default padding
  static const double defaultPadding = 16.0;
  
  /// Small padding
  static const double smallPadding = 8.0;
  
  /// Large padding
  static const double largePadding = 24.0;
  
  /// Default border radius
  static const double defaultBorderRadius = 12.0;
  
  /// Large border radius
  static const double largeBorderRadius = 16.0;
  
  /// Card elevation
  static const double cardElevation = 2.0;
  
  /// Button height
  static const double buttonHeight = 48.0;
}

// Suggestions For Features and Additions Later:
// - Add feature flags for gradual rollout
// - Implement A/B testing constants
// - Add analytics event names
// - Consider adding environment-specific constants
