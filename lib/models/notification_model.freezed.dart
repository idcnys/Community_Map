// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppNotificationModel {

 String get id; String get type; String get targetUserId; String get actorId; String get actorName; String get postId; String get postTitle; String get message; bool get read; DateTime? get createdAt;
/// Create a copy of AppNotificationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppNotificationModelCopyWith<AppNotificationModel> get copyWith => _$AppNotificationModelCopyWithImpl<AppNotificationModel>(this as AppNotificationModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppNotificationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.postTitle, postTitle) || other.postTitle == postTitle)&&(identical(other.message, message) || other.message == message)&&(identical(other.read, read) || other.read == read)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,targetUserId,actorId,actorName,postId,postTitle,message,read,createdAt);

@override
String toString() {
  return 'AppNotificationModel(id: $id, type: $type, targetUserId: $targetUserId, actorId: $actorId, actorName: $actorName, postId: $postId, postTitle: $postTitle, message: $message, read: $read, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AppNotificationModelCopyWith<$Res>  {
  factory $AppNotificationModelCopyWith(AppNotificationModel value, $Res Function(AppNotificationModel) _then) = _$AppNotificationModelCopyWithImpl;
@useResult
$Res call({
 String id, String type, String targetUserId, String actorId, String actorName, String postId, String postTitle, String message, bool read, DateTime? createdAt
});




}
/// @nodoc
class _$AppNotificationModelCopyWithImpl<$Res>
    implements $AppNotificationModelCopyWith<$Res> {
  _$AppNotificationModelCopyWithImpl(this._self, this._then);

  final AppNotificationModel _self;
  final $Res Function(AppNotificationModel) _then;

/// Create a copy of AppNotificationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? targetUserId = null,Object? actorId = null,Object? actorName = null,Object? postId = null,Object? postTitle = null,Object? message = null,Object? read = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,targetUserId: null == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,actorName: null == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,postTitle: null == postTitle ? _self.postTitle : postTitle // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppNotificationModel].
extension AppNotificationModelPatterns on AppNotificationModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppNotificationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppNotificationModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppNotificationModel value)  $default,){
final _that = this;
switch (_that) {
case _AppNotificationModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppNotificationModel value)?  $default,){
final _that = this;
switch (_that) {
case _AppNotificationModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String targetUserId,  String actorId,  String actorName,  String postId,  String postTitle,  String message,  bool read,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppNotificationModel() when $default != null:
return $default(_that.id,_that.type,_that.targetUserId,_that.actorId,_that.actorName,_that.postId,_that.postTitle,_that.message,_that.read,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String targetUserId,  String actorId,  String actorName,  String postId,  String postTitle,  String message,  bool read,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AppNotificationModel():
return $default(_that.id,_that.type,_that.targetUserId,_that.actorId,_that.actorName,_that.postId,_that.postTitle,_that.message,_that.read,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String targetUserId,  String actorId,  String actorName,  String postId,  String postTitle,  String message,  bool read,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AppNotificationModel() when $default != null:
return $default(_that.id,_that.type,_that.targetUserId,_that.actorId,_that.actorName,_that.postId,_that.postTitle,_that.message,_that.read,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AppNotificationModel extends AppNotificationModel {
  const _AppNotificationModel({this.id = '', this.type = '', this.targetUserId = '', this.actorId = '', this.actorName = '', this.postId = '', this.postTitle = '', this.message = '', this.read = false, this.createdAt = null}): super._();
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String type;
@override@JsonKey() final  String targetUserId;
@override@JsonKey() final  String actorId;
@override@JsonKey() final  String actorName;
@override@JsonKey() final  String postId;
@override@JsonKey() final  String postTitle;
@override@JsonKey() final  String message;
@override@JsonKey() final  bool read;
@override@JsonKey() final  DateTime? createdAt;

/// Create a copy of AppNotificationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppNotificationModelCopyWith<_AppNotificationModel> get copyWith => __$AppNotificationModelCopyWithImpl<_AppNotificationModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppNotificationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.postId, postId) || other.postId == postId)&&(identical(other.postTitle, postTitle) || other.postTitle == postTitle)&&(identical(other.message, message) || other.message == message)&&(identical(other.read, read) || other.read == read)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,targetUserId,actorId,actorName,postId,postTitle,message,read,createdAt);

@override
String toString() {
  return 'AppNotificationModel(id: $id, type: $type, targetUserId: $targetUserId, actorId: $actorId, actorName: $actorName, postId: $postId, postTitle: $postTitle, message: $message, read: $read, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AppNotificationModelCopyWith<$Res> implements $AppNotificationModelCopyWith<$Res> {
  factory _$AppNotificationModelCopyWith(_AppNotificationModel value, $Res Function(_AppNotificationModel) _then) = __$AppNotificationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String targetUserId, String actorId, String actorName, String postId, String postTitle, String message, bool read, DateTime? createdAt
});




}
/// @nodoc
class __$AppNotificationModelCopyWithImpl<$Res>
    implements _$AppNotificationModelCopyWith<$Res> {
  __$AppNotificationModelCopyWithImpl(this._self, this._then);

  final _AppNotificationModel _self;
  final $Res Function(_AppNotificationModel) _then;

/// Create a copy of AppNotificationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? targetUserId = null,Object? actorId = null,Object? actorName = null,Object? postId = null,Object? postTitle = null,Object? message = null,Object? read = null,Object? createdAt = freezed,}) {
  return _then(_AppNotificationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,targetUserId: null == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,actorName: null == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String,postId: null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,postTitle: null == postTitle ? _self.postTitle : postTitle // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
