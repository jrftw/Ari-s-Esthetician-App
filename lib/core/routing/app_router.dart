/*
 * Filename: app_router.dart
 * Purpose: Application routing configuration with role-based access control
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: go_router, firebase_auth
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';
import '../../services/auth_service.dart';
import '../../screens/client/client_booking_screen.dart';
import '../../screens/client/client_confirmation_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_services_screen.dart';
import '../../screens/admin/admin_appointments_screen.dart';
import '../../screens/admin/admin_clients_screen.dart';
import '../../screens/admin/admin_settings_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/welcome/welcome_screen.dart';
import '../../screens/welcome/account_choice_screen.dart';

// MARK: - Router Configuration
/// Application router with role-based routing
/// Handles navigation between client and admin screens
class AppRouter {
  final AuthService _authService = AuthService();

  /// Get the configured GoRouter instance
  GoRouter get router {
    logRouter('Creating GoRouter instance', tag: 'AppRouter');
    logRouter('Initial location: ${AppConstants.routeClientBooking}', tag: 'AppRouter');
    logDebug('Total routes: 9', tag: 'AppRouter');
    
    return GoRouter(
      initialLocation: AppConstants.routeWelcome,
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
      ],
    );
  }

  // MARK: - Redirect Handler
  /// Handles route redirection based on authentication and role
  Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    logRouter('Handling redirect for: ${state.matchedLocation}', tag: 'AppRouter');
    logDebug('Full location: ${state.uri}', tag: 'AppRouter');
    
    final user = FirebaseAuth.instance.currentUser;
    logAuth('Current user: ${user?.email ?? "null"}', tag: 'AppRouter');
    
    final isLoginRoute = state.matchedLocation == '/login';
    final isSignupRoute = state.matchedLocation == '/signup';
    final isSplashRoute = state.matchedLocation == '/';
    final isWelcomeRoute = state.matchedLocation == AppConstants.routeWelcome;
    final isAccountChoiceRoute = state.matchedLocation == AppConstants.routeAccountChoice;
    final isBookingRoute = state.matchedLocation == AppConstants.routeClientBooking;
    final isConfirmationRoute = state.matchedLocation.startsWith(AppConstants.routeClientConfirmation);

    logDebug('Route checks - Login: $isLoginRoute, Signup: $isSignupRoute, Splash: $isSplashRoute, Welcome: $isWelcomeRoute, AccountChoice: $isAccountChoiceRoute, Booking: $isBookingRoute, Confirmation: $isConfirmationRoute', tag: 'AppRouter');

    // Allow public routes without authentication
    if (isSplashRoute || isWelcomeRoute || isAccountChoiceRoute || isLoginRoute || isSignupRoute || isBookingRoute || isConfirmationRoute) {
      logRouter('Public route - allowing navigation', tag: 'AppRouter');
      return null;
    }

    // Redirect to login if not authenticated for protected routes
    if (user == null) {
      logRouter('No user - redirecting to /login', tag: 'AppRouter');
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

    logRouter('Allowing navigation', tag: 'AppRouter');
    return null; // Allow navigation
  }
}

// Suggestions For Features and Additions Later:
// - Add deep linking support
// - Add route transitions/animations
// - Add route guards for specific features
// - Add route analytics tracking
