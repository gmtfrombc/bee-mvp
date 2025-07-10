// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_tags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AiTags _$AiTagsFromJson(Map<String, dynamic> json) {
  return _AiTags.fromJson(json);
}

/// @nodoc
mixin _$AiTags {
  MotivationType get motivationType => throw _privateConstructorUsedError;
  ReadinessLevel get readinessLevel => throw _privateConstructorUsedError;
  CoachStyle get coachStyle => throw _privateConstructorUsedError;

  /// Serializes this AiTags to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiTags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiTagsCopyWith<AiTags> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiTagsCopyWith<$Res> {
  factory $AiTagsCopyWith(AiTags value, $Res Function(AiTags) then) =
      _$AiTagsCopyWithImpl<$Res, AiTags>;
  @useResult
  $Res call(
      {MotivationType motivationType,
      ReadinessLevel readinessLevel,
      CoachStyle coachStyle});
}

/// @nodoc
class _$AiTagsCopyWithImpl<$Res, $Val extends AiTags>
    implements $AiTagsCopyWith<$Res> {
  _$AiTagsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiTags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? motivationType = null,
    Object? readinessLevel = null,
    Object? coachStyle = null,
  }) {
    return _then(_value.copyWith(
      motivationType: null == motivationType
          ? _value.motivationType
          : motivationType // ignore: cast_nullable_to_non_nullable
              as MotivationType,
      readinessLevel: null == readinessLevel
          ? _value.readinessLevel
          : readinessLevel // ignore: cast_nullable_to_non_nullable
              as ReadinessLevel,
      coachStyle: null == coachStyle
          ? _value.coachStyle
          : coachStyle // ignore: cast_nullable_to_non_nullable
              as CoachStyle,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AiTagsImplCopyWith<$Res> implements $AiTagsCopyWith<$Res> {
  factory _$$AiTagsImplCopyWith(
          _$AiTagsImpl value, $Res Function(_$AiTagsImpl) then) =
      __$$AiTagsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MotivationType motivationType,
      ReadinessLevel readinessLevel,
      CoachStyle coachStyle});
}

/// @nodoc
class __$$AiTagsImplCopyWithImpl<$Res>
    extends _$AiTagsCopyWithImpl<$Res, _$AiTagsImpl>
    implements _$$AiTagsImplCopyWith<$Res> {
  __$$AiTagsImplCopyWithImpl(
      _$AiTagsImpl _value, $Res Function(_$AiTagsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AiTags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? motivationType = null,
    Object? readinessLevel = null,
    Object? coachStyle = null,
  }) {
    return _then(_$AiTagsImpl(
      motivationType: null == motivationType
          ? _value.motivationType
          : motivationType // ignore: cast_nullable_to_non_nullable
              as MotivationType,
      readinessLevel: null == readinessLevel
          ? _value.readinessLevel
          : readinessLevel // ignore: cast_nullable_to_non_nullable
              as ReadinessLevel,
      coachStyle: null == coachStyle
          ? _value.coachStyle
          : coachStyle // ignore: cast_nullable_to_non_nullable
              as CoachStyle,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AiTagsImpl implements _AiTags {
  const _$AiTagsImpl(
      {required this.motivationType,
      required this.readinessLevel,
      required this.coachStyle});

  factory _$AiTagsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiTagsImplFromJson(json);

  @override
  final MotivationType motivationType;
  @override
  final ReadinessLevel readinessLevel;
  @override
  final CoachStyle coachStyle;

  @override
  String toString() {
    return 'AiTags(motivationType: $motivationType, readinessLevel: $readinessLevel, coachStyle: $coachStyle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiTagsImpl &&
            (identical(other.motivationType, motivationType) ||
                other.motivationType == motivationType) &&
            (identical(other.readinessLevel, readinessLevel) ||
                other.readinessLevel == readinessLevel) &&
            (identical(other.coachStyle, coachStyle) ||
                other.coachStyle == coachStyle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, motivationType, readinessLevel, coachStyle);

  /// Create a copy of AiTags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiTagsImplCopyWith<_$AiTagsImpl> get copyWith =>
      __$$AiTagsImplCopyWithImpl<_$AiTagsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiTagsImplToJson(
      this,
    );
  }
}

abstract class _AiTags implements AiTags {
  const factory _AiTags(
      {required final MotivationType motivationType,
      required final ReadinessLevel readinessLevel,
      required final CoachStyle coachStyle}) = _$AiTagsImpl;

  factory _AiTags.fromJson(Map<String, dynamic> json) = _$AiTagsImpl.fromJson;

  @override
  MotivationType get motivationType;
  @override
  ReadinessLevel get readinessLevel;
  @override
  CoachStyle get coachStyle;

  /// Create a copy of AiTags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiTagsImplCopyWith<_$AiTagsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
