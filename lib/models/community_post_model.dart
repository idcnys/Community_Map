import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_post_model.freezed.dart';

/// Nullable timestamp converter for Firestore.
class NullableTimestampConverter implements JsonConverter<DateTime, Timestamp?> {
  const NullableTimestampConverter();

  @override
  DateTime fromJson(Timestamp? timestamp) => timestamp?.toDate() ?? DateTime.now();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

@freezed
abstract class CommunityPostModel with _$CommunityPostModel {
  const CommunityPostModel._();

  const factory CommunityPostModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @Default('') String authorId,
    @Default('') String authorName,
    @Default('public') String originType,
    @Default('') String groupId,
    @Default('Public') String groupName,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int viewCount,
    @Default(0) int repostCount,
    @Default('') String originalPostId,
    @Default('') String originalAuthorName,
    @Default(null) DateTime? createdAt,
    // Poll fields
    @Default(false) bool isPoll,
    @Default([]) List<String> pollOptions,
    @Default('single') String pollType, // 'single' or 'multi'
    @Default({}) Map<String, List<String>> pollVotes, // optionIndex -> [userIds]
  }) = _CommunityPostModel;

  bool get isPublic => originType == 'public';
  bool get isRepost => originalPostId.isNotEmpty;
  int get totalPollVotes => pollVotes.values.fold(0, (sum, list) => sum + list.length);

  factory CommunityPostModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityPostModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      originType: map['originType'] ?? 'public',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? 'Public',
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      repostCount: map['repostCount'] ?? 0,
      originalPostId: map['originalPostId'] ?? '',
      originalAuthorName: map['originalAuthorName'] ?? '',
      isPoll: map['isPoll'] ?? false,
      pollOptions: List<String>.from(map['pollOptions'] ?? []),
      pollType: map['pollType'] ?? 'single',
      pollVotes: (map['pollVotes'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v ?? [])),
      ) ?? {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'originType': originType,
      'groupId': groupId,
      'groupName': groupName,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'repostCount': repostCount,
      'originalPostId': originalPostId,
      'originalAuthorName': originalAuthorName,
      'isPoll': isPoll,
      'pollOptions': pollOptions,
      'pollType': pollType,
      'pollVotes': pollVotes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

@freezed
abstract class CommunityCommentModel with _$CommunityCommentModel {
  const CommunityCommentModel._();

  const factory CommunityCommentModel({
    @Default('') String id,
    @Default('') String content,
    @Default('') String authorId,
    @Default('') String authorName,
    @Default(null) DateTime? createdAt,
  }) = _CommunityCommentModel;

  factory CommunityCommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityCommentModel(
      id: id,
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
