/*
 * Filename: service_model.dart
 * Purpose: Data model for esthetician services with pricing and deposit information
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_model.g.dart';

// MARK: - Service Package Tier Enum
/// Represents the package tier level for a service
/// Used to categorize services into different price/service levels
enum ServicePackageTier {
  /// Lower tier package - entry level services
  lower,
  
  /// Mid tier package - standard services
  mid,
  
  /// Higher tier package - premium services
  higher;

  /// Get display name for the tier
  String get displayName {
    switch (this) {
      case ServicePackageTier.lower:
        return 'Lower';
      case ServicePackageTier.mid:
        return 'Mid';
      case ServicePackageTier.higher:
        return 'Higher';
    }
  }

  /// Get tier from string value (for JSON deserialization)
  static ServicePackageTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lower':
        return ServicePackageTier.lower;
      case 'mid':
        return ServicePackageTier.mid;
      case 'higher':
        return ServicePackageTier.higher;
      default:
        return ServicePackageTier.mid; // Default to mid if invalid
    }
  }

  /// Convert tier to string (for JSON serialization)
  String toJson() {
    return name;
  }
}

// MARK: - Service Package Option
/// Represents a package tier option for a service with its own pricing
/// Allows services to have multiple tier options (higher, mid, lower) with different pricing
@JsonSerializable()
class ServicePackageOption extends Equatable {
  /// The tier level for this option
  @JsonKey(fromJson: ServicePackageTier.fromString, toJson: _packageTierToJson)
  final ServicePackageTier tier;
  
  /// Price in cents for this tier option
  final int priceCents;
  
  /// Deposit amount in cents for this tier option
  final int depositAmountCents;
  
  /// Optional description for this tier option
  final String? description;

  const ServicePackageOption({
    required this.tier,
    required this.priceCents,
    required this.depositAmountCents,
    this.description,
  });

  factory ServicePackageOption.fromJson(Map<String, dynamic> json) =>
      _$ServicePackageOptionFromJson(json);

  Map<String, dynamic> toJson() => _$ServicePackageOptionToJson(this);

  /// Get formatted price as string (e.g., "$150.00")
  String get formattedPrice {
    return '\$${(priceCents / 100).toStringAsFixed(2)}';
  }

  /// Get formatted deposit as string (e.g., "$50.00")
  String get formattedDeposit {
    return '\$${(depositAmountCents / 100).toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [tier, priceCents, depositAmountCents, description];

  static String _packageTierToJson(ServicePackageTier tier) => tier.toJson();
}

// MARK: - Service Model
/// Represents a service offered by the esthetician business
/// This model is used throughout the app for displaying services and managing bookings
@JsonSerializable()
class ServiceModel extends Equatable {
  /// Unique identifier for the service
  final String id;
  
  /// Service name (e.g., "Facial Treatment")
  final String name;
  
  /// Service description
  final String description;
  
  /// Service duration in minutes
  final int durationMinutes;
  
  /// Full service price in cents (e.g., 15000 = $150.00)
  final int priceCents;
  
  /// Required deposit amount in cents (e.g., 5000 = $50.00)
  final int depositAmountCents;
  
  /// Buffer time before this service in minutes
  final int bufferTimeBeforeMinutes;
  
  /// Buffer time after this service in minutes
  final int bufferTimeAfterMinutes;
  
  /// Whether the service is currently active/visible to clients
  final bool isActive;
  
  /// Display order for sorting services
  final int displayOrder;
  
  /// Package tier level (higher, mid, lower) - used as default if packageOptions is empty
  @JsonKey(fromJson: _packageTierFromJson, toJson: _packageTierToJson)
  final ServicePackageTier packageTier;
  
  /// Multiple package tier options with different pricing
  /// If provided, clients can choose which tier they want
  /// If empty, uses the default packageTier, priceCents, and depositAmountCents
  @JsonKey(fromJson: _packageOptionsFromJson, toJson: _packageOptionsToJson)
  final List<ServicePackageOption>? packageOptions;
  
  /// Optional category ID for organizing services into categories
  /// If null or empty, service is treated as "Uncategorized" / "Other"
  final String? categoryId;
  
  /// Optional snapshot of category name at time of service creation/update
  /// Used as a fallback display name if category document is missing or inactive
  final String? categoryNameSnapshot;
  
  /// Timestamp when the service was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when the service was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  // MARK: - Constructor
  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.priceCents,
    required this.depositAmountCents,
    this.bufferTimeBeforeMinutes = 0,
    this.bufferTimeAfterMinutes = 0,
    this.isActive = true,
    this.displayOrder = 0,
    this.packageTier = ServicePackageTier.mid,
    this.packageOptions,
    this.categoryId,
    this.categoryNameSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });

  // MARK: - Factory Constructors
  /// Create a ServiceModel from Firestore document
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a ServiceModel from JSON
  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);

  /// Create a new ServiceModel with default timestamps
  factory ServiceModel.create({
    required String name,
    required String description,
    required int durationMinutes,
    required int priceCents,
    required int depositAmountCents,
    int bufferTimeBeforeMinutes = 0,
    int bufferTimeAfterMinutes = 0,
    bool isActive = true,
    int displayOrder = 0,
    ServicePackageTier packageTier = ServicePackageTier.mid,
    List<ServicePackageOption>? packageOptions,
    String? categoryId,
    String? categoryNameSnapshot,
  }) {
    final now = DateTime.now();
    return ServiceModel(
      id: '', // Will be set by Firestore
      name: name,
      description: description,
      durationMinutes: durationMinutes,
      priceCents: priceCents,
      depositAmountCents: depositAmountCents,
      bufferTimeBeforeMinutes: bufferTimeBeforeMinutes,
      bufferTimeAfterMinutes: bufferTimeAfterMinutes,
      isActive: isActive,
      displayOrder: displayOrder,
      packageTier: packageTier,
      packageOptions: packageOptions,
      categoryId: categoryId,
      categoryNameSnapshot: categoryNameSnapshot,
      createdAt: now,
      updatedAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert ServiceModel to JSON
  Map<String, dynamic> toJson() => _$ServiceModelToJson(this);

  /// Convert ServiceModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    
    // Only include category fields if they are not null/empty (backwards compatible)
    // This ensures existing services without categories don't get these fields written
    final hasCategoryId = categoryId != null && categoryId!.isNotEmpty;
    final hasCategoryName = categoryNameSnapshot != null && categoryNameSnapshot!.isNotEmpty;
    
    if (!hasCategoryId) {
      json.remove('categoryId');
    }
    if (!hasCategoryName) {
      json.remove('categoryNameSnapshot');
    }
    
    return json;
  }

  // MARK: - Helper Methods
  /// Get formatted price as string (e.g., "$150.00")
  String get formattedPrice {
    return '\$${(priceCents / 100).toStringAsFixed(2)}';
  }

  /// Get formatted deposit as string (e.g., "$50.00")
  String get formattedDeposit {
    return '\$${(depositAmountCents / 100).toStringAsFixed(2)}';
  }

  /// Check if service has multiple package options available
  bool get hasMultiplePackageOptions {
    return packageOptions != null && packageOptions!.isNotEmpty;
  }

  /// Get available package tiers for this service
  List<ServicePackageTier> get availablePackageTiers {
    if (hasMultiplePackageOptions) {
      return packageOptions!.map((option) => option.tier).toList();
    }
    return [packageTier];
  }

  /// Get package option for a specific tier
  /// Returns null if tier is not available
  ServicePackageOption? getPackageOption(ServicePackageTier tier) {
    if (hasMultiplePackageOptions) {
      try {
        return packageOptions!.firstWhere((option) => option.tier == tier);
      } catch (e) {
        return null;
      }
    }
    // Return default option if no package options are set
    if (tier == packageTier) {
      return ServicePackageOption(
        tier: packageTier,
        priceCents: priceCents,
        depositAmountCents: depositAmountCents,
      );
    }
    return null;
  }

  /// Get price for a specific tier
  int getPriceForTier(ServicePackageTier tier) {
    final option = getPackageOption(tier);
    return option?.priceCents ?? priceCents;
  }

  /// Get deposit for a specific tier
  int getDepositForTier(ServicePackageTier tier) {
    final option = getPackageOption(tier);
    return option?.depositAmountCents ?? depositAmountCents;
  }

  /// Get total duration including buffers
  int get totalDurationMinutes {
    return durationMinutes + bufferTimeBeforeMinutes + bufferTimeAfterMinutes;
  }

  /// Create a copy with updated fields
  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    int? durationMinutes,
    int? priceCents,
    int? depositAmountCents,
    int? bufferTimeBeforeMinutes,
    int? bufferTimeAfterMinutes,
    bool? isActive,
    int? displayOrder,
    ServicePackageTier? packageTier,
    List<ServicePackageOption>? packageOptions,
    String? categoryId,
    String? categoryNameSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priceCents: priceCents ?? this.priceCents,
      depositAmountCents: depositAmountCents ?? this.depositAmountCents,
      bufferTimeBeforeMinutes: bufferTimeBeforeMinutes ?? this.bufferTimeBeforeMinutes,
      bufferTimeAfterMinutes: bufferTimeAfterMinutes ?? this.bufferTimeAfterMinutes,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      packageTier: packageTier ?? this.packageTier,
      packageOptions: packageOptions ?? this.packageOptions,
      categoryId: categoryId ?? this.categoryId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        name,
        description,
        durationMinutes,
        priceCents,
        depositAmountCents,
        bufferTimeBeforeMinutes,
        bufferTimeAfterMinutes,
        isActive,
        displayOrder,
        packageTier,
        packageOptions,
        categoryId,
        categoryNameSnapshot,
        createdAt,
        updatedAt,
      ];

  // MARK: - Timestamp Helpers
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  // MARK: - Package Tier Helpers
  /// Convert package tier from JSON (string) to enum
  static ServicePackageTier _packageTierFromJson(dynamic value) {
    if (value is String) {
      return ServicePackageTier.fromString(value);
    }
    return ServicePackageTier.mid; // Default to mid if invalid
  }

  /// Convert package tier enum to JSON (string)
  static String _packageTierToJson(ServicePackageTier tier) {
    return tier.toJson();
  }

  // MARK: - Package Options Helpers
  /// Convert package options from JSON (list)
  static List<ServicePackageOption>? _packageOptionsFromJson(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((item) => item is Map<String, dynamic>
              ? ServicePackageOption.fromJson(item)
              : null)
          .whereType<ServicePackageOption>()
          .toList();
    }
    return null;
  }

  /// Convert package options list to JSON
  static List<Map<String, dynamic>>? _packageOptionsToJson(List<ServicePackageOption>? options) {
    if (options == null || options.isEmpty) return null;
    return options.map((option) => option.toJson()).toList();
  }
}

// Suggestions For Features and Additions Later:
// - Add service categories/tags
// - Add service images
// - Add service availability by day/time
// - Add service packages/bundles
// - Add service add-ons
