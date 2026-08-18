import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_extensions.dart';

class CommunityPostModel {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final String originType;
  final String groupId;
  final String groupName;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int repostCount;
  final String originalPostId;
  final String originalAuthorName;
  final String imageUrl;
  final DateTime? createdAt;
  final bool isPoll;
  final List<String> pollOptions;
  final String pollType;
  final Map<String, List<String>> pollVotes;
  final int reportCount;
  final bool isSpam;

  CommunityPostModel({
    this.id = '',
    this.title = '',
    this.description = '',
    this.authorId = '',
    this.authorName = '',
    this.authorImageUrl = '',
    this.originType = 'public',
    this.groupId = '',
    this.groupName = 'Public',
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.repostCount = 0,
    this.originalPostId = '',
    this.originalAuthorName = '',
    this.imageUrl = '',
    this.createdAt,
    this.isPoll = false,
    this.pollOptions = const [],
    this.pollType = 'single',
    this.pollVotes = const {},
    this.reportCount = 0,
    this.isSpam = false,
  });

  bool get isPublic => originType == 'public';
  bool get isRepost => originalPostId.isNotEmpty;
  int get totalPollVotes => pollVotes.values.fold(0, (sum, list) => sum + list.length);

  CommunityPostModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? authorImageUrl,
    String? originType,
    String? groupId,
    String? groupName,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    int? repostCount,
    String? originalPostId,
    String? originalAuthorName,
    String? imageUrl,
    DateTime? createdAt,
    bool? isPoll,
    List<String>? pollOptions,
    String? pollType,
    Map<String, List<String>>? pollVotes,
    int? reportCount,
    bool? isSpam,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      originType: originType ?? this.originType,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      repostCount: repostCount ?? this.repostCount,
      originalPostId: originalPostId ?? this.originalPostId,
      originalAuthorName: originalAuthorName ?? this.originalAuthorName,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isPoll: isPoll ?? this.isPoll,
      pollOptions: pollOptions ?? this.pollOptions,
      pollType: pollType ?? this.pollType,
      pollVotes: pollVotes ?? this.pollVotes,
      reportCount: reportCount ?? this.reportCount,
      isSpam: isSpam ?? this.isSpam,
    );
  }

  factory CommunityPostModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityPostModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImageUrl: map['authorImageUrl'] ?? '',
      originType: map['originType'] ?? 'public',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? 'Public',
      likeCount: map['likeCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      repostCount: map['repostCount'] ?? 0,
      originalPostId: map['originalPostId'] ?? '',
      originalAuthorName: map['originalAuthorName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isPoll: map['isPoll'] ?? false,
      pollOptions: List<String>.from(map['pollOptions'] ?? []),
      pollType: map['pollType'] ?? 'single',
      pollVotes: (map['pollVotes'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v ?? [])),
      ) ?? {},
      reportCount: map['reportCount'] ?? 0,
      isSpam: map['isSpam'] ?? false,
      createdAt: map.parseTimestamp('createdAt'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'originType': originType,
      'groupId': groupId,
      'groupName': groupName,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'repostCount': repostCount,
      'originalPostId': originalPostId,
      'originalAuthorName': originalAuthorName,
      'imageUrl': imageUrl,
      'isPoll': isPoll,
      'pollOptions': pollOptions,
      'pollType': pollType,
      'pollVotes': pollVotes,
      'reportCount': reportCount,
      'isSpam': isSpam,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

class CommunityCommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final String parentId;
  final DateTime? createdAt;

  CommunityCommentModel({
    this.id = '',
    this.content = '',
    this.authorId = '',
    this.authorName = '',
    this.authorImageUrl = '',
    this.parentId = '',
    this.createdAt,
  });

  factory CommunityCommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityCommentModel(
      id: id,
      content: map['content'] ?? map['text'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImageUrl: map['authorImageUrl'] ?? '',
      parentId: map['parentId'] ?? map['reportId'] ?? '',
      createdAt: map.parseTimestamp('createdAt'),
    );
  }
}
