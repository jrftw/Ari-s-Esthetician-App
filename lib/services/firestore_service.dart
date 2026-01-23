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
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/client_model.dart';
import '../models/business_settings_model.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';

// MARK: - Firestore Service
/// Service for all Firestore database operations
/// Handles CRUD operations for services, appointments, clients, and settings
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<void> updateAppointment(AppointmentModel appointment) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .doc(appointment.id)
          .update(appointment.copyWith(updatedAt: DateTime.now()).toFirestore());

      AppLogger().logInfo('Appointment updated: ${appointment.id}', tag: 'FirestoreService');
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
}

// Suggestions For Features and Additions Later:
// - Add real-time listeners for appointments
// - Add pagination for large datasets
// - Add batch operations
// - Add transaction support for critical operations
// - Add caching layer
