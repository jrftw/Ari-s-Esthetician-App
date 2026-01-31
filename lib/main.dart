/*
 * Filename: main.dart
 * Purpose: Application entry point and initialization
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter, Firebase, Theme, Routing, AppDiagnosticsService
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'core/routing/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'services/version_check_service.dart';
import 'services/preferences_service.dart';
import 'services/app_diagnostics_service.dart';
import 'screens/update_required_screen.dart';

// MARK: - Main Function
/// Application entry point
/// Initializes Firebase, logging, and starts the app
void main() async {
  // Basic print to verify app starts (always works)
  print('🔍 ========================================');
  print('🔍 APP STARTING - Main function called');
  print('🔍 ========================================');
  
  try {
    // CRITICAL: Initialize logger FIRST before any logging calls
    print('🔍 Step 1: Initializing logger...');
    AppLogger().initialize();
    print('🔍 Step 1: Logger initialized ✅');
    
    logInit('Starting application initialization', tag: 'Main');
    logStep(1, 'Ensuring Flutter binding is initialized', tag: 'Main');
    
    print('🔍 Step 2: Ensuring Flutter binding...');
    WidgetsFlutterBinding.ensureInitialized();
    print('🔍 Step 2: Flutter binding initialized ✅');
    logSuccess('Flutter binding initialized', tag: 'Main');
  } catch (e, stackTrace) {
    print('🔍 ❌ ERROR in initialization: $e');
    print('🔍 Stack trace: $stackTrace');
    rethrow;
  }

  // Initialize Firebase
  print('🔍 Step 3: Initializing Firebase...');
  logStep(3, 'Initializing Firebase', tag: 'Main');
  bool firebaseInitialized = false;
  String? firebaseError;
  final AppDiagnosticsService diagnostics = AppDiagnosticsService();
  try {
    logFirebase('Attempting Firebase initialization', tag: 'Main');
    await FirebaseConfig.initialize();
    firebaseInitialized = true;
    diagnostics.recordCheck(
      checkKey: 'firebase',
      displayName: AriDiagnosticCheckNames.firebase,
      working: true,
    );
    print('🔍 Step 3: Firebase initialized ✅');
    logSuccess('Firebase initialized successfully', tag: 'Main');
    logComplete('Application initialization complete', tag: 'Main');
  } catch (e, stackTrace) {
    firebaseInitialized = false;
    firebaseError = e.toString();
    diagnostics.recordCheck(
      checkKey: 'firebase',
      displayName: AriDiagnosticCheckNames.firebase,
      working: false,
      shortReason: 'Initialization failed',
    );
    diagnostics.recordUnavailable(
      checkKey: 'auth',
      displayName: AriDiagnosticCheckNames.authentication,
      reason: 'Requires Firebase',
    );
    diagnostics.recordUnavailable(
      checkKey: 'database',
      displayName: AriDiagnosticCheckNames.database,
      reason: 'Requires Firebase',
    );
    print('🔍 Step 3: Firebase failed ❌ - $e');
    logError(
      'Firebase initialization failed',
      tag: 'Main',
      error: e,
      stackTrace: stackTrace,
    );
    logWarning('Continuing with error screen', tag: 'Main');
  }

  print('🔍 Step 4: Building and running app...');
  logStep(4, 'Building and running app', tag: 'Main');
  logUI('Creating ArisEstheticianApp widget', tag: 'Main');
  
  try {
    runApp(ArisEstheticianApp(
      firebaseInitialized: firebaseInitialized,
      firebaseError: firebaseError,
    ));
    print('🔍 Step 4: runApp() called ✅');
    logComplete('App launched successfully', tag: 'Main');
    print('🔍 ========================================');
    print('🔍 APP STARTED SUCCESSFULLY!');
    print('🔍 ========================================');
  } catch (e, stackTrace) {
    print('🔍 ❌ CRITICAL ERROR in runApp: $e');
    print('🔍 Stack trace: $stackTrace');
    // Try to show error widget
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Critical Error: $e'),
        ),
      ),
    ));
  }
}

// MARK: - Main App Widget
/// Root application widget
/// Configures theme, routing, and global app settings
/// Checks app version before allowing app usage
class ArisEstheticianApp extends StatefulWidget {
  final bool firebaseInitialized;
  final String? firebaseError;

  const ArisEstheticianApp({
    super.key,
    required this.firebaseInitialized,
    this.firebaseError,
  });

  @override
  State<ArisEstheticianApp> createState() => _ArisEstheticianAppState();
}

// MARK: - Main App Widget State
/// State for main app widget with version checking and theme/aura preferences
class _ArisEstheticianAppState extends State<ArisEstheticianApp> {
  VersionCheckResult? _versionCheckResult;
  bool _versionCheckComplete = false;
  final VersionCheckService _versionCheckService = VersionCheckService();

  /// Single router instance per app lifecycle; created lazily and disposed in dispose() to avoid auth subscription leak.
  AppRouter? _appRouter;

  @override
  void initState() {
    super.initState();
    print('🔍 Building ArisEstheticianApp widget...');
    print('🔍 Firebase initialized: ${widget.firebaseInitialized}');
    
    logUI('Building ArisEstheticianApp widget', tag: 'ArisEstheticianApp');
    logDebug('Firebase initialized: ${widget.firebaseInitialized}', tag: 'ArisEstheticianApp');
    
    // MARK: - Theme and Aura Preferences
    /// Load aura cache only; theme is forced to light mode for now
    PreferencesService.instance.ensureThemeAuraCache().then((_) {
      if (mounted) setState(() {});
    });
    PreferencesService.instance.addListener(_onPreferencesChanged);
    
    // MARK: - Version Check
    /// Check app version if Firebase is initialized
    /// Skip check if Firebase failed (will show error screen)
    if (widget.firebaseInitialized) {
      _checkVersion();
    } else {
      // If Firebase not initialized, skip version check
      _versionCheckComplete = true;
    }
  }

  void _onPreferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appRouter?.dispose();
    _appRouter = null;
    PreferencesService.instance.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  /// Theme is forced to light only for now (dark and auto disabled)
  ThemeMode get _resolvedThemeMode => ThemeMode.light;

  // MARK: - Version Check Method
  /// Check app version against latest required version
  Future<void> _checkVersion() async {
    final diagnostics = AppDiagnosticsService();
    try {
      logInfo('Starting version check', tag: 'ArisEstheticianApp');
      print('🔍 Checking app version...');
      
      final result = await _versionCheckService.checkVersion();
      
      diagnostics.recordCheck(
        checkKey: 'version_check',
        displayName: AriDiagnosticCheckNames.versionCheck,
        working: true,
      );
      if (mounted) {
        setState(() {
          _versionCheckResult = result;
          _versionCheckComplete = true;
        });
        
        if (result.updateRequired) {
          logWarning('Update required: ${result.currentVersion} (Build ${result.currentBuildNumber}) < ${result.latestVersion} (Build ${result.latestBuildNumber})', tag: 'ArisEstheticianApp');
          print('🔍 Update required - showing update screen');
        } else {
          logInfo('App version is up to date', tag: 'ArisEstheticianApp');
          print('🔍 App version is up to date ✅');
        }
      }
    } catch (e, stackTrace) {
      diagnostics.recordCheck(
        checkKey: 'version_check',
        displayName: AriDiagnosticCheckNames.versionCheck,
        working: false,
        shortReason: 'Check failed',
      );
      logError(
        'Version check failed',
        tag: 'ArisEstheticianApp',
        error: e,
        stackTrace: stackTrace,
      );
      print('🔍 Version check failed - allowing app to continue');
      // On error, allow app to continue (fail open)
      if (mounted) {
        setState(() {
          _versionCheckResult = VersionCheckResult(
            updateRequired: false,
            currentVersion: '1.0.0',
            currentBuildNumber: 3,
            error: e.toString(),
          );
          _versionCheckComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // MARK: - Firebase Error Screen
    /// Show error screen if Firebase failed to initialize
    if (!widget.firebaseInitialized) {
      print('🔍 Firebase not initialized - showing error screen');
      logWarning('Firebase not initialized - showing error screen', tag: 'ArisEstheticianApp');
      logUI('Creating MaterialApp with error screen', tag: 'ArisEstheticianApp');
      return MaterialApp(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _FirebaseErrorScreen(error: widget.firebaseError),
      );
    }

    // MARK: - Version Check Loading
    /// Show loading while checking version
    if (!_versionCheckComplete) {
      logUI('Version check in progress - showing loading', tag: 'ArisEstheticianApp');
      return MaterialApp(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.sunflowerYellow,
                ),
                const SizedBox(height: 16),
                Text(
                  'Checking for updates...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // MARK: - Update Required Screen
    /// Show update screen if update is required
    if (_versionCheckResult?.updateRequired == true) {
      logUI('Update required - showing UpdateRequiredScreen', tag: 'ArisEstheticianApp');
      return MaterialApp(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: UpdateRequiredScreen(
          currentVersion: _versionCheckResult!.currentVersion,
          currentBuildNumber: _versionCheckResult!.currentBuildNumber,
          latestVersion: _versionCheckResult!.latestVersion ?? '1.0.0',
          latestBuildNumber: _versionCheckResult!.latestBuildNumber ?? 3,
          updateMessage: _versionCheckResult!.updateMessage,
          updateUrl: _versionCheckResult!.updateUrl,
        ),
      );
    }

    // MARK: - Normal App
    /// Show normal app if version is up to date
    final diagnostics = AppDiagnosticsService();
    print('🔍 Creating AppRouter instance...');
    logRouter('Creating AppRouter instance', tag: 'ArisEstheticianApp');
    try {
      _appRouter ??= AppRouter();
      final router = _appRouter!.router;
      diagnostics.recordCheck(
        checkKey: 'router',
        displayName: AriDiagnosticCheckNames.appRouter,
        working: true,
      );
      print('🔍 Router created successfully ✅');
      logSuccess('Router created successfully', tag: 'ArisEstheticianApp');

      print('🔍 Creating MaterialApp.router...');
      logUI('Creating MaterialApp.router with theme and routing', tag: 'ArisEstheticianApp');
      final app = MaterialApp.router(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        
        // MARK: - Theme Configuration (light only for now; dark and auto disabled)
        theme: AppTheme.lightTheme,
        themeMode: _resolvedThemeMode,

        // MARK: - Router Configuration
        routerConfig: router,
      );
      print('🔍 MaterialApp.router created ✅');
      return app;
    } catch (e, stackTrace) {
      diagnostics.recordCheck(
        checkKey: 'router',
        displayName: AriDiagnosticCheckNames.appRouter,
        working: false,
        shortReason: 'Initialization failed',
      );
      print('🔍 ❌ ERROR creating router: $e');
      print('🔍 Stack trace: $stackTrace');
      logError('Failed to create router', tag: 'ArisEstheticianApp', error: e, stackTrace: stackTrace);
      // Fallback to simple MaterialApp if router fails
      return MaterialApp(
        title: 'Ari\'s Esthetician App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _ErrorScreen(
          title: 'Router Error',
          message: 'Failed to initialize router. Please try again or contact support.',
        ),
      );
    }
  }
}

// MARK: - Error Screen (Generic)
/// Generic error screen for displaying errors. Shows Copy diagnostic report when diagnostics indicate failures.
class _ErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const _ErrorScreen({
    required this.title,
    required this.message,
  });

  void _copyDiagnosticReport(BuildContext context) {
    final diagnostics = AppDiagnosticsService();
    if (!diagnostics.hasAnyFailure) return;
    final report = diagnostics.getCopyableReport();
    if (report.isEmpty) return;
    Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostic report copied. You can send it to support.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logUI('Building ErrorScreen: $title', tag: 'ErrorScreen');
    final diagnostics = AppDiagnosticsService();
    final showCopyReport = diagnostics.hasAnyFailure;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.darkBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (showCopyReport) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _copyDiagnosticReport(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy diagnostic report'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sunflowerYellow,
                    foregroundColor: AppColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send the report to support to help fix the issue.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Firebase Error Screen
/// Displays error message when Firebase initialization fails. Shows Copy diagnostic report for support.
class _FirebaseErrorScreen extends StatelessWidget {
  final String? error;

  const _FirebaseErrorScreen({this.error});

  void _copyDiagnosticReport(BuildContext context) {
    final diagnostics = AppDiagnosticsService();
    if (!diagnostics.hasAnyFailure) return;
    final report = diagnostics.getCopyableReport();
    if (report.isEmpty) return;
    Clipboard.setData(ClipboardData(text: report));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostic report copied. You can send it to support.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logUI('Building FirebaseErrorScreen', tag: 'FirebaseErrorScreen');
    logDebug('Error message: ${error ?? "No error details"}', tag: 'FirebaseErrorScreen');
    final diagnostics = AppDiagnosticsService();
    final showCopyReport = diagnostics.hasAnyFailure;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 24),
                Text(
                  'Firebase Configuration Error',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.darkBrown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Firebase has not been properly configured.\n\n'
                  'Please run:\n'
                  'flutterfire configure --project=ari-s-esthetician-app',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Error: $error',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (showCopyReport) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _copyDiagnosticReport(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy diagnostic report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sunflowerYellow,
                      foregroundColor: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send the report to support to help fix the issue.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add error boundary widget
// - Add global loading indicator
// - Add offline mode handling
// - Add app update checking
// - Add analytics initialization
// - Diagnostics: optional auth/database checks when Firebase is up for richer reports
