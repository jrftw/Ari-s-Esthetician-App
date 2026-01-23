/*
 * Filename: client_model.dart
 * Purpose: Data model for client information and profile management
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2024-01-XX
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_model.g.dart';

// MARK: - Client Tag Enum
/// Tags that can be assigned to clients for categorization
enum ClientTag {
  @JsonValue('vip')
  vip,
  @JsonValue('sensitive_skin')
  sensitiveSkin,
  @JsonValue('repeat_no_show')
  repeatNoShow,
  @JsonValue('regular')
  regular,
  @JsonValue('first_time')
  firstTime,
  @JsonValue('preferred')
  preferred,
}

// MARK: - Client Model
/// Represents a client profile with booking history and notes
/// This model is used for client management in the admin dashboard
@JsonSerializable()
class ClientModel extends Equatable {
  /// Unique identifier for the client
  final String id;
  
  /// Client first name
  final String firstName;
  
  /// Client last name
  final String lastName;
  
  /// Client email address
  final String email;
  
  /// Client phone number
  final String phone;
  
  /// List of tags assigned to the client
  @JsonKey(defaultValue: [])
  final List<ClientTag> tags;
  
  /// Internal admin notes about the client
  final String? internalNotes;
  
  /// Total number of appointments booked
  final int totalAppointments;
  
  /// Total number of completed appointments
  final int completedAppointments;
  
  /// Total number of no-shows
  final int noShowCount;
  
  /// Total amount spent in cents
  final int totalSpentCents;
  
  /// Timestamp when the client was first created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when the client was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  
  /// Timestamp of last appointment
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? lastAppointmentAt;

  // MARK: - Constructor
  const ClientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.tags = const [],
    this.internalNotes,
    this.totalAppointments = 0,
    this.completedAppointments = 0,
    this.noShowCount = 0,
    this.totalSpentCents = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastAppointmentAt,
  });

  // MARK: - Factory Constructors
  /// Create a ClientModel from Firestore document
  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a ClientModel from JSON
  factory ClientModel.fromJson(Map<String, dynamic> json) =>
      _$ClientModelFromJson(json);

  /// Create a new ClientModel from booking information
  factory ClientModel.create({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    List<ClientTag> tags = const [],
  }) {
    final now = DateTime.now();
    return ClientModel(
      id: '', // Will be set by Firestore
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      tags: tags,
      totalAppointments: 0,
      completedAppointments: 0,
      noShowCount: 0,
      totalSpentCents: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert ClientModel to JSON
  Map<String, dynamic> toJson() => _$ClientModelToJson(this);

  /// Convert ClientModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    return json;
  }

  // MARK: - Helper Methods
  /// Get full client name
  String get fullName {
    return '$firstName $lastName';
  }

  /// Get formatted total spent as string
  String get formattedTotalSpent {
    return '\$${(totalSpentCents / 100).toStringAsFixed(2)}';
  }

  /// Check if client has a specific tag
  bool hasTag(ClientTag tag) {
    return tags.contains(tag);
  }

  /// Get completion rate as percentage
  double get completionRate {
    if (totalAppointments == 0) return 0.0;
    return (completedAppointments / totalAppointments) * 100;
  }

  /// Get no-show rate as percentage
  double get noShowRate {
    if (totalAppointments == 0) return 0.0;
    return (noShowCount / totalAppointments) * 100;
  }

  /// Check if client is a repeat no-show
  bool get isRepeatNoShow {
    return noShowCount >= 2 || hasTag(ClientTag.repeatNoShow);
  }

  /// Create a copy with updated fields
  ClientModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    List<ClientTag>? tags,
    String? internalNotes,
    int? totalAppointments,
    int? completedAppointments,
    int? noShowCount,
    int? totalSpentCents,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAppointmentAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      tags: tags ?? this.tags,
      internalNotes: internalNotes ?? this.internalNotes,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      completedAppointments: completedAppointments ?? this.completedAppointments,
      noShowCount: noShowCount ?? this.noShowCount,
      totalSpentCents: totalSpentCents ?? this.totalSpentCents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastAppointmentAt: lastAppointmentAt ?? this.lastAppointmentAt,
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        tags,
        internalNotes,
        totalAppointments,
        completedAppointments,
        noShowCount,
        totalSpentCents,
        createdAt,
        updatedAt,
        lastAppointmentAt,
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
// - Add client preferences (preferred times, services)
// - Add client allergies/sensitivities
// - Add client birthday for special offers
// - Add client referral tracking
// - Add client communication preferences
