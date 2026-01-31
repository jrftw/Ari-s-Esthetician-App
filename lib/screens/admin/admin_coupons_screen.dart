/*
 * Filename: admin_coupons_screen.dart
 * Purpose: Admin screen for managing booking coupon codes (percent off, dollar off, or free)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: Flutter, services, models, go_router
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../services/firestore_service.dart';
import '../../models/coupon_model.dart';

// MARK: - Admin Coupons Screen
/// Screen for managing coupon codes clients can apply at booking
class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

// MARK: - Admin Coupons Screen State
class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  // MARK: - Services
  final FirestoreService _firestoreService = FirestoreService();

  // MARK: - State Variables
  List<CouponModel> _coupons = [];
  bool _isLoading = true;

  // MARK: - Lifecycle Methods
  @override
  void initState() {
    super.initState();
    logUI('AdminCouponsScreen initState called', tag: 'AdminCouponsScreen');
    _loadCoupons();
  }

  // MARK: - Data Loading
  /// Load all coupons from Firestore
  Future<void> _loadCoupons() async {
    try {
      logLoading('Loading coupons...', tag: 'AdminCouponsScreen');
      setState(() => _isLoading = true);

      final coupons = await _firestoreService.getAllCoupons();
      logSuccess('Loaded ${coupons.length} coupons', tag: 'AdminCouponsScreen');

      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logError('Failed to load coupons', tag: 'AdminCouponsScreen', error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load coupons: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    logUI('Building AdminCouponsScreen widget', tag: 'AdminCouponsScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupon Codes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppConstants.routeAdminDashboard),
          tooltip: 'Back to Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCouponDialog(),
            tooltip: 'Add Coupon',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
              ? _buildEmptyState()
              : _buildCouponList(),
    );
  }

  // MARK: - Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: context.themeSecondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Coupons Yet',
            style: AppTypography.titleMedium.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a coupon code for clients',
            style: AppTypography.bodyMedium.copyWith(
              color: context.themeSecondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Coupon List
  Widget _buildCouponList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coupons.length,
      itemBuilder: (context, index) {
        final coupon = _coupons[index];
        return _buildCouponCard(coupon);
      },
    );
  }

  // MARK: - Coupon Card
  Widget _buildCouponCard(CouponModel coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.local_offer,
          color: coupon.isActive ? AppColors.sunflowerYellow : context.themeSecondaryTextColor,
        ),
        title: Text(
          coupon.code,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            decoration: coupon.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              coupon.discountDescription,
              style: AppTypography.bodySmall.copyWith(
                color: context.themePrimaryTextColor,
              ),
            ),
            Text(
              'Used ${coupon.timesUsed}${coupon.usageLimit != null ? ' / ${coupon.usageLimit}' : ''} times',
              style: AppTypography.bodySmall.copyWith(
                color: context.themeSecondaryTextColor,
              ),
            ),
            if (coupon.description != null && coupon.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                coupon.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: context.themeSecondaryTextColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!coupon.isActive)
              Icon(
                Icons.visibility_off,
                color: context.themeSecondaryTextColor,
                size: 20,
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCouponDialog(coupon),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteCouponDialog(coupon),
              tooltip: 'Delete',
              color: AppColors.errorRed,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // MARK: - Dialogs
  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (context) => _CouponDialog(
        firestoreService: _firestoreService,
        onSaved: () {
          _loadCoupons();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditCouponDialog(CouponModel coupon) {
    showDialog(
      context: context,
      builder: (context) => _CouponDialog(
        firestoreService: _firestoreService,
        coupon: coupon,
        onSaved: () {
          _loadCoupons();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDeleteCouponDialog(CouponModel coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
          'Are you sure you want to delete coupon "${coupon.code}"? Clients will no longer be able to use it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deleteCoupon(coupon.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadCoupons();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon deleted'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${e.toString()}'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// MARK: - Coupon Dialog
/// Dialog for adding or editing a coupon
class _CouponDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final CouponModel? coupon;
  final VoidCallback onSaved;

  const _CouponDialog({
    required this.firestoreService,
    this.coupon,
    required this.onSaved,
  });

  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

// MARK: - Coupon Dialog State
class _CouponDialogState extends State<_CouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _percentOffController = TextEditingController();
  final _amountOffController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _usageLimitController = TextEditingController();

  CouponDiscountType _discountType = CouponDiscountType.percent;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.coupon != null) {
      final c = widget.coupon!;
      _codeController.text = c.code;
      _discountType = c.discountType;
      _percentOffController.text = c.percentOff?.toString() ?? '';
      _amountOffController.text = c.amountOffCents != null ? (c.amountOffCents! / 100).toStringAsFixed(2) : '';
      _descriptionController.text = c.description ?? '';
      _usageLimitController.text = c.usageLimit?.toString() ?? '';
      _isActive = c.isActive;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _percentOffController.dispose();
    _amountOffController.dispose();
    _descriptionController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a coupon code'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    int? percentOff;
    int? amountOffCents;
    switch (_discountType) {
      case CouponDiscountType.percent:
        percentOff = int.tryParse(_percentOffController.text.trim());
        if (percentOff == null || percentOff < 0 || percentOff > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid percent (0–100)'), backgroundColor: AppColors.errorRed),
          );
          return;
        }
        break;
      case CouponDiscountType.fixed:
        final dollars = double.tryParse(_amountOffController.text.trim());
        if (dollars == null || dollars < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid dollar amount'), backgroundColor: AppColors.errorRed),
          );
          return;
        }
        amountOffCents = (dollars * 100).round();
        break;
      case CouponDiscountType.free:
        percentOff = 100;
        break;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      if (widget.coupon != null) {
        final updated = widget.coupon!.copyWith(
          code: code,
          discountType: _discountType,
          percentOff: percentOff,
          amountOffCents: amountOffCents,
          isActive: _isActive,
          usageLimit: int.tryParse(_usageLimitController.text.trim()),
          updatedAt: now,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );
        await widget.firestoreService.updateCoupon(updated);
      } else {
        final coupon = CouponModel(
          id: '',
          code: code,
          discountType: _discountType,
          percentOff: percentOff,
          amountOffCents: amountOffCents,
          isActive: _isActive,
          usageLimit: int.tryParse(_usageLimitController.text.trim()),
          timesUsed: 0,
          createdAt: now,
          updatedAt: now,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );
        await widget.firestoreService.createCoupon(coupon);
      }
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.coupon != null ? 'Coupon updated' : 'Coupon created'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.coupon != null ? 'Edit Coupon' : 'Add Coupon'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code',
                  hintText: 'e.g. SAVE20',
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: widget.coupon == null,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CouponDiscountType>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: const [
                  DropdownMenuItem(value: CouponDiscountType.percent, child: Text('Percent off')),
                  DropdownMenuItem(value: CouponDiscountType.fixed, child: Text('Dollar amount off')),
                  DropdownMenuItem(value: CouponDiscountType.free, child: Text('Free (100% off)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _discountType = v);
                },
              ),
              if (_discountType == CouponDiscountType.percent) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _percentOffController,
                  decoration: const InputDecoration(
                    labelText: 'Percent off (0–100)',
                    hintText: 'e.g. 20',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (_discountType != CouponDiscountType.percent) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0 || n > 100) return 'Enter 0–100';
                    return null;
                  },
                ),
              ],
              if (_discountType == CouponDiscountType.fixed) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountOffController,
                  decoration: const InputDecoration(
                    labelText: 'Amount off (\$)',
                    hintText: 'e.g. 10.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (v) {
                    if (_discountType != CouponDiscountType.fixed) return null;
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Admin note only',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usageLimitController,
                decoration: const InputDecoration(
                  labelText: 'Usage limit (optional)',
                  hintText: 'Leave empty for unlimited',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Inactive coupons cannot be used by clients'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeColor: AppColors.sunflowerYellow,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sunflowerYellow,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add valid from / valid until date pickers
// - Add minimum booking amount for coupon
// - Add one-time-use-per-client option
