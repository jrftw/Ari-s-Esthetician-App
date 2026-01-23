/*
 * Filename: service_category_model.dart
 * Purpose: Data model for service categories used to organize and filter services
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_category_model.g.dart';

// MARK: - Service Category Model
/// Represents a category for organizing services
/// Categories allow services to be grouped and filtered in the client booking interface
@JsonSerializable()
class ServiceCategoryModel extends Equatable {
  /// Unique identifier for the category
  final String id;
  
  /// Category name (e.g., "Facial Treatments", "Body Treatments")
  final String name;
  
  /// Sort order for displaying categories (lower numbers appear first)
  /// Defaults to 0 if not specified
  final int sortOrder;
  
  /// Whether the category is currently active/visible
  /// Inactive categories won't appear in category tabs but services referencing them will still show
  final bool isActive;
  
  /// Timestamp when the category was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when the category was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  // MARK: - Constructor
  const ServiceCategoryModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // MARK: - Factory Constructors
  /// Create a ServiceCategoryModel from Firestore document
  factory ServiceCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceCategoryModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a ServiceCategoryModel from JSON
  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryModelFromJson(json);

  /// Create a new ServiceCategoryModel with default timestamps
  factory ServiceCategoryModel.create({
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return ServiceCategoryModel(
      id: '', // Will be set by Firestore
      name: name,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert ServiceCategoryModel to JSON
  Map<String, dynamic> toJson() => _$ServiceCategoryModelToJson(this);

  /// Convert ServiceCategoryModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    return json;
  }

  /// Create a copy with updated fields
  ServiceCategoryModel copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        name,
        sortOrder,
        isActive,
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
// - Add category icons/images
// - Add category descriptions
// - Add category color coding
// - Add category display preferences (grid/list)
// - Add category-level pricing rules