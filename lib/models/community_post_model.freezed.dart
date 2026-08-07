// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_post_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommunityPostModel {

 String get id; String get title; String get description; String get authorId; String get authorName; String get authorImageUrl; String get originType; String get groupId; String get groupName; int get likeCount; int get commentCount; int get viewCount; int get repostCount; String get originalPostId; String get originalAuthorName; String get imageUrl; DateTime? get createdAt; bool get isPoll; List<String> get pollOptions; String get pollType; Map<String, List<String>> get pollVotes;
/// Create a copy of CommunityPostModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunityPostModelCopyWith<CommunityPostModel> get copyWith => _$CommunityPostModelCopyWithImpl<CommunityPostModel>(this as CommunityPostModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityPostModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorImageUrl, authorImageUrl) || other.authorImageUrl == authorImageUrl)&&(identical(other.originType, originType) || other.originType == originType)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.originalPostId, originalPostId) || other.originalPostId == originalPostId)&&(identical(other.originalAuthorName, originalAuthorName) || other.originalAuthorName == originalAuthorName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isPoll, isPoll) || other.isPoll == isPoll)&&const DeepCollectionEquality().equals(other.pollOptions, pollOptions)&&(identical(other.pollType, pollType) || other.pollType == pollType)&&const DeepCollectionEquality().equals(other.pollVotes, pollVotes));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,authorId,authorName,authorImageUrl,originType,groupId,groupName,likeCount,commentCount,viewCount,repostCount,originalPostId,originalAuthorName,imageUrl,createdAt,isPoll,const DeepCollectionEquality().hash(pollOptions),pollType,const DeepCollectionEquality().hash(pollVotes)]);

@override
String toString() {
  return 'CommunityPostModel(id: $id, title: $title, description: $description, authorId: $authorId, authorName: $authorName, authorImageUrl: $authorImageUrl, originType: $originType, groupId: $groupId, groupName: $groupName, likeCount: $likeCount, commentCount: $commentCount, viewCount: $viewCount, repostCount: $repostCount, originalPostId: $originalPostId, originalAuthorName: $originalAuthorName, imageUrl: $imageUrl, createdAt: $createdAt, isPoll: $isPoll, pollOptions: $pollOptions, pollType: $pollType, pollVotes: $pollVotes)';
}


}

/// @nodoc
abstract mixin class $CommunityPostModelCopyWith<$Res>  {
  factory $CommunityPostModelCopyWith(CommunityPostModel value, $Res Function(CommunityPostModel) _then) = _$CommunityPostModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String authorId, String authorName, String authorImageUrl, String originType, String groupId, String groupName, int likeCount, int commentCount, int viewCount, int repostCount, String originalPostId, String originalAuthorName, String imageUrl, DateTime? createdAt, bool isPoll, List<String> pollOptions, String pollType, Map<String, List<String>> pollVotes
});




}
/// @nodoc
class _$CommunityPostModelCopyWithImpl<$Res>
    implements $CommunityPostModelCopyWith<$Res> {
  _$CommunityPostModelCopyWithImpl(this._self, this._then);

  final CommunityPostModel _self;
  final $Res Function(CommunityPostModel) _then;

/// Create a copy of CommunityPostModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? authorId = null,Object? authorName = null,Object? authorImageUrl = null,Object? originType = null,Object? groupId = null,Object? groupName = null,Object? likeCount = null,Object? commentCount = null,Object? viewCount = null,Object? repostCount = null,Object? originalPostId = null,Object? originalAuthorName = null,Object? imageUrl = null,Object? createdAt = freezed,Object? isPoll = null,Object? pollOptions = null,Object? pollType = null,Object? pollVotes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorImageUrl: null == authorImageUrl ? _self.authorImageUrl : authorImageUrl // ignore: cast_nullable_to_non_nullable
as String,originType: null == originType ? _self.originType : originType // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,originalPostId: null == originalPostId ? _self.originalPostId : originalPostId // ignore: cast_nullable_to_non_nullable
as String,originalAuthorName: null == originalAuthorName ? _self.originalAuthorName : originalAuthorName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isPoll: null == isPoll ? _self.isPoll : isPoll // ignore: cast_nullable_to_non_nullable
as bool,pollOptions: null == pollOptions ? _self.pollOptions : pollOptions // ignore: cast_nullable_to_non_nullable
as List<String>,pollType: null == pollType ? _self.pollType : pollType // ignore: cast_nullable_to_non_nullable
as String,pollVotes: null == pollVotes ? _self.pollVotes : pollVotes // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [CommunityPostModel].
extension CommunityPostModelPatterns on CommunityPostModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommunityPostModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommunityPostModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommunityPostModel value)  $default,){
final _that = this;
switch (_that) {
case _CommunityPostModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommunityPostModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommunityPostModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String authorId,  String authorName,  String authorImageUrl,  String originType,  String groupId,  String groupName,  int likeCount,  int commentCount,  int viewCount,  int repostCount,  String originalPostId,  String originalAuthorName,  String imageUrl,  DateTime? createdAt,  bool isPoll,  List<String> pollOptions,  String pollType,  Map<String, List<String>> pollVotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommunityPostModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.authorId,_that.authorName,_that.authorImageUrl,_that.originType,_that.groupId,_that.groupName,_that.likeCount,_that.commentCount,_that.viewCount,_that.repostCount,_that.originalPostId,_that.originalAuthorName,_that.imageUrl,_that.createdAt,_that.isPoll,_that.pollOptions,_that.pollType,_that.pollVotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String authorId,  String authorName,  String authorImageUrl,  String originType,  String groupId,  String groupName,  int likeCount,  int commentCount,  int viewCount,  int repostCount,  String originalPostId,  String originalAuthorName,  String imageUrl,  DateTime? createdAt,  bool isPoll,  List<String> pollOptions,  String pollType,  Map<String, List<String>> pollVotes)  $default,) {final _that = this;
switch (_that) {
case _CommunityPostModel():
return $default(_that.id,_that.title,_that.description,_that.authorId,_that.authorName,_that.authorImageUrl,_that.originType,_that.groupId,_that.groupName,_that.likeCount,_that.commentCount,_that.viewCount,_that.repostCount,_that.originalPostId,_that.originalAuthorName,_that.imageUrl,_that.createdAt,_that.isPoll,_that.pollOptions,_that.pollType,_that.pollVotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String authorId,  String authorName,  String authorImageUrl,  String originType,  String groupId,  String groupName,  int likeCount,  int commentCount,  int viewCount,  int repostCount,  String originalPostId,  String originalAuthorName,  String imageUrl,  DateTime? createdAt,  bool isPoll,  List<String> pollOptions,  String pollType,  Map<String, List<String>> pollVotes)?  $default,) {final _that = this;
switch (_that) {
case _CommunityPostModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.authorId,_that.authorName,_that.authorImageUrl,_that.originType,_that.groupId,_that.groupName,_that.likeCount,_that.commentCount,_that.viewCount,_that.repostCount,_that.originalPostId,_that.originalAuthorName,_that.imageUrl,_that.createdAt,_that.isPoll,_that.pollOptions,_that.pollType,_that.pollVotes);case _:
  return null;

}
}

}

/// @nodoc


class _CommunityPostModel extends CommunityPostModel {
  const _CommunityPostModel({this.id = '', this.title = '', this.description = '', this.authorId = '', this.authorName = '', this.authorImageUrl = '', this.originType = 'public', this.groupId = '', this.groupName = 'Public', this.likeCount = 0, this.commentCount = 0, this.viewCount = 0, this.repostCount = 0, this.originalPostId = '', this.originalAuthorName = '', this.imageUrl = '', this.createdAt = null, this.isPoll = false, final  List<String> pollOptions = const [], this.pollType = 'single', final  Map<String, List<String>> pollVotes = const {}}): _pollOptions = pollOptions,_pollVotes = pollVotes,super._();
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String authorId;
@override@JsonKey() final  String authorName;
@override@JsonKey() final  String authorImageUrl;
@override@JsonKey() final  String originType;
@override@JsonKey() final  String groupId;
@override@JsonKey() final  String groupName;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int commentCount;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int repostCount;
@override@JsonKey() final  String originalPostId;
@override@JsonKey() final  String originalAuthorName;
@override@JsonKey() final  String imageUrl;
@override@JsonKey() final  DateTime? createdAt;
@override@JsonKey() final  bool isPoll;
 final  List<String> _pollOptions;
@override@JsonKey() List<String> get pollOptions {
  if (_pollOptions is EqualUnmodifiableListView) return _pollOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pollOptions);
}

@override@JsonKey() final  String pollType;
 final  Map<String, List<String>> _pollVotes;
@override@JsonKey() Map<String, List<String>> get pollVotes {
  if (_pollVotes is EqualUnmodifiableMapView) return _pollVotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pollVotes);
}


/// Create a copy of CommunityPostModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommunityPostModelCopyWith<_CommunityPostModel> get copyWith => __$CommunityPostModelCopyWithImpl<_CommunityPostModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommunityPostModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorImageUrl, authorImageUrl) || other.authorImageUrl == authorImageUrl)&&(identical(other.originType, originType) || other.originType == originType)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.repostCount, repostCount) || other.repostCount == repostCount)&&(identical(other.originalPostId, originalPostId) || other.originalPostId == originalPostId)&&(identical(other.originalAuthorName, originalAuthorName) || other.originalAuthorName == originalAuthorName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isPoll, isPoll) || other.isPoll == isPoll)&&const DeepCollectionEquality().equals(other._pollOptions, _pollOptions)&&(identical(other.pollType, pollType) || other.pollType == pollType)&&const DeepCollectionEquality().equals(other._pollVotes, _pollVotes));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,authorId,authorName,authorImageUrl,originType,groupId,groupName,likeCount,commentCount,viewCount,repostCount,originalPostId,originalAuthorName,imageUrl,createdAt,isPoll,const DeepCollectionEquality().hash(_pollOptions),pollType,const DeepCollectionEquality().hash(_pollVotes)]);

@override
String toString() {
  return 'CommunityPostModel(id: $id, title: $title, description: $description, authorId: $authorId, authorName: $authorName, authorImageUrl: $authorImageUrl, originType: $originType, groupId: $groupId, groupName: $groupName, likeCount: $likeCount, commentCount: $commentCount, viewCount: $viewCount, repostCount: $repostCount, originalPostId: $originalPostId, originalAuthorName: $originalAuthorName, imageUrl: $imageUrl, createdAt: $createdAt, isPoll: $isPoll, pollOptions: $pollOptions, pollType: $pollType, pollVotes: $pollVotes)';
}


}

/// @nodoc
abstract mixin class _$CommunityPostModelCopyWith<$Res> implements $CommunityPostModelCopyWith<$Res> {
  factory _$CommunityPostModelCopyWith(_CommunityPostModel value, $Res Function(_CommunityPostModel) _then) = __$CommunityPostModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String authorId, String authorName, String authorImageUrl, String originType, String groupId, String groupName, int likeCount, int commentCount, int viewCount, int repostCount, String originalPostId, String originalAuthorName, String imageUrl, DateTime? createdAt, bool isPoll, List<String> pollOptions, String pollType, Map<String, List<String>> pollVotes
});




}
/// @nodoc
class __$CommunityPostModelCopyWithImpl<$Res>
    implements _$CommunityPostModelCopyWith<$Res> {
  __$CommunityPostModelCopyWithImpl(this._self, this._then);

  final _CommunityPostModel _self;
  final $Res Function(_CommunityPostModel) _then;

/// Create a copy of CommunityPostModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? authorId = null,Object? authorName = null,Object? authorImageUrl = null,Object? originType = null,Object? groupId = null,Object? groupName = null,Object? likeCount = null,Object? commentCount = null,Object? viewCount = null,Object? repostCount = null,Object? originalPostId = null,Object? originalAuthorName = null,Object? imageUrl = null,Object? createdAt = freezed,Object? isPoll = null,Object? pollOptions = null,Object? pollType = null,Object? pollVotes = null,}) {
  return _then(_CommunityPostModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorImageUrl: null == authorImageUrl ? _self.authorImageUrl : authorImageUrl // ignore: cast_nullable_to_non_nullable
as String,originType: null == originType ? _self.originType : originType // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,repostCount: null == repostCount ? _self.repostCount : repostCount // ignore: cast_nullable_to_non_nullable
as int,originalPostId: null == originalPostId ? _self.originalPostId : originalPostId // ignore: cast_nullable_to_non_nullable
as String,originalAuthorName: null == originalAuthorName ? _self.originalAuthorName : originalAuthorName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isPoll: null == isPoll ? _self.isPoll : isPoll // ignore: cast_nullable_to_non_nullable
as bool,pollOptions: null == pollOptions ? _self._pollOptions : pollOptions // ignore: cast_nullable_to_non_nullable
as List<String>,pollType: null == pollType ? _self.pollType : pollType // ignore: cast_nullable_to_non_nullable
as String,pollVotes: null == pollVotes ? _self._pollVotes : pollVotes // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}


}

/// @nodoc
mixin _$CommunityCommentModel {

 String get id; String get content; String get authorId; String get authorName; String get authorImageUrl; DateTime? get createdAt;
/// Create a copy of CommunityCommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunityCommentModelCopyWith<CommunityCommentModel> get copyWith => _$CommunityCommentModelCopyWithImpl<CommunityCommentModel>(this as CommunityCommentModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorImageUrl, authorImageUrl) || other.authorImageUrl == authorImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,content,authorId,authorName,authorImageUrl,createdAt);

@override
String toString() {
  return 'CommunityCommentModel(id: $id, content: $content, authorId: $authorId, authorName: $authorName, authorImageUrl: $authorImageUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CommunityCommentModelCopyWith<$Res>  {
  factory $CommunityCommentModelCopyWith(CommunityCommentModel value, $Res Function(CommunityCommentModel) _then) = _$CommunityCommentModelCopyWithImpl;
@useResult
$Res call({
 String id, String content, String authorId, String authorName, String authorImageUrl, DateTime? createdAt
});




}
/// @nodoc
class _$CommunityCommentModelCopyWithImpl<$Res>
    implements $CommunityCommentModelCopyWith<$Res> {
  _$CommunityCommentModelCopyWithImpl(this._self, this._then);

  final CommunityCommentModel _self;
  final $Res Function(CommunityCommentModel) _then;

/// Create a copy of CommunityCommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? authorId = null,Object? authorName = null,Object? authorImageUrl = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorImageUrl: null == authorImageUrl ? _self.authorImageUrl : authorImageUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommunityCommentModel].
extension CommunityCommentModelPatterns on CommunityCommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommunityCommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommunityCommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommunityCommentModel value)  $default,){
final _that = this;
switch (_that) {
case _CommunityCommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommunityCommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _CommunityCommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String content,  String authorId,  String authorName,  String authorImageUrl,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommunityCommentModel() when $default != null:
return $default(_that.id,_that.content,_that.authorId,_that.authorName,_that.authorImageUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String content,  String authorId,  String authorName,  String authorImageUrl,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CommunityCommentModel():
return $default(_that.id,_that.content,_that.authorId,_that.authorName,_that.authorImageUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String content,  String authorId,  String authorName,  String authorImageUrl,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CommunityCommentModel() when $default != null:
return $default(_that.id,_that.content,_that.authorId,_that.authorName,_that.authorImageUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _CommunityCommentModel extends CommunityCommentModel {
  const _CommunityCommentModel({this.id = '', this.content = '', this.authorId = '', this.authorName = '', this.authorImageUrl = '', this.createdAt = null}): super._();
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String content;
@override@JsonKey() final  String authorId;
@override@JsonKey() final  String authorName;
@override@JsonKey() final  String authorImageUrl;
@override@JsonKey() final  DateTime? createdAt;

/// Create a copy of CommunityCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommunityCommentModelCopyWith<_CommunityCommentModel> get copyWith => __$CommunityCommentModelCopyWithImpl<_CommunityCommentModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommunityCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.authorImageUrl, authorImageUrl) || other.authorImageUrl == authorImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,content,authorId,authorName,authorImageUrl,createdAt);

@override
String toString() {
  return 'CommunityCommentModel(id: $id, content: $content, authorId: $authorId, authorName: $authorName, authorImageUrl: $authorImageUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CommunityCommentModelCopyWith<$Res> implements $CommunityCommentModelCopyWith<$Res> {
  factory _$CommunityCommentModelCopyWith(_CommunityCommentModel value, $Res Function(_CommunityCommentModel) _then) = __$CommunityCommentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String content, String authorId, String authorName, String authorImageUrl, DateTime? createdAt
});




}
/// @nodoc
class __$CommunityCommentModelCopyWithImpl<$Res>
    implements _$CommunityCommentModelCopyWith<$Res> {
  __$CommunityCommentModelCopyWithImpl(this._self, this._then);

  final _CommunityCommentModel _self;
  final $Res Function(_CommunityCommentModel) _then;

/// Create a copy of CommunityCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? authorId = null,Object? authorName = null,Object? authorImageUrl = null,Object? createdAt = freezed,}) {
  return _then(_CommunityCommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,authorName: null == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String,authorImageUrl: null == authorImageUrl ? _self.authorImageUrl : authorImageUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
