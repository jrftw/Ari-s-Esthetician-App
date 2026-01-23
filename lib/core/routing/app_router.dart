/*
 * Filename: app_router.dart
 * Purpose: Application routing configuration with role-based access control
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: go_router, firebase_auth
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';
import '../../screens/client/client_booking_screen.dart';
import '../../screens/client/client_confirmation_screen.dart';
import '../../screens/client/client_appointments_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_services_screen.dart';
import '../../screens/admin/admin_appointments_screen.dart';
import '../../screens/admin/admin_clients_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/admin/admin_category_management_screen.dart';
import '../../screens/admin/admin_earnings_screen.dart';
import '../../screens/admin/admin_notifications_screen.dart';
import '../../screens/admin/admin_software_enhancements_screen.dart';
import '../../screens/admin/admin_time_off_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/welcome/welcome_screen.dart';
import '../../screens/welcome/account_choice_screen.dart';
import '../../screens/settings/settings_screen.dart';

// MARK: - Auth State Notifier
/// Notifier that listens to Firebase Auth state changes
/// Used to refresh router when auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;
  User? _currentUser;

  _AuthStateNotifier() {
    _init();
  }

  /// Initialize auth state listener
  void _init() {
    logAuth('Initializing AuthStateNotifier', tag: 'AuthStateNotifier');
    
    // Get initial user state
    _currentUser = _auth.currentUser;
    logAuth('Initial user: ${_currentUser?.email ?? "null"}', tag: 'AuthStateNotifier');
    
    // Listen to auth state changes
    _authSubscription = _auth.authStateChanges().listen((user) {
      logAuth('Auth state changed: ${user?.email ?? "null"}', tag: 'AuthStateNotifier');
      final wasInitialized = _isInitialized;
      _isInitialized = true;
      _currentUser = user;
      
      // Only notify if we've already initialized (to avoid initial double notification)
      if (wasInitialized) {
        notifyListeners();
      } else {
        // First time - notify after a short delay to ensure auth state is fully restored
        Future.delayed(const Duration(milliseconds: 100), () {
          notifyListeners();
        });
      }
    });
  }

  /// Get current user
  User? get currentUser => _currentUser;

  /// Check if auth state has been initialized
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// MARK: - Router Configuration
/// Application router with role-based routing
/// Handles navigation between client and admin screens
class AppRouter {
  final AuthService _authService = AuthService();
  final PreferencesService _preferencesService = PreferencesService.instance;
  final _AuthStateNotifier _authStateNotifier = _AuthStateNotifier();

  /// Get the configured GoRouter instance
  GoRouter get router {
    logRouter('Creating GoRouter instance', tag: 'AppRouter');
    logRouter('Initial location: ${AppConstants.routeClientBooking}', tag: 'AppRouter');
    logDebug('Total routes: 10', tag: 'AppRouter');
    
    return GoRouter(
      initialLocation: AppConstants.routeWelcome,
      refreshListenable: _authStateNotifier,
      redirect: _handleRedirect,
      routes: [
        // MARK: - Splash Route
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) {
            logRouter('Building SplashScreen route', tag: 'AppRouter');
            return const SplashScreen();
          },
        ),

        // MARK: - Welcome Routes
        GoRoute(
          path: AppConstants.routeWelcome,
          name: 'welcome',
          builder: (context, state) {
            logRouter('Building WelcomeScreen route', tag: 'AppRouter');
            return const WelcomeScreen();
          },
        ),
        GoRoute(
          path: AppConstants.routeAccountChoice,
          name: 'account-choice',
          builder: (context, state) {
            logRouter('Building AccountChoiceScreen route', tag: 'AppRouter');
            return const AccountChoiceScreen();
          },
        ),

        // MARK: - Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),

        // MARK: - Client Routes
        GoRoute(
          path: AppConstants.routeClientBooking,
          name: 'client-booking',
          builder: (context, state) {
            logRouter('Building ClientBookingScreen route', tag: 'AppRouter');
            return const ClientBookingScreen();
          },
        ),
        GoRoute(
          path: '${AppConstants.routeClientConfirmation}/:appointmentId',
          name: 'client-confirmation',
          builder: (context, state) {
            final appointmentId = state.pathParameters['appointmentId'] ?? '';
            return ClientConfirmationScreen(appointmentId: appointmentId);
          },
        ),
        GoRoute(
          path: AppConstants.routeClientAppointments,
          name: 'client-appointments',
          builder: (context, state) {
            logRouter('Building ClientAppointmentsScreen route', tag: 'AppRouter');
            return const ClientAppointmentsScreen();
          },
        ),

        // MARK: - Admin Routes
        GoRoute(
          path: AppConstants.routeAdminDashboard,
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminServices,
          name: 'admin-services',
          builder: (context, state) => const AdminServicesScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminAppointments,
          name: 'admin-appointments',
          builder: (context, state) => const AdminAppointmentsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminClients,
          name: 'admin-clients',
          builder: (context, state) => const AdminClientsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminSettings,
          name: 'admin-settings',
          builder: (context, state) => const AdminSettingsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminCategories,
          name: 'admin-categories',
          builder: (context, state) => const AdminCategoryManagementScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminEarnings,
          name: 'admin-earnings',
          builder: (context, state) => const AdminEarningsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminNotifications,
          name: 'admin-notifications',
          builder: (context, state) => const AdminNotificationsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminSoftwareEnhancements,
          name: 'admin-software-enhancements',
          builder: (context, state) => const AdminSoftwareEnhancementsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeAdminTimeOff,
          name: 'admin-time-off',
          builder: (context, state) => const AdminTimeOffScreen(),
        ),

        // MARK: - Settings Route (General)
        GoRoute(
          path: AppConstants.routeSettings,
          name: 'settings',
          builder: (context, state) {
            logRouter('Building SettingsScreen route', tag: 'AppRouter');
            return const SettingsScreen();
          },
        ),
      ],
    );
  }

  // MARK: - Redirect Handler
  /// Handles route redirection based on authentication and role
  /// Waits for auth state to be restored before making routing decisions
  /// Firebase Auth persists sessions automatically, so we always check for existing sessions
  Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    logRouter('Handling redirect for: ${state.matchedLocation}', tag: 'AppRouter');
    logDebug('Full location: ${state.uri}', tag: 'AppRouter');
    
    // MARK: - Wait for Auth State Initialization
    /// Wait for auth state to be restored (important for web/simulator refresh and hot reload)
    /// Firebase Auth on web needs time to restore session from IndexedDB
    /// Firebase Auth persists sessions automatically, so we always wait for restoration
    if (!_authStateNotifier.isInitialized) {
      logAuth('Auth state not initialized yet - waiting...', tag: 'AppRouter');
      // Wait for auth state to be initialized (max 3 seconds)
      int attempts = 0;
      while (!_authStateNotifier.isInitialized && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      logAuth('Auth state initialization check complete (attempts: $attempts)', tag: 'AppRouter');
    }
    
    // MARK: - Check Firebase Auth Session (Always)
    /// Firebase Auth persists sessions automatically, so we always check for existing sessions
    /// This ensures users stay logged in after hot reload and app restarts
    /// Wait a bit more for Firebase Auth to restore session (especially important for hot reload)
    User? user = _authStateNotifier.currentUser ?? FirebaseAuth.instance.currentUser;
    
    // If no user found yet, wait a bit more for Firebase Auth to restore from local storage
    // This is critical for hot reload and app restarts
    if (user == null) {
      logAuth('No user found initially - waiting for Firebase Auth session restoration...', tag: 'AppRouter');
      // Wait for auth state changes to emit (Firebase restores session automatically)
      await Future.delayed(const Duration(milliseconds: 500));
      user = FirebaseAuth.instance.currentUser;
      
      // If still no user, wait for auth state changes stream
      if (user == null) {
        try {
          // Wait for auth state restoration (Firebase handles this automatically)
          final restoredUser = await _authService.waitForAuthStateRestoration(timeout: const Duration(seconds: 2));
          if (restoredUser != null) {
            user = restoredUser;
            logAuth('Session restored from Firebase Auth: ${user.email}', tag: 'AppRouter');
            // Update notifier with restored user
            _authStateNotifier.notifyListeners();
          }
        } catch (e) {
          logAuth('Error waiting for auth state restoration: $e', tag: 'AppRouter');
        }
      } else {
        logAuth('Session found after delay: ${user.email}', tag: 'AppRouter');
        // Update notifier with found user
        _authStateNotifier.notifyListeners();
      }
    } else {
      logAuth('Current user found: ${user.email}', tag: 'AppRouter');
    }
    
    final isLoginRoute = state.matchedLocation == '/login';
    final isSignupRoute = state.matchedLocation == '/signup';
    final isSplashRoute = state.matchedLocation == '/';
    final isWelcomeRoute = state.matchedLocation == AppConstants.routeWelcome;
    final isAccountChoiceRoute = state.matchedLocation == AppConstants.routeAccountChoice;
    final isBookingRoute = state.matchedLocation == AppConstants.routeClientBooking;
    final isConfirmationRoute = state.matchedLocation.startsWith(AppConstants.routeClientConfirmation);
    final isAppointmentsRoute = state.matchedLocation == AppConstants.routeClientAppointments;
    final isSettingsRoute = state.matchedLocation == AppConstants.routeSettings;

    logDebug('Route checks - Login: $isLoginRoute, Signup: $isSignupRoute, Splash: $isSplashRoute, Welcome: $isWelcomeRoute, AccountChoice: $isAccountChoiceRoute, Booking: $isBookingRoute, Confirmation: $isConfirmationRoute, Settings: $isSettingsRoute', tag: 'AppRouter');

    // Allow public routes without authentication
    if (isSplashRoute || isWelcomeRoute || isAccountChoiceRoute || isLoginRoute || isSignupRoute || isBookingRoute || isConfirmationRoute || isAppointmentsRoute || isSettingsRoute) {
      logRouter('Public route - allowing navigation', tag: 'AppRouter');
      return null;
    }

    // Get final user state after potential restoration
    // Always check Firebase Auth directly as it persists sessions automatically
    final finalUser = user ?? _authStateNotifier.currentUser ?? FirebaseAuth.instance.currentUser;
    
    // Redirect to login if not authenticated for protected routes
    if (finalUser == null) {
      logRouter('No user found after restoration - redirecting to /login', tag: 'AppRouter');
      return '/login';
    }

    // Check user role for admin routes
    final isAdminRoute = state.matchedLocation.startsWith('/admin');
    logDebug('Is admin route: $isAdminRoute', tag: 'AppRouter');
    
    if (isAdminRoute) {
      logAuth('Checking admin status for user', tag: 'AppRouter');
      final isAdmin = await _authService.isAdmin();
      logAuth('Is admin: $isAdmin', tag: 'AppRouter');
      
      if (!isAdmin) {
        logRouter('Non-admin user accessing admin route - redirecting to booking', tag: 'AppRouter');
        return AppConstants.routeClientBooking;
      }
      logRouter('Admin user - allowing access', tag: 'AppRouter');
    }

    // Allow admins to access client routes (for "view as client" feature)
    // Client routes are public, but we log when admins access them
    final isClientRoute = state.matchedLocation == AppConstants.routeClientBooking ||
        state.matchedLocation.startsWith(AppConstants.routeClientConfirmation) ||
        state.matchedLocation == AppConstants.routeClientAppointments;
    if (isClientRoute && finalUser != null) {
      final isAdmin = await _authService.isAdmin();
      if (isAdmin) {
        logRouter('Admin user accessing client route - allowing for view-as-client feature', tag: 'AppRouter');
      }
    }

    logRouter('Allowing navigation', tag: 'AppRouter');
    return null; // Allow navigation
  }
}

// Suggestions For Features and Additions Later:
// - Add deep linking support
// - Add route transitions/animations
// - Add route guards for specific features
// - Add route analytics tracking
