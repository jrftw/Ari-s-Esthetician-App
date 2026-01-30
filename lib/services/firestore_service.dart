/*
 * Filename: firestore_service.dart
 * Purpose: Firestore database service for CRUD operations on all data models
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: cloud_firestore, models
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/service_category_model.dart';
import '../models/appointment_model.dart';
import '../models/client_model.dart';
import '../models/business_settings_model.dart';
import '../models/software_enhancement_model.dart';
import '../models/time_off_model.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';
import 'notification_service.dart';

// MARK: - Firestore Service
/// Service for all Firestore database operations
/// Handles CRUD operations for services, appointments, clients, and settings
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // MARK: - Service Operations
  /// Get all active services
  Future<List<ServiceModel>> getActiveServices() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get active services',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all services (including inactive)
  Future<List<ServiceModel>> getAllServices() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all services',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get a service by ID
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .doc(serviceId)
          .get();

      if (!doc.exists) return null;
      return ServiceModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get service by ID',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new service
  Future<String> createService(ServiceModel service) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .add(service.toFirestore());

      AppLogger().logInfo('Service created: ${docRef.id}', tag: 'FirestoreService');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create service',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing service
  Future<void> updateService(ServiceModel service) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .doc(service.id)
          .update(service.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Service updated: ${service.id}', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update service',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a service
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreServicesCollection)
          .doc(serviceId)
          .delete();

      AppLogger().logInfo('Service deleted: $serviceId', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete service',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Appointment Operations
  /// Create a new appointment
  /// This method includes backend validation to prevent double-booking
  /// Also syncs/updates client record with booking information
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      // Backend validation: Check for overlapping appointments
      final overlapping = await _checkOverlappingAppointments(
        appointment.startTime,
        appointment.endTime,
      );

      if (overlapping.isNotEmpty) {
        throw Exception('Time slot is already booked');
      }

      final docRef = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .add(appointment.toFirestore());

      AppLogger().logInfo('Appointment created: ${docRef.id}', tag: 'FirestoreService');
      
      // Sync client data - create or update client record
      try {
        await _syncClientFromAppointment(appointment);
      } catch (e, stackTrace) {
        // Log error but don't fail appointment creation if client sync fails
        AppLogger().logError(
          'Failed to sync client data for appointment',
          tag: 'FirestoreService',
          error: e,
          stackTrace: stackTrace,
        );
      }
      
      // Create notification for admin
      _notificationService.createAppointmentCreatedNotification(
        appointmentId: docRef.id,
        clientName: appointment.clientFullName,
        clientEmail: appointment.clientEmail,
        appointmentStartTime: appointment.startTime,
      );
      
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create appointment',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check for overlapping appointments
  Future<List<AppointmentModel>> _checkOverlappingAppointments(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('status', whereIn: [
            AppointmentStatus.confirmed.name,
            AppointmentStatus.arrived.name,
          ])
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      return appointments.where((apt) {
        // Check if appointments overlap
        return (apt.startTime.isBefore(endTime) && apt.endTime.isAfter(startTime));
      }).toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to check overlapping appointments',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get appointments for a date range
  Future<List<AppointmentModel>> getAppointmentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get appointments by date range',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!doc.exists) return null;
      return AppointmentModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get appointment by ID',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update appointment
  /// Also updates client stats when appointment status changes
  Future<void> updateAppointment(AppointmentModel appointment) async {
    try {
      // Get previous appointment to compare status
      final previousAppointment = await getAppointmentById(appointment.id);
      final previousStatus = previousAppointment?.status;
      final newStatus = appointment.status;
      
      await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .doc(appointment.id)
          .update(appointment.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Appointment updated: ${appointment.id}', tag: 'FirestoreService');
      
      // Update client stats if status changed
      if (previousStatus != null && previousStatus != newStatus) {
        try {
          await _updateClientStatsFromAppointmentChange(
            appointment: appointment,
            previousStatus: previousStatus,
            newStatus: newStatus,
          );
        } catch (e, stackTrace) {
          // Log error but don't fail appointment update if client stats update fails
          AppLogger().logError(
            'Failed to update client stats for appointment',
            tag: 'FirestoreService',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
      
      // Create notifications based on what changed
      if (previousStatus != null && previousStatus != newStatus) {
        // Status changed - create status change notification
        if (newStatus == AppointmentStatus.canceled) {
          // Special handling for cancellations
          _notificationService.createAppointmentCanceledNotification(
            appointmentId: appointment.id,
            clientName: appointment.clientFullName,
            clientEmail: appointment.clientEmail,
            appointmentStartTime: appointment.startTime,
          );
        } else {
          // General status change
          _notificationService.createAppointmentStatusChangedNotification(
            appointmentId: appointment.id,
            clientName: appointment.clientFullName,
            clientEmail: appointment.clientEmail,
            previousStatus: previousStatus.name,
            newStatus: newStatus.name,
            appointmentStartTime: appointment.startTime,
          );
        }
      } else {
        // General update (no status change)
        _notificationService.createAppointmentUpdatedNotification(
          appointmentId: appointment.id,
          clientName: appointment.clientFullName,
          clientEmail: appointment.clientEmail,
          appointmentStartTime: appointment.startTime,
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update appointment',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete appointment
  /// Also updates client stats when appointment is deleted
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      // Get appointment details before deleting for notification
      final appointment = await getAppointmentById(appointmentId);
      
      if (appointment == null) {
        AppLogger().logWarning('Appointment not found for deletion: $appointmentId', tag: 'FirestoreService');
        return;
      }

      await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .doc(appointmentId)
          .delete();

      AppLogger().logInfo('Appointment deleted: $appointmentId', tag: 'FirestoreService');
      
      // Update client stats - decrement appointment count
      try {
        final snapshot = await _firestore
            .collection(AppConstants.firestoreClientsCollection)
            .where('email', isEqualTo: appointment.clientEmail)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final client = ClientModel.fromFirestore(snapshot.docs.first);
          final clientDocId = snapshot.docs.first.id;

          // Decrement stats based on appointment status
          int completedDelta = 0;
          int noShowDelta = 0;
          int totalSpentDelta = 0;

          if (appointment.status == AppointmentStatus.completed) {
            completedDelta = -1;
            totalSpentDelta = -(appointment.depositAmountCents + appointment.totalTipAmountCents);
          } else if (appointment.status == AppointmentStatus.noShow) {
            noShowDelta = -1;
          }

          final updatedClient = client.copyWith(
            totalAppointments: (client.totalAppointments - 1).clamp(0, double.infinity).toInt(),
            completedAppointments: (client.completedAppointments + completedDelta).clamp(0, double.infinity).toInt(),
            noShowCount: (client.noShowCount + noShowDelta).clamp(0, double.infinity).toInt(),
            totalSpentCents: (client.totalSpentCents + totalSpentDelta).clamp(0, double.infinity).toInt(),
          );

          await _firestore
              .collection(AppConstants.firestoreClientsCollection)
              .doc(clientDocId)
              .update(updatedClient.toFirestore());

          AppLogger().logInfo('Client stats updated after appointment deletion: $clientDocId', tag: 'FirestoreService');
        }
      } catch (e, stackTrace) {
        // Log error but don't fail deletion if client stats update fails
        AppLogger().logError(
          'Failed to update client stats after appointment deletion',
          tag: 'FirestoreService',
          error: e,
          stackTrace: stackTrace,
        );
      }
      
      // Create notification for deletion
      _notificationService.createAppointmentCanceledNotification(
        appointmentId: appointmentId,
        clientName: appointment.clientFullName,
        clientEmail: appointment.clientEmail,
        appointmentStartTime: appointment.startTime,
      );
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete appointment',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get appointments stream (real-time updates)
  Stream<List<AppointmentModel>> getAppointmentsStream({
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) {
    try {
      Query query = _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .orderBy('startTime', descending: false);

      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList();
      });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get appointments stream',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get appointments by status
  Future<List<AppointmentModel>> getAppointmentsByStatus(AppointmentStatus status) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('status', isEqualTo: status.name)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get appointments by status',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get appointments by client email
  Future<List<AppointmentModel>> getAppointmentsByClientEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('clientEmail', isEqualTo: email)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get appointments by client email',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get appointments stream by client email (real-time updates)
  /// Returns a stream of appointments for a specific client email
  /// Note: Requires Firestore composite index on (clientEmail, startTime)
  Stream<List<AppointmentModel>> getAppointmentsByClientEmailStream(String email) {
    try {
      return _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('clientEmail', isEqualTo: email)
          .orderBy('startTime', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => AppointmentModel.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get appointments stream by client email',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  /// Get all appointments (for admin view)
  Future<List<AppointmentModel>> getAllAppointments() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all appointments',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all appointments stream for public schedule view (clients can see schedule)
  /// Note: Personal information (name, email, phone, notes, payment info) should be filtered
  /// in the UI when displaying to clients. Only show: service, startTime, endTime, status
  Stream<List<AppointmentModel>> getPublicScheduleAppointmentsStream() {
    try {
      return _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('status', whereIn: [
            'confirmed',
            'arrived',
          ])
          .orderBy('startTime')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => AppointmentModel.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get public schedule appointments stream',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  /// Get all appointments for public schedule view (clients can see schedule)
  /// Note: Personal information (name, email, phone, notes, payment info) should be filtered
  /// in the UI when displaying to clients. Only show: service, startTime, endTime, status
  Future<List<AppointmentModel>> getPublicScheduleAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('status', whereIn: [
            'confirmed',
            'arrived',
          ]);

      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.orderBy('startTime').get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get public schedule appointments',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Client Operations
  /// Get or create client by email
  Future<ClientModel> getOrCreateClient({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      // Try to find existing client by email
      final snapshot = await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ClientModel.fromFirestore(snapshot.docs.first);
      }

      // Create new client
      final client = ClientModel.create(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      final docRef = await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .add(client.toFirestore());

      AppLogger().logInfo('Client created: ${docRef.id}', tag: 'FirestoreService');
      return client.copyWith(id: docRef.id);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get or create client',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Client Sync Helpers
  /// Sync client record from appointment data
  /// Creates or updates client record with appointment information
  Future<void> _syncClientFromAppointment(AppointmentModel appointment) async {
    try {
      // Find existing client by email
      final snapshot = await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .where('email', isEqualTo: appointment.clientEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Update existing client
        final existingClient = ClientModel.fromFirestore(snapshot.docs.first);
        final clientDocId = snapshot.docs.first.id;

        // Update client info if missing or different
        final updatedClient = existingClient.copyWith(
          firstName: existingClient.firstName.isEmpty
              ? appointment.clientFirstName
              : existingClient.firstName,
          lastName: existingClient.lastName.isEmpty
              ? appointment.clientLastName
              : existingClient.lastName,
          phone: existingClient.phone.isEmpty
              ? appointment.clientPhone
              : existingClient.phone,
          // Increment total appointments
          totalAppointments: existingClient.totalAppointments + 1,
        );

        await _firestore
            .collection(AppConstants.firestoreClientsCollection)
            .doc(clientDocId)
            .update(updatedClient.toFirestore());

        AppLogger().logInfo('Client updated from appointment: $clientDocId', tag: 'FirestoreService');
      } else {
        // Create new client
        final client = ClientModel.create(
          firstName: appointment.clientFirstName,
          lastName: appointment.clientLastName,
          email: appointment.clientEmail,
          phone: appointment.clientPhone,
        ).copyWith(
          totalAppointments: 1,
        );

        await _firestore
            .collection(AppConstants.firestoreClientsCollection)
            .add(client.toFirestore());

        AppLogger().logInfo('Client created from appointment: ${appointment.clientEmail}', tag: 'FirestoreService');
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to sync client from appointment',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update client stats when appointment status changes
  Future<void> _updateClientStatsFromAppointmentChange({
    required AppointmentModel appointment,
    required AppointmentStatus previousStatus,
    required AppointmentStatus newStatus,
  }) async {
    try {
      // Find client by email
      final snapshot = await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .where('email', isEqualTo: appointment.clientEmail)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        AppLogger().logWarning('Client not found for appointment: ${appointment.clientEmail}', tag: 'FirestoreService');
        return;
      }

      final client = ClientModel.fromFirestore(snapshot.docs.first);
      final clientDocId = snapshot.docs.first.id;

      // Calculate changes based on status transitions
      int completedDelta = 0;
      int noShowDelta = 0;
      int totalSpentDelta = 0;

      // Handle previous status removal
      if (previousStatus == AppointmentStatus.completed) {
        completedDelta -= 1;
        // Subtract previous payment amount
        totalSpentDelta -= (appointment.depositAmountCents + appointment.totalTipAmountCents);
      } else if (previousStatus == AppointmentStatus.noShow) {
        noShowDelta -= 1;
      }

      // Handle new status addition
      if (newStatus == AppointmentStatus.completed) {
        completedDelta += 1;
        // Add payment amount
        totalSpentDelta += (appointment.depositAmountCents + appointment.totalTipAmountCents);
      } else if (newStatus == AppointmentStatus.noShow) {
        noShowDelta += 1;
      }

      // Update client stats
      final updatedClient = client.copyWith(
        completedAppointments: (client.completedAppointments + completedDelta).clamp(0, double.infinity).toInt(),
        noShowCount: (client.noShowCount + noShowDelta).clamp(0, double.infinity).toInt(),
        totalSpentCents: (client.totalSpentCents + totalSpentDelta).clamp(0, double.infinity).toInt(),
        lastAppointmentAt: newStatus == AppointmentStatus.completed ? appointment.startTime : client.lastAppointmentAt,
      );

      await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .doc(clientDocId)
          .update(updatedClient.toFirestore());

      AppLogger().logInfo('Client stats updated: $clientDocId', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update client stats from appointment change',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Recalculate client stats from all appointments
  /// Useful for fixing inconsistencies or bulk updates
  Future<void> recalculateClientStats(String clientEmail) async {
    try {
      // Get all appointments for this client
      final appointmentsSnapshot = await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .where('clientEmail', isEqualTo: clientEmail)
          .get();

      final appointments = appointmentsSnapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      // Calculate stats
      int totalAppointments = appointments.length;
      int completedAppointments = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .length;
      int noShowCount = appointments
          .where((apt) => apt.status == AppointmentStatus.noShow)
          .length;
      int totalSpentCents = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .fold<int>(0, (sum, apt) => sum + apt.depositAmountCents + apt.totalTipAmountCents);

      // Get most recent completed appointment
      final completedAppointmentsList = appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .toList();
      DateTime? lastAppointmentAt;
      if (completedAppointmentsList.isNotEmpty) {
        completedAppointmentsList.sort((a, b) => b.startTime.compareTo(a.startTime));
        lastAppointmentAt = completedAppointmentsList.first.startTime;
      }

      // Find and update client
      final clientSnapshot = await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .where('email', isEqualTo: clientEmail)
          .limit(1)
          .get();

      if (clientSnapshot.docs.isEmpty) {
        AppLogger().logWarning('Client not found for recalculation: $clientEmail', tag: 'FirestoreService');
        return;
      }

      final client = ClientModel.fromFirestore(clientSnapshot.docs.first);
      final updatedClient = client.copyWith(
        totalAppointments: totalAppointments,
        completedAppointments: completedAppointments,
        noShowCount: noShowCount,
        totalSpentCents: totalSpentCents,
        lastAppointmentAt: lastAppointmentAt,
      );

      await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .doc(clientSnapshot.docs.first.id)
          .update(updatedClient.toFirestore());

      AppLogger().logInfo('Client stats recalculated: ${clientSnapshot.docs.first.id}', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to recalculate client stats',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all clients
  Future<List<ClientModel>> getAllClients() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .orderBy('lastName')
          .orderBy('firstName')
          .get();

      return snapshot.docs
          .map((doc) => ClientModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all clients',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Search clients by name, email, or phone
  Future<List<ClientModel>> searchClients(String query) async {
    try {
      final allClients = await getAllClients();
      final lowerQuery = query.toLowerCase();

      return allClients.where((client) {
        return client.firstName.toLowerCase().contains(lowerQuery) ||
            client.lastName.toLowerCase().contains(lowerQuery) ||
            client.email.toLowerCase().contains(lowerQuery) ||
            client.phone.contains(query);
      }).toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to search clients',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update client
  Future<void> updateClient(ClientModel client) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreClientsCollection)
          .doc(client.id)
          .update(client.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Client updated: ${client.id}', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update client',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Business Settings Operations
  /// Get business settings
  Future<BusinessSettingsModel?> getBusinessSettings() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreBusinessSettingsCollection)
          .doc('main')
          .get();

      if (!doc.exists) return null;
      return BusinessSettingsModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get business settings',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update business settings
  Future<void> updateBusinessSettings(BusinessSettingsModel settings) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreBusinessSettingsCollection)
          .doc(settings.id)
          .set(settings.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Business settings updated', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update business settings',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Service Category Operations
  /// Get all active categories
  /// Returns categories sorted by sortOrder, then name
  Future<List<ServiceCategoryModel>> getActiveCategories() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      final categories = snapshot.docs
          .map((doc) => ServiceCategoryModel.fromFirestore(doc))
          .toList();

      AppLogger().logInfo('Loaded ${categories.length} active categories', tag: 'FirestoreService');
      return categories;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get active categories',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all categories (including inactive)
  /// Returns categories sorted by isActive (active first), then sortOrder, then name
  Future<List<ServiceCategoryModel>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .orderBy('isActive', descending: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      final categories = snapshot.docs
          .map((doc) => ServiceCategoryModel.fromFirestore(doc))
          .toList();

      AppLogger().logInfo('Loaded ${categories.length} categories', tag: 'FirestoreService');
      return categories;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all categories',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get categories stream (real-time updates)
  /// Returns only active categories
  Stream<List<ServiceCategoryModel>> getActiveCategoriesStream() {
    try {
      return _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ServiceCategoryModel.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get active categories stream',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get a category by ID
  Future<ServiceCategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .doc(categoryId)
          .get();

      if (!doc.exists) return null;
      return ServiceCategoryModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get category by ID',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new category
  Future<String> createCategory(ServiceCategoryModel category) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .add(category.toFirestore());

      AppLogger().logInfo('Category created: ${docRef.id}', tag: 'FirestoreService');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create category',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing category
  Future<void> updateCategory(ServiceCategoryModel category) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .doc(category.id)
          .update(category.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Category updated: ${category.id}', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update category',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Soft delete a category (set isActive to false)
  /// Does NOT update services that reference this category
  Future<void> deleteCategory(String categoryId) async {
    try {
      final category = await getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Category not found: $categoryId');
      }

      // Soft delete: set isActive to false
      await _firestore
          .collection(AppConstants.firestoreServiceCategoriesCollection)
          .doc(categoryId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger().logInfo('Category soft deleted: $categoryId', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete category',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Software Enhancement Operations
  /// Get all software enhancements
  Future<List<SoftwareEnhancementModel>> getAllSoftwareEnhancements() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreSoftwareEnhancementsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SoftwareEnhancementModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all software enhancements',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get software enhancements stream (real-time updates)
  Stream<List<SoftwareEnhancementModel>> getSoftwareEnhancementsStream() {
    try {
      return _firestore
          .collection(AppConstants.firestoreSoftwareEnhancementsCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => SoftwareEnhancementModel.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get software enhancements stream',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  /// Get a software enhancement by ID
  Future<SoftwareEnhancementModel?> getSoftwareEnhancementById(String enhancementId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreSoftwareEnhancementsCollection)
          .doc(enhancementId)
          .get();

      if (!doc.exists) return null;
      return SoftwareEnhancementModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get software enhancement by ID',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new software enhancement
  Future<String> createSoftwareEnhancement(SoftwareEnhancementModel enhancement) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.firestoreSoftwareEnhancementsCollection)
          .add(enhancement.toFirestore());

      AppLogger().logInfo('Software enhancement created: ${docRef.id}', tag: 'FirestoreService');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create software enhancement',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing software enhancement
  Future<void> updateSoftwareEnhancement(SoftwareEnhancementModel enhancement) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreSoftwareEnhancementsCollection)
          .doc(enhancement.id)
          .update(enhancement.toFirestore());

      AppLogger().logInfo('Software enhancement updated: ${enhancement.id}', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update software enhancement',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a software enhancement
  Future<void> deleteSoftwareEnhancement(String enhancementId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreSoftwareEnhancementsCollection)
          .doc(enhancementId)
          .delete();

      AppLogger().logInfo('Software enhancement deleted: $enhancementId', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete software enhancement',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Time-Off Operations
  /// Get all active time-off periods
  Future<List<TimeOffModel>> getAllTimeOff() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => TimeOffModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all time-off',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all time-off periods (including inactive)
  Future<List<TimeOffModel>> getAllTimeOffIncludingInactive() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TimeOffModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get all time-off including inactive',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get time-off periods that overlap with a date range
  Future<List<TimeOffModel>> getTimeOffInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Get all active time-off periods
      final allTimeOff = await getAllTimeOff();
      
      // Filter to those that overlap with the range
      return allTimeOff.where((timeOff) {
        if (!timeOff.isRecurring) {
          // One-time: check if it overlaps
          return timeOff.overlapsWith(startDate, endDate);
        } else {
          // Recurring: check if any occurrence overlaps
          final occurrences = timeOff.getOccurrencesInRange(startDate, endDate);
          return occurrences.isNotEmpty;
        }
      }).toList();
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get time-off in range',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if a time slot is available (not blocked by time-off, appointments, or outside working hours)
  /// When business settings are missing (e.g. no Firestore document), only overlap and time-off are checked.
  Future<bool> isTimeSlotAvailable(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      // MARK: - Business Working Hours Check
      // When getBusinessSettings() returns null (no document), skip this block so slots are only filtered by overlap/time-off.
      final businessSettings = await getBusinessSettings();
      if (businessSettings != null) {
        // Get day of week (0 = Sunday, 6 = Saturday)
        final dayOfWeek = startTime.weekday % 7; // Convert Monday=1 to Sunday=0 format
        
        final dayHours = businessSettings.getHoursForDay(dayOfWeek);
        
        // If business is closed on this day, slot is not available
        if (dayHours == null || !dayHours.isOpen || dayHours.timeSlots.isEmpty) {
          AppLogger().logInfo(
            'Time slot not available: business is closed on day $dayOfWeek',
            tag: 'FirestoreService',
          );
          return false;
        }
        
        // Check if start and end times are within working hours
        bool isWithinWorkingHours = false;
        final startTimeOfDay = TimeOfDay(hour: startTime.hour, minute: startTime.minute);
        final endTimeOfDay = TimeOfDay(hour: endTime.hour, minute: endTime.minute);
        
        for (int i = 0; i < dayHours.timeSlots.length; i += 2) {
          if (i + 1 >= dayHours.timeSlots.length) break;
          
          final startTimeStr = dayHours.timeSlots[i];
          final endTimeStr = dayHours.timeSlots[i + 1];
          
          final startParts = startTimeStr.split(':');
          final endParts = endTimeStr.split(':');
          
          if (startParts.length != 2 || endParts.length != 2) continue;
          
          final slotStartHour = int.tryParse(startParts[0]);
          final slotStartMinute = int.tryParse(startParts[1]);
          final slotEndHour = int.tryParse(endParts[0]);
          final slotEndMinute = int.tryParse(endParts[1]);
          
          if (slotStartHour == null || slotStartMinute == null || slotEndHour == null || slotEndMinute == null) continue;
          
          final slotStartTime = TimeOfDay(hour: slotStartHour, minute: slotStartMinute);
          final slotEndTime = TimeOfDay(hour: slotEndHour, minute: slotEndMinute);
          
          // Check if the appointment time is within this working hour slot
          if (_isTimeOfDayBeforeOrEqual(slotStartTime, startTimeOfDay) &&
              _isTimeOfDayBeforeOrEqual(startTimeOfDay, slotEndTime) &&
              _isTimeOfDayBeforeOrEqual(endTimeOfDay, slotEndTime)) {
            isWithinWorkingHours = true;
            break;
          }
        }
        
        if (!isWithinWorkingHours) {
          AppLogger().logInfo(
            'Time slot not available: outside working hours',
            tag: 'FirestoreService',
          );
          return false;
        }
      }
      
      // MARK: - Appointment Overlap Check
      // Check for overlapping appointments
      final overlappingAppointments = await _checkOverlappingAppointments(
        startTime,
        endTime,
      );
      if (overlappingAppointments.isNotEmpty) {
        return false;
      }

      // MARK: - Time-Off Overlap Check
      // Check for overlapping time-off
      final overlappingTimeOff = await getTimeOffInRange(startTime, endTime);
      for (final timeOff in overlappingTimeOff) {
        if (!timeOff.isRecurring) {
          if (timeOff.overlapsWith(startTime, endTime)) {
            return false;
          }
        } else {
          // Check if any occurrence overlaps
          final occurrences = timeOff.getOccurrencesInRange(startTime, endTime);
          for (final occurrence in occurrences) {
            if (occurrence.start.isBefore(endTime) && 
                occurrence.end.isAfter(startTime)) {
              return false;
            }
          }
        }
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to check time slot availability',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
  
  /// Helper method to compare TimeOfDay values
  bool _isTimeOfDayBeforeOrEqual(TimeOfDay a, TimeOfDay b) {
    if (a.hour < b.hour) return true;
    if (a.hour > b.hour) return false;
    return a.minute <= b.minute;
  }

  /// Get time-off by ID
  Future<TimeOffModel?> getTimeOffById(String timeOffId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .doc(timeOffId)
          .get();

      if (!doc.exists) return null;
      return TimeOffModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get time-off by ID',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a new time-off period
  Future<String> createTimeOff(TimeOffModel timeOff) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .add(timeOff.toFirestore());

      AppLogger().logInfo('Time-off created: ${docRef.id}', tag: 'FirestoreService');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to create time-off',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update an existing time-off period
  Future<void> updateTimeOff(TimeOffModel timeOff) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .doc(timeOff.id)
          .update(timeOff.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Time-off updated: ${timeOff.id}', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to update time-off',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a time-off period
  Future<void> deleteTimeOff(String timeOffId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .doc(timeOffId)
          .delete();

      AppLogger().logInfo('Time-off deleted: $timeOffId', tag: 'FirestoreService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to delete time-off',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get time-off stream (real-time updates)
  Stream<List<TimeOffModel>> getTimeOffStream() {
    try {
      return _firestore
          .collection(AppConstants.firestoreTimeOffCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => TimeOffModel.fromFirestore(doc))
                .toList();
          });
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get time-off stream',
        tag: 'FirestoreService',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty stream on error
      return Stream.value([]);
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add real-time listeners for appointments
// - Add pagination for large datasets
// - Add batch operations
// - Add transaction support for critical operations
// - Add caching layer
