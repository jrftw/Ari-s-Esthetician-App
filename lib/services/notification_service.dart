/*
 * Filename: notification_service.dart
 * Purpose: Service for managing admin notifications about appointment events
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: cloud_firestore, notification_model
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';

// MARK: - Notification Service
/// Service for managing notifications for admin users
/// Tracks appointment events and provides real-time updates
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // MARK: - Notification Creation
  /// Create a notification for appointment created event
  Future<void> createAppointmentCreatedNotification({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    required DateTime appointmentStartTime,
  }) async {
    try {
      final notification = NotificationModel.appointmentCreated(
        appointmentId: appointmentId,
        clientName: clientName,
        clientEmail: clientEmail,
        appointmentStartTime: appointmentStartTime,
      );

      await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .add(notification.toFirestore());

      AppLogger().logInfo(
        'Created appointment created notification: $appointmentId',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create appointment created notification',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - notification creation failure shouldn't break appointment flow
    }
  }

  /// Create a notification for appointment updated event
  Future<void> createAppointmentUpdatedNotification({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    DateTime? appointmentStartTime,
  }) async {
    try {
      final notification = NotificationModel.appointmentUpdated(
        appointmentId: appointmentId,
        clientName: clientName,
        clientEmail: clientEmail,
        appointmentStartTime: appointmentStartTime,
      );

      await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .add(notification.toFirestore());

      AppLogger().logInfo(
        'Created appointment updated notification: $appointmentId',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create appointment updated notification',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - notification creation failure shouldn't break appointment flow
    }
  }

  /// Create a notification for appointment canceled event
  Future<void> createAppointmentCanceledNotification({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    DateTime? appointmentStartTime,
  }) async {
    try {
      final notification = NotificationModel.appointmentCanceled(
        appointmentId: appointmentId,
        clientName: clientName,
        clientEmail: clientEmail,
        appointmentStartTime: appointmentStartTime,
      );

      await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .add(notification.toFirestore());

      AppLogger().logInfo(
        'Created appointment canceled notification: $appointmentId',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create appointment canceled notification',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - notification creation failure shouldn't break appointment flow
    }
  }

  /// Create a notification for appointment status changed event
  Future<void> createAppointmentStatusChangedNotification({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    required String previousStatus,
    required String newStatus,
    DateTime? appointmentStartTime,
  }) async {
    try {
      final notification = NotificationModel.appointmentStatusChanged(
        appointmentId: appointmentId,
        clientName: clientName,
        clientEmail: clientEmail,
        previousStatus: previousStatus,
        newStatus: newStatus,
        appointmentStartTime: appointmentStartTime,
      );

      await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .add(notification.toFirestore());

      AppLogger().logInfo(
        'Created appointment status changed notification: $appointmentId',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create appointment status changed notification',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - notification creation failure shouldn't break appointment flow
    }
  }

  // MARK: - Notification Retrieval
  /// Get all notifications (for admin)
  /// Returns notifications sorted by creation date (newest first)
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all notifications',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get unread notifications count',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return 0; // Return 0 on error to avoid breaking UI
    }
  }

  /// Get notifications stream (real-time updates)
  /// Returns notifications sorted by creation date (newest first)
  Stream<List<NotificationModel>> getNotificationsStream() {
    try {
      return _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get notifications stream',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream.value([]);
    }
  }

  /// Get unread notifications count stream (real-time updates)
  Stream<int> getUnreadNotificationsCountStream() {
    try {
      return _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get unread notifications count stream',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream.value(0);
    }
  }

  // MARK: - Notification Management
  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      AppLogger().logInfo(
        'Marked notification as read: $notificationId',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to mark notification as read',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final unreadNotifications = await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': now,
        });
      }

      await batch.commit();

      AppLogger().logInfo(
        'Marked ${unreadNotifications.docs.length} notifications as read',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to mark all notifications as read',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .doc(notificationId)
          .delete();

      AppLogger().logInfo(
        'Deleted notification: $notificationId',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete notification',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete old notifications (cleanup)
  /// Deletes notifications older than the specified number of days
  Future<void> deleteOldNotifications({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final oldNotifications = await _firestore
          .collection(AppConstants.firestoreNotificationsCollection)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      AppLogger().logInfo(
        'Deleted ${oldNotifications.docs.length} old notifications',
        tag: 'NotificationService',
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete old notifications',
        tag: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - cleanup failure shouldn't break the app
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add notification filtering by type
// - Add notification pagination
// - Add notification search functionality
// - Add notification grouping by date
// - Add notification export functionality
// - Add notification preferences (email, push, etc.)
