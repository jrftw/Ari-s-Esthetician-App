// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentModel _$AppointmentModelFromJson(Map<String, dynamic> json) =>
    AppointmentModel(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      serviceSnapshot:
          AppointmentModel._serviceModelFromJson(json['serviceSnapshot']),
      clientFirstName: json['clientFirstName'] as String,
      clientLastName: json['clientLastName'] as String,
      clientEmail: json['clientEmail'] as String,
      clientPhone: json['clientPhone'] as String,
      intakeNotes: json['intakeNotes'] as String?,
      startTime: AppointmentModel._timestampFromJson(json['startTime']),
      endTime: AppointmentModel._timestampFromJson(json['endTime']),
      status: $enumDecodeNullable(_$AppointmentStatusEnumMap, json['status']) ??
          AppointmentStatus.confirmed,
      depositAmountCents: (json['depositAmountCents'] as num).toInt(),
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      tipAmountCents: (json['tipAmountCents'] as num?)?.toInt() ?? 0,
      tipPaymentIntentId: json['tipPaymentIntentId'] as String?,
      postAppointmentTipAmountCents:
          (json['postAppointmentTipAmountCents'] as num?)?.toInt(),
      postAppointmentTipPaymentIntentId:
          json['postAppointmentTipPaymentIntentId'] as String?,
      depositForfeited: json['depositForfeited'] as bool? ?? false,
      calendarSynced: json['calendarSynced'] as bool? ?? false,
      googleCalendarEventId: json['googleCalendarEventId'] as String?,
      createdAt: AppointmentModel._timestampFromJson(json['createdAt']),
      updatedAt: AppointmentModel._timestampFromJson(json['updatedAt']),
      confirmationEmailSentAt:
          AppointmentModel._timestampFromJson(json['confirmationEmailSentAt']),
      reminderEmailSentAt:
          AppointmentModel._timestampFromJson(json['reminderEmailSentAt']),
      dayOfReminderEmailSentAt:
          AppointmentModel._timestampFromJson(json['dayOfReminderEmailSentAt']),
      adminNotes: json['adminNotes'] as String?,
      termsAcceptanceMetadata: AppointmentModel._termsMetadataFromJson(
          json['termsAcceptanceMetadata']),
      healthDisclosure:
          AppointmentModel._healthDisclosureFromJson(json['healthDisclosure']),
      requiredAcknowledgments:
          AppointmentModel._requiredAcknowledgmentsFromJson(
              json['requiredAcknowledgments']),
      cancellationPolicyAcknowledged:
          json['cancellationPolicyAcknowledged'] as bool? ?? false,
      userId: json['userId'] as String?,
      healthDisclosureDetails:
          AppointmentModel._healthDisclosureDetailsFromJson(
              json['healthDisclosureDetails']),
      requiredAcknowledgmentsAcceptedAt:
          AppointmentModel._timestampNullableFromJson(
              json['requiredAcknowledgmentsAcceptedAt']),
      cancellationPolicySnapshot:
          AppointmentModel._cancellationPolicySnapshotFromJson(
              json['cancellationPolicySnapshot']),
      couponCode: json['couponCode'] as String?,
      discountAmountCents: (json['discountAmountCents'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AppointmentModelToJson(AppointmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceId': instance.serviceId,
      'serviceSnapshot':
          AppointmentModel._serviceModelToJson(instance.serviceSnapshot),
      'clientFirstName': instance.clientFirstName,
      'clientLastName': instance.clientLastName,
      'clientEmail': instance.clientEmail,
      'clientPhone': instance.clientPhone,
      'intakeNotes': instance.intakeNotes,
      'startTime': AppointmentModel._timestampToJson(instance.startTime),
      'endTime': AppointmentModel._timestampToJson(instance.endTime),
      'status': _$AppointmentStatusEnumMap[instance.status]!,
      'depositAmountCents': instance.depositAmountCents,
      'stripePaymentIntentId': instance.stripePaymentIntentId,
      'tipAmountCents': instance.tipAmountCents,
      'tipPaymentIntentId': instance.tipPaymentIntentId,
      'postAppointmentTipAmountCents': instance.postAppointmentTipAmountCents,
      'postAppointmentTipPaymentIntentId':
          instance.postAppointmentTipPaymentIntentId,
      'depositForfeited': instance.depositForfeited,
      'calendarSynced': instance.calendarSynced,
      'googleCalendarEventId': instance.googleCalendarEventId,
      'createdAt': AppointmentModel._timestampToJson(instance.createdAt),
      'updatedAt': AppointmentModel._timestampToJson(instance.updatedAt),
      'confirmationEmailSentAt':
          AppointmentModel._timestampToJson(instance.confirmationEmailSentAt),
      'reminderEmailSentAt':
          AppointmentModel._timestampToJson(instance.reminderEmailSentAt),
      'dayOfReminderEmailSentAt':
          AppointmentModel._timestampToJson(instance.dayOfReminderEmailSentAt),
      'adminNotes': instance.adminNotes,
      'termsAcceptanceMetadata': AppointmentModel._termsMetadataToJson(
          instance.termsAcceptanceMetadata),
      'healthDisclosure':
          AppointmentModel._healthDisclosureToJson(instance.healthDisclosure),
      'requiredAcknowledgments':
          AppointmentModel._requiredAcknowledgmentsToJson(
              instance.requiredAcknowledgments),
      'cancellationPolicyAcknowledged': instance.cancellationPolicyAcknowledged,
      'userId': instance.userId,
      'healthDisclosureDetails':
          AppointmentModel._healthDisclosureDetailsToJson(
              instance.healthDisclosureDetails),
      'requiredAcknowledgmentsAcceptedAt': AppointmentModel._timestampToJson(
          instance.requiredAcknowledgmentsAcceptedAt),
      'cancellationPolicySnapshot':
          AppointmentModel._cancellationPolicySnapshotToJson(
              instance.cancellationPolicySnapshot),
      'couponCode': instance.couponCode,
      'discountAmountCents': instance.discountAmountCents,
    };

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.confirmed: 'confirmed',
  AppointmentStatus.arrived: 'arrived',
  AppointmentStatus.completed: 'completed',
  AppointmentStatus.noShow: 'no_show',
  AppointmentStatus.canceled: 'canceled',
};

CancellationPolicySnapshot _$CancellationPolicySnapshotFromJson(
        Map<String, dynamic> json) =>
    CancellationPolicySnapshot(
      acknowledged: json['acknowledged'] as bool,
      acknowledgedAt:
          AppointmentModel._timestampFromJson(json['acknowledgedAt']),
      policyVersion: json['policyVersion'] as String?,
      policyTextHash: json['policyTextHash'] as String?,
    );

Map<String, dynamic> _$CancellationPolicySnapshotToJson(
        CancellationPolicySnapshot instance) =>
    <String, dynamic>{
      'acknowledged': instance.acknowledged,
      'acknowledgedAt':
          AppointmentModel._timestampToJson(instance.acknowledgedAt),
      'policyVersion': instance.policyVersion,
      'policyTextHash': instance.policyTextHash,
    };

TermsAcceptanceMetadata _$TermsAcceptanceMetadataFromJson(
        Map<String, dynamic> json) =>
    TermsAcceptanceMetadata(
      termsAccepted: json['termsAccepted'] as bool,
      termsAcceptedAtUtc:
          AppointmentModel._timestampFromJson(json['termsAcceptedAtUtc']),
      termsAcceptedAtLocal:
          AppointmentModel._timestampFromJson(json['termsAcceptedAtLocal']),
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      platform: json['platform'] as String?,
      osVersion: json['osVersion'] as String?,
    );

Map<String, dynamic> _$TermsAcceptanceMetadataToJson(
        TermsAcceptanceMetadata instance) =>
    <String, dynamic>{
      'termsAccepted': instance.termsAccepted,
      'termsAcceptedAtUtc':
          AppointmentModel._timestampToJson(instance.termsAcceptedAtUtc),
      'termsAcceptedAtLocal':
          AppointmentModel._timestampToJson(instance.termsAcceptedAtLocal),
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
      'platform': instance.platform,
      'osVersion': instance.osVersion,
    };

HealthDisclosure _$HealthDisclosureFromJson(Map<String, dynamic> json) =>
    HealthDisclosure(
      hasSkinConditions: json['hasSkinConditions'] as bool,
      hasAllergies: json['hasAllergies'] as bool,
      hasCurrentMedications: json['hasCurrentMedications'] as bool,
      isPregnantOrBreastfeeding: json['isPregnantOrBreastfeeding'] as bool,
      hasRecentCosmeticTreatments: json['hasRecentCosmeticTreatments'] as bool,
      hasKnownReactions: json['hasKnownReactions'] as bool,
      additionalNotes: json['additionalNotes'] as String?,
    );

Map<String, dynamic> _$HealthDisclosureToJson(HealthDisclosure instance) =>
    <String, dynamic>{
      'hasSkinConditions': instance.hasSkinConditions,
      'hasAllergies': instance.hasAllergies,
      'hasCurrentMedications': instance.hasCurrentMedications,
      'isPregnantOrBreastfeeding': instance.isPregnantOrBreastfeeding,
      'hasRecentCosmeticTreatments': instance.hasRecentCosmeticTreatments,
      'hasKnownReactions': instance.hasKnownReactions,
      'additionalNotes': instance.additionalNotes,
    };

RequiredAcknowledgments _$RequiredAcknowledgmentsFromJson(
        Map<String, dynamic> json) =>
    RequiredAcknowledgments(
      understandsResultsNotGuaranteed:
          json['understandsResultsNotGuaranteed'] as bool,
      understandsServicesNonMedical:
          json['understandsServicesNonMedical'] as bool,
      agreesToFollowAftercare: json['agreesToFollowAftercare'] as bool,
      acceptsInherentRisks: json['acceptsInherentRisks'] as bool,
    );

Map<String, dynamic> _$RequiredAcknowledgmentsToJson(
        RequiredAcknowledgments instance) =>
    <String, dynamic>{
      'understandsResultsNotGuaranteed':
          instance.understandsResultsNotGuaranteed,
      'understandsServicesNonMedical': instance.understandsServicesNonMedical,
      'agreesToFollowAftercare': instance.agreesToFollowAftercare,
      'acceptsInherentRisks': instance.acceptsInherentRisks,
    };
