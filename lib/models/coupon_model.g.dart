// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponModel _$CouponModelFromJson(Map<String, dynamic> json) => CouponModel(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: $enumDecodeNullable(
              _$CouponDiscountTypeEnumMap, json['discountType']) ??
          CouponDiscountType.percent,
      percentOff: (json['percentOff'] as num?)?.toInt(),
      amountOffCents: (json['amountOffCents'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      validFrom: CouponModel._timestampNullableFromJson(json['validFrom']),
      validUntil: CouponModel._timestampNullableFromJson(json['validUntil']),
      usageLimit: (json['usageLimit'] as num?)?.toInt(),
      timesUsed: (json['timesUsed'] as num?)?.toInt() ?? 0,
      createdAt: CouponModel._timestampFromJson(json['createdAt']),
      updatedAt: CouponModel._timestampFromJson(json['updatedAt']),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CouponModelToJson(CouponModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'discountType': _$CouponDiscountTypeEnumMap[instance.discountType]!,
      'percentOff': instance.percentOff,
      'amountOffCents': instance.amountOffCents,
      'isActive': instance.isActive,
      'validFrom': CouponModel._timestampToJson(instance.validFrom),
      'validUntil': CouponModel._timestampToJson(instance.validUntil),
      'usageLimit': instance.usageLimit,
      'timesUsed': instance.timesUsed,
      'createdAt': CouponModel._timestampToJson(instance.createdAt),
      'updatedAt': CouponModel._timestampToJson(instance.updatedAt),
      'description': instance.description,
    };

const _$CouponDiscountTypeEnumMap = {
  CouponDiscountType.percent: 'percent',
  CouponDiscountType.fixed: 'fixed',
  CouponDiscountType.free: 'free',
};
