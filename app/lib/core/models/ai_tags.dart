import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_tags.freezed.dart';
part 'ai_tags.g.dart';

@freezed
class AiTags with _$AiTags {
  const factory AiTags({
    required MotivationType motivationType,
    required ReadinessLevel readinessLevel,
    required CoachStyle coachStyle,
  }) = _AiTags;

  factory AiTags.fromJson(Map<String, dynamic> json) => _$AiTagsFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.pascal)
enum MotivationType {
  @JsonValue('Internal')
  internal,
  @JsonValue('Mixed')
  mixed,
  @JsonValue('External')
  external,
  @JsonValue('Unclear')
  unclear,
}

@JsonEnum(fieldRename: FieldRename.pascal)
enum ReadinessLevel {
  @JsonValue('Low')
  low,
  @JsonValue('Moderate')
  moderate,
  @JsonValue('High')
  high,
}

@JsonEnum()
enum CoachStyle {
  @JsonValue('RH')
  rightHand,
  @JsonValue('Cheerleader')
  cheerleader,
  @JsonValue('DS')
  drillSergeant,
  @JsonValue('Unsure')
  unsure,
}
