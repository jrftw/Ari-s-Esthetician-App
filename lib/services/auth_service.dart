/*
 * Filename: auth_service.dart
 * Purpose: Firebase Authentication service for user login and role management
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: firebase_auth, cloud_firestore
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logging/app_logger.dart';
import '../core/constants/app_constants.dart';

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

  // MARK: - Auth State Stream
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  // MARK: - Authentication Methods
  /// Sign in with email and password
  /// Returns the user if successful, throws exception on failure
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger().logInfo('Attempting to sign in: $email', tag: 'AuthService');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger().logInfo('Sign in successful: ${userCredential.user?.email}', tag: 'AuthService');
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
  Future<void> signOut() async {
    try {
      AppLogger().logInfo('Signing out user', tag: 'AuthService');
      await _auth.signOut();
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
// - Add session management
