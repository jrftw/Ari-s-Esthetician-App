// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      appointmentId: json['appointmentId'] as String,
      clientName: json['clientName'] as String,
      clientEmail: json['clientEmail'] as String,
      appointmentStartTime:
          NotificationModel._timestampFromJson(json['appointmentStartTime']),
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: NotificationModel._timestampFromJson(json['createdAt']),
      readAt: NotificationModel._timestampFromJson(json['readAt']),
      archivedAt: NotificationModel._timestampFromJson(json['archivedAt']),
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
      'appointmentId': instance.appointmentId,
      'clientName': instance.clientName,
      'clientEmail': instance.clientEmail,
      'appointmentStartTime':
          NotificationModel._timestampToJson(instance.appointmentStartTime),
      'previousStatus': instance.previousStatus,
      'newStatus': instance.newStatus,
      'isRead': instance.isRead,
      'isArchived': instance.isArchived,
      'createdAt': NotificationModel._timestampToJson(instance.createdAt),
      'readAt': NotificationModel._timestampToJson(instance.readAt),
      'archivedAt': NotificationModel._timestampToJson(instance.archivedAt),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.appointmentCreated: 'appointment_created',
  NotificationType.appointmentUpdated: 'appointment_updated',
  NotificationType.appointmentCanceled: 'appointment_canceled',
  NotificationType.appointmentStatusChanged: 'appointment_status_changed',
};
