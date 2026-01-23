// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServicePackageOption _$ServicePackageOptionFromJson(
        Map<String, dynamic> json) =>
    ServicePackageOption(
      tier: ServicePackageTier.fromString(json['tier'] as String),
      priceCents: (json['priceCents'] as num).toInt(),
      depositAmountCents: (json['depositAmountCents'] as num).toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ServicePackageOptionToJson(
        ServicePackageOption instance) =>
    <String, dynamic>{
      'tier': ServicePackageOption._packageTierToJson(instance.tier),
      'priceCents': instance.priceCents,
      'depositAmountCents': instance.depositAmountCents,
      'description': instance.description,
    };

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
      packageTier: json['packageTier'] == null
          ? ServicePackageTier.mid
          : ServiceModel._packageTierFromJson(json['packageTier']),
      packageOptions:
          ServiceModel._packageOptionsFromJson(json['packageOptions']),
      categoryId: json['categoryId'] as String?,
      categoryNameSnapshot: json['categoryNameSnapshot'] as String?,
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
      'packageTier': ServiceModel._packageTierToJson(instance.packageTier),
      'packageOptions':
          ServiceModel._packageOptionsToJson(instance.packageOptions),
      'categoryId': instance.categoryId,
      'categoryNameSnapshot': instance.categoryNameSnapshot,
      'createdAt': ServiceModel._timestampToJson(instance.createdAt),
      'updatedAt': ServiceModel._timestampToJson(instance.updatedAt),
    };
