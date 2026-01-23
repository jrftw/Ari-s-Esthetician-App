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
import '../models/service_category_model.dart';
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

  /// Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreAppointmentsCollection)
          .doc(appointmentId)
          .delete();

      AppLogger().logInfo('Appointment deleted: $appointmentId', tag: 'FirestoreService');
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
}

// Suggestions For Features and Additions Later:
// - Add real-time listeners for appointments
// - Add pagination for large datasets
// - Add batch operations
// - Add transaction support for critical operations
// - Add caching layer
