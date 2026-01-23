// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) => ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      priceCents: (json['priceCents'] as num).toInt(),
      depositAmountCents: (json['depositAmountCents'] as num).toInt(),
      bufferTimeBeforeMinutes:
          (json['bufferTimeBeforeMinutes'] as num?)?.toInt() ?? 0,
      bufferTimeAfterMinutes:
          (json['bufferTimeAfterMinutes'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: ServiceModel._timestampFromJson(json['createdAt']),
      updatedAt: ServiceModel._timestampFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ServiceModelToJson(ServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'durationMinutes': instance.durationMinutes,
      'priceCents': instance.priceCents,
      'depositAmountCents': instance.depositAmountCents,
      'bufferTimeBeforeMinutes': instance.bufferTimeBeforeMinutes,
      'bufferTimeAfterMinutes': instance.bufferTimeAfterMinutes,
      'isActive': instance.isActive,
      'displayOrder': instance.displayOrder,
      'createdAt': ServiceModel._timestampToJson(instance.createdAt),
      'updatedAt': ServiceModel._timestampToJson(instance.updatedAt),
    };
