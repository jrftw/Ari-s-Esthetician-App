// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessHoursModel _$BusinessHoursModelFromJson(Map<String, dynamic> json) =>
    BusinessHoursModel(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      isOpen: json['isOpen'] as bool? ?? false,
      timeSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$BusinessHoursModelToJson(BusinessHoursModel instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'isOpen': instance.isOpen,
      'timeSlots': instance.timeSlots,
    };

BusinessSettingsModel _$BusinessSettingsModelFromJson(
        Map<String, dynamic> json) =>
    BusinessSettingsModel(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      businessEmail: json['businessEmail'] as String,
      businessPhone: json['businessPhone'] as String,
      businessAddress: json['businessAddress'] as String?,
      logoUrl: json['logoUrl'] as String?,
      primaryColorHex: json['primaryColorHex'] as String?,
      secondaryColorHex: json['secondaryColorHex'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      twitterUrl: json['twitterUrl'] as String?,
      weeklyHours: json['weeklyHours'] == null
          ? []
          : BusinessSettingsModel._weeklyHoursFromJson(
              json['weeklyHours'] as List),
      cancellationWindowHours:
          (json['cancellationWindowHours'] as num?)?.toInt() ?? 24,
      latePolicyText: json['latePolicyText'] as String? ?? '',
      noShowPolicyText: json['noShowPolicyText'] as String? ?? '',
      bookingPolicyText: json['bookingPolicyText'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'America/New_York',
      googleCalendarId: json['googleCalendarId'] as String?,
      calendarSyncEnabled: json['calendarSyncEnabled'] as bool? ?? false,
      calendarSyncProvider: json['calendarSyncProvider'] as String?,
      stripePublishableKey: json['stripePublishableKey'] as String?,
      stripeSecretKey: json['stripeSecretKey'] as String?,
      minDepositAmountCents: (json['minDepositAmountCents'] as num?)?.toInt(),
      cancellationFeeCents: (json['cancellationFeeCents'] as num?)?.toInt(),
      paymentsEnabled: json['paymentsEnabled'] as bool? ?? false,
      createdAt: BusinessSettingsModel._timestampFromJson(json['createdAt']),
      updatedAt: BusinessSettingsModel._timestampFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$BusinessSettingsModelToJson(
        BusinessSettingsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
      'businessEmail': instance.businessEmail,
      'businessPhone': instance.businessPhone,
      'businessAddress': instance.businessAddress,
      'logoUrl': instance.logoUrl,
      'primaryColorHex': instance.primaryColorHex,
      'secondaryColorHex': instance.secondaryColorHex,
      'websiteUrl': instance.websiteUrl,
      'facebookUrl': instance.facebookUrl,
      'instagramUrl': instance.instagramUrl,
      'twitterUrl': instance.twitterUrl,
      'weeklyHours':
          BusinessSettingsModel._weeklyHoursToJson(instance.weeklyHours),
      'cancellationWindowHours': instance.cancellationWindowHours,
      'latePolicyText': instance.latePolicyText,
      'noShowPolicyText': instance.noShowPolicyText,
      'bookingPolicyText': instance.bookingPolicyText,
      'timezone': instance.timezone,
      'googleCalendarId': instance.googleCalendarId,
      'calendarSyncEnabled': instance.calendarSyncEnabled,
      'calendarSyncProvider': instance.calendarSyncProvider,
      'stripePublishableKey': instance.stripePublishableKey,
      'stripeSecretKey': instance.stripeSecretKey,
      'minDepositAmountCents': instance.minDepositAmountCents,
      'cancellationFeeCents': instance.cancellationFeeCents,
      'paymentsEnabled': instance.paymentsEnabled,
      'createdAt': BusinessSettingsModel._timestampToJson(instance.createdAt),
      'updatedAt': BusinessSettingsModel._timestampToJson(instance.updatedAt),
    };
