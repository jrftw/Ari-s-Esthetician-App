/*
 * Filename: time_off_model.dart
 * Purpose: Data model for managing time-off and unavailability periods (breaks, vacations, etc.)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2025-01-22
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'time_off_model.g.dart';

// MARK: - Recurrence Pattern Enum
/// Defines how time-off repeats
enum RecurrencePattern {
  @JsonValue('none')
  none, // One-time only
  @JsonValue('daily')
  daily, // Every day
  @JsonValue('weekly')
  weekly, // Every week on same day
  @JsonValue('monthly')
  monthly, // Every month on same date
}

// MARK: - Time Off Model
/// Represents a period when the esthetician is unavailable
/// Supports both one-time and recurring time-off periods
@JsonSerializable()
class TimeOffModel extends Equatable {
  /// Unique identifier for the time-off period
  final String id;
  
  /// Title/description of the time-off (e.g., "Lunch Break", "Vacation", "Personal Day")
  final String title;
  
  /// Start date and time of the unavailability period
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime startTime;
  
  /// End date and time of the unavailability period
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime endTime;
  
  /// Whether this is a recurring time-off period
  final bool isRecurring;
  
  /// Recurrence pattern (if isRecurring is true)
  @JsonKey(defaultValue: RecurrencePattern.none)
  final RecurrencePattern recurrencePattern;
  
  /// End date for recurring time-off (null = no end date)
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime? recurrenceEndDate;
  
  /// Whether this time-off period is active
  final bool isActive;
  
  /// Optional notes about the time-off
  final String? notes;
  
  /// Timestamp when the time-off was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  
  /// Timestamp when the time-off was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  // MARK: - Constructor
  const TimeOffModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
    this.recurrencePattern = RecurrencePattern.none,
    this.recurrenceEndDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // MARK: - Factory Constructors
  /// Create a TimeOffModel from Firestore document
  factory TimeOffModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeOffModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a TimeOffModel from JSON
  factory TimeOffModel.fromJson(Map<String, dynamic> json) =>
      _$TimeOffModelFromJson(json);

  /// Create a one-time time-off period
  factory TimeOffModel.createOneTime({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) {
    final now = DateTime.now();
    return TimeOffModel(
      id: '', // Will be set by Firestore
      title: title,
      startTime: startTime,
      endTime: endTime,
      isRecurring: false,
      recurrencePattern: RecurrencePattern.none,
      isActive: true,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a recurring time-off period
  factory TimeOffModel.createRecurring({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required RecurrencePattern recurrencePattern,
    DateTime? recurrenceEndDate,
    String? notes,
  }) {
    final now = DateTime.now();
    return TimeOffModel(
      id: '', // Will be set by Firestore
      title: title,
      startTime: startTime,
      endTime: endTime,
      isRecurring: true,
      recurrencePattern: recurrencePattern,
      recurrenceEndDate: recurrenceEndDate,
      isActive: true,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  // MARK: - Conversion Methods
  /// Convert TimeOffModel to JSON
  Map<String, dynamic> toJson() => _$TimeOffModelToJson(this);

  /// Convert TimeOffModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore handles ID separately
    return json;
  }

  // MARK: - Helper Methods
  /// Check if this time-off period overlaps with a given time range
  bool overlapsWith(DateTime checkStartTime, DateTime checkEndTime) {
    return startTime.isBefore(checkEndTime) && endTime.isAfter(checkStartTime);
  }

  /// Check if this time-off period is active for a specific date/time
  bool isActiveForDateTime(DateTime dateTime) {
    if (!isActive) return false;
    
    if (!isRecurring) {
      // One-time: check if dateTime is within the period
      return dateTime.isAfter(startTime.subtract(const Duration(seconds: 1))) &&
             dateTime.isBefore(endTime.add(const Duration(seconds: 1)));
    }
    
    // Recurring: check if dateTime matches the recurrence pattern
    if (recurrenceEndDate != null && dateTime.isAfter(recurrenceEndDate!)) {
      return false;
    }
    
    // Extract time components from startTime and endTime
    final startTimeOfDay = TimeOfDay.fromDateTime(startTime);
    final endTimeOfDay = TimeOfDay.fromDateTime(endTime);
    final checkTimeOfDay = TimeOfDay.fromDateTime(dateTime);
    
    // Check if the time of day is within the time-off window
    final checkMinutes = checkTimeOfDay.hour * 60 + checkTimeOfDay.minute;
    final startMinutes = startTimeOfDay.hour * 60 + startTimeOfDay.minute;
    final endMinutes = endTimeOfDay.hour * 60 + endTimeOfDay.minute;
    
    if (checkMinutes < startMinutes || checkMinutes >= endMinutes) {
      return false;
    }
    
    // Check recurrence pattern
    switch (recurrencePattern) {
      case RecurrencePattern.daily:
        return true; // Every day at this time
      case RecurrencePattern.weekly:
        return dateTime.weekday == startTime.weekday;
      case RecurrencePattern.monthly:
        return dateTime.day == startTime.day;
      case RecurrencePattern.none:
        return false;
    }
  }

  /// Get all occurrences of this time-off within a date range (for recurring)
  List<DateTimeRange> getOccurrencesInRange(DateTime rangeStart, DateTime rangeEnd) {
    if (!isRecurring) {
      // One-time: return single occurrence if it's in range
      if (startTime.isBefore(rangeEnd) && endTime.isAfter(rangeStart)) {
        return [DateTimeRange(start: startTime, end: endTime)];
      }
      return [];
    }
    
    final occurrences = <DateTimeRange>[];
    final startTimeOfDay = TimeOfDay.fromDateTime(startTime);
    final endTimeOfDay = TimeOfDay.fromDateTime(endTime);
    final duration = endTime.difference(startTime);
    
    DateTime currentDate = startTime;
    
    while (currentDate.isBefore(rangeEnd) || currentDate.isAtSameMomentAs(rangeEnd)) {
      if (recurrenceEndDate != null && currentDate.isAfter(recurrenceEndDate!)) {
        break;
      }
      
      // Check if this date matches the recurrence pattern
      bool matches = false;
      switch (recurrencePattern) {
        case RecurrencePattern.daily:
          matches = true;
          break;
        case RecurrencePattern.weekly:
          matches = currentDate.weekday == startTime.weekday;
          break;
        case RecurrencePattern.monthly:
          matches = currentDate.day == startTime.day;
          break;
        case RecurrencePattern.none:
          matches = false;
          break;
      }
      
      if (matches) {
        final occurrenceStart = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          startTimeOfDay.hour,
          startTimeOfDay.minute,
        );
        final occurrenceEnd = occurrenceStart.add(duration);
        
        if (occurrenceStart.isBefore(rangeEnd) && occurrenceEnd.isAfter(rangeStart)) {
          occurrences.add(DateTimeRange(start: occurrenceStart, end: occurrenceEnd));
        }
      }
      
      // Move to next potential occurrence
      switch (recurrencePattern) {
        case RecurrencePattern.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case RecurrencePattern.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case RecurrencePattern.monthly:
          // Move to same day next month
          if (currentDate.month == 12) {
            currentDate = DateTime(currentDate.year + 1, 1, startTime.day);
          } else {
            currentDate = DateTime(currentDate.year, currentDate.month + 1, startTime.day);
          }
          break;
        case RecurrencePattern.none:
          break;
      }
    }
    
    return occurrences;
  }

  /// Create a copy with updated fields
  TimeOffModel copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
    DateTime? recurrenceEndDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeOffModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        title,
        startTime,
        endTime,
        isRecurring,
        recurrencePattern,
        recurrenceEndDate,
        isActive,
        notes,
        createdAt,
        updatedAt,
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

// MARK: - TimeOfDay Helper Extension
/// Extension to convert DateTime to TimeOfDay
extension DateTimeToTimeOfDay on DateTime {
  TimeOfDay toTimeOfDay() {
    return TimeOfDay(hour: hour, minute: minute);
  }
}

// Suggestions For Features and Additions Later:
// - Add support for multiple staff members with individual time-off
// - Add time-off approval workflow
// - Add time-off templates for common breaks
// - Add calendar integration for time-off
// - Add notifications when time-off conflicts with existing appointments
