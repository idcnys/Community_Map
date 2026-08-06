
class CommunityPostModel {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String originType; // 'group' or 'public'
  final String groupId; // empty if public
  final String groupName; // 'Public' if public
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int repostCount;
  final String originalPostId; // non-empty if this is a repost
  final String originalAuthorName; // original author if repost
  final DateTime createdAt;

  CommunityPostModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.originType,
    this.groupId = '',
    this.groupName = 'Public',
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.repostCount = 0,
    this.originalPostId = '',
    this.originalAuthorName = '',
    required this.createdAt,
  });

  bool get isPublic => originType == 'public';
  bool get isRepost => originalPostId.isNotEmpty;

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
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
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
      'createdAt': createdAt,
    };
  }
}

class CommunityCommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  CommunityCommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory CommunityCommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommunityCommentModel(
      id: id,
      content: map['content'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
