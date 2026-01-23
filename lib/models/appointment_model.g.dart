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
    };

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.confirmed: 'confirmed',
  AppointmentStatus.arrived: 'arrived',
  AppointmentStatus.completed: 'completed',
  AppointmentStatus.noShow: 'no_show',
  AppointmentStatus.canceled: 'canceled',
};
