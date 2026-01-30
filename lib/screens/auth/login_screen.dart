/*
 * Filename: login_screen.dart
 * Purpose: Admin login screen for accessing admin dashboard
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-30
 * Dependencies: Flutter, go_router, auth_service, preferences_service
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_version.dart';
import '../../services/auth_service.dart';
import '../../services/view_mode_service.dart';
import '../../services/preferences_service.dart';
import '../../core/logging/app_logger.dart';

// MARK: - Login Screen
/// Screen for admin authentication
/// Allows admins to sign in to access the admin dashboard
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// MARK: - Login Screen State
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _preferencesService = PreferencesService.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _keepSignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // MARK: - Load Saved Preferences
  /// Load saved email and checkbox preferences
  Future<void> _loadSavedPreferences() async {
    try {
      final savedEmail = await _preferencesService.getSavedEmail();
      final rememberMe = await _preferencesService.getRememberMe();
      final keepSignedIn = await _preferencesService.getKeepSignedIn();

      if (mounted) {
        setState(() {
          if (savedEmail != null && rememberMe) {
            _emailController.text = savedEmail;
          }
          _rememberMe = rememberMe;
          _keepSignedIn = keepSignedIn;
        });
      }
    } catch (e) {
      AppLogger().logError(
        'Failed to load saved preferences',
        tag: 'LoginScreen',
        error: e,
      );
    }
  }

  // MARK: - Login Handler
  /// Handle login form submission
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Sign in with email and password
      // Note: Firebase Auth persists sessions automatically regardless of keepSignedIn parameter
      // The keepSignedIn parameter is mainly for UI preference tracking
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
        keepSignedIn: _keepSignedIn,
      );

      if (!mounted) return;

      // Save preferences based on checkboxes
      // Note: Firebase Auth will keep the user signed in automatically
      // The keepSignedIn preference is for UI purposes (showing checkbox state)
      await _saveLoginPreferences(email, password);

      // Check if user is admin and redirect accordingly
      final isAdmin = await _authService.isAdmin();
      
      // Initialize view mode service
      final viewModeService = ViewModeService.instance;
      await viewModeService.initialize(isAdmin: isAdmin);
      
      if (isAdmin) {
        // Admin users go to admin dashboard
        context.go('/admin');
      } else {
        // Client users go to booking page (or their appointments page when implemented)
        context.go('/booking');
      }
    } catch (e) {
      AppLogger().logError('Login failed', tag: 'LoginScreen', error: e);
      
      if (!mounted) return;

      String errorMessage = 'Login failed. Please try again.';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // MARK: - Save Login Preferences
  /// Save login preferences based on checkbox states
  Future<void> _saveLoginPreferences(String email, String password) async {
    try {
      // Save remember me preference
      await _preferencesService.setRememberMe(_rememberMe);
      
      // Save keep signed in preference
      await _preferencesService.setKeepSignedIn(_keepSignedIn);

      if (_rememberMe) {
        // Save email if remember me is checked
        await _preferencesService.saveEmail(email);
        // Optionally save password (less secure, but for convenience)
        // Uncomment the line below if you want to save password too
        // await _preferencesService.savePassword(password);
      } else {
        // Clear saved email if remember me is unchecked
        await _preferencesService.clearSavedEmail();
        await _preferencesService.clearSavedPassword();
      }

      // Note: Firebase Auth persists sessions automatically regardless of keepSignedIn preference
      // The keepSignedIn preference is mainly for UI purposes (showing checkbox state)
      // Firebase Auth will keep users signed in until they explicitly sign out
      if (!_keepSignedIn) {
        // User unchecked "keep signed in" - but Firebase Auth still persists the session
        // The session will remain until the user explicitly signs out
        AppLogger().logInfo('Keep signed in checkbox unchecked, but Firebase Auth persists sessions automatically', tag: 'LoginScreen');
      } else {
        AppLogger().logInfo('Keep signed in checkbox checked - preference saved', tag: 'LoginScreen');
      }
    } catch (e) {
      AppLogger().logError(
        'Failed to save login preferences',
        tag: 'LoginScreen',
        error: e,
      );
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // MARK: - Header
                  Text(
                    'Sign In',
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.darkBrown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Sign in to your account',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // MARK: - Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // MARK: - Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // MARK: - Remember Me Checkbox
                  /// CheckboxListTile ensures the entire row is tappable and state updates reliably on all platforms (iOS, Android, Web).
                  /// State is persisted immediately on toggle so the choice is saved even if the user navigates away without logging in.
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (bool? value) {
                      final newValue = value ?? false;
                      setState(() {
                        _rememberMe = newValue;
                      });
                      _preferencesService.setRememberMe(newValue);
                      if (!newValue) {
                        _preferencesService.clearSavedEmail();
                        _preferencesService.clearSavedPassword();
                      }
                      AppLogger().logInfo('Remember Me toggled: $newValue', tag: 'LoginScreen');
                    },
                    title: Text(
                      'Remember Me',
                      style: AppTypography.bodyMedium,
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.sunflowerYellow,
                    checkColor: AppColors.darkBrown,
                  ),
                  
                  // MARK: - Keep Me Signed In Checkbox
                  /// CheckboxListTile ensures the entire row is tappable. State persisted immediately on toggle.
                  CheckboxListTile(
                    value: _keepSignedIn,
                    onChanged: (bool? value) {
                      final newValue = value ?? false;
                      setState(() {
                        _keepSignedIn = newValue;
                      });
                      _preferencesService.setKeepSignedIn(newValue);
                      AppLogger().logInfo('Keep Me Signed In toggled: $newValue', tag: 'LoginScreen');
                    },
                    title: Text(
                      'Keep Me Signed In',
                      style: AppTypography.bodyMedium,
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.sunflowerYellow,
                    checkColor: AppColors.darkBrown,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // MARK: - Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // MARK: - Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: AppTypography.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // MARK: - Back to Booking Link
                  TextButton(
                    onPressed: () => context.go('/booking'),
                    child: const Text('Continue as Guest'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // MARK: - Footer
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Version ${AppVersion.versionString}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© ${DateTime.now().year} Copyright Arianna DeAngelis\nAll rights reserved',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Built in the USA 🇺🇸 with ❤️ by @jrftw',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add "Forgot Password" functionality
// - Add biometric authentication
// - Add social login options
// - Add password strength indicator
// - Add account lockout after failed attempts
