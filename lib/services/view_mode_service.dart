/*
 * Filename: view_mode_service.dart
 * Purpose: Service to manage view mode switching for admin users (admin view vs client view)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: flutter/foundation.dart
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';

// MARK: - View Mode Enum
/// View modes available for admin users
enum ViewMode {
  /// Admin view - full admin dashboard and features
  admin,
  /// Client view - viewing the app as a regular client would see it
  client,
}

// MARK: - View Mode Service
/// Service for managing view mode state for admin users
/// Allows admins to switch between admin view and client view
/// This is a singleton service that maintains state across the app
class ViewModeService extends ChangeNotifier {
  // MARK: - Singleton Instance
  /// Private constructor for singleton pattern
  ViewModeService._();
  
  /// Singleton instance
  static final ViewModeService _instance = ViewModeService._();
  
  /// Get the singleton instance
  static ViewModeService get instance => _instance;

  // MARK: - State Variables
  /// Current view mode (defaults to admin)
  ViewMode _currentViewMode = ViewMode.admin;
  
  /// Whether the user is an admin (determines if view switching is available)
  bool _isAdminUser = false;

  // MARK: - Getters
  /// Get current view mode
  ViewMode get currentViewMode => _currentViewMode;
  
  /// Check if currently viewing as client
  bool get isViewingAsClient => _currentViewMode == ViewMode.client;
  
  /// Check if currently viewing as admin
  bool get isViewingAsAdmin => _currentViewMode == ViewMode.admin;
  
  /// Check if view mode switching is available (user must be admin)
  bool get canSwitchViewMode => _isAdminUser;

  // MARK: - Initialization
  /// Initialize the service with user admin status
  /// Should be called after user authentication to determine if view switching is available
  Future<void> initialize({required bool isAdmin}) async {
    logInfo('Initializing ViewModeService - isAdmin: $isAdmin', tag: 'ViewModeService');
    _isAdminUser = isAdmin;
    
    // If user is not admin, always use client view
    if (!isAdmin) {
      _currentViewMode = ViewMode.client;
    } else {
      // Admin users default to admin view
      _currentViewMode = ViewMode.admin;
    }
    
    notifyListeners();
    logInfo('ViewModeService initialized - viewMode: ${_currentViewMode.name}', tag: 'ViewModeService');
  }

  // MARK: - View Mode Switching
  /// Switch to client view
  /// Only works if user is an admin
  void switchToClientView() {
    if (!_isAdminUser) {
      logWarning('Attempted to switch to client view but user is not admin', tag: 'ViewModeService');
      return;
    }
    
    logInfo('Switching to client view', tag: 'ViewModeService');
    _currentViewMode = ViewMode.client;
    notifyListeners();
    logSuccess('Switched to client view', tag: 'ViewModeService');
  }

  /// Switch to admin view
  /// Only works if user is an admin
  void switchToAdminView() {
    if (!_isAdminUser) {
      logWarning('Attempted to switch to admin view but user is not admin', tag: 'ViewModeService');
      return;
    }
    
    logInfo('Switching to admin view', tag: 'ViewModeService');
    _currentViewMode = ViewMode.admin;
    notifyListeners();
    logSuccess('Switched to admin view', tag: 'ViewModeService');
  }

  /// Toggle between admin and client view
  /// Only works if user is an admin
  void toggleViewMode() {
    if (!_isAdminUser) {
      logWarning('Attempted to toggle view mode but user is not admin', tag: 'ViewModeService');
      return;
    }
    
    if (_currentViewMode == ViewMode.admin) {
      switchToClientView();
    } else {
      switchToAdminView();
    }
  }

  // MARK: - Reset
  /// Reset view mode to default (admin for admins, client for non-admins)
  void reset() {
    logInfo('Resetting ViewModeService', tag: 'ViewModeService');
    if (_isAdminUser) {
      _currentViewMode = ViewMode.admin;
    } else {
      _currentViewMode = ViewMode.client;
    }
    notifyListeners();
    logInfo('ViewModeService reset - viewMode: ${_currentViewMode.name}', tag: 'ViewModeService');
  }

  // MARK: - Cleanup
  /// Clean up resources (called on logout)
  void dispose() {
    logInfo('Disposing ViewModeService', tag: 'ViewModeService');
    _currentViewMode = ViewMode.admin;
    _isAdminUser = false;
    super.dispose();
  }
}

// Suggestions For Features and Additions Later:
// - Add persistent storage for view mode preference
// - Add analytics tracking for view mode switches
// - Add support for multiple view modes (e.g., staff view)
// - Add view mode history/undo functionality
// - Add view mode restrictions based on permissions
