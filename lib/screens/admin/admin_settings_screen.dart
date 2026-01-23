/*
 * Filename: admin_settings_screen.dart
 * Purpose: Comprehensive admin settings screen for managing business settings, branding, policies, and integrations
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: Flutter, cloud_firestore, services, models
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/business_settings_model.dart';

// MARK: - Admin Settings Screen
/// Comprehensive settings screen for admins and superadmins
/// Allows management of all business settings including branding, policies, hours, and integrations
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

// MARK: - Admin Settings Screen State
/// State management for admin settings screen
class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // MARK: - State Variables
  BusinessSettingsModel? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSuperAdmin = false;
  bool _paymentsEnabled = false;

  // MARK: - Form Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessEmailController = TextEditingController();
  final TextEditingController _businessPhoneController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _primaryColorController = TextEditingController();
  final TextEditingController _secondaryColorController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _facebookUrlController = TextEditingController();
  final TextEditingController _instagramUrlController = TextEditingController();
  final TextEditingController _twitterUrlController = TextEditingController();
  final TextEditingController _cancellationWindowController = TextEditingController();
  final TextEditingController _latePolicyController = TextEditingController();
  final TextEditingController _noShowPolicyController = TextEditingController();
  final TextEditingController _bookingPolicyController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _googleCalendarIdController = TextEditingController();
  final TextEditingController _stripePublishableKeyController = TextEditingController();
  final TextEditingController _stripeSecretKeyController = TextEditingController();
  final TextEditingController _minDepositAmountController = TextEditingController();
  final TextEditingController _cancellationFeeController = TextEditingController();

  // MARK: - Lifecycle Methods
  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    // MARK: - Cleanup
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _logoUrlController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _websiteUrlController.dispose();
    _facebookUrlController.dispose();
    _instagramUrlController.dispose();
    _twitterUrlController.dispose();
    _cancellationWindowController.dispose();
    _latePolicyController.dispose();
    _noShowPolicyController.dispose();
    _bookingPolicyController.dispose();
    _timezoneController.dispose();
    _googleCalendarIdController.dispose();
    _stripePublishableKeyController.dispose();
    _stripeSecretKeyController.dispose();
    _minDepositAmountController.dispose();
    _cancellationFeeController.dispose();
    super.dispose();
  }

  // MARK: - Initialization
  /// Initialize settings by loading from Firestore and checking user role
  Future<void> _initializeSettings() async {
    try {
      AppLogger().logInfo('Initializing admin settings screen', tag: 'AdminSettingsScreen');
      
      // Check if user is super admin
      _isSuperAdmin = await _authService.isSuperAdmin();
      
      // Load business settings
      final settings = await _firestoreService.getBusinessSettings();
      
      if (settings != null) {
        _settings = settings;
        _populateFormFields(settings);
      } else {
        // Create default settings if none exist
        AppLogger().logWarning('No business settings found, creating defaults', tag: 'AdminSettingsScreen');
        _settings = BusinessSettingsModel.createDefault(
          businessName: 'Ari\'s Esthetician',
          businessEmail: '',
          businessPhone: '',
        );
        _populateFormFields(_settings!);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      AppLogger().logSuccess('Settings initialized successfully', tag: 'AdminSettingsScreen');
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to initialize settings',
        tag: 'AdminSettingsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // MARK: - Form Population
  /// Populate form fields with current settings values
  void _populateFormFields(BusinessSettingsModel settings) {
    _businessNameController.text = settings.businessName;
    _businessEmailController.text = settings.businessEmail;
    _businessPhoneController.text = settings.businessPhone;
    _businessAddressController.text = settings.businessAddress ?? '';
    _logoUrlController.text = settings.logoUrl ?? '';
    _primaryColorController.text = settings.primaryColorHex ?? '';
    _secondaryColorController.text = settings.secondaryColorHex ?? '';
    _websiteUrlController.text = settings.websiteUrl ?? '';
    _facebookUrlController.text = settings.facebookUrl ?? '';
    _instagramUrlController.text = settings.instagramUrl ?? '';
    _twitterUrlController.text = settings.twitterUrl ?? '';
    _cancellationWindowController.text = settings.cancellationWindowHours.toString();
    _latePolicyController.text = settings.latePolicyText;
    _noShowPolicyController.text = settings.noShowPolicyText;
    _bookingPolicyController.text = settings.bookingPolicyText;
    _timezoneController.text = settings.timezone;
    _googleCalendarIdController.text = settings.googleCalendarId ?? '';
    _stripePublishableKeyController.text = settings.stripePublishableKey ?? '';
    _stripeSecretKeyController.text = settings.stripeSecretKey ?? '';
    _minDepositAmountController.text = settings.minDepositAmountCents != null
        ? (settings.minDepositAmountCents! / 100).toStringAsFixed(2)
        : '';
    _cancellationFeeController.text = settings.cancellationFeeCents != null
        ? (settings.cancellationFeeCents! / 100).toStringAsFixed(2)
        : '';
    _paymentsEnabled = settings.paymentsEnabled;
  }

  // MARK: - Save Functionality
  /// Save settings to Firestore
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      AppLogger().logWarning('Form validation failed', tag: 'AdminSettingsScreen');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      AppLogger().logInfo('Saving business settings', tag: 'AdminSettingsScreen');
      
      // Build updated settings from form fields
      final updatedSettings = _buildSettingsFromForm();
      
      // Save to Firestore
      await _firestoreService.updateBusinessSettings(updatedSettings);
      
      _settings = updatedSettings;
      
      AppLogger().logSuccess('Settings saved successfully', tag: 'AdminSettingsScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().logError(
        'Failed to save settings',
        tag: 'AdminSettingsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // MARK: - Settings Builder
  /// Build BusinessSettingsModel from form field values
  BusinessSettingsModel _buildSettingsFromForm() {
    final now = DateTime.now();
    final cancellationWindow = int.tryParse(_cancellationWindowController.text) ?? 24;
    
    return BusinessSettingsModel(
      id: _settings?.id ?? 'main',
      businessName: _businessNameController.text.trim(),
      businessEmail: _businessEmailController.text.trim(),
      businessPhone: _businessPhoneController.text.trim(),
      businessAddress: _businessAddressController.text.trim().isEmpty 
          ? null 
          : _businessAddressController.text.trim(),
      logoUrl: _logoUrlController.text.trim().isEmpty 
          ? null 
          : _logoUrlController.text.trim(),
      primaryColorHex: _primaryColorController.text.trim().isEmpty 
          ? null 
          : _primaryColorController.text.trim(),
      secondaryColorHex: _secondaryColorController.text.trim().isEmpty 
          ? null 
          : _secondaryColorController.text.trim(),
      websiteUrl: _websiteUrlController.text.trim().isEmpty 
          ? null 
          : _websiteUrlController.text.trim(),
      facebookUrl: _facebookUrlController.text.trim().isEmpty 
          ? null 
          : _facebookUrlController.text.trim(),
      instagramUrl: _instagramUrlController.text.trim().isEmpty 
          ? null 
          : _instagramUrlController.text.trim(),
      twitterUrl: _twitterUrlController.text.trim().isEmpty 
          ? null 
          : _twitterUrlController.text.trim(),
      weeklyHours: _settings?.weeklyHours ?? [],
      cancellationWindowHours: cancellationWindow,
      latePolicyText: _latePolicyController.text.trim(),
      noShowPolicyText: _noShowPolicyController.text.trim(),
      bookingPolicyText: _bookingPolicyController.text.trim(),
      timezone: _timezoneController.text.trim(),
      googleCalendarId: _googleCalendarIdController.text.trim().isEmpty 
          ? null 
          : _googleCalendarIdController.text.trim(),
      stripePublishableKey: _stripePublishableKeyController.text.trim().isEmpty 
          ? null 
          : _stripePublishableKeyController.text.trim(),
      stripeSecretKey: _stripeSecretKeyController.text.trim().isEmpty 
          ? null 
          : _stripeSecretKeyController.text.trim(),
      minDepositAmountCents: _minDepositAmountController.text.trim().isEmpty
          ? null
          : ((double.tryParse(_minDepositAmountController.text.trim()) ?? 0.0) * 100).toInt(),
      cancellationFeeCents: _cancellationFeeController.text.trim().isEmpty
          ? null
          : ((double.tryParse(_cancellationFeeController.text.trim()) ?? 0.0) * 100).toInt(),
      paymentsEnabled: _paymentsEnabled,
      createdAt: _settings?.createdAt ?? now,
      updatedAt: now,
    );
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              AppLogger().logInfo('Settings button tapped', tag: 'AdminSettingsScreen');
              context.push(AppConstants.routeSettings);
            },
            tooltip: 'General Settings',
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // MARK: - Business Information Section
            _buildSectionHeader(
              title: 'Business Information',
              icon: Icons.business,
            ),
            _buildTextField(
              controller: _businessNameController,
              label: 'Business Name',
              icon: Icons.store,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessEmailController,
              label: 'Business Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business email is required';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessPhoneController,
              label: 'Business Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business phone is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _businessAddressController,
              label: 'Business Address (Optional)',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // MARK: - Branding Section
            _buildSectionHeader(
              title: 'Branding',
              icon: Icons.palette,
            ),
            _buildTextField(
              controller: _logoUrlController,
              label: 'Logo URL (Optional)',
              icon: Icons.image,
              hint: 'https://example.com/logo.png',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _primaryColorController,
              label: 'Primary Color Hex (Optional)',
              icon: Icons.color_lens,
              hint: '#FFD700',
              prefixText: '#',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _secondaryColorController,
              label: 'Secondary Color Hex (Optional)',
              icon: Icons.color_lens_outlined,
              hint: '#FFF8E1',
              prefixText: '#',
            ),
            const SizedBox(height: 32),

            // MARK: - Social Media Section
            _buildSectionHeader(
              title: 'Social Media Links',
              icon: Icons.share,
            ),
            _buildTextField(
              controller: _websiteUrlController,
              label: 'Website URL (Optional)',
              icon: Icons.language,
              hint: 'https://example.com',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _facebookUrlController,
              label: 'Facebook URL (Optional)',
              icon: Icons.facebook,
              hint: 'https://facebook.com/yourpage',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _instagramUrlController,
              label: 'Instagram URL (Optional)',
              icon: Icons.camera_alt,
              hint: 'https://instagram.com/yourhandle',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _twitterUrlController,
              label: 'Twitter URL (Optional)',
              icon: Icons.alternate_email,
              hint: 'https://twitter.com/yourhandle',
            ),
            const SizedBox(height: 32),

            // MARK: - Policies Section
            _buildSectionHeader(
              title: 'Policies',
              icon: Icons.description,
            ),
            _buildTextField(
              controller: _cancellationWindowController,
              label: 'Cancellation Window (Hours)',
              icon: Icons.access_time,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cancellation window is required';
                }
                final hours = int.tryParse(value);
                if (hours == null || hours < 0) {
                  return 'Please enter a valid number of hours';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _minDepositAmountController,
              label: 'Minimum Deposit Amount (\$) (Optional)',
              icon: Icons.payment,
              hint: '5.00',
              prefixText: '\$',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to allow any deposit amount (including \$0.00)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cancellationFeeController,
              label: 'Cancellation Fee (\$) (Optional)',
              icon: Icons.cancel,
              hint: '25.00',
              prefixText: '\$',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to disable cancellation fees',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _latePolicyController,
              label: 'Late Policy Text',
              icon: Icons.schedule,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _noShowPolicyController,
              label: 'No-Show Policy Text',
              icon: Icons.cancel,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bookingPolicyController,
              label: 'Booking Policy Text',
              icon: Icons.event_note,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // MARK: - Advanced Settings Section
            _buildSectionHeader(
              title: 'Advanced Settings',
              icon: Icons.settings,
            ),
            _buildTextField(
              controller: _timezoneController,
              label: 'Timezone',
              icon: Icons.access_time,
              hint: 'America/New_York',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Timezone is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _googleCalendarIdController,
              label: 'Google Calendar ID (Optional)',
              icon: Icons.calendar_today,
              hint: 'For calendar sync integration',
            ),
            const SizedBox(height: 32),

            // MARK: - Payment Integration Section (Super Admin Only)
            if (_isSuperAdmin) ...[
              _buildSectionHeader(
                title: 'Payment Integration (Super Admin Only)',
                icon: Icons.payment,
              ),
              // Payment Enable/Disable Toggle
              SwitchListTile(
                title: Text(
                  'Enable Payments',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _paymentsEnabled
                      ? 'Payments are enabled. Clients will be required to pay during booking.'
                      : 'Payments are disabled. Clients can book without payment. Pricing will still be shown.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _paymentsEnabled,
                onChanged: (value) {
                  setState(() {
                    _paymentsEnabled = value;
                  });
                },
                activeColor: AppColors.sunflowerYellow,
                secondary: Icon(
                  _paymentsEnabled ? Icons.payment : Icons.payment_outlined,
                  color: _paymentsEnabled ? AppColors.sunflowerYellow : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _stripePublishableKeyController,
                label: 'Stripe Publishable Key (Optional)',
                icon: Icons.vpn_key,
                hint: 'pk_test_...',
              ),
              const SizedBox(height: 8),
              Text(
                'Required if payments are enabled',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _stripeSecretKeyController,
                label: 'Stripe Secret Key (Optional)',
                icon: Icons.lock,
                hint: 'sk_test_...',
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Text(
                'Required if payments are enabled. Store securely in Cloud Functions.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // MARK: - Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save All Settings'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // MARK: - Helper Widgets
  /// Build section header with icon and title
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.sunflowerYellow, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build text field with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add logo upload functionality with image picker
// - Add color picker widget for color selection
// - Add business hours editor with day/time picker
// - Add preview mode to see how settings affect the app
// - Add settings import/export functionality
// - Add settings version history/rollback
// - Add validation for URL formats
// - Add timezone picker with search
// - Add Stripe key validation
// - Add Google Calendar integration test button