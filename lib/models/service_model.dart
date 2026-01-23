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
}

// Suggestions For Features and Additions Later:
// - Add service categories/tags
// - Add service images
// - Add service availability by day/time
// - Add service packages/bundles
// - Add service add-ons
