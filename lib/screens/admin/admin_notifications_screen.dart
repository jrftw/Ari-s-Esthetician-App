/*
 * Filename: admin_notifications_screen.dart
 * Purpose: Admin screen for viewing notification history of appointment events
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter, cloud_firestore, intl
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

// MARK: - Admin Notifications Screen
/// Screen for viewing all appointment-related notifications
/// Shows notification history with read/unread status
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

// MARK: - Admin Notifications Screen State
class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  // MARK: - Services
  final NotificationService _notificationService = NotificationService();

  // MARK: - State Variables
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    logUI('AdminNotificationsScreen initState called', tag: 'AdminNotificationsScreen');
    _loadNotifications();
  }

  // MARK: - Data Loading
  /// Load notifications from Firestore with real-time updates
  void _loadNotifications() {
    logLoading('Loading notifications...', tag: 'AdminNotificationsScreen');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load notifications stream for real-time updates
      final stream = _notificationService.getNotificationsStream(includeArchived: _showArchived);
      stream.listen(
        (notifications) {
          logSuccess('Loaded ${notifications.length} notifications', tag: 'AdminNotificationsScreen');
          if (mounted) {
            setState(() {
              _notifications = notifications;
              _unreadCount = notifications.where((n) => !n.isRead).length;
              _isLoading = false;
            });
          }
        },
        onError: (error, stackTrace) {
          logError(
            'Failed to load notifications',
            tag: 'AdminNotificationsScreen',
            error: error,
            stackTrace: stackTrace,
          );
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
              _isLoading = false;
            });
          }
        },
      );

      // Also load unread count stream
      final unreadStream = _notificationService.getUnreadNotificationsCountStream();
      unreadStream.listen(
        (count) {
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        },
        onError: (error, stackTrace) {
          logError(
            'Failed to load unread count',
            tag: 'AdminNotificationsScreen',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to initialize notifications stream',
        tag: 'AdminNotificationsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // MARK: - Notification Actions
  /// Mark a notification as read
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      logLoading('Marking notification as read: ${notification.id}', tag: 'AdminNotificationsScreen');
      await _notificationService.markNotificationAsRead(notification.id);
      logSuccess('Notification marked as read', tag: 'AdminNotificationsScreen');
    } catch (e, stackTrace) {
      logError(
        'Failed to mark notification as read',
        tag: 'AdminNotificationsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      logLoading('Marking all notifications as read...', tag: 'AdminNotificationsScreen');
      await _notificationService.markAllNotificationsAsRead();
      logSuccess('All notifications marked as read', tag: 'AdminNotificationsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to mark all notifications as read',
        tag: 'AdminNotificationsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Archive a notification
  Future<void> _archiveNotification(NotificationModel notification) async {
    try {
      logLoading('Archiving notification: ${notification.id}', tag: 'AdminNotificationsScreen');
      await _notificationService.archiveNotification(notification.id);
      logSuccess('Notification archived', tag: 'AdminNotificationsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification archived'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to archive notification',
        tag: 'AdminNotificationsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Unarchive a notification
  Future<void> _unarchiveNotification(NotificationModel notification) async {
    try {
      logLoading('Unarchiving notification: ${notification.id}', tag: 'AdminNotificationsScreen');
      await _notificationService.unarchiveNotification(notification.id);
      logSuccess('Notification unarchived', tag: 'AdminNotificationsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification unarchived'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to unarchive notification',
        tag: 'AdminNotificationsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unarchive: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Delete a notification
  Future<void> _deleteNotification(NotificationModel notification) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      logLoading('Deleting notification: ${notification.id}', tag: 'AdminNotificationsScreen');
      await _notificationService.deleteNotification(notification.id);
      logSuccess('Notification deleted', tag: 'AdminNotificationsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      logError(
        'Failed to delete notification',
        tag: 'AdminNotificationsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Dismiss a notification (mark as read without navigating)
  Future<void> _dismissNotification(NotificationModel notification) async {
    await _markAsRead(notification);
  }

  /// Navigate to appointment details
  void _navigateToAppointment(String appointmentId) {
    logInfo('Navigating to appointment: $appointmentId', tag: 'AdminNotificationsScreen');
    context.push('${AppConstants.routeAdminAppointments}?appointmentId=$appointmentId');
  }

  // MARK: - UI Builders
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Toggle archived notifications
          IconButton(
            icon: Icon(_showArchived ? Icons.archive : Icons.archive_outlined),
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
              _loadNotifications();
            },
            tooltip: _showArchived ? 'Hide Archived' : 'Show Archived',
          ),
          if (_unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All Read'),
              onPressed: _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              'Error loading notifications',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: AppColors.darkBrown,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see notifications here when appointments are created, updated, or canceled.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = !notification.isRead;
    final isArchived = notification.isArchived;
    final icon = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isUnread
          ? AppColors.sunflowerYellow.withOpacity(0.1)
          : isArchived
              ? AppColors.textSecondary.withOpacity(0.05)
              : null,
      child: InkWell(
        onTap: () {
          if (!isArchived) {
            _markAsRead(notification);
            _navigateToAppointment(notification.appointmentId);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  decoration: isArchived ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (isUnread && !isArchived)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.sunflowerYellow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (isArchived)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Archived',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: AppTypography.bodyMedium.copyWith(
                            decoration: isArchived ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              notification.clientName,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(notification.createdAt),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (notification.appointmentStartTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Appointment: ${_formatDateTime(notification.appointmentStartTime!)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Action buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Dismiss button (mark as read)
                  if (!notification.isRead && !isArchived)
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Dismiss'),
                      onPressed: () => _dismissNotification(notification),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkBrown,
                      ),
                    ),
                  // Archive/Unarchive button
                  if (!isArchived)
                    TextButton.icon(
                      icon: const Icon(Icons.archive, size: 16),
                      label: const Text('Archive'),
                      onPressed: () => _archiveNotification(notification),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkBrown,
                      ),
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.unarchive, size: 16),
                      label: const Text('Unarchive'),
                      onPressed: () => _unarchiveNotification(notification),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkBrown,
                      ),
                    ),
                  // Delete button
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    onPressed: () => _deleteNotification(notification),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Helper Methods
  /// Get icon for notification type
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentCreated:
        return Icons.event_available;
      case NotificationType.appointmentUpdated:
        return Icons.edit;
      case NotificationType.appointmentCanceled:
        return Icons.cancel;
      case NotificationType.appointmentStatusChanged:
        return Icons.swap_horiz;
    }
  }

  /// Get color for notification type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentCreated:
        return AppColors.successGreen;
      case NotificationType.appointmentUpdated:
        return AppColors.sunflowerYellow;
      case NotificationType.appointmentCanceled:
        return AppColors.errorRed;
      case NotificationType.appointmentStatusChanged:
        return AppColors.darkBrown;
    }
  }

  /// Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add notification filtering by type
// - Add notification search functionality
// - Add notification grouping by date
// - Add swipe actions (mark as read, delete)
// - Add notification preferences
// - Add push notification integration
// - Add email notification integration
