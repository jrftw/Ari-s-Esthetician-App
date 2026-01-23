// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'software_enhancement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoftwareEnhancementModel _$SoftwareEnhancementModelFromJson(
        Map<String, dynamic> json) =>
    SoftwareEnhancementModel(
      id: json['id'] as String,
      type: $enumDecode(_$EnhancementTypeEnumMap, json['type']),
      status: $enumDecode(_$EnhancementStatusEnumMap, json['status']),
      title: json['title'] as String,
      description: json['description'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdByEmail: json['createdByEmail'] as String,
      createdByName: json['createdByName'] as String,
      createdAt: SoftwareEnhancementModel._timestampFromJson(json['createdAt']),
      updatedByUserId: json['updatedByUserId'] as String?,
      updatedByEmail: json['updatedByEmail'] as String?,
      updatedByName: json['updatedByName'] as String?,
      updatedAt: SoftwareEnhancementModel._timestampFromJson(json['updatedAt']),
      notes: json['notes'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$SoftwareEnhancementModelToJson(
        SoftwareEnhancementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$EnhancementTypeEnumMap[instance.type]!,
      'status': _$EnhancementStatusEnumMap[instance.status]!,
      'title': instance.title,
      'description': instance.description,
      'createdByUserId': instance.createdByUserId,
      'createdByEmail': instance.createdByEmail,
      'createdByName': instance.createdByName,
      'createdAt':
          SoftwareEnhancementModel._timestampToJson(instance.createdAt),
      'updatedByUserId': instance.updatedByUserId,
      'updatedByEmail': instance.updatedByEmail,
      'updatedByName': instance.updatedByName,
      'updatedAt':
          SoftwareEnhancementModel._timestampToJson(instance.updatedAt),
      'notes': instance.notes,
      'priority': instance.priority,
    };

const _$EnhancementTypeEnumMap = {
  EnhancementType.bug: 'bug',
  EnhancementType.feature: 'feature',
  EnhancementType.suggestion: 'suggestion',
  EnhancementType.improvement: 'improvement',
};

const _$EnhancementStatusEnumMap = {
  EnhancementStatus.open: 'open',
  EnhancementStatus.inProgress: 'in_progress',
  EnhancementStatus.completed: 'completed',
  EnhancementStatus.deferred: 'deferred',
  EnhancementStatus.rejected: 'rejected',
};
