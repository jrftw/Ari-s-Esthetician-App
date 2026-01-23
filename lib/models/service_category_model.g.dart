// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceCategoryModel _$ServiceCategoryModelFromJson(
        Map<String, dynamic> json) =>
    ServiceCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: ServiceCategoryModel._timestampFromJson(json['createdAt']),
      updatedAt: ServiceCategoryModel._timestampFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ServiceCategoryModelToJson(
        ServiceCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'createdAt': ServiceCategoryModel._timestampToJson(instance.createdAt),
      'updatedAt': ServiceCategoryModel._timestampToJson(instance.updatedAt),
    };
