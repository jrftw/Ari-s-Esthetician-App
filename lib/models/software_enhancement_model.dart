/*
 * Filename: software_enhancement_model.dart
 * Purpose: Data model for software enhancements (bugs, features, suggestions) tracked by super admins
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-22
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'software_enhancement_model.g.dart';

// MARK: - Enhancement Type Enum
/// Type of software enhancement
enum EnhancementType {
  @JsonValue('bug')
  bug,
  @JsonValue('feature')
  feature,
  @JsonValue('suggestion')
  suggestion,
  @JsonValue('improvement')
  improvement,
}

// MARK: - Enhancement Status Enum
/// Status of the software enhancement
enum EnhancementStatus {
  @JsonValue('open')
  open,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('deferred')
  deferred,
  @JsonValue('rejected')
  rejected,
}

// MARK: - Software Enhancement Model
/// Represents a software enhancement (bug report, feature request, suggestion)
/// Tracks who created and updated it, along with status and type
@JsonSerializable()
class SoftwareEnhancementModel extends Equatable {
  /// Unique identifier for the enhancement
  final String id;
  
  /// Type of enhancement (bug, feature, suggestion, improvement)
  final EnhancementType type;
  
  /// Status of the enhancement
  final EnhancementStatus status;
  
  /// Title of the enhancement
  final String title;
  
  /// Detailed description of the enhancement
  final String description;
  
  /// User ID of the creator
  final String createdByUserId;
  
  /// Email of the creator
  final String createdByEmail;
  
  /// Name of the creator
  final String createdByName;
  
  /// Timestamp when the enhancement was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// User ID of the last updater
  final String? updatedByUserId;
  
  /// Email of the last updater
  final String? updatedByEmail;
  
  /// Name of the last updater
  final String? updatedByName;
  
  /// Timestamp when the enhancement was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? updatedAt;
  
  /// Additional notes or comments
  final String? notes;
  
  /// Priority level (1-5, where 5 is highest)
  final int priority;

  // MARK: - Constructor
  const SoftwareEnhancementModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.createdByUserId,
    required this.createdByEmail,
    required this.createdByName,
    required this.createdAt,
    this.updatedByUserId,
    this.updatedByEmail,
    this.updatedByName,
    this.updatedAt,
    this.notes,
    this.priority = 3,
  });

  // MARK: - Factory Constructors
  /// Create a SoftwareEnhancementModel from Firestore document
  factory SoftwareEnhancementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SoftwareEnhancementModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a SoftwareEnhancementModel from JSON
  factory SoftwareEnhancementModel.fromJson(Map<String, dynamic> json) =>
      _$SoftwareEnhancementModelFromJson(json);

  /// Create a new enhancement
  factory SoftwareEnhancementModel.create({
    required EnhancementType type,
    required String title,
    required String description,
    required String createdByUserId,
    required String createdByEmail,
    required String createdByName,
    String? notes,
    int priority = 3,
  }) {
    final now = DateTime.now();
    return SoftwareEnhancementModel(
      id: '', // Will be set by Firestore
      type: type,
      status: EnhancementStatus.open,
      title: title,
      description: description,
      createdByUserId: createdByUserId,
      createdByEmail: createdByEmail,
      createdByName: createdByName,
      createdAt: now,
      notes: notes,
      priority: priority,
    );
  }

  // MARK: - Conversion Methods
  /// Convert SoftwareEnhancementModel to JSON
  Map<String, dynamic> toJson() => _$SoftwareEnhancementModelToJson(this);

  /// Convert SoftwareEnhancementModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    return json;
  }

  // MARK: - Helper Methods
  /// Create a copy with updated fields
  SoftwareEnhancementModel copyWith({
    String? id,
    EnhancementType? type,
    EnhancementStatus? status,
    String? title,
    String? description,
    String? createdByUserId,
    String? createdByEmail,
    String? createdByName,
    DateTime? createdAt,
    String? updatedByUserId,
    String? updatedByEmail,
    String? updatedByName,
    DateTime? updatedAt,
    String? notes,
    int? priority,
  }) {
    return SoftwareEnhancementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      updatedByEmail: updatedByEmail ?? this.updatedByEmail,
      updatedByName: updatedByName ?? this.updatedByName,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }

  /// Update the enhancement with new information
  SoftwareEnhancementModel updateWith({
    EnhancementStatus? status,
    String? title,
    String? description,
    String? updatedByUserId,
    String? updatedByEmail,
    String? updatedByName,
    String? notes,
    int? priority,
  }) {
    return copyWith(
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      updatedByUserId: updatedByUserId,
      updatedByEmail: updatedByEmail,
      updatedByName: updatedByName,
      updatedAt: DateTime.now(),
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        type,
        status,
        title,
        description,
        createdByUserId,
        createdByEmail,
        createdByName,
        createdAt,
        updatedByUserId,
        updatedByEmail,
        updatedByName,
        updatedAt,
        notes,
        priority,
      ];

  // MARK: - Timestamp Helpers
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}

// Suggestions For Features and Additions Later:
// - Add attachment support (screenshots, files)
// - Add voting/priority system
// - Add tags/categories for better organization
// - Add linked enhancements (related bugs/features)
// - Add estimated completion date
// - Add actual completion date
// - Add time tracking (hours spent)
// - Add assignee field (who is working on it)
// - Add comments/thread system for discussion
// - Add change history/audit log
