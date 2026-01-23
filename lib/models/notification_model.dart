/*
 * Filename: notification_model.dart
 * Purpose: Data model for admin notifications tracking appointment events
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

// MARK: - Notification Type Enum
/// Type of notification event
enum NotificationType {
  @JsonValue('appointment_created')
  appointmentCreated,
  @JsonValue('appointment_updated')
  appointmentUpdated,
  @JsonValue('appointment_canceled')
  appointmentCanceled,
  @JsonValue('appointment_status_changed')
  appointmentStatusChanged,
}

// MARK: - Notification Model
/// Represents a notification for admin users about appointment events
/// This model tracks all appointment-related activities for admin visibility
@JsonSerializable()
class NotificationModel extends Equatable {
  /// Unique identifier for the notification
  final String id;
  
  /// Type of notification event
  final NotificationType type;
  
  /// Title of the notification
  final String title;
  
  /// Detailed message describing the event
  final String message;
  
  /// ID of the related appointment
  final String appointmentId;
  
  /// Client name associated with the appointment
  final String clientName;
  
  /// Client email associated with the appointment
  final String clientEmail;
  
  /// Appointment start time
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? appointmentStartTime;
  
  /// Previous status (for status change notifications)
  final String? previousStatus;
  
  /// New status (for status change notifications)
  final String? newStatus;
  
  /// Whether the notification has been read by an admin
  final bool isRead;
  
  /// Whether the notification has been archived
  final bool isArchived;
  
  /// Timestamp when the notification was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when the notification was read (if read)
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? readAt;
  
  /// Timestamp when the notification was archived (if archived)
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? archivedAt;

  // MARK: - Constructor
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.appointmentId,
    required this.clientName,
    required this.clientEmail,
    this.appointmentStartTime,
    this.previousStatus,
    this.newStatus,
    this.isRead = false,
    this.isArchived = false,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
  });

  // MARK: - Factory Constructors
  /// Create a NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Create a notification for appointment created event
  factory NotificationModel.appointmentCreated({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    required DateTime appointmentStartTime,
  }) {
    final now = DateTime.now();
    return NotificationModel(
      id: '', // Will be set by Firestore
      type: NotificationType.appointmentCreated,
      title: 'New Appointment Booked',
      message: '$clientName has booked an appointment for ${_formatDateTime(appointmentStartTime)}',
      appointmentId: appointmentId,
      clientName: clientName,
      clientEmail: clientEmail,
      appointmentStartTime: appointmentStartTime,
      isRead: false,
      isArchived: false,
      createdAt: now,
    );
  }

  /// Create a notification for appointment updated event
  factory NotificationModel.appointmentUpdated({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    DateTime? appointmentStartTime,
  }) {
    final now = DateTime.now();
    return NotificationModel(
      id: '', // Will be set by Firestore
      type: NotificationType.appointmentUpdated,
      title: 'Appointment Updated',
      message: 'Appointment for $clientName has been updated',
      appointmentId: appointmentId,
      clientName: clientName,
      clientEmail: clientEmail,
      appointmentStartTime: appointmentStartTime,
      isRead: false,
      isArchived: false,
      createdAt: now,
    );
  }

  /// Create a notification for appointment canceled event
  factory NotificationModel.appointmentCanceled({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    DateTime? appointmentStartTime,
  }) {
    final now = DateTime.now();
    return NotificationModel(
      id: '', // Will be set by Firestore
      type: NotificationType.appointmentCanceled,
      title: 'Appointment Canceled',
      message: '$clientName has canceled their appointment${appointmentStartTime != null ? ' for ${_formatDateTime(appointmentStartTime)}' : ''}',
      appointmentId: appointmentId,
      clientName: clientName,
      clientEmail: clientEmail,
      appointmentStartTime: appointmentStartTime,
      isRead: false,
      isArchived: false,
      createdAt: now,
    );
  }

  /// Create a notification for appointment status changed event
  factory NotificationModel.appointmentStatusChanged({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    required String previousStatus,
    required String newStatus,
    DateTime? appointmentStartTime,
  }) {
    final now = DateTime.now();
    return NotificationModel(
      id: '', // Will be set by Firestore
      type: NotificationType.appointmentStatusChanged,
      title: 'Appointment Status Changed',
      message: 'Appointment for $clientName changed from ${_formatStatus(previousStatus)} to ${_formatStatus(newStatus)}',
      appointmentId: appointmentId,
      clientName: clientName,
      clientEmail: clientEmail,
      appointmentStartTime: appointmentStartTime,
      previousStatus: previousStatus,
      newStatus: newStatus,
      isRead: false,
      isArchived: false,
      createdAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Convert NotificationModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    return json;
  }

  // MARK: - Helper Methods
  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? appointmentId,
    String? clientName,
    String? clientEmail,
    DateTime? appointmentStartTime,
    String? previousStatus,
    String? newStatus,
    bool? isRead,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? archivedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      appointmentId: appointmentId ?? this.appointmentId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      appointmentStartTime: appointmentStartTime ?? this.appointmentStartTime,
      previousStatus: previousStatus ?? this.previousStatus,
      newStatus: newStatus ?? this.newStatus,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  /// Mark notification as read
  NotificationModel markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Mark notification as archived
  NotificationModel markAsArchived() {
    return copyWith(
      isArchived: true,
      archivedAt: DateTime.now(),
    );
  }

  /// Mark notification as unarchived
  NotificationModel markAsUnarchived() {
    return copyWith(
      isArchived: false,
      archivedAt: null,
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        appointmentId,
        clientName,
        clientEmail,
        appointmentStartTime,
        previousStatus,
        newStatus,
        isRead,
        isArchived,
        createdAt,
        readAt,
        archivedAt,
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

  // MARK: - Formatting Helpers
  static String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year at $hour:$minute $amPm';
  }

  static String _formatStatus(String status) {
    // Convert snake_case to Title Case
    return status.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// Suggestions For Features and Additions Later:
// - Add notification priority levels
// - Add notification categories/filtering
// - Add notification expiration/auto-cleanup
// - Add notification actions (e.g., "View Appointment", "Contact Client")
// - Add push notification integration
// - Add email notification integration
// - Add notification preferences per admin user
