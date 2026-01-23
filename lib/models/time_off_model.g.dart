// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_off_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeOffModel _$TimeOffModelFromJson(Map<String, dynamic> json) => TimeOffModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: TimeOffModel._timestampFromJson(json['startTime']),
      endTime: TimeOffModel._timestampFromJson(json['endTime']),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: $enumDecodeNullable(
              _$RecurrencePatternEnumMap, json['recurrencePattern']) ??
          RecurrencePattern.none,
      recurrenceEndDate:
          TimeOffModel._timestampFromJson(json['recurrenceEndDate']),
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: TimeOffModel._timestampFromJson(json['createdAt']),
      updatedAt: TimeOffModel._timestampFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$TimeOffModelToJson(TimeOffModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startTime': TimeOffModel._timestampToJson(instance.startTime),
      'endTime': TimeOffModel._timestampToJson(instance.endTime),
      'isRecurring': instance.isRecurring,
      'recurrencePattern':
          _$RecurrencePatternEnumMap[instance.recurrencePattern]!,
      'recurrenceEndDate':
          TimeOffModel._timestampToJson(instance.recurrenceEndDate),
      'isActive': instance.isActive,
      'notes': instance.notes,
      'createdAt': TimeOffModel._timestampToJson(instance.createdAt),
      'updatedAt': TimeOffModel._timestampToJson(instance.updatedAt),
    };

const _$RecurrencePatternEnumMap = {
  RecurrencePattern.none: 'none',
  RecurrencePattern.daily: 'daily',
  RecurrencePattern.weekly: 'weekly',
  RecurrencePattern.monthly: 'monthly',
};
