// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientModel _$ClientModelFromJson(Map<String, dynamic> json) => ClientModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$ClientTagEnumMap, e))
              .toList() ??
          [],
      internalNotes: json['internalNotes'] as String?,
      totalAppointments: (json['totalAppointments'] as num?)?.toInt() ?? 0,
      completedAppointments:
          (json['completedAppointments'] as num?)?.toInt() ?? 0,
      noShowCount: (json['noShowCount'] as num?)?.toInt() ?? 0,
      totalSpentCents: (json['totalSpentCents'] as num?)?.toInt() ?? 0,
      createdAt: ClientModel._timestampFromJson(json['createdAt']),
      updatedAt: ClientModel._timestampFromJson(json['updatedAt']),
      lastAppointmentAt:
          ClientModel._timestampFromJson(json['lastAppointmentAt']),
    );

Map<String, dynamic> _$ClientModelToJson(ClientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'tags': instance.tags.map((e) => _$ClientTagEnumMap[e]!).toList(),
      'internalNotes': instance.internalNotes,
      'totalAppointments': instance.totalAppointments,
      'completedAppointments': instance.completedAppointments,
      'noShowCount': instance.noShowCount,
      'totalSpentCents': instance.totalSpentCents,
      'createdAt': ClientModel._timestampToJson(instance.createdAt),
      'updatedAt': ClientModel._timestampToJson(instance.updatedAt),
      'lastAppointmentAt':
          ClientModel._timestampToJson(instance.lastAppointmentAt),
    };

const _$ClientTagEnumMap = {
  ClientTag.vip: 'vip',
  ClientTag.sensitiveSkin: 'sensitive_skin',
  ClientTag.repeatNoShow: 'repeat_no_show',
  ClientTag.regular: 'regular',
  ClientTag.firstTime: 'first_time',
  ClientTag.preferred: 'preferred',
};
