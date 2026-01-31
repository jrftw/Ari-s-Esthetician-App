/*
 * Filename: admin_earnings_screen.dart
 * Purpose: Admin screen for viewing estimated earnings with service filtering and statistics
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: Flutter, go_router, cloud_firestore
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import '../../models/appointment_model.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';

// MARK: - Admin Earnings Screen
/// Screen displaying estimated earnings from all appointments
/// Allows filtering by service and shows comprehensive statistics
class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

// MARK: - Admin Earnings Screen State
class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // MARK: - State Variables
  List<AppointmentModel> _allAppointments = [];
  List<ServiceModel> _allServices = [];
  String? _selectedServiceId;
  bool _isLoading = true;
  String? _errorMessage;

  // MARK: - Lifecycle Methods
  @override
  void initState() {
    super.initState();
    logInfo('AdminEarningsScreen initialized', tag: 'AdminEarningsScreen');
    _loadData();
  }

  // MARK: - Data Loading
  /// Load appointments and services data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logInfo('Loading earnings data', tag: 'AdminEarningsScreen');
      
      final appointmentsFuture = _firestoreService.getAllAppointments();
      final servicesFuture = _firestoreService.getAllServices();
      
      final results = await Future.wait([appointmentsFuture, servicesFuture]);
      
      setState(() {
        _allAppointments = results[0] as List<AppointmentModel>;
        _allServices = results[1] as List<ServiceModel>;
        _isLoading = false;
      });
      
      logInfo(
        'Loaded ${_allAppointments.length} appointments and ${_allServices.length} services',
        tag: 'AdminEarningsScreen',
      );
    } catch (e, stackTrace) {
      logError(
        'Failed to load earnings data',
        tag: 'AdminEarningsScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _errorMessage = 'Failed to load earnings data. Please try again.';
        _isLoading = false;
      });
    }
  }

  // MARK: - Filtering Logic
  /// Get filtered appointments based on selected service
  List<AppointmentModel> get _filteredAppointments {
    if (_selectedServiceId == null) {
      return _allAppointments;
    }
    return _allAppointments
        .where((apt) => apt.serviceId == _selectedServiceId)
        .toList();
  }

  // MARK: - Earnings Calculations
  /// Calculate total estimated earnings from filtered appointments
  /// Includes deposits and all tips (pre and post appointment)
  int get _totalEarningsCents {
    return _filteredAppointments.fold<int>(
      0,
      (sum, apt) {
        // Only count earnings from completed appointments or confirmed with deposits
        if (apt.status == AppointmentStatus.completed ||
            apt.status == AppointmentStatus.confirmed ||
            apt.status == AppointmentStatus.arrived) {
          final deposit = apt.depositAmountCents;
          final totalTips = apt.totalTipAmountCents;
          return sum + deposit + totalTips;
        }
        return sum;
      },
    );
  }

  /// Calculate total deposits from filtered appointments
  int get _totalDepositsCents {
    return _filteredAppointments.fold<int>(
      0,
      (sum, apt) {
        if (apt.status == AppointmentStatus.completed ||
            apt.status == AppointmentStatus.confirmed ||
            apt.status == AppointmentStatus.arrived) {
          return sum + apt.depositAmountCents;
        }
        return sum;
      },
    );
  }

  /// Calculate total tips from filtered appointments
  int get _totalTipsCents {
    return _filteredAppointments.fold<int>(
      0,
      (sum, apt) {
        if (apt.status == AppointmentStatus.completed ||
            apt.status == AppointmentStatus.confirmed ||
            apt.status == AppointmentStatus.arrived) {
          return sum + apt.totalTipAmountCents;
        }
        return sum;
      },
    );
  }

  /// Get count of appointments included in earnings calculation
  int get _appointmentCount {
    return _filteredAppointments.where((apt) {
      return apt.status == AppointmentStatus.completed ||
          apt.status == AppointmentStatus.confirmed ||
          apt.status == AppointmentStatus.arrived;
    }).length;
  }

  /// Calculate average earnings per appointment
  double get _averageEarningsPerAppointment {
    if (_appointmentCount == 0) return 0.0;
    return _totalEarningsCents / _appointmentCount;
  }

  /// Get count of completed appointments
  int get _completedCount {
    return _filteredAppointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .length;
  }

  /// Get count of confirmed appointments
  int get _confirmedCount {
    return _filteredAppointments
        .where((apt) => apt.status == AppointmentStatus.confirmed)
        .length;
  }

  /// Get count of canceled appointments
  int get _canceledCount {
    return _filteredAppointments
        .where((apt) => apt.status == AppointmentStatus.canceled)
        .length;
  }

  /// Get count of no-show appointments
  int get _noShowCount {
    return _filteredAppointments
        .where((apt) => apt.status == AppointmentStatus.noShow)
        .length;
  }

  // MARK: - Helper Methods
  /// Format cents to currency string
  String _formatCurrency(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }

  /// Get service name by ID
  String _getServiceName(String serviceId) {
    try {
      final service = _allServices.firstWhere((s) => s.id == serviceId);
      return service.name;
    } catch (e) {
      return 'Unknown Service';
    }
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimated Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  // MARK: - UI Builders
  /// Build error view
  Widget _buildErrorView() {
    return Center(
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
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerYellow,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main content
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MARK: - Filter Section
          _buildFilterSection(),
          const SizedBox(height: 24),
          
          // MARK: - Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),
          
          // MARK: - Statistics Section
          _buildStatisticsSection(),
          const SizedBox(height: 24),
          
          // MARK: - Appointment Status Breakdown
          _buildStatusBreakdown(),
        ],
      ),
    );
  }

  /// Build filter section
  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter by Service',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedServiceId,
              decoration: InputDecoration(
                labelText: 'All Services',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.backgroundCream,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Services'),
                ),
                ..._allServices.map((service) {
                  return DropdownMenuItem<String>(
                    value: service.id,
                    child: Text(service.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedServiceId = value;
                });
                logInfo(
                  'Service filter changed: ${value ?? "All"}',
                  tag: 'AdminEarningsScreen',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Total Earnings Card
        _buildStatCard(
          title: 'Total Estimated Earnings',
          value: _formatCurrency(_totalEarningsCents),
          icon: Icons.attach_money,
          color: AppColors.sunflowerYellow,
        ),
        const SizedBox(height: 12),
        
        // Deposits Card
        _buildStatCard(
          title: 'Total Deposits',
          value: _formatCurrency(_totalDepositsCents),
          icon: Icons.payment,
          color: AppColors.infoBlue,
        ),
        const SizedBox(height: 12),
        
        // Tips Card
        _buildStatCard(
          title: 'Total Tips',
          value: _formatCurrency(_totalTipsCents),
          icon: Icons.favorite,
          color: AppColors.successGreen,
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.themeSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.themePrimaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build statistics section
  Widget _buildStatisticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              label: 'Total Appointments',
              value: '${_appointmentCount}',
            ),
            const Divider(),
            _buildStatRow(
              label: 'Average per Appointment',
              value: _formatCurrency(_averageEarningsPerAppointment.round()),
            ),
            const Divider(),
            _buildStatRow(
              label: 'Total Appointments (All Statuses)',
              value: '${_filteredAppointments.length}',
            ),
            if (_selectedServiceId != null) ...[
              const Divider(),
              _buildStatRow(
                label: 'Service',
                value: _getServiceName(_selectedServiceId!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build stat row
  Widget _buildStatRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium,
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status breakdown section
  Widget _buildStatusBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Status Breakdown',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              label: 'Completed',
              count: _completedCount,
              color: AppColors.statusCompleted,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              label: 'Confirmed',
              count: _confirmedCount,
              color: AppColors.statusConfirmed,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              label: 'Canceled',
              count: _canceledCount,
              color: AppColors.statusCancelled,
            ),
            const SizedBox(height: 8),
            _buildStatusRow(
              label: 'No Show',
              count: _noShowCount,
              color: AppColors.statusNoShow,
            ),
          ],
        ),
      ),
    );
  }

  /// Build status row
  Widget _buildStatusRow({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        Text(
          '$count',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Suggestions For Features and Additions Later:
// - Add date range filtering
// - Add export to CSV/PDF functionality
// - Add charts/graphs for earnings visualization
// - Add comparison with previous periods
// - Add earnings by month/week breakdown
// - Add estimated remaining balance calculation (full price - deposit)
// - Add filtering by appointment status
// - Add search functionality for appointments
// - Add detailed appointment list view
// - Add earnings trends over time
