/*
 * Filename: auth_service.dart
 * Purpose: Firebase Authentication service for user login and role management
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: firebase_auth, cloud_firestore, shared_preferences
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../core/logging/app_logger.dart';
import '../core/constants/app_constants.dart';
import 'preferences_service.dart';
import 'firestore_service.dart';
import '../models/client_model.dart';

// MARK: - User Role Enum
/// User roles in the application
enum UserRole {
  admin,
  superAdmin,
  client,
}

// MARK: - Auth Service
/// Service for handling authentication and user role management
/// This service manages Firebase Auth and stores user roles in Firestore
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // MARK: - Auth State Stream
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  // MARK: - Authentication Methods
  /// Sign in with email and password
  /// Returns the user if successful, throws exception on failure
  /// [keepSignedIn] determines if the session should persist across app restarts
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool keepSignedIn = true,
  }) async {
    try {
      AppLogger().logInfo('Attempting to sign in: $email (keepSignedIn: $keepSignedIn)', tag: 'AuthService');
      
      // Firebase Auth persists sessions by default
      // The keepSignedIn parameter is used for preference tracking
      // Firebase Auth will maintain the session automatically
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger().logInfo('Sign in successful: ${userCredential.user?.email}', tag: 'AuthService');
      
      // Note: Firebase Auth automatically persists sessions
      // If keepSignedIn is false, the user can still sign out manually
      // The session will persist until explicitly signed out
      
      return userCredential.user;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger().logError(
        'Sign in failed: ${e.code}',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign up with email and password
  /// Creates a new user account and sets default role to 'client'
  /// Also creates a client record in the clients collection
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    UserRole role = UserRole.client,
  }) async {
    try {
      AppLogger().logInfo('Attempting to sign up: $email', tag: 'AuthService');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set user role in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'role': role.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create client record if user is a client
        if (role == UserRole.client) {
          try {
            // Check if client already exists by email
            final existingClient = await _firestore
                .collection(AppConstants.firestoreClientsCollection)
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

            if (existingClient.docs.isEmpty) {
              // Create new client record with email only
              // Name and phone will be added when they book their first appointment
              final client = ClientModel.create(
                firstName: '', // Will be updated on first booking
                lastName: '', // Will be updated on first booking
                email: email,
                phone: '', // Will be updated on first booking
                userId: userCredential.user!.uid,
              );

              final docRef = await _firestore
                  .collection(AppConstants.firestoreClientsCollection)
                  .add(client.toFirestore());

              AppLogger().logInfo('Client record created for: $email', tag: 'AuthService');
            } else {
              AppLogger().logInfo('Client record already exists for: $email', tag: 'AuthService');
            }
            // Account linking: set userId on client and all appointments with this email
            try {
              await _firestoreService.linkClientAndAppointmentsToUser(
                uid: userCredential.user!.uid,
                email: email,
              );
            } catch (e, stackTrace) {
              AppLogger().logError(
                'Account linking failed (client/appointments may not show userId)',
                tag: 'AuthService',
                error: e,
                stackTrace: stackTrace,
              );
              // Don't fail signup if linking fails; history still loads by email
            }
          } catch (e, stackTrace) {
            // Log error but don't fail signup if client creation fails
            AppLogger().logError(
              'Failed to create client record during signup',
              tag: 'AuthService',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }

      AppLogger().logInfo('Sign up successful: ${userCredential.user?.email}', tag: 'AuthService');
      return userCredential.user;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger().logError(
        'Sign up failed: ${e.code}',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign out current user
  /// Clears the Firebase Auth session
  /// If [clearKeepSignedIn] is true, also clears the "keep signed in" preference
  Future<void> signOut({bool clearKeepSignedIn = true}) async {
    try {
      AppLogger().logInfo('Signing out user (clearKeepSignedIn: $clearKeepSignedIn)', tag: 'AuthService');
      
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Clear keep signed in preference if requested
      if (clearKeepSignedIn) {
        final preferencesService = PreferencesService.instance;
        await preferencesService.setKeepSignedIn(false);
        AppLogger().logInfo('Keep signed in preference cleared', tag: 'AuthService');
      }
      
      AppLogger().logInfo('Sign out successful', tag: 'AuthService');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Sign out failed',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // MARK: - Session Management
  /// Check if user session is persistent
  /// Firebase Auth automatically persists sessions, this is informational
  bool get isSessionPersistent {
    // Firebase Auth persists sessions by default
    // This method returns true if there's a current user
    return _auth.currentUser != null;
  }

  /// Wait for auth state to be restored
  /// Important for web/simulator where Firebase Auth needs time to restore session from IndexedDB
  /// Returns the current user after waiting for auth state restoration
  Future<User?> waitForAuthStateRestoration({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      AppLogger().logInfo('Waiting for auth state restoration', tag: 'AuthService');
      
      // If user already exists, return immediately
      if (_auth.currentUser != null) {
        AppLogger().logInfo('User already authenticated: ${_auth.currentUser?.email}', tag: 'AuthService');
        return _auth.currentUser;
      }

      // Wait for auth state changes stream to emit initial value
      final completer = Completer<User?>();
      StreamSubscription<User?>? subscription;
      Timer? timeoutTimer;

      subscription = _auth.authStateChanges().listen((user) {
        if (!completer.isCompleted) {
          AppLogger().logInfo('Auth state restored: ${user?.email ?? "null"}', tag: 'AuthService');
          completer.complete(user);
          subscription?.cancel();
          timeoutTimer?.cancel();
        }
      });

      // Set timeout
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          AppLogger().logWarning('Auth state restoration timeout', tag: 'AuthService');
          completer.complete(_auth.currentUser);
          subscription?.cancel();
        }
      });

      final user = await completer.future;
      return user;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to wait for auth state restoration',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      return _auth.currentUser;
    }
  }

  /// Restore session if "keep signed in" is enabled
  /// Checks preferences and waits for Firebase Auth to restore session
  /// Note: Firebase Auth persists sessions automatically, so this method primarily
  /// waits for Firebase to restore the session from local storage
  Future<User?> restoreSessionIfEnabled() async {
    try {
      // Firebase Auth persists sessions automatically, so we always check for existing sessions
      // The keepSignedIn preference is mainly for UI purposes (showing checkbox)
      // But we still respect it if the user explicitly disabled it
      final preferencesService = PreferencesService.instance;
      final keepSignedIn = await preferencesService.getKeepSignedIn();
      
      // Always wait for Firebase Auth to restore session (it persists automatically)
      // Only skip if user explicitly disabled keep signed in AND no current user exists
      if (!keepSignedIn && _auth.currentUser == null) {
        AppLogger().logInfo('Keep signed in is disabled and no current user - skipping session restoration', tag: 'AuthService');
        return null;
      }

      AppLogger().logInfo('Checking for Firebase Auth session restoration (Firebase persists automatically)', tag: 'AuthService');
      
      // Wait for auth state to be restored (Firebase handles persistence automatically)
      final user = await waitForAuthStateRestoration();
      
      if (user != null) {
        AppLogger().logInfo('Session restored successfully: ${user.email}', tag: 'AuthService');
      } else {
        AppLogger().logInfo('No session to restore', tag: 'AuthService');
      }
      
      return user;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to restore session',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Check for existing Firebase Auth session
  /// Firebase Auth persists sessions automatically, so this checks for any existing session
  /// This is useful for hot reload and app restarts
  Future<User?> checkExistingSession() async {
    try {
      AppLogger().logInfo('Checking for existing Firebase Auth session', tag: 'AuthService');
      
      // Firebase Auth persists sessions automatically
      // Wait for auth state to be restored (important for hot reload)
      final user = await waitForAuthStateRestoration();
      
      if (user != null) {
        AppLogger().logInfo('Existing session found: ${user.email}', tag: 'AuthService');
      } else {
        AppLogger().logInfo('No existing session found', tag: 'AuthService');
      }
      
      return user;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to check existing session',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      return _auth.currentUser;
    }
  }

  /// Get user role from Firestore
  /// Returns the role of the current user, defaults to 'client' if not found
  Future<UserRole> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger().logWarning('No current user to get role', tag: 'AuthService');
        return UserRole.client;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        AppLogger().logWarning('User document not found, defaulting to client', tag: 'AuthService');
        return UserRole.client;
      }

      final roleString = userDoc.data()?['role'] as String? ?? 'client';
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleString,
        orElse: () => UserRole.client,
      );

      AppLogger().logInfo('User role: ${role.name}', tag: 'AuthService');
      return role;
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to get user role',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      return UserRole.client; // Default to client on error
    }
  }

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == UserRole.admin || role == UserRole.superAdmin;
  }

  /// Check if current user is super admin
  Future<bool> isSuperAdmin() async {
    final role = await getUserRole();
    return role == UserRole.superAdmin;
  }

  /// Reset password via email
  Future<void> resetPassword(String email) async {
    try {
      AppLogger().logInfo('Sending password reset email to: $email', tag: 'AuthService');
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger().logInfo('Password reset email sent', tag: 'AuthService');
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger().logError(
        'Password reset failed: ${e.code}',
        tag: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add social authentication (Google, Apple)
// - Add phone number authentication
// - Add email verification
// - Add two-factor authentication
// - Add session timeout handling
// - Add automatic token refresh handling
