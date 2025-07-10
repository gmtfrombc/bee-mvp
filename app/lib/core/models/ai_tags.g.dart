// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_tags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiTagsImpl _$$AiTagsImplFromJson(Map<String, dynamic> json) => _$AiTagsImpl(
      motivationType:
          $enumDecode(_$MotivationTypeEnumMap, json['motivationType']),
      readinessLevel:
          $enumDecode(_$ReadinessLevelEnumMap, json['readinessLevel']),
      coachStyle: $enumDecode(_$CoachStyleEnumMap, json['coachStyle']),
    );

Map<String, dynamic> _$$AiTagsImplToJson(_$AiTagsImpl instance) =>
    <String, dynamic>{
      'motivationType': _$MotivationTypeEnumMap[instance.motivationType]!,
      'readinessLevel': _$ReadinessLevelEnumMap[instance.readinessLevel]!,
      'coachStyle': _$CoachStyleEnumMap[instance.coachStyle]!,
    };

const _$MotivationTypeEnumMap = {
  MotivationType.internal: 'Internal',
  MotivationType.mixed: 'Mixed',
  MotivationType.external: 'External',
  MotivationType.unclear: 'Unclear',
};

const _$ReadinessLevelEnumMap = {
  ReadinessLevel.low: 'Low',
  ReadinessLevel.moderate: 'Moderate',
  ReadinessLevel.high: 'High',
};

const _$CoachStyleEnumMap = {
  CoachStyle.rightHand: 'RH',
  CoachStyle.cheerleader: 'Cheerleader',
  CoachStyle.drillSergeant: 'DS',
  CoachStyle.unsure: 'Unsure',
};
